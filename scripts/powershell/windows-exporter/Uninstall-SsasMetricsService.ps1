#Requires -Version 5.1
<#
.SYNOPSIS
  Safely uninstalls the prometheus_windows_ssas Windows service.
.DESCRIPTION
  Detects ServiceBase or NSSM, stops and removes the service, and removes the
  legacy scheduled task if present. Shared windows-exporter files are preserved
  by default. Use -RemoveFiles to back up and remove SSAS-only runtime files.
.EXAMPLE
  .\Uninstall-SsasMetricsService.ps1 -WhatIf
.EXAMPLE
  .\Uninstall-SsasMetricsService.ps1 -ServiceMode NSSM -RemoveFiles
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter',
    [string]$ServiceName = 'prometheus_windows_ssas',
    [ValidateSet('Preserve','ServiceBase','NSSM')][string]$ServiceMode = 'Preserve',
    [string]$LegacyTaskName = 'DBA Monitoring - SSAS Prometheus Metrics',
    [ValidateRange(5,300)][int]$ServiceTimeoutSec = 60,
    [switch]$RemoveFiles,
    [switch]$SkipBackup,
    [switch]$RemoveEventSource
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CommandExe([string]$CommandLine) {
    if (-not $CommandLine) { return $null }
    $expanded = [Environment]::ExpandEnvironmentVariables($CommandLine.Trim())
    if ($expanded.StartsWith('"')) { return ($expanded -split '"')[1] }
    ($expanded -split '\s+')[0]
}

if ($PSCmdlet.ShouldProcess($ServiceName, 'Uninstall SSAS metrics Windows service')) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Administrator rights are required to uninstall $ServiceName."
    }

    $InstallRoot = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($InstallRoot.TrimEnd('\')))
    if ($InstallRoot -eq [IO.Path]::GetPathRoot($InstallRoot)) { throw "Unsafe install root: $InstallRoot" }

    $escaped = $ServiceName.Replace("'", "''")
    $serviceCim = Get-CimInstance Win32_Service -Filter "Name='$escaped'" -ErrorAction SilentlyContinue
    $parameters = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName\Parameters"
    $application = if (Test-Path -LiteralPath $parameters) {
        (Get-ItemProperty -LiteralPath $parameters -Name Application -ErrorAction SilentlyContinue).Application
    }
    $detectedMode = if ($application -or ($serviceCim -and (Get-CommandExe $serviceCim.PathName) -match '(?i)nssm\.exe$')) { 'NSSM' } else { 'ServiceBase' }
    if ($ServiceMode -ne 'Preserve' -and $ServiceMode -ne $detectedMode) {
        throw "Requested ServiceMode '$ServiceMode' does not match installed mode '$detectedMode'."
    }

    $backupPath = $null
    $ssasScripts = @(
        'Collect-SsasMetrics.ps1',
        'Collect-SsasPerformanceCounters.ps1',
        'Collect-SsasXEventMetrics.ps1',
        'Invoke-SsasCollectors.ps1',
        'Run-SsasMetricsService.ps1',
        'Run-SsasMetricsLoop.ps1'
    )
    $runtimeFiles = @(
        (Join-Path $InstallRoot 'collector\ssas-collector.json'),
        (Join-Path $InstallRoot 'Log\prometheus_windows_ssas.out.log'),
        (Join-Path $InstallRoot 'Log\prometheus_windows_ssas.err.log')
    )
    $runtimeFiles += $ssasScripts | ForEach-Object { Join-Path $InstallRoot "scripts\powershell\$_" }
    if (Test-Path -LiteralPath (Join-Path $InstallRoot 'textfile_inputs')) {
        $runtimeFiles += Get-ChildItem -LiteralPath (Join-Path $InstallRoot 'textfile_inputs') -File -Filter 'ssas*.prom' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    }

    if ($RemoveFiles -and -not $SkipBackup) {
        $existingFiles = @($runtimeFiles | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
        if ($existingFiles.Count) {
            $backupRoot = Join-Path $env:ProgramData 'Observability\PrometheusExporters\uninstall-backups'
            $stage = Join-Path $env:TEMP ("{0}_{1}" -f $ServiceName,[guid]::NewGuid().ToString('N'))
            New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null
            New-Item -Path $stage -ItemType Directory -Force | Out-Null
            try {
                foreach ($file in $existingFiles) { Copy-Item -LiteralPath $file -Destination (Join-Path $stage ([IO.Path]::GetFileName($file))) -Force }
                $backupPath = Join-Path $backupRoot ("{0}_{1}.zip" -f $ServiceName,(Get-Date -Format 'yyyyMMdd_HHmmss'))
                Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $backupPath -CompressionLevel Optimal -Force
            } finally { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -ne 'Stopped') {
            Stop-Service -Name $ServiceName -Force
            $service.WaitForStatus('Stopped',[TimeSpan]::FromSeconds($ServiceTimeoutSec))
        }
        $nssmExe = if ($detectedMode -eq 'NSSM' -and $serviceCim) { Get-CommandExe $serviceCim.PathName } else { $null }
        if ($detectedMode -eq 'NSSM' -and $nssmExe -and (Test-Path -LiteralPath $nssmExe -PathType Leaf)) {
            $output = & $nssmExe remove $ServiceName confirm 2>&1
            if ($LASTEXITCODE -ne 0) { throw "NSSM remove failed: $($output -join [Environment]::NewLine)" }
        } else {
            $output = & sc.exe delete $ServiceName 2>&1
            if ($LASTEXITCODE -ne 0) { throw "sc.exe delete failed: $($output -join [Environment]::NewLine)" }
        }
        $deadline = (Get-Date).AddSeconds($ServiceTimeoutSec)
        while ((Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 250 }
        if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) { throw "Service was not removed within $ServiceTimeoutSec seconds: $ServiceName" }
    }

    $legacyTask = Get-ScheduledTask -TaskName $LegacyTaskName -ErrorAction SilentlyContinue
    if ($legacyTask) { Unregister-ScheduledTask -TaskName $LegacyTaskName -Confirm:$false }
    if ($RemoveFiles) {
        foreach ($file in $runtimeFiles | Select-Object -Unique) {
            if (Test-Path -LiteralPath $file -PathType Leaf) { Remove-Item -LiteralPath $file -Force }
        }
    }
    if ($RemoveEventSource) {
        $eventKey = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\$ServiceName"
        if (Test-Path -LiteralPath $eventKey) { Remove-Item -LiteralPath $eventKey -Recurse -Force }
    }

    [pscustomobject]@{
        Service = $ServiceName
        Mode = $detectedMode
        Status = 'Removed'
        LegacyTaskRemoved = [bool]$legacyTask
        Files = $(if ($RemoveFiles) { 'Removed' } else { 'Preserved' })
        Backup = $backupPath
        EventSource = $(if ($RemoveEventSource) { 'Removed' } else { 'Preserved' })
    }
}
