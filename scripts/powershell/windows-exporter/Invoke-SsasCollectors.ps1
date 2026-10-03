#Requires -Version 5.1
[CmdletBinding()]
param(
  [string]$ConfigPath,
  [string[]]$Instance=@('localhost'),
  [string[]]$Endpoint=@(),
  [string[]]$BackupPath=@(),
  [string[]]$ReadOnlyProbeConnectionStringFile=@(),
  [string[]]$XelPath=@()
)
$ErrorActionPreference='Continue'
. (Join-Path $PSScriptRoot 'Ssas-CollectorConfig.ps1')

$collectorParams = @{
  Instance = $Instance
  Endpoint = $Endpoint
  BackupPath = $BackupPath
  ReadOnlyProbeConnectionStringFile = $ReadOnlyProbeConnectionStringFile
}
$config = $null
if ($ConfigPath) {
  $config = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
  $Instance = @($config.Instance)
  $Endpoint = @($config.Endpoint)
  $BackupPath = @($config.BackupPath)
  $ReadOnlyProbeConnectionStringFile = @($config.ReadOnlyProbeConnectionStringFile)
  $XelPath = @($config.XelPath)
  $collectorParams.Instance = $Instance
  $collectorParams.Endpoint = $Endpoint
  $collectorParams.BackupPath = $BackupPath
  $collectorParams.ReadOnlyProbeConnectionStringFile = $ReadOnlyProbeConnectionStringFile
  foreach ($name in @('CommandTimeoutSec', 'StaleAfterHours', 'LongSessionMinutes', 'IdleSessionMinutes')) {
    if ($null -ne $config.$name) { $collectorParams[$name] = [int]$config.$name }
  }
}

if ($config) {
  Ensure-SsasProgramDataLayoutFromConfig -Config $config | Out-Null
}

& (Join-Path $PSScriptRoot 'Collect-SsasMetrics.ps1') @collectorParams
& (Join-Path $PSScriptRoot 'Collect-SsasPerformanceCounters.ps1')

if ($XelPath.Count) {
  $resolved = Resolve-SsasCollectorPathsFromConfig -Config $config
  $rotation = Resolve-SsasRotationFromConfig -Config $config
  $xeventParams = @{
    XelPath            = @($resolved.XelPath)
    SiemOutputPath     = $resolved.SiemOutputPath
    XEventsDirectory   = $resolved.XEventsDirectory
    AuditLogMaxBytes   = $rotation.AuditLogMaxBytes
    XelFileMaxBytes    = $rotation.XelFileMaxBytes
    XelDirectoryMaxBytes = $rotation.XelDirectoryMaxBytes
    KeepRotatedFiles   = $rotation.KeepRotatedFiles
  }
  & (Join-Path $PSScriptRoot 'Collect-SsasXEventMetrics.ps1') @xeventParams
}
