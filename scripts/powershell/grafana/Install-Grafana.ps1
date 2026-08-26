#Requires -Version 5.1
<#
.SYNOPSIS
  Installs or upgrades Grafana as an automatic Windows service using NSSM.
.DESCRIPTION
  Deploys a Grafana Windows runtime, provisions Prometheus and project
  dashboards, protects the generated secrets, configures recovery and rotating
  logs, and verifies the Grafana health endpoint after startup.
.EXAMPLE
  $adminPassword = Read-Host 'Grafana admin password' -AsSecureString
  .\scripts\powershell\grafana\Install-Grafana.ps1 `
    -AdminPassword $adminPassword -OpenFirewall
.EXAMPLE
  $adminPassword = Read-Host 'Grafana admin password' -AsSecureString
  $prometheusPassword = Read-Host 'Prometheus password' -AsSecureString
  .\scripts\powershell\grafana\Install-Grafana.ps1 `
    -RuntimeArchivePath C:\Install\grafana.zip `
    -AdminPassword $adminPassword `
    -PrometheusUsername admin -PrometheusPassword $prometheusPassword
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SourceRoot,
    [string]$RuntimeArchivePath,
    [string]$InstallRoot = 'C:\Program Files\Observability\Grafana',
    [string]$DataRoot,
    [string]$LogRoot,
    [string]$ServiceName = 'grafana',
    [string]$ServiceDisplayName = 'Grafana Observability Server',
    [string]$ServiceDescription = 'Grafana dashboards and visualization server',
    [string]$HttpAddress = '0.0.0.0',
    [ValidateRange(1, 65535)][int]$HttpPort = 3000,
    [string]$Domain = 'localhost',
    [string]$RootUrl,
    [string]$AdminUsername = 'admin',
    [SecureString]$AdminPassword,
    [switch]$AllowDefaultAdminPassword,
    [string]$PrometheusUrl = 'http://localhost:9090',
    [string]$PrometheusUsername,
    [SecureString]$PrometheusPassword,
    [switch]$ForceConfig,
    [switch]$OpenFirewall,
    [ValidateRange(5, 300)][int]$ServiceTimeoutSec = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this installer from an elevated PowerShell session (Run as Administrator).'
    }
}

function Assert-SafeAbsolutePath {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name)
    $resolved = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Path.TrimEnd('\')))
    if (-not [IO.Path]::IsPathRooted($resolved) -or $resolved -eq [IO.Path]::GetPathRoot($resolved)) {
        throw "Unsafe $Name path: $resolved"
    }
    $resolved
}

function ConvertFrom-SecureValue {
    param([Parameter(Mandatory)][SecureString]$Value)
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}

function ConvertTo-IniValue {
    param([Parameter(Mandatory)][string]$Value)
    if ($Value -match "[\r\n]") { throw 'Configuration values cannot contain line breaks.' }
    $Value
}

function ConvertTo-YamlDoubleQuoted {
    param([Parameter(Mandatory)][string]$Value)
    '"' + $Value.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n') + '"'
}

function Copy-DirectoryContent {
    param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Destination)
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Invoke-Nssm {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = & $script:nssmTarget @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "NSSM failed: nssm $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }
}

Assert-Administrator

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
}
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$InstallRoot = Assert-SafeAbsolutePath -Path $InstallRoot -Name InstallRoot
$DataRoot = Assert-SafeAbsolutePath -Path $(if ($DataRoot) { $DataRoot } else { Join-Path $InstallRoot 'data' }) -Name DataRoot
$LogRoot = Assert-SafeAbsolutePath -Path $(if ($LogRoot) { $LogRoot } else { Join-Path $InstallRoot 'logs' }) -Name LogRoot

