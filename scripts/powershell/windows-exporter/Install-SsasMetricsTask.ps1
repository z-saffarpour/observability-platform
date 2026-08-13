#Requires -Version 5.1
<#
.SYNOPSIS
  Installs the SSAS metric collectors as the prometheus_windows_ssas Windows service.

.DESCRIPTION
  The historical script name is retained for compatibility. No scheduled task is
  created. An existing legacy SSAS scheduled task is removed during installation.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string[]]$Instance = @('localhost'),
    [string[]]$Endpoint = @(),
    [string[]]$BackupPath = @(),
    [string[]]$ReadOnlyProbeConnectionStringFile = @(),
    [string[]]$XelPath = @(),
    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter',
    [string]$ServiceName = 'prometheus_windows_ssas',
    [string]$DisplayName = 'Prometheus Windows SSAS Metrics',
    [ValidateSet('ServiceBase', 'NSSM')][string]$ServiceMode = 'ServiceBase',
    [string]$NssmPath,
    [string]$LegacyTaskName = 'DBA Monitoring - SSAS Prometheus Metrics',
    [ValidateRange(1, 60)][int]$IntervalMinutes = 1,
    [ValidateRange(5, 300)][int]$ServiceTimeoutSec = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptNames = @(
    'Collect-SsasMetrics.ps1',
    'Collect-SsasPerformanceCounters.ps1',
    'Collect-SsasXEventMetrics.ps1',
    'Invoke-SsasCollectors.ps1',
    'Run-SsasMetricsService.ps1',
    'Run-SsasMetricsLoop.ps1'
)
$targetDir = Join-Path $InstallRoot 'scripts\powershell'
$serviceHost = Join-Path $targetDir 'Run-SsasMetricsService.ps1'
$serviceLoop = Join-Path $targetDir 'Run-SsasMetricsLoop.ps1'
$collectorScript = Join-Path $targetDir 'Invoke-SsasCollectors.ps1'
$collectorDir = Join-Path $InstallRoot 'collector'
$configPath = Join-Path $collectorDir 'ssas-collector.json'
$textfileDir = Join-Path $InstallRoot 'textfile_inputs'
$logDir = Join-Path $InstallRoot 'Log'

if ([string]::IsNullOrWhiteSpace($NssmPath)) {
    $NssmPath = 'C:\Program Files\Observability\Tools\NSSM\nssm.exe'
}

foreach ($name in $scriptNames) {
    $sourceFile = Join-Path $PSScriptRoot $name
    if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
        throw "Required service script was not found: $sourceFile"
    }
}

