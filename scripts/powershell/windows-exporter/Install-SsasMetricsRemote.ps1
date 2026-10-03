#Requires -Version 5.1
<#
.SYNOPSIS
  Installs or updates prometheus_windows_ssas remotely over WinRM.
.DESCRIPTION
  Stages the SSAS service scripts on each target and invokes the local installer
  there. Supports the same ServiceBase/NSSM modes as Install-SsasMetricsTask.ps1.
.EXAMPLE
  .\Install-SsasMetricsRemote.ps1 -Computers SSAS01,SSAS02 -WhatIf
.EXAMPLE
  .\Install-SsasMetricsRemote.ps1 -Computers SSAS01  -ServiceMode NSSM -Instance 'NODE' -Endpoint 'NODE=localhost:2383'
.EXAMPLE
  .\Install-SsasMetricsRemote.ps1 -Computers SSAS01 -ServiceMode NSSM -RemoteCredential (Get-Credential)
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string[]]$Computers,
    [string]$SourceRoot,
    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter',
    [string]$ServiceName = 'prometheus_windows_ssas',
    [string]$DisplayName = 'Prometheus Windows SSAS Metrics',
    [ValidateSet('ServiceBase','NSSM')][string]$ServiceMode = 'ServiceBase',
    [ValidateSet('LocalSystem', 'LocalService', 'NetworkService', 'Credential', 'gMSA', 'NtService')]
    [string]$ServiceAccountMode = 'LocalSystem',
    [string]$ServiceAccount,
    [pscredential]$ServiceCredential,
    [string[]]$Instance = @('localhost'),
    [string[]]$Endpoint = @(),
    [string[]]$BackupPath = @(),
    [string[]]$ReadOnlyProbeConnectionStringFile = @(),
    [string[]]$XelPath = @(),
    [string]$LegacyTaskName = 'DBA Monitoring - SSAS Prometheus Metrics',
    [ValidateRange(1,60)][int]$IntervalMinutes = 1,
    [ValidateRange(5,300)][int]$ServiceTimeoutSec = 60,
    [ValidateRange(5,300)][int]$CommandTimeoutSec = 30,
    [ValidateRange(1,168)][int]$StaleAfterHours = 24,
    [ValidateRange(1,1440)][int]$LongSessionMinutes = 30,
    [ValidateRange(1,1440)][int]$IdleSessionMinutes = 15,
    [switch]$EnableXEvents,
    [string]$ProgramDataRoot = '',
    [string]$XEventsDirectory = '',
    [string]$SecretsDirectory = '',
    [string]$AuditDirectory = '',
    [string]$SiemOutputPath = '',
    [long]$AuditLogMaxBytes = 0,
    [long]$XelFileMaxBytes = 0,
    [long]$XelDirectoryMaxBytes = 0,
    [ValidateRange(1, 100)][int]$KeepRotatedFiles = 0,
    [pscredential]$RemoteCredential
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PlainText([Security.SecureString]$Value) {
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

$account = switch ($ServiceAccountMode) {
    'LocalSystem'    { 'LocalSystem' }
    'LocalService'   { 'NT AUTHORITY\LocalService' }
    'NetworkService' { 'NT AUTHORITY\NetworkService' }
    'NtService' {
        if ($ServiceAccount) {
            if ($ServiceAccount -notmatch '(?i)^NT SERVICE\\') {
                throw 'For NtService mode, -ServiceAccount must be NT SERVICE\<ServiceName> (or omit it to use -ServiceName).'
            }
            $ServiceAccount
        } else {
            "NT SERVICE\$ServiceName"
        }
    }
    'Credential' {
        if (-not $ServiceCredential) { throw '-ServiceCredential is required for Credential mode.' }
        $ServiceCredential.UserName
    }
    'gMSA' {
        if (-not $ServiceAccount -or $ServiceAccount -notmatch '\$$') { throw 'A gMSA -ServiceAccount ending in $ is required.' }
        $ServiceAccount
    }
}
$password = if ($ServiceAccountMode -eq 'Credential') { Get-PlainText $ServiceCredential.Password } else { '' }
if (-not $SourceRoot) { $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..')) }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$scriptSource = Join-Path $SourceRoot 'scripts\powershell\windows-exporter'
$commonScriptSource = Join-Path $SourceRoot 'scripts\powershell\common'
$installerName = 'Install-SsasMetricsTask.ps1'
$requiredScripts = @(
    $installerName,
    'Ssas-CollectorPaths.ps1',
    'Ssas-CollectorConfig.ps1',
    'Update-SsasCollectorConfig.ps1',
    'Collect-SsasMetrics.ps1',
    'Collect-SsasPerformanceCounters.ps1',
    'Collect-SsasXEventMetrics.ps1',
    'Invoke-SsasCollectors.ps1',
    'Run-SsasMetricsService.ps1',
    'Run-SsasMetricsLoop.ps1'
)
$requiredCommonScripts = @(
    'Observability-NssmServiceHelpers.ps1'
)
foreach ($name in $requiredScripts) {
    $path = Join-Path $scriptSource $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required script was not found: $path" }
}
foreach ($name in $requiredCommonScripts) {
    $path = Join-Path $commonScriptSource $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required helper script was not found: $path" }
}
$nssmSource = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
if ($ServiceMode -eq 'NSSM' -and -not (Test-Path -LiteralPath $nssmSource -PathType Leaf)) { throw "NSSM was not found: $nssmSource" }

$targets = @($Computers | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$results = @()
$targetIndex = 0
foreach ($computer in $targets) {
    $targetIndex++
    $row = [ordered]@{ Computer=$computer; Mode=$ServiceMode; Status=''; ConfigPath=''; LegacyTaskRemoved=$false; Error='' }
    $session = $null
    $stage = $null
    Write-Host ''
    Write-Host "===== [$targetIndex/$($targets.Count)] $computer =====" -ForegroundColor Yellow
    try {
        if (-not $PSCmdlet.ShouldProcess($computer, "Install or update $ServiceName ($ServiceMode)")) {
            $row.Status='WhatIf'
            Write-Host "[$computer] Skipped by WhatIf." -ForegroundColor DarkYellow
            continue
        }
        Write-Host "[$computer] Connecting over WinRM..." -ForegroundColor Cyan
        $sessionArgs = @{ ComputerName=$computer; ErrorAction='Stop' }
        if ($RemoteCredential) { $sessionArgs.Credential = $RemoteCredential }
        $session = New-PSSession @sessionArgs
        Write-Host "[$computer] Creating staging directory..." -ForegroundColor DarkGray
        $stage = Invoke-Command -Session $session -ScriptBlock {
            $path = Join-Path $env:ProgramData ("Observability\PrometheusExporters\staging\ssas-{0}" -f [guid]::NewGuid().ToString('N'))
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            $path
        }
        foreach ($name in $requiredScripts) { Copy-Item -LiteralPath (Join-Path $scriptSource $name) -Destination (Join-Path $stage $name) -ToSession $session -Force }
        foreach ($name in $requiredCommonScripts) {
            Copy-Item -LiteralPath (Join-Path $commonScriptSource $name) -Destination (Join-Path $stage $name) -ToSession $session -Force
        }
        if ($ServiceMode -eq 'NSSM') { Copy-Item -LiteralPath $nssmSource -Destination (Join-Path $stage 'nssm.exe') -ToSession $session -Force }
        Write-Host "[$computer] Installing $ServiceName..." -ForegroundColor Cyan

        $remote = Invoke-Command -Session $session -ScriptBlock {
            param($Stage,$InstallPath,$Name,$Display,$Mode,$AccountMode,$Account,$Password,$Instances,$Endpoints,$Backups,$ProbeFiles,$XelFiles,$TaskName,$Interval,$Timeout,$CommandTimeout,$StaleAfter,$LongSession,$IdleSession,$EnableXEventsSwitch,$ProgramDataRoot,$XEventsDirectory,$SecretsDirectory,$AuditDirectory,$SiemOutputPath,$AuditLogMaxBytes,$XelFileMaxBytes,$XelDirectoryMaxBytes,$KeepRotatedFiles)
            Set-StrictMode -Version Latest
            $ErrorActionPreference = 'Stop'
            if ($Mode -eq 'NSSM') {
                $nssmDir = 'C:\Program Files\Observability\Tools\NSSM'
                New-Item -Path $nssmDir -ItemType Directory -Force | Out-Null
                $targetNssm = Join-Path $nssmDir 'nssm.exe'
                if (-not (Test-Path -LiteralPath $targetNssm -PathType Leaf)) { Copy-Item -LiteralPath (Join-Path $Stage 'nssm.exe') -Destination $targetNssm -Force }
            }
            $arguments = @{
                InstallRoot=$InstallPath; ServiceName=$Name; DisplayName=$Display; ServiceMode=$Mode
                ServiceAccountMode=$AccountMode; ServiceAccount=$Account
                Instance=$Instances; Endpoint=$Endpoints; BackupPath=$Backups
                ReadOnlyProbeConnectionStringFile=$ProbeFiles; XelPath=$XelFiles
                LegacyTaskName=$TaskName; IntervalMinutes=$Interval; ServiceTimeoutSec=$Timeout
                CommandTimeoutSec=$CommandTimeout; StaleAfterHours=$StaleAfter
                LongSessionMinutes=$LongSession; IdleSessionMinutes=$IdleSession
                EnableXEvents=$EnableXEventsSwitch
                ProgramDataRoot=$ProgramDataRoot; XEventsDirectory=$XEventsDirectory
                SecretsDirectory=$SecretsDirectory; AuditDirectory=$AuditDirectory
                SiemOutputPath=$SiemOutputPath; AuditLogMaxBytes=$AuditLogMaxBytes
                XelFileMaxBytes=$XelFileMaxBytes; XelDirectoryMaxBytes=$XelDirectoryMaxBytes
                KeepRotatedFiles=$KeepRotatedFiles
                Confirm=$false
            }
            if ($AccountMode -eq 'Credential') {
                $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
                $arguments.ServiceCredential = [pscredential]::new($Account, $securePassword)
            }
            & (Join-Path $Stage 'Install-SsasMetricsTask.ps1') @arguments
        } -ArgumentList $stage,$InstallRoot,$ServiceName,$DisplayName,$ServiceMode,$ServiceAccountMode,$account,$password,$Instance,$Endpoint,$BackupPath,$ReadOnlyProbeConnectionStringFile,$XelPath,$LegacyTaskName,$IntervalMinutes,$ServiceTimeoutSec,$CommandTimeoutSec,$StaleAfterHours,$LongSessionMinutes,$IdleSessionMinutes,$EnableXEvents.IsPresent,$ProgramDataRoot,$XEventsDirectory,$SecretsDirectory,$AuditDirectory,$SiemOutputPath,$AuditLogMaxBytes,$XelFileMaxBytes,$XelDirectoryMaxBytes,$KeepRotatedFiles
        $row.Status = $remote.Status
        $row.ConfigPath = $remote.ConfigPath
        $row.LegacyTaskRemoved = $remote.LegacyTaskRemoved
        Write-Host "[$computer] Completed. Service status=$($row.Status)" -ForegroundColor Green
    } catch {
        $row.Error = $_.Exception.Message
        Write-Host "[$computer] ERROR: $($row.Error)" -ForegroundColor Red
    }
    finally {
        if ($session -and $stage) {
            Invoke-Command -Session $session -ScriptBlock {
                param($Path)
                if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue }
                $stagingRoot = Split-Path -Parent $Path
                if ((Test-Path -LiteralPath $stagingRoot -PathType Container) -and @((Get-ChildItem -LiteralPath $stagingRoot -Force -ErrorAction SilentlyContinue)).Count -eq 0) { Remove-Item -LiteralPath $stagingRoot -Force -ErrorAction SilentlyContinue }
            } -ArgumentList $stage -ErrorAction SilentlyContinue
        }
        if ($session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        $results += [pscustomobject]$row
    }
}
$results | Format-Table -AutoSize
if (@($results | Where-Object Error).Count) { exit 1 }