if ($HttpAddress -notmatch '^(?:\d{1,3}(?:\.\d{1,3}){3}|localhost|\*)$') { throw "Invalid HttpAddress: $HttpAddress" }
if ($PrometheusUrl -notmatch '^https?://') { throw 'PrometheusUrl must start with http:// or https://.' }
if ([string]::IsNullOrWhiteSpace($RootUrl)) { $RootUrl = "http://${Domain}:$HttpPort/" }
if (-not $AllowDefaultAdminPassword -and $null -eq $AdminPassword) {
    throw 'AdminPassword is required. Use -AllowDefaultAdminPassword only for an isolated test environment.'
}
if ($AllowDefaultAdminPassword -and $null -ne $AdminPassword) { throw 'Do not combine AllowDefaultAdminPassword and AdminPassword.' }
if ([string]::IsNullOrWhiteSpace($PrometheusUsername) -ne ($null -eq $PrometheusPassword)) {
    throw 'PrometheusUsername and PrometheusPassword must be supplied together.'
}

$runtimeSource = Join-Path $SourceRoot 'grafana\runtime'
$serverSource = Join-Path $SourceRoot 'grafana\bin\windows-amd64\grafana.exe'
$nssmSource = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
$configTemplate = Join-Path $SourceRoot 'grafana\config\grafana.ini.template'
$datasourceTemplate = Join-Path $SourceRoot 'grafana\provisioning\datasources\prometheus.yml.template'
$dashboardProviderSource = Join-Path $SourceRoot 'grafana\provisioning\dashboards\dashboards.yml'
$dashboardSource = Join-Path $SourceRoot 'grafana\dashboards'
foreach ($required in @($nssmSource, $configTemplate, $datasourceTemplate, $dashboardProviderSource)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required source file was not found: $required" }
}

