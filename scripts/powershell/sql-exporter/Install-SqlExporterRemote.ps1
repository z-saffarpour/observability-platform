#Requires -Version 5.1
<#
.SYNOPSIS
  Install or update sql_exporter remotely over WinRM (optionally using NSSM).

.DESCRIPTION
  - Uses PowerShell Remoting (WinRM) and Copy-Item -ToSession
  - Stages files on remote host, then deploys atomically into install path
  - Creates or updates Windows service using native Service Control Manager
  - Supports LocalSystem / LocalService / NetworkService / gMSA / custom credential
  - Idempotent: safe to run repeatedly for update rollout
  - Optional -Profile applies profiles/<name>.yml collectors into sql_exporter.yml
    (same UX as windows_exporter -Profile sql-server.yml)

  Files deployed from SourceRoot (the repository root):
    - exporters\sql-exporter\bin\sql_exporter.exe
    - exporters\sql-exporter\config\sql_exporter.yml
    - exporters\sql-exporter\config\web-config.yml
    - exporters\sql-exporter\version\sql_exporter_version
    - profiles\*.yml
    - collector\*.collector.yml (deployed as collectors\ unless -SkipCollectors)

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
    -Computers (Get-Content .\scripts\powershell\sql-exporter\servers.txt) `
    -RemoteCredential (Get-Credential)

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -Profile oltp.yml `
    -RemoteCredential (Get-Credential)

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -ServiceAccountMode Credential `
    -ServiceCredential (Get-Credential 'DOMAIN\SqlExporterAccount')

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -ServiceAccountMode gMSA `
    -ServiceAccount 'DOMAIN\SqlExporterAccount$'

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -ListenAddress ':9399' `
    -BasicAuthUsername 'scrape_user' `
    -BasicAuthHash '$2a$12$...' `
    -RemoteCredential (Get-Credential)

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -ListenAddress '127.0.0.1:9399' `
    -WebConfigPath 'C:\Secrets\sql-exporter-web-config.yml' `
    -RemoteCredential (Get-Credential)

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -TargetName 'sql-prod-01' `
    -DataSourceName 'sqlserver://sql-prod-01:1433?trusted+connection=yes&encrypt=true&TrustServerCertificate=true&app+name=sql_exporter' `
    -SqlServerServiceDependency Auto `
    -RemoteCredential (Get-Credential)

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -SqlServerServiceName 'MSSQL$INSTANCE01' `
    -RemoteCredential (Get-Credential)
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Computers = @(
        'sql-host-01'
        'sql-host-02'
        'sql-host-03'
        'sql-host-04'
    ),

    [Parameter(Mandatory = $false)]
    [string]$SourceRoot,

    [Parameter(Mandatory = $false)]
    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\sql-exporter',

    [Parameter(Mandatory = $false)]
    [string]$ServiceName = 'prometheus_sql_exporter',

    [Parameter(Mandatory = $false)]
    [string]$ServiceDisplayName = 'Prometheus SQL Exporter',

    [Parameter(Mandatory = $false)]
    [string]$ServiceDescription = 'Prometheus SQL Exporter service',

    [Parameter(Mandatory = $false)]
    [string]$ListenAddress = ':9399',

    [Parameter(Mandatory = $false)]
    [string]$WebConfigPath,

    [Parameter(Mandatory = $false)]
    [string]$BasicAuthUsername,

    [Parameter(Mandatory = $false)]
    [SecureString]$BasicAuthPassword,

    [Parameter(Mandatory = $false)]
    [string]$BasicAuthHash,

    [Parameter(Mandatory = $false)]
    [string]$Profile,

    [Parameter(Mandatory = $false)]
    [string]$TargetName,

    [Parameter(Mandatory = $false)]
    [string]$DataSourceName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Auto', 'None')]
    [string]$SqlServerServiceDependency = 'Auto',

    [Parameter(Mandatory = $false)]
    [string]$SqlServerServiceName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('LocalSystem', 'LocalService', 'NetworkService', 'Credential', 'gMSA', 'NtService')]
    [string]$ServiceAccountMode = 'LocalSystem',

    [Parameter(Mandatory = $false)]
    [string]$ServiceAccount,

    [Parameter(Mandatory = $false)]
    [pscredential]$ServiceCredential,

    [Parameter(Mandatory = $false)]
    [pscredential]$RemoteCredential,

    [Parameter(Mandatory = $false)]
    [int]$ServiceTimeoutSec = 60,

    [Parameter(Mandatory = $false)]
    [ValidateSet('ServiceBase', 'NSSM')]
    [string]$ServiceMode = 'ServiceBase',

    [Parameter(Mandatory = $false)]
    [switch]$SkipCollectors
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$serviceHelpersPath = Join-Path $PSScriptRoot '..\common\Observability-NssmServiceHelpers.ps1'
$webConfigHelpersPath = Join-Path $PSScriptRoot '..\common\Observability-WebConfigHelpers.ps1'
if (-not (Test-Path -LiteralPath $serviceHelpersPath -PathType Leaf)) {
    throw "Required helper script was not found: $serviceHelpersPath"
}
if (-not (Test-Path -LiteralPath $webConfigHelpersPath -PathType Leaf)) {
    throw "Required helper script was not found: $webConfigHelpersPath"
}
. $webConfigHelpersPath

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
}

function Write-Step {
    param([string]$Message, [string]$Color = 'Cyan')
    Write-Host $Message -ForegroundColor $Color
}

function ConvertTo-PlainText {
    param([Security.SecureString]$SecureString)
    if ($null -eq $SecureString) { return $null }
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function Resolve-ComputerList {
    param([string[]]$InputComputers)
    @(
        $InputComputers |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Resolve-SourceLayout {
    param(
        [string]$Root,
        [switch]$SkipCollectorFolder
    )

    $projectRoot = (Resolve-Path -LiteralPath $Root).Path
    $resolvedRoot = Join-Path $projectRoot 'exporters\sql-exporter'
    $exe = Join-Path $resolvedRoot 'bin\sql_exporter.exe'
    $cfg = Join-Path $resolvedRoot 'config\sql_exporter.yml'
    $web = Join-Path $resolvedRoot 'config\web-config.yml'
    $version = Join-Path $resolvedRoot 'version\sql_exporter_version.ini'
    $collector = Join-Path $resolvedRoot 'collector'
    $profiles = Join-Path $resolvedRoot 'profiles'
    $nssm = Join-Path $projectRoot 'deployment\windows\tools\nssm\nssm.exe'

    foreach ($f in @($exe, $cfg, $web, $version)) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) {
            throw "Required file not found: $f"
        }
    }

    if (-not (Test-Path -LiteralPath $profiles -PathType Container)) {
        throw "profiles folder not found: $profiles"
    }

    if (-not $SkipCollectorFolder) {
        if (-not (Test-Path -LiteralPath $collector -PathType Container)) {
            throw "collector folder not found: $collector"
        }
    }

    [pscustomobject]@{
        Root         = $resolvedRoot
        ExePath      = $exe
        ConfigPath   = $cfg
        WebConfig    = $web
        VersionPath  = $version
        CollectorDir = $collector
        ProfilesDir  = $profiles
        NssmPath     = $nssm
    }
}

function Resolve-ProfileLeaf {
    param(
        [string]$Name,
        [string]$ProfilesRoot
    )

    $leaf = [IO.Path]::GetFileName($Name)
    if ($leaf -notmatch '\.ya?ml$') { $leaf = "$leaf.yml" }
    $path = Join-Path $ProfilesRoot $leaf
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $available = (
            Get-ChildItem -LiteralPath $ProfilesRoot -File -Filter '*.yml' |
                ForEach-Object { [IO.Path]::GetFileName($_.FullName) }
        ) -join ', '
        throw "Profile was not found: $leaf. Available: $available"
    }
    $leaf
}

function New-SqlExporterConfigWithProfile {
    param(
        [Parameter(Mandatory)][string]$BaseConfigPath,
        [Parameter(Mandatory)][string]$ProfilePath,
        [Parameter(Mandatory)][string]$ProfileLeaf,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $config = Get-Content -LiteralPath $BaseConfigPath -Raw
    if ([string]::IsNullOrWhiteSpace($config)) {
        throw "Base config is empty: $BaseConfigPath"
    }

    $profileRaw = Get-Content -LiteralPath $ProfilePath -Raw
    if ($profileRaw -notmatch '(?ms)^collectors:\s*\r?\n(?:[ \t]+-[ \t]+\S[^\r\n]*\r?\n?)+') {
        throw "Profile does not contain a collectors list: $ProfilePath"
    }

    $rootBlock = $Matches[0].TrimEnd("`r", "`n")
    $indented = (($rootBlock -split '\r?\n') | ForEach-Object { '  ' + $_ }) -join [Environment]::NewLine
    $replacement = ('  # Applied by deploy script from profiles/{0}' -f $ProfileLeaf) +
        [Environment]::NewLine + $indented

    $pattern = '(?m)^  collectors:\s*(?:\[[^\]]*\]|(?:\r?\n(?:[ \t]+-[ \t]+[^\r\n]+)+))'
    $found = [regex]::Matches($config, $pattern)
    if ($found.Count -eq 0) {
        throw "Could not find an active target.collectors entry in: $BaseConfigPath"
    }

    $last = $found[$found.Count - 1]
    $newConfig = $config.Substring(0, $last.Index) + $replacement + $config.Substring($last.Index + $last.Length)

    $outDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($OutputPath, $newConfig, $utf8)
}

function ConvertTo-SqlExporterYamlSingleQuoted {
    param([Parameter(Mandatory)][string]$Value)

    return "'" + $Value.Replace("'", "''") + "'"
}

function Set-SqlExporterTargetSettings {
    param(
        [Parameter(Mandatory)][string]$ConfigPath,
        [string]$Name,
        [string]$DataSourceName,
        [Parameter(Mandatory)][string]$OutputPath
    )

    if ([string]::IsNullOrWhiteSpace($Name) -and [string]::IsNullOrWhiteSpace($DataSourceName)) {
        if ($ConfigPath -ne $OutputPath) {
            Copy-Item -LiteralPath $ConfigPath -Destination $OutputPath -Force
        }
        return
    }

    $config = Get-Content -LiteralPath $ConfigPath -Raw
    if ([string]::IsNullOrWhiteSpace($config)) {
        throw "Config is empty: $ConfigPath"
    }

    if (-not [string]::IsNullOrWhiteSpace($Name)) {
        $nameValue = ConvertTo-SqlExporterYamlSingleQuoted -Value $Name.Trim()
        $config = [regex]::Replace($config, '(?m)^(\s{2}name:\s*).*$', {
            param($match)
            return $match.Groups[1].Value + $nameValue
        }, 1)
    }

    if (-not [string]::IsNullOrWhiteSpace($DataSourceName)) {
        $dsnValue = ConvertTo-SqlExporterYamlSingleQuoted -Value $DataSourceName.Trim()
        $config = [regex]::Replace($config, '(?m)^(\s{2}data_source_name:\s*).*$', {
            param($match)
            return $match.Groups[1].Value + $dsnValue
        }, 1)
    }

    $outDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($OutputPath, $config, $utf8)
}

function New-RemoteSession {
    param(
        [string]$ComputerName,
        [pscredential]$Credential
    )

    if ($null -ne $Credential) {
        return New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
    }
    return New-PSSession -ComputerName $ComputerName -ErrorAction Stop
}

function Get-ServiceAccountContext {
    param(
        [string]$Mode,
        [string]$Account,
        [pscredential]$Credential
    )

    $result = [ordered]@{
        Mode      = $Mode
        Account   = $null
        Password  = $null
    }

    switch ($Mode) {
        'LocalSystem' {
            $result.Account = 'LocalSystem'
            $result.Password = ''
        }
        'LocalService' {
            $result.Account = 'NT AUTHORITY\LocalService'
            $result.Password = ''
        }
        'NetworkService' {
            $result.Account = 'NT AUTHORITY\NetworkService'
            $result.Password = ''
        }
        'gMSA' {
            if ([string]::IsNullOrWhiteSpace($Account)) {
                throw 'ServiceAccount is required when ServiceAccountMode is gMSA.'
            }
            if ($Account -notmatch '\$$') {
                throw "gMSA account must end with '$': $Account"
            }
            $result.Account = $Account
            $result.Password = ''
        }
        'Credential' {
            if ($null -eq $Credential) {
                throw 'ServiceCredential is required when ServiceAccountMode is Credential.'
            }
            $result.Account = $Credential.UserName
            $result.Password = ConvertTo-PlainText -SecureString $Credential.Password
            if ([string]::IsNullOrWhiteSpace($result.Password)) {
                throw 'Resolved service account password is empty.'
            }
        }
        'NtService' {
            if ([string]::IsNullOrWhiteSpace($Account)) {
                throw 'ServiceAccount is required when ServiceAccountMode is NtService.'
            }
            if ($Account -notmatch '^NT SERVICE\\') {
                throw "NtService account must start with 'NT SERVICE\\': $Account"
            }
            # Virtual service accounts use no password
            $result.Account = $Account
            $result.Password = ''
        }
        default {
            throw "Unsupported ServiceAccountMode: $Mode"
        }
    }

    [pscustomobject]$result
}

$layout = Resolve-SourceLayout -Root $SourceRoot -SkipCollectorFolder:$SkipCollectors
$Computers = @(Resolve-ComputerList -InputComputers $Computers)

if ($Computers.Count -eq 0) {
    throw 'No target servers were resolved.'
}

$profileLeaf = $null
$configToDeploy = $layout.ConfigPath
$tempConfigPath = $null
if (-not [string]::IsNullOrWhiteSpace($Profile)) {
    $profileLeaf = Resolve-ProfileLeaf -Name $Profile -ProfilesRoot $layout.ProfilesDir
    $tempConfigPath = Join-Path $env:TEMP ("sql_exporter-profile-{0}-{1}.yml" -f ([IO.Path]::GetFileNameWithoutExtension($profileLeaf)), [guid]::NewGuid().ToString('N'))
    New-SqlExporterConfigWithProfile `
        -BaseConfigPath $layout.ConfigPath `
        -ProfilePath (Join-Path $layout.ProfilesDir $profileLeaf) `
        -ProfileLeaf $profileLeaf `
        -OutputPath $tempConfigPath
    $configToDeploy = $tempConfigPath
}

if (-not [string]::IsNullOrWhiteSpace($TargetName) -or -not [string]::IsNullOrWhiteSpace($DataSourceName)) {
    if (-not $tempConfigPath) {
        $tempConfigPath = Join-Path $env:TEMP ("sql_exporter-target-{0}.yml" -f [guid]::NewGuid().ToString('N'))
    }

    Set-SqlExporterTargetSettings `
        -ConfigPath $configToDeploy `
        -Name $TargetName `
        -DataSourceName $DataSourceName `
        -OutputPath $tempConfigPath
    $configToDeploy = $tempConfigPath
}

# The deployed config lives in config\ and collectors are its sibling directory.
if (-not $tempConfigPath) {
    $tempConfigPath = Join-Path $env:TEMP ("sql_exporter-layout-{0}.yml" -f [guid]::NewGuid().ToString('N'))
}
$deployConfig = Get-Content -LiteralPath $configToDeploy -Raw
$deployConfig = $deployConfig.Replace('"collector/*.collector.yml"', '"../collectors/*.collector.yml"')
[IO.File]::WriteAllText($tempConfigPath, $deployConfig, (New-Object Text.UTF8Encoding $false))
$configToDeploy = $tempConfigPath

Test-ObservabilityListenAddress -Address $ListenAddress
$webConfigToDeploy = Resolve-ObservabilityWebConfigDeployment `
    -TemplatePath $layout.WebConfig `
    -WebConfigPath $WebConfigPath `
    -BasicAuthUsername $BasicAuthUsername `
    -BasicAuthPassword $BasicAuthPassword `
    -BasicAuthHash $BasicAuthHash
