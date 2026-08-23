#Requires -Version 5.1
<#
.SYNOPSIS
  Installs or upgrades Prometheus as an automatic Windows service using NSSM.
.DESCRIPTION
  Copies the Windows amd64 runtime and project configuration to a conventional
  installation directory, validates the configuration with promtool, configures
  service recovery and rotating logs, then starts the service.
.EXAMPLE
  .\scripts\powershell\prometheus\Install-Prometheus.ps1 `
    -WebConfigPath C:\Secure\prometheus-web-config.yml
.EXAMPLE
  $password = Read-Host 'Prometheus password' -AsSecureString
  .\scripts\powershell\prometheus\Install-Prometheus.ps1 `
    -BasicAuthUsername admin -BasicAuthPassword $password
.EXAMPLE
  .\scripts\powershell\prometheus\Install-Prometheus.ps1 -AllowUnauthenticated -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SourceRoot,
    [string]$InstallRoot = 'C:\Program Files\Observability\Prometheus',
    [string]$DataRoot,
    [string]$LogRoot,
    [string]$ServiceName = 'prometheus',
    [string]$ServiceDisplayName = 'Prometheus Monitoring Server',
    [string]$ServiceDescription = 'Prometheus monitoring and time-series database',
    [string]$ListenAddress = '0.0.0.0:9090',
    [string]$WebConfigPath,
    [string]$BasicAuthUsername,
    [SecureString]$BasicAuthPassword,
    [string]$BasicAuthHash,
    [switch]$AllowUnauthenticated,
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

function Copy-DirectoryContent {
    param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Destination)
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "Required source directory was not found: $Source"
    }
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
$DataRoot = if ([string]::IsNullOrWhiteSpace($DataRoot)) { Join-Path $InstallRoot 'data' } else { $DataRoot }
$LogRoot = if ([string]::IsNullOrWhiteSpace($LogRoot)) { Join-Path $InstallRoot 'logs' } else { $LogRoot }
$DataRoot = Assert-SafeAbsolutePath -Path $DataRoot -Name DataRoot
$LogRoot = Assert-SafeAbsolutePath -Path $LogRoot -Name LogRoot

if ($ListenAddress -notmatch '^(?:\d{1,3}(?:\.\d{1,3}){3}|localhost|\*|):\d+$') {
    throw "Invalid ListenAddress: $ListenAddress"
}

$authOptions = @(
    -not [string]::IsNullOrWhiteSpace($WebConfigPath),
    -not [string]::IsNullOrWhiteSpace($BasicAuthUsername),
    $null -ne $BasicAuthPassword,
    -not [string]::IsNullOrWhiteSpace($BasicAuthHash)
)
if (-not $AllowUnauthenticated -and -not ($authOptions -contains $true)) {
    throw 'Authentication is required. Pass -WebConfigPath, Basic Auth parameters, or explicitly use -AllowUnauthenticated.'
}
if ($AllowUnauthenticated -and ($authOptions -contains $true)) {
    throw 'Do not combine -AllowUnauthenticated with authentication parameters.'
}

$prometheusSource = Join-Path $SourceRoot 'prometheus\bin\windows-amd64\prometheus.exe'
$promtoolSource = Join-Path $SourceRoot 'prometheus\bin\windows-amd64\promtool.exe'
$nssmSource = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
$configSource = Join-Path $SourceRoot 'prometheus\config\prometheus.yml'
$webTemplate = Join-Path $SourceRoot 'prometheus\config\web-config.example.yml'
$webHelper = Join-Path $SourceRoot 'scripts\powershell\common\Observability-WebConfigHelpers.ps1'
$secretSource = Join-Path $SourceRoot 'prometheus\secrets'

foreach ($requiredFile in @($prometheusSource, $promtoolSource, $nssmSource, $configSource, $webTemplate, $webHelper)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required source file was not found: $requiredFile"
    }
}