$temporaryRuntime = $null
try {
    if ($RuntimeArchivePath) {
        $RuntimeArchivePath = (Resolve-Path -LiteralPath $RuntimeArchivePath).Path
        $temporaryRuntime = Join-Path $env:TEMP ("grafana-runtime-{0}" -f [guid]::NewGuid().ToString('N'))
        if ($RuntimeArchivePath -match '\.zip$') {
            Expand-Archive -LiteralPath $RuntimeArchivePath -DestinationPath $temporaryRuntime -Force
        }
        elseif ($RuntimeArchivePath -match '\.(?:tar\.gz|tgz)$') {
            New-Item -ItemType Directory -Path $temporaryRuntime -Force | Out-Null
            & tar.exe -xzf $RuntimeArchivePath -C $temporaryRuntime
            if ($LASTEXITCODE -ne 0) { throw 'Could not extract the Grafana tar.gz archive.' }
        }
        else {
            throw 'RuntimeArchivePath must be a .zip, .tar.gz, or .tgz archive.'
        }
        $runtimeCandidate = Get-ChildItem -LiteralPath $temporaryRuntime -Recurse -File | Where-Object { $_.Name -in @('grafana-server.exe', 'grafana.exe') } | Select-Object -First 1
        if (-not $runtimeCandidate) { throw 'The archive does not contain grafana-server.exe or grafana.exe.' }
        $runtimeSource = Split-Path (Split-Path $runtimeCandidate.FullName -Parent) -Parent
        $serverSource = $runtimeCandidate.FullName
    }

    if (-not (Test-Path -LiteralPath $serverSource -PathType Leaf)) { throw "Windows Grafana binary was not found: $serverSource" }
    if (-not (Test-Path -LiteralPath (Join-Path $runtimeSource 'public') -PathType Container)) { throw "Grafana shared runtime was not found: $runtimeSource" }

    $existingService = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $ServiceName.Replace("'", "''")) -ErrorAction SilentlyContinue
    if ($existingService -and $existingService.PathName -notmatch '(?i)nssm\.exe') {
        throw "Service '$ServiceName' already exists but is not managed by NSSM. Remove or rename it before continuing."
    }
    if (-not $PSCmdlet.ShouldProcess($InstallRoot, "Install Grafana and configure service '$ServiceName'")) { return }

    if ($existingService) {
        $service = Get-Service -Name $ServiceName
        if ($service.Status -ne 'Stopped') {
            Stop-Service -Name $ServiceName -Force
            $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
        }
    }

    $runtimeTarget = Join-Path $InstallRoot 'runtime'
    $configTarget = Join-Path $InstallRoot 'config'
    $provisioningTarget = Join-Path $InstallRoot 'provisioning'
    $dashboardsTarget = Join-Path $InstallRoot 'dashboards'
    $pluginsTarget = Join-Path $InstallRoot 'plugins'
    $secretsTarget = Join-Path $InstallRoot 'secrets'
    foreach ($directory in @($runtimeTarget, $configTarget, $provisioningTarget, $dashboardsTarget, $pluginsTarget, $secretsTarget, $DataRoot, $LogRoot)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Copy-DirectoryContent -Source $runtimeSource -Destination $runtimeTarget
    $runtimeBinTarget = Join-Path $runtimeTarget 'bin'
    New-Item -ItemType Directory -Path $runtimeBinTarget -Force | Out-Null
    Copy-Item -LiteralPath $serverSource -Destination (Join-Path $runtimeBinTarget ([IO.Path]::GetFileName($serverSource))) -Force
    Copy-DirectoryContent -Source $dashboardSource -Destination $dashboardsTarget
    New-Item -ItemType Directory -Path (Join-Path $provisioningTarget 'datasources'),(Join-Path $provisioningTarget 'dashboards') -Force | Out-Null

    $adminSecret = Join-Path $secretsTarget 'grafana-admin-password'
    $adminPlain = if ($AdminPassword) { ConvertFrom-SecureValue $AdminPassword } else { 'admin' }
    [IO.File]::WriteAllText($adminSecret, $adminPlain, [Text.UTF8Encoding]::new($false))
    & icacls.exe $adminSecret /inheritance:r /grant:r '*S-1-5-18:(R)' '*S-1-5-32-544:(F)' | Out-Null

    $configPath = Join-Path $configTarget 'grafana.ini'
    if ($ForceConfig -or -not (Test-Path -LiteralPath $configPath)) {
        $config = Get-Content -LiteralPath $configTemplate -Raw
        $values = @{
            '{{DATA_ROOT}}' = $DataRoot; '{{LOG_ROOT}}' = $LogRoot; '{{PLUGINS_ROOT}}' = $pluginsTarget
            '{{PROVISIONING_ROOT}}' = $provisioningTarget; '{{HTTP_ADDR}}' = $HttpAddress
            '{{HTTP_PORT}}' = "$HttpPort"; '{{DOMAIN}}' = $Domain; '{{ROOT_URL}}' = $RootUrl
            '{{ADMIN_USER}}' = $AdminUsername; '{{ADMIN_PASSWORD_FILE}}' = $adminSecret
            '{{COOKIE_SECURE}}' = if ($RootUrl -match '^https://') { 'true' } else { 'false' }
        }
        foreach ($entry in $values.GetEnumerator()) { $config = $config.Replace($entry.Key, (ConvertTo-IniValue $entry.Value)) }
        [IO.File]::WriteAllText($configPath, $config, [Text.UTF8Encoding]::new($false))
    }

    $basicAuthBlock = ''
    if ($PrometheusUsername) {
        $prometheusPlain = ConvertFrom-SecureValue $PrometheusPassword
        $basicAuthBlock = @"
    basicAuth: true
    basicAuthUser: $(ConvertTo-YamlDoubleQuoted $PrometheusUsername)
    secureJsonData:
      basicAuthPassword: $(ConvertTo-YamlDoubleQuoted $prometheusPlain)
"@
    }
    $datasource = (Get-Content -LiteralPath $datasourceTemplate -Raw).Replace('{{PROMETHEUS_URL}}', $PrometheusUrl.Replace('"', '\"')).Replace('{{BASIC_AUTH_BLOCK}}', $basicAuthBlock.TrimEnd())
    $datasourcePath = Join-Path $provisioningTarget 'datasources\prometheus.yml'
    [IO.File]::WriteAllText($datasourcePath, $datasource, [Text.UTF8Encoding]::new($false))
    if ($PrometheusUsername) {
        & icacls.exe $datasourcePath /inheritance:r /grant:r '*S-1-5-18:(R)' '*S-1-5-32-544:(F)' | Out-Null
    }
    $dashboardProvider = (Get-Content -LiteralPath $dashboardProviderSource -Raw).Replace('__DASHBOARDS_ROOT__', $dashboardsTarget)
    [IO.File]::WriteAllText((Join-Path $provisioningTarget 'dashboards\dashboards.yml'), $dashboardProvider, [Text.UTF8Encoding]::new($false))

    $serverTarget = Get-ChildItem -LiteralPath $runtimeTarget -Recurse -File | Where-Object { $_.Name -in @('grafana-server.exe', 'grafana.exe') } | Select-Object -First 1
    $homePath = $runtimeTarget
    if (-not (Test-Path -LiteralPath (Join-Path $homePath 'public'))) {
        $homePath = Split-Path (Split-Path $serverTarget.FullName -Parent) -Parent
    }
    $script:nssmTarget = Join-Path $InstallRoot 'nssm.exe'
    Copy-Item -LiteralPath $nssmSource -Destination $script:nssmTarget -Force
    $appParameters = if ($serverTarget.Name -eq 'grafana.exe') {
        "server --homepath=`"$homePath`" --config=`"$configPath`""
    } else {
        "--homepath=`"$homePath`" --config=`"$configPath`""
    }

    if (-not $existingService) { Invoke-Nssm -Arguments @('install', $ServiceName, $serverTarget.FullName) }
    Invoke-Nssm -Arguments @('set', $ServiceName, 'Application', $serverTarget.FullName)
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppDirectory', $homePath)
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppParameters', $appParameters)
    Invoke-Nssm -Arguments @('set', $ServiceName, 'DisplayName', $ServiceDisplayName)
    Invoke-Nssm -Arguments @('set', $ServiceName, 'Description', $ServiceDescription)
    Invoke-Nssm -Arguments @('set', $ServiceName, 'Start', 'SERVICE_DELAYED_AUTO_START')
    Invoke-Nssm -Arguments @('set', $ServiceName, 'ObjectName', 'LocalSystem')
    Invoke-Nssm -Arguments @('set', $ServiceName, 'DependOnService', 'Tcpip')
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppExit', 'Default', 'Restart')
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRestartDelay', '5000')
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppThrottle', '5000')
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppStdout', (Join-Path $LogRoot "$ServiceName.out.log"))
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppStderr', (Join-Path $LogRoot "$ServiceName.err.log"))
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateFiles', '1')
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateOnline', '1')
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateBytes', '10485760')
    & sc.exe failure $ServiceName 'reset=' 86400 'actions=' 'restart/5000/restart/15000/restart/60000' | Out-Null
    & sc.exe failureflag $ServiceName 1 | Out-Null

    if ($OpenFirewall) {
        $firewallName = "Grafana TCP $HttpPort"
        if (-not (Get-NetFirewallRule -DisplayName $firewallName -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName $firewallName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $HttpPort -Profile Domain,Private | Out-Null
        }
    }

    Start-Service -Name $ServiceName
    $runningService = Get-Service -Name $ServiceName
    $runningService.WaitForStatus('Running', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
    $healthHost = if ($HttpAddress -in @('0.0.0.0', '*')) { 'localhost' } else { $HttpAddress }
    $healthUri = "http://${healthHost}:$HttpPort/api/health"
    $deadline = [DateTime]::UtcNow.AddSeconds($ServiceTimeoutSec)
    $health = $null
    do {
        try { $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 5; break } catch { Start-Sleep -Seconds 2 }
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $health -or $health.database -ne 'ok') {
        $errorLog = Join-Path $LogRoot "$ServiceName.err.log"
        $tail = if (Test-Path -LiteralPath $errorLog) { Get-Content $errorLog -Tail 50 | Out-String } else { 'No error log was created.' }
        throw "Grafana health check failed at $healthUri.`n$tail"
    }

    [pscustomobject]@{ Service = $ServiceName; Status = $runningService.Status; Url = $RootUrl; InstallRoot = $InstallRoot; DataRoot = $DataRoot; LogRoot = $LogRoot }
}
finally {
    $adminPlain = $null
    $prometheusPlain = $null
    if ($temporaryRuntime -and (Test-Path -LiteralPath $temporaryRuntime)) { Remove-Item -LiteralPath $temporaryRuntime -Recurse -Force -ErrorAction SilentlyContinue }
}