if ($PSCmdlet.ShouldProcess($ServiceName, 'Install or update SSAS metrics Windows service')) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Administrator rights are required to install prometheus_windows_ssas.'
    }
    foreach ($directory in @($targetDir, $collectorDir, $textfileDir, $logDir)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    foreach ($name in $scriptNames) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $targetDir $name) -Force
    }

    if (-not [Diagnostics.EventLog]::SourceExists($ServiceName)) {
        New-EventLog -LogName Application -Source $ServiceName
    }

    [ordered]@{
        Instance = @($Instance)
        Endpoint = @($Endpoint)
        BackupPath = @($BackupPath)
        ReadOnlyProbeConnectionStringFile = @($ReadOnlyProbeConnectionStringFile)
        XelPath = @($XelPath)
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $configPath -Encoding UTF8

    $legacyTask = Get-ScheduledTask -TaskName $LegacyTaskName -ErrorAction SilentlyContinue
    if ($legacyTask) {
        Unregister-ScheduledTask -TaskName $LegacyTaskName -Confirm:$false
    }

    $existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($existing -and $existing.Status -ne 'Stopped') {
        Stop-Service -Name $ServiceName -Force
        $existing.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
    }

    $powershellExe = Join-Path $PSHOME 'powershell.exe'
    if ($ServiceMode -eq 'NSSM') {
        if (-not (Test-Path -LiteralPath $NssmPath -PathType Leaf)) {
            throw "NSSM was not found: $NssmPath. Deploy deployment\windows\tools\nssm\nssm.exe to C:\Program Files\Observability\Tools\NSSM\nssm.exe or pass -NssmPath."
        }
        if ($existing) {
            $deleteOutput = & sc.exe delete $ServiceName 2>&1
            if ($LASTEXITCODE -ne 0) { throw "Unable to replace existing service with NSSM: $($deleteOutput -join [Environment]::NewLine)" }
            $deadline = (Get-Date).AddSeconds($ServiceTimeoutSec)
            while ((Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
                Start-Sleep -Milliseconds 250
            }
            if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
                throw "Existing service could not be removed: $ServiceName"
            }
        }
        $loopArguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -EventSource "{1}" -CollectorScript "{2}" -ConfigPath "{3}" -IntervalMinutes {4}' -f `
            $serviceLoop, $ServiceName, $collectorScript, $configPath, $IntervalMinutes
        function Invoke-Nssm {
            param([Parameter(Mandatory)][string[]]$Arguments)
            $result = & $NssmPath @Arguments 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "NSSM failed: nssm $($Arguments -join ' ')`n$($result -join [Environment]::NewLine)"
            }
        }
        Invoke-Nssm -Arguments @('install', $ServiceName, $powershellExe, $loopArguments)
        Invoke-Nssm -Arguments @('set', $ServiceName, 'DisplayName', $DisplayName)
        Invoke-Nssm -Arguments @('set', $ServiceName, 'Description', 'Collects Microsoft SSAS metrics for Prometheus windows_exporter.')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'Start', 'SERVICE_AUTO_START')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'ObjectName', 'LocalSystem')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'AppDirectory', $InstallRoot)
        Invoke-Nssm -Arguments @('set', $ServiceName, 'AppStdout', (Join-Path $logDir 'prometheus_windows_ssas.out.log'))
        Invoke-Nssm -Arguments @('set', $ServiceName, 'AppStderr', (Join-Path $logDir 'prometheus_windows_ssas.err.log'))
        Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateFiles', '1')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateBytes', '10485760')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'AppExit', 'Default', 'Restart')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'AppThrottle', '5000')
    }
    else {
        $serviceArguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -ServiceName "{1}" -CollectorScript "{2}" -ConfigPath "{3}" -IntervalMinutes {4}' -f `
            $serviceHost, $ServiceName, $collectorScript, $configPath, $IntervalMinutes
        $binaryPath = '"{0}" {1}' -f $powershellExe, $serviceArguments
        if (-not $existing) {
            New-Service -Name $ServiceName -DisplayName $DisplayName -BinaryPathName $binaryPath -StartupType Automatic | Out-Null
        }
        else {
            $output = & sc.exe config $ServiceName ('binPath= ' + $binaryPath) 'start= auto' ('DisplayName= ' + $DisplayName) 2>&1
            if ($LASTEXITCODE -ne 0) { throw "sc.exe config failed: $($output -join [Environment]::NewLine)" }
        }
    }
    $description = & sc.exe description $ServiceName 'Collects Microsoft SSAS metrics for Prometheus windows_exporter.' 2>&1
    if ($LASTEXITCODE -ne 0) { throw "sc.exe description failed: $($description -join [Environment]::NewLine)" }
    $failure = & sc.exe failure $ServiceName 'reset= 86400' 'actions= restart/60000/restart/60000/restart/60000' 2>&1
    if ($LASTEXITCODE -ne 0) { throw "sc.exe failure configuration failed: $($failure -join [Environment]::NewLine)" }
    & sc.exe failureflag $ServiceName 1 | Out-Null

    Start-Service -Name $ServiceName
    $service = Get-Service -Name $ServiceName
    $service.WaitForStatus('Running', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
    $service.Refresh()
    if ($service.Status -ne 'Running') { throw "Service did not reach Running state: $ServiceName" }
    Write-EventLog -LogName Application -Source $ServiceName -EntryType Information -EventId 1001 `
        -Message "Windows service installed and started. Mode=$ServiceMode; ConfigPath=$configPath; IntervalMinutes=$IntervalMinutes"

    [pscustomobject]@{
        Service = $ServiceName
        Status = $service.Status.ToString()
        StartType = 'Automatic'
        ConfigPath = $configPath
        IntervalMinutes = $IntervalMinutes
        Mode = $ServiceMode
        LegacyTaskRemoved = [bool]$legacyTask
    }
}
