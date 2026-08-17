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
if($ConfigPath){$config=Get-Content -Raw -LiteralPath $ConfigPath|ConvertFrom-Json;$Instance=@($config.Instance);$Endpoint=@($config.Endpoint);$BackupPath=@($config.BackupPath);$ReadOnlyProbeConnectionStringFile=@($config.ReadOnlyProbeConnectionStringFile);$XelPath=@($config.XelPath)}
& (Join-Path $PSScriptRoot 'Collect-SsasMetrics.ps1') -Instance $Instance -Endpoint $Endpoint -BackupPath $BackupPath -ReadOnlyProbeConnectionStringFile $ReadOnlyProbeConnectionStringFile
& (Join-Path $PSScriptRoot 'Collect-SsasPerformanceCounters.ps1')
if($XelPath.Count){& (Join-Path $PSScriptRoot 'Collect-SsasXEventMetrics.ps1') -XelPath $XelPath}