. $webHelper
$temporaryWebConfig = $null
try {
    if ($AllowUnauthenticated) {
        $temporaryWebConfig = Join-Path $env:TEMP ("prometheus-web-{0}.yml" -f [guid]::NewGuid().ToString('N'))
        New-ObservabilityWebConfigDeployFile -TemplatePath $webTemplate -OutputPath $temporaryWebConfig -BasicAuthUsers @{} | Out-Null
        $resolvedWebConfig = $temporaryWebConfig
    }
    else {
        $resolvedWebConfig = Resolve-ObservabilityWebConfigDeployment `
            -TemplatePath $webTemplate `
            -WebConfigPath $WebConfigPath `
            -BasicAuthUsername $BasicAuthUsername `
            -BasicAuthPassword $BasicAuthPassword `
            -BasicAuthHash $BasicAuthHash
        if ([string]::IsNullOrWhiteSpace($WebConfigPath)) { $temporaryWebConfig = $resolvedWebConfig }
    }

    $existingService = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $ServiceName.Replace("'", "''")) -ErrorAction SilentlyContinue
    if ($existingService -and $existingService.PathName -notmatch '(?i)nssm\.exe') {
        throw "Service '$ServiceName' already exists but is not managed by NSSM. Remove or rename it before continuing."
    }

    if (-not $PSCmdlet.ShouldProcess($InstallRoot, "Install Prometheus and configure service '$ServiceName'")) {
        return
    }

    if ($existingService) {
        $service = Get-Service -Name $ServiceName
        if ($service.Status -ne 'Stopped') {
            Stop-Service -Name $ServiceName -Force
            $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
        }
    }

    $binTarget = Join-Path $InstallRoot 'bin'
    $configTarget = Join-Path $InstallRoot 'config'
    $rulesTarget = Join-Path $InstallRoot 'alert-rules'
    $recordingTarget = Join-Path $InstallRoot 'recording-rules'
    $targetsTarget = Join-Path $InstallRoot 'targets'
    $secretsTarget = Join-Path $InstallRoot 'secrets'
    foreach ($directory in @($binTarget, $configTarget, $rulesTarget, $recordingTarget, $targetsTarget, $secretsTarget, $DataRoot, $LogRoot)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $prometheusTarget = Join-Path $binTarget 'prometheus.exe'
    $promtoolTarget = Join-Path $binTarget 'promtool.exe'
    $script:nssmTarget = Join-Path $binTarget 'nssm.exe'
    Copy-DirectoryContent -Source (Join-Path $SourceRoot 'prometheus\bin\windows-amd64') -Destination $binTarget
    Copy-Item -LiteralPath $nssmSource -Destination $script:nssmTarget -Force

    $deployedConfig = Join-Path $configTarget 'prometheus.yml'
    if ($ForceConfig -or -not (Test-Path -LiteralPath $deployedConfig)) {
        Copy-Item -LiteralPath $configSource -Destination $deployedConfig -Force
    }
    $deployedWebConfig = Join-Path $configTarget 'web-config.yml'
    Copy-Item -LiteralPath $resolvedWebConfig -Destination $deployedWebConfig -Force
    Copy-Item -LiteralPath $webTemplate -Destination (Join-Path $configTarget 'web-config.example.yml') -Force
    Copy-DirectoryContent -Source (Join-Path $SourceRoot 'prometheus\alert-rules') -Destination $rulesTarget
    Copy-DirectoryContent -Source (Join-Path $SourceRoot 'prometheus\recording-rules') -Destination $recordingTarget
    Copy-DirectoryContent -Source (Join-Path $SourceRoot 'prometheus\targets') -Destination $targetsTarget

    if (Test-Path -LiteralPath $secretSource -PathType Container) {
        Get-ChildItem -LiteralPath $secretSource -File | Where-Object { $_.Length -gt 0 } | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $secretsTarget $_.Name) -Force
        }
    }

    & $promtoolTarget check web-config $deployedWebConfig
    if ($LASTEXITCODE -ne 0) { throw 'Prometheus web configuration validation failed.' }
    & $promtoolTarget check config $deployedConfig
    if ($LASTEXITCODE -ne 0) { throw 'Prometheus configuration validation failed.' }

    $appParameters = @(
        "--config.file=`"$deployedConfig`""
        "--web.config.file=`"$deployedWebConfig`""
        "--storage.tsdb.path=`"$DataRoot`""
        "--web.listen-address=`"$ListenAddress`""
        '--web.enable-lifecycle'
    ) -join ' '

    if (-not $existingService) {
        Invoke-Nssm -Arguments @('install', $ServiceName, $prometheusTarget)
    }
    Invoke-Nssm -Arguments @('set', $ServiceName, 'Application', $prometheusTarget)
    Invoke-Nssm -Arguments @('set', $ServiceName, 'AppDirectory', $InstallRoot)
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
        $port = [int](($ListenAddress -split ':')[-1])
        $firewallName = "Prometheus TCP $port"
        if (-not (Get-NetFirewallRule -DisplayName $firewallName -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName $firewallName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -Profile Domain,Private | Out-Null
        }
    }

    Start-Service -Name $ServiceName
    $runningService = Get-Service -Name $ServiceName
    $runningService.WaitForStatus('Running', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
    Start-Sleep -Seconds 3
    $runningService.Refresh()
    if ($runningService.Status -ne 'Running') {
        $errorLog = Join-Path $LogRoot "$ServiceName.err.log"
        $tail = if (Test-Path -LiteralPath $errorLog) { Get-Content -LiteralPath $errorLog -Tail 50 | Out-String } else { 'No error log was created.' }
        throw "Prometheus service stopped after startup.`n$tail"
    }

    [pscustomobject]@{
        Service = $ServiceName
        Status = $runningService.Status
        Startup = 'Automatic (Delayed Start)'
        InstallRoot = $InstallRoot
        DataRoot = $DataRoot
        LogRoot = $LogRoot
        ListenAddress = $ListenAddress
    }
}
finally {
    if ($temporaryWebConfig -and (Test-Path -LiteralPath $temporaryWebConfig)) {
        Remove-Item -LiteralPath $temporaryWebConfig -Force -ErrorAction SilentlyContinue
    }
}
