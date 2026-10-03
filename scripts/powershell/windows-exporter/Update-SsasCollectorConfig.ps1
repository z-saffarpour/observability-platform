#Requires -Version 5.1
<#
.SYNOPSIS
  Refreshes collector\ssas-collector.json with standard Paths/Rotation defaults.
.DESCRIPTION
  Merges existing Instance/Endpoint/tuning with current default paths and rotation
  settings. Safe to run during upgrade without reinstalling prometheus_windows_ssas.
.EXAMPLE
  .\Update-SsasCollectorConfig.ps1
.EXAMPLE
  .\Update-SsasCollectorConfig.ps1 -ProgramDataRoot 'D:\Observability\SSAS' -AuditLogMaxBytes 104857600
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter',
    [string]$ProgramDataRoot = '',
    [string]$XEventsDirectory = '',
    [string]$SecretsDirectory = '',
    [string]$AuditDirectory = '',
    [string]$SiemOutputPath = '',
    [long]$AuditLogMaxBytes = 0,
    [long]$XelFileMaxBytes = 0,
    [long]$XelDirectoryMaxBytes = 0,
    [ValidateRange(1, 100)][int]$KeepRotatedFiles = 0,
    [switch]$EnableXEvents
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Ssas-CollectorConfig.ps1')

$configPath = Join-Path $InstallRoot 'collector\ssas-collector.json'
$existingConfig = $null
if (Test-Path -LiteralPath $configPath) {
    try { $existingConfig = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json } catch {}
}

$installParameters = @{
    EnableXEvents        = $EnableXEvents
    ProgramDataRoot      = $ProgramDataRoot
    XEventsDirectory     = $XEventsDirectory
    SecretsDirectory     = $SecretsDirectory
    AuditDirectory       = $AuditDirectory
    SiemOutputPath       = $SiemOutputPath
    AuditLogMaxBytes     = $AuditLogMaxBytes
    XelFileMaxBytes      = $XelFileMaxBytes
    XelDirectoryMaxBytes = $XelDirectoryMaxBytes
    KeepRotatedFiles     = $KeepRotatedFiles
}

if ($existingConfig) {
    foreach ($key in @('Instance', 'Endpoint', 'BackupPath', 'ReadOnlyProbeConnectionStringFile', 'XelPath')) {
        if ($existingConfig.PSObject.Properties.Name -contains $key) {
            $installParameters[$key] = @($existingConfig.$key | ForEach-Object { $_ })
        }
    }
    foreach ($key in @('CommandTimeoutSec', 'StaleAfterHours', 'LongSessionMinutes', 'IdleSessionMinutes')) {
        if ($existingConfig.PSObject.Properties.Name -contains $key) {
            $installParameters[$key] = [int]$existingConfig.$key
        }
    }
}

if (-not $PSCmdlet.ShouldProcess($configPath, 'Refresh SSAS collector configuration')) { return }

New-Item -Path (Split-Path $configPath -Parent) -ItemType Directory -Force | Out-Null
$mergedConfig = Merge-SsasCollectorConfig -Existing $existingConfig -Install $installParameters
Ensure-SsasProgramDataLayoutFromConfig -Config $mergedConfig | Out-Null
$mergedConfig | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $configPath -Encoding UTF8

[pscustomobject]@{
    Status     = 'Updated'
    ConfigPath = $configPath
    Paths      = $mergedConfig.Paths
    Rotation   = $mergedConfig.Rotation
}
