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
    [string[]]$Instance = @('localhost'),
    [string[]]$Endpoint = @(),
    [string[]]$BackupPath = @(),
    [string[]]$ReadOnlyProbeConnectionStringFile = @(),
    [string[]]$XelPath = @(),
    [string]$LegacyTaskName = 'DBA Monitoring - SSAS Prometheus Metrics',
    [ValidateRange(1,60)][int]$IntervalMinutes = 1,
    [ValidateRange(5,300)][int]$ServiceTimeoutSec = 60,
    [pscredential]$RemoteCredential
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $SourceRoot) { $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..')) }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$scriptSource = Join-Path $SourceRoot 'scripts\powershell\windows-exporter'
$installerName = 'Install-SsasMetricsTask.ps1'
$requiredScripts = @(
    $installerName,
    'Collect-SsasMetrics.ps1',
    'Collect-SsasPerformanceCounters.ps1',
    'Collect-SsasXEventMetrics.ps1',
    'Invoke-SsasCollectors.ps1',
    'Run-SsasMetricsService.ps1',
    'Run-SsasMetricsLoop.ps1'
)
foreach ($name in $requiredScripts) {
    $path = Join-Path $scriptSource $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required script was not found: $path" }
}
$nssmSource = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
if ($ServiceMode -eq 'NSSM' -and -not (Test-Path -LiteralPath $nssmSource -PathType Leaf)) { throw "NSSM was not found: $nssmSource" }

$results = @()
foreach ($computer in @($Computers | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    $row = [ordered]@{ Computer=$computer; Mode=$ServiceMode; Status=''; ConfigPath=''; LegacyTaskRemoved=$false; Error='' }
    $session = $null
    $stage = $null
    try {
        if (-not $PSCmdlet.ShouldProcess($computer, "Install or update $ServiceName ($ServiceMode)")) { $row.Status='WhatIf'; continue }
        $sessionArgs = @{ ComputerName=$computer; ErrorAction='Stop' }
        if ($RemoteCredential) { $sessionArgs.Credential = $RemoteCredential }
        $session = New-PSSession @sessionArgs
        $stage = Invoke-Command -Session $session -ScriptBlock {
            $path = Join-Path $env:ProgramData ("Observability\PrometheusExporters\staging\ssas-{0}" -f [guid]::NewGuid().ToString('N'))
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            $path
        }
        foreach ($name in $requiredScripts) { Copy-Item -LiteralPath (Join-Path $scriptSource $name) -Destination (Join-Path $stage $name) -ToSession $session -Force }
        if ($ServiceMode -eq 'NSSM') { Copy-Item -LiteralPath $nssmSource -Destination (Join-Path $stage 'nssm.exe') -ToSession $session -Force }

        $remote = Invoke-Command -Session $session -ScriptBlock {
            param($Stage,$InstallPath,$Name,$Display,$Mode,$Instances,$Endpoints,$Backups,$ProbeFiles,$XelFiles,$TaskName,$Interval,$Timeout)
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
                Instance=$Instances; Endpoint=$Endpoints; BackupPath=$Backups
                ReadOnlyProbeConnectionStringFile=$ProbeFiles; XelPath=$XelFiles
                LegacyTaskName=$TaskName; IntervalMinutes=$Interval; ServiceTimeoutSec=$Timeout
                Confirm=$false
            }
            & (Join-Path $Stage 'Install-SsasMetricsTask.ps1') @arguments
        } -ArgumentList $stage,$InstallRoot,$ServiceName,$DisplayName,$ServiceMode,$Instance,$Endpoint,$BackupPath,$ReadOnlyProbeConnectionStringFile,$XelPath,$LegacyTaskName,$IntervalMinutes,$ServiceTimeoutSec
        $row.Status = $remote.Status
        $row.ConfigPath = $remote.ConfigPath
        $row.LegacyTaskRemoved = $remote.LegacyTaskRemoved
    } catch { $row.Error = $_.Exception.Message }
    finally {
        if ($session -and $stage) { Invoke-Command -Session $session -ScriptBlock { param($Path) Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue } -ArgumentList $stage -ErrorAction SilentlyContinue }
        if ($session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        $results += [pscustomobject]$row
    }
}
$results | Format-Table -AutoSize
if (@($results | Where-Object Error).Count) { exit 1 }