$tempWebConfigPath = if ($webConfigToDeploy -ne $layout.WebConfig) { $webConfigToDeploy } else { $null }

$svcContext = Get-ServiceAccountContext -Mode $ServiceAccountMode -Account $ServiceAccount -Credential $ServiceCredential

Write-Step ("Source root     : {0}" -f $layout.Root)
Write-Step ("Install root    : {0}" -f $InstallRoot)
Write-Step ("Service         : {0}" -f $ServiceName)
Write-Step ("Display name    : {0}" -f $ServiceDisplayName)
Write-Step ("Listen address  : {0}" -f $ListenAddress)
Write-Step ("Web config      : {0}" -f $(if ($WebConfigPath) { $WebConfigPath } elseif ($BasicAuthUsername) { "Basic Auth user=$BasicAuthUsername" } else { '<package default>' }))
Write-Step ("Target name     : {0}" -f $(if ($TargetName) { $TargetName } else { '<package default>' }))
Write-Step ("Data source     : {0}" -f $(if ($DataSourceName) { $DataSourceName } else { '<package default>' }))
Write-Step ("SQL dependency  : {0}" -f $(if ($SqlServerServiceName) { $SqlServerServiceName } else { $SqlServerServiceDependency }))
Write-Step ("Service account : {0} ({1})" -f $svcContext.Account, $svcContext.Mode)
Write-Step ("Profile         : {0}" -f ($(if ($profileLeaf) { $profileLeaf } else { '<default sql_exporter.yml collectors>' })))
Write-Step ("Collectors      : {0}" -f ($(if ($SkipCollectors) { 'Skip' } else { 'Deploy' })))
Write-Step ("Hosts           : {0}" -f ($Computers -join ', '))
Write-Host ''

