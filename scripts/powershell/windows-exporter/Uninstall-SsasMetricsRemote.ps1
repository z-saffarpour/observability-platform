#Requires -Version 5.1
<#
.SYNOPSIS
  Uninstalls prometheus_windows_ssas remotely over WinRM.
.DESCRIPTION
  Stages and invokes Uninstall-SsasMetricsService.ps1 on each target. SSAS-only
  files are preserved unless -RemoveFiles is specified.
.EXAMPLE
  .\Uninstall-SsasMetricsRemote.ps1 -Computers SSAS01,SSAS02 -WhatIf
.EXAMPLE
  .\Uninstall-SsasMetricsRemote.ps1 -Computers SSAS01 -RemoveFiles -RemoteCredential (Get-Credential)
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string[]]$Computers,
    [string]$SourceRoot,
    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter',
    [string]$ServiceName = 'prometheus_windows_ssas',
    [ValidateSet('Preserve','ServiceBase','NSSM')][string]$ServiceMode = 'Preserve',
    [string]$LegacyTaskName = 'DBA Monitoring - SSAS Prometheus Metrics',
    [ValidateRange(5,300)][int]$ServiceTimeoutSec = 60,
    [switch]$RemoveFiles,
    [switch]$SkipBackup,
    [switch]$RemoveEventSource,
    [pscredential]$RemoteCredential
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $SourceRoot) { $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..')) }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$uninstallerSource = Join-Path $SourceRoot 'scripts\powershell\windows-exporter\Uninstall-SsasMetricsService.ps1'
if (-not (Test-Path -LiteralPath $uninstallerSource -PathType Leaf)) { throw "Required script was not found: $uninstallerSource" }

$results = @()
foreach ($computer in @($Computers | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    $row = [ordered]@{ Computer=$computer; Mode=''; Status=''; Files=''; Backup=''; EventSource=''; Error='' }
    $session = $null
    $stage = $null
    try {
        if (-not $PSCmdlet.ShouldProcess($computer, "Uninstall $ServiceName")) { $row.Status='WhatIf'; $row.Files='WhatIf'; continue }
        $sessionArgs = @{ ComputerName=$computer; ErrorAction='Stop' }
        if ($RemoteCredential) { $sessionArgs.Credential = $RemoteCredential }
        $session = New-PSSession @sessionArgs
        $stage = Invoke-Command -Session $session -ScriptBlock {
            $path = Join-Path $env:ProgramData ("Observability\PrometheusExporters\staging\ssas-uninstall-{0}" -f [guid]::NewGuid().ToString('N'))
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            $path
        }
        $remoteScript = Join-Path $stage 'Uninstall-SsasMetricsService.ps1'
        Copy-Item -LiteralPath $uninstallerSource -Destination $remoteScript -ToSession $session -Force
        $remote = Invoke-Command -Session $session -ScriptBlock {
            param($Script,$InstallPath,$Name,$Mode,$TaskName,$Timeout,$DeleteFiles,$NoBackup,$DeleteSource)
            $arguments = @{
                InstallRoot=$InstallPath; ServiceName=$Name; ServiceMode=$Mode
                LegacyTaskName=$TaskName; ServiceTimeoutSec=$Timeout; Confirm=$false
            }
            if ($DeleteFiles) { $arguments.RemoveFiles = $true }
            if ($NoBackup) { $arguments.SkipBackup = $true }
            if ($DeleteSource) { $arguments.RemoveEventSource = $true }
            & $Script @arguments
        } -ArgumentList $remoteScript,$InstallRoot,$ServiceName,$ServiceMode,$LegacyTaskName,$ServiceTimeoutSec,[bool]$RemoveFiles,[bool]$SkipBackup,[bool]$RemoveEventSource
        foreach ($key in @('Mode','Status','Files','Backup','EventSource')) { $row[$key] = $remote.$key }
    } catch { $row.Error = $_.Exception.Message }
    finally {
        if ($session -and $stage) { Invoke-Command -Session $session -ScriptBlock { param($Path) Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue } -ArgumentList $stage -ErrorAction SilentlyContinue }
        if ($session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        $results += [pscustomobject]$row
    }
}
$results | Format-Table -AutoSize
if (@($results | Where-Object Error).Count) { exit 1 }