$results = @()

try {
foreach ($computer in $Computers) {
    $row = [ordered]@{
        Computer  = $computer
        Profile   = $profileLeaf
        Session   = 'Skipped'
        Deploy    = 'Skipped'
        Service   = 'Skipped'
        Error     = $null
    }

    Write-Step ("===== {0} =====" -f $computer) 'Yellow'

    $session = $null
    $stage = $null
    try {
        if (-not $PSCmdlet.ShouldProcess($computer, "Install/update $ServiceName")) {
            $row.Deploy = 'WhatIf'
            $row.Service = 'WhatIf'
            $results += [pscustomobject]$row
            Write-Host ''
            continue
        }

        $session = New-RemoteSession -ComputerName $computer -Credential $RemoteCredential
        $row.Session = 'OK'
        Write-Step '  WinRM session established.' 'Green'

        $stage = Invoke-Command -Session $session -ScriptBlock {
            param($SvcName)
            $id = [guid]::NewGuid().ToString('N')
            $stageDir = Join-Path $env:ProgramData ("Observability\PrometheusExporters\staging\sql_exporter-{0}-{1}" -f $SvcName, $id)
            New-Item -Path $stageDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $stageDir 'collector') -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $stageDir 'profiles') -ItemType Directory -Force | Out-Null
            $stageDir
        } -ArgumentList $ServiceName

        Write-Step ("  Staging path: {0}" -f $stage) 'DarkGray'

        if ($ServiceMode -eq 'NSSM') {
            if (-not (Test-Path -LiteralPath $layout.NssmPath -PathType Leaf)) {
                throw "NSSM requested but not found: $($layout.NssmPath)"
            }
            Copy-Item -Path $layout.NssmPath -Destination (Join-Path $stage 'nssm.exe') -ToSession $session -Force
            Write-Step ("  NSSM staged from: {0}" -f $layout.NssmPath) 'DarkGray'
        }

        Copy-Item -Path $layout.ExePath -Destination (Join-Path $stage 'sql_exporter.exe') -ToSession $session -Force
        Copy-Item -Path $configToDeploy -Destination (Join-Path $stage 'sql_exporter.yml') -ToSession $session -Force
        Copy-Item -Path $webConfigToDeploy -Destination (Join-Path $stage 'web-config.yml') -ToSession $session -Force
        Copy-Item -Path $layout.VersionPath -Destination (Join-Path $stage 'sql_exporter_version.ini') -ToSession $session -Force
        Copy-Item -Path (Join-Path $layout.ProfilesDir '*') -Destination (Join-Path $stage 'profiles') -ToSession $session -Force
        if (-not $SkipCollectors) {
            Copy-Item -Path (Join-Path $layout.CollectorDir '*') -Destination (Join-Path $stage 'collector') -ToSession $session -Force -Recurse
        }
        Copy-Item -Path $serviceHelpersPath -Destination (Join-Path $stage 'Observability-NssmServiceHelpers.ps1') -ToSession $session -Force
        Copy-Item -Path $webConfigHelpersPath -Destination (Join-Path $stage 'Observability-WebConfigHelpers.ps1') -ToSession $session -Force

        $deployResult = Invoke-Command -Session $session -ScriptBlock {
            param(
                $InstallPath,
                $SvcName,
                $Display,
                $Description,
                $Listen,
                $TimeoutSec,
                $StageDir,
                $SvcAccount,
                $SvcPassword,
                $DeployCollectors,
                $ServiceMode,
                $ProfileName,
                $SqlDependencyMode,
                $SqlDependencyServiceName,
                $DataSourceNameForDependency
            )

            Set-StrictMode -Version Latest
            $ErrorActionPreference = 'Stop'
            . (Join-Path $StageDir 'Observability-NssmServiceHelpers.ps1')
            . (Join-Path $StageDir 'Observability-WebConfigHelpers.ps1')

            function Wait-ServiceStatus {
                param([string]$Name, [string]$Status, [int]$Timeout)
                $svc = Get-Service -Name $Name -ErrorAction Stop
                $svc.WaitForStatus($Status, [TimeSpan]::FromSeconds($Timeout))
                $svc.Refresh()
                return $svc
            }

            function Backup-IfExists {
                param([string]$Path, [string]$BackupRoot)
                if (Test-Path -LiteralPath $Path) {
                    Copy-Item -LiteralPath $Path -Destination $BackupRoot -Recurse -Force
                }
            }

            if (-not (Test-Path -LiteralPath $InstallPath)) {
                New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
            }

            $backupRoot = Join-Path $InstallPath ('_backup\{0}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
            New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null

            $svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
            if ($null -ne $svc -and $svc.Status -ne 'Stopped') {
                Stop-Service -Name $SvcName -Force -ErrorAction Stop
                [void](Wait-ServiceStatus -Name $SvcName -Status 'Stopped' -Timeout $TimeoutSec)
            }

            Backup-IfExists -Path (Join-Path $InstallPath 'bin') -BackupRoot $backupRoot
            Backup-IfExists -Path (Join-Path $InstallPath 'config') -BackupRoot $backupRoot
            Backup-IfExists -Path (Join-Path $InstallPath 'version') -BackupRoot $backupRoot
            Backup-IfExists -Path (Join-Path $InstallPath 'profiles') -BackupRoot $backupRoot
            if ($DeployCollectors) {
                Backup-IfExists -Path (Join-Path $InstallPath 'collectors') -BackupRoot $backupRoot
            }

            function Invoke-Nssm {
                param([string]$Executable, [string[]]$Arguments)
                $output = & $Executable @Arguments 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw ("NSSM failed: nssm {0}`n{1}" -f ($Arguments -join ' '), ($output -join [Environment]::NewLine))
                }
            }

            $binDir = Join-Path $InstallPath 'bin'
            $configDir = Join-Path $InstallPath 'config'
            $versionDir = Join-Path $InstallPath 'version'
            $logDir = Join-Path $InstallPath 'log'
            foreach ($dir in @($binDir, $configDir, $versionDir, $logDir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -LiteralPath (Join-Path $StageDir 'sql_exporter.exe') -Destination (Join-Path $binDir 'sql_exporter.exe') -Force
            Copy-Item -LiteralPath (Join-Path $StageDir 'sql_exporter.yml') -Destination (Join-Path $configDir 'sql_exporter.yml') -Force
            Copy-Item -LiteralPath (Join-Path $StageDir 'web-config.yml') -Destination (Join-Path $configDir 'web-config.yml') -Force
            Copy-Item -LiteralPath (Join-Path $StageDir 'sql_exporter_version.ini') -Destination (Join-Path $versionDir 'sql_exporter_version.ini') -Force

            $targetProfiles = Join-Path $InstallPath 'profiles'
            if (Test-Path -LiteralPath $targetProfiles) {
                Remove-Item -LiteralPath $targetProfiles -Recurse -Force
            }
            New-Item -Path $targetProfiles -ItemType Directory -Force | Out-Null
            Copy-Item -Path (Join-Path $StageDir 'profiles\*') -Destination $targetProfiles -Force

            if ($DeployCollectors) {
                $targetCollector = Join-Path $InstallPath 'collectors'
                if (Test-Path -LiteralPath $targetCollector) {
                    Remove-Item -LiteralPath $targetCollector -Recurse -Force
                }
                New-Item -Path $targetCollector -ItemType Directory -Force | Out-Null
                Copy-Item -Path (Join-Path $StageDir 'collector\*') -Destination $targetCollector -Recurse -Force
            }

            $exePath = Join-Path $InstallPath 'bin\sql_exporter.exe'
            $cfgPath = Join-Path $InstallPath 'config\sql_exporter.yml'
            $webCfgPath = Join-Path $InstallPath 'config\web-config.yml'
            $appParameters = Get-ObservabilityExporterAppParameters `
                -ConfigFile $cfgPath `
                -WebConfigFile $webCfgPath `
                -ListenAddress $Listen `
                -LogFormat 'json'
            $binaryPath = ('"{0}" {1}' -f $exePath, $appParameters)
            $stdoutLog = Join-Path $logDir "$SvcName.out.log"
            $stderrLog = Join-Path $logDir "$SvcName.err.log"
            if ($SvcAccount) {
                Grant-ObservabilityServiceLogAccess -Path $logDir -Account $SvcAccount
            }

            $svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
            if ($ServiceMode -eq 'NSSM') {
                $nssmDir = 'C:\Program Files\Observability\Tools\NSSM'
                New-Item -Path $nssmDir -ItemType Directory -Force | Out-Null
                $nssmExe = Join-Path $nssmDir 'nssm.exe'
                if (Test-Path -LiteralPath (Join-Path $StageDir 'nssm.exe')) {
                    if (-not (Test-Path -LiteralPath $nssmExe -PathType Leaf)) {
                        Copy-Item -LiteralPath (Join-Path $StageDir 'nssm.exe') -Destination $nssmExe -Force
                    }
                }
                if (-not (Test-Path -LiteralPath $nssmExe)) { throw "nssm.exe not found at $nssmExe" }

                if ($null -eq $svc) {
                    Invoke-Nssm -Executable $nssmExe -Arguments @('install', $SvcName, $exePath)
                }
                else {
                    Invoke-Nssm -Executable $nssmExe -Arguments @('remove', $SvcName, 'confirm')
                    Invoke-Nssm -Executable $nssmExe -Arguments @('install', $SvcName, $exePath)
                }

                $parameters = "HKLM:\SYSTEM\CurrentControlSet\Services\$SvcName\Parameters"
                if (-not (Test-Path -LiteralPath $parameters)) {
                    throw "NSSM parameters key was not found: $parameters"
                }
                Set-ItemProperty -LiteralPath $parameters -Name Application -Value $exePath
                Set-ItemProperty -LiteralPath $parameters -Name AppParameters -Value $appParameters
                Set-ItemProperty -LiteralPath $parameters -Name AppDirectory -Value $InstallPath
                Set-ObservabilityNssmLogging -ParametersKey $parameters -StdoutLog $stdoutLog -StderrLog $stderrLog
                Invoke-Nssm -Executable $nssmExe -Arguments @('set', $SvcName, 'AppExit', 'Default', 'Restart')
                Invoke-Nssm -Executable $nssmExe -Arguments @('set', $SvcName, 'DisplayName', $Display)
                Invoke-Nssm -Executable $nssmExe -Arguments @('set', $SvcName, 'Description', $Description)
                Invoke-Nssm -Executable $nssmExe -Arguments @('set', $SvcName, 'Start', 'SERVICE_AUTO_START')
                Invoke-ObservabilitySc -Arguments @('config', $SvcName, ('binPath= ' + ('"{0}"' -f $nssmExe)))
                Register-ObservabilityNssmEventSource -NssmExe $nssmExe

                if ($SvcAccount) {
                    if ($SvcPassword -ne '') {
                        Invoke-Nssm -Executable $nssmExe -Arguments @('set', $SvcName, 'ObjectName', $SvcAccount, $SvcPassword)
                    }
                    else {
                        Invoke-Nssm -Executable $nssmExe -Arguments @('set', $SvcName, 'ObjectName', $SvcAccount)
                    }
                }
            }
            else {
                if ($null -eq $svc) {
                    New-Service -Name $SvcName -DisplayName $Display -BinaryPathName $binaryPath -StartupType Automatic | Out-Null
                }
                else {
                    Invoke-ObservabilitySc -Arguments @('config', $SvcName, ('binPath= ' + $binaryPath), 'start= auto', ('DisplayName= ' + $Display))
                }

                $scArgs2 = @('config', $SvcName, ('obj= ' + $SvcAccount))
                if ($SvcPassword -ne '') { $scArgs2 += ('password= ' + $SvcPassword) }
                Invoke-ObservabilitySc -Arguments $scArgs2
                Invoke-ObservabilitySc -Arguments @('description', $SvcName, $Description)
            }

            $dependencyMode = if ($SqlDependencyServiceName) { $SqlDependencyServiceName } else { $SqlDependencyMode }
            $dependencyServices = Set-ObservabilitySqlServerServiceDependency `
                -ServiceName $SvcName `
                -DependencyMode $dependencyMode `
                -DataSourceName $DataSourceNameForDependency

            $svc = Start-ObservabilityManagedService -Name $SvcName -TimeoutSec $TimeoutSec -LogDirectory $logDir -ProcessLabel 'sql_exporter.exe'

            if (-not [Diagnostics.EventLog]::SourceExists($SvcName)) {
                New-EventLog -LogName Application -Source $SvcName
            }
            Write-EventLog -LogName Application -Source $SvcName -EntryType Information -EventId 1001 `
                -Message "Windows service installed and started. Mode=$ServiceMode; InstallPath=$InstallPath"

            [pscustomobject]@{
                InstallPath        = $InstallPath
                BackupPath         = $backupRoot
                ServiceName        = $svc.Name
                ServiceStatus      = $svc.Status.ToString()
                BinaryPath         = $binaryPath
                CollectorsDeployed = [bool]$DeployCollectors
                Profile            = $ProfileName
                SqlDependencies    = ($dependencyServices -join '/')
            }
        } -ArgumentList `
            $InstallRoot, `
            $ServiceName, `
            $ServiceDisplayName, `
            $ServiceDescription, `
            $ListenAddress, `
            $ServiceTimeoutSec, `
            $stage, `
            $svcContext.Account, `
            $svcContext.Password, `
            (-not $SkipCollectors), `
            $ServiceMode, `
            $profileLeaf, `
            $SqlServerServiceDependency, `
            $SqlServerServiceName, `
            $DataSourceName

        $row.Deploy = 'OK'
        $row.Service = $deployResult.ServiceStatus
        if ($deployResult.Profile) { $row.Profile = $deployResult.Profile }

        Write-Step ("  Deploy OK   : {0}" -f $deployResult.InstallPath) 'Green'
        Write-Step ("  Profile     : {0}" -f ($(if ($row.Profile) { $row.Profile } else { '<default>' }))) 'DarkGray'
        if ($deployResult.SqlDependencies) {
            Write-Step ("  SQL depends : {0}" -f $deployResult.SqlDependencies) 'DarkGray'
        }
        Write-Step ("  Backup path : {0}" -f $deployResult.BackupPath) 'DarkGray'
        Write-Step ("  Service     : {0}" -f $deployResult.ServiceStatus) 'Green'
    }
    catch {
        $row.Error = $_.Exception.Message
        Write-Step ("  ERROR: {0}" -f $_.Exception.Message) 'Red'
    }
    finally {
        if ($null -ne $session) {
            if (-not [string]::IsNullOrWhiteSpace($stage)) {
                try {
                    Invoke-Command -Session $session -ScriptBlock {
                        param($StageDir)

                        if (Test-Path -LiteralPath $StageDir) {
                            Remove-Item -LiteralPath $StageDir -Recurse -Force -ErrorAction Stop
                        }

                        $stagingRoot = Split-Path -Parent $StageDir
                        if ((Test-Path -LiteralPath $stagingRoot -PathType Container) -and
                            @((Get-ChildItem -LiteralPath $stagingRoot -Force -ErrorAction Stop)).Count -eq 0) {
                            Remove-Item -LiteralPath $stagingRoot -Force -ErrorAction Stop
                        }
                    } -ArgumentList $stage -ErrorAction Stop
                    Write-Step '  Staging files removed.' 'DarkGray'
                }
                catch {
                    Write-Step ("  WARNING: Could not remove staging files: {0}" -f $_.Exception.Message) 'DarkYellow'
                }
            }
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }
    }

    $results += [pscustomobject]$row
    Write-Host ''
}
}
finally {
    if ($tempConfigPath -and (Test-Path -LiteralPath $tempConfigPath)) {
        [IO.File]::Delete($tempConfigPath)
    }
    if ($tempWebConfigPath -and (Test-Path -LiteralPath $tempWebConfigPath)) {
        [IO.File]::Delete($tempWebConfigPath)
    }
}

Write-Step '===== Summary =====' 'Yellow'
$results | Format-Table -AutoSize | Out-String | Write-Host

$failed = @($results | Where-Object { $_.Error })
if ($failed.Count -gt 0) {
    exit 1
}

exit 0
