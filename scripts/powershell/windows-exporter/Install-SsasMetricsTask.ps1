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
    [ValidateSet('LocalSystem', 'LocalService', 'NetworkService', 'Credential', 'gMSA', 'NtService')]
    [string]$ServiceAccountMode = 'LocalSystem',
    [string]$ServiceAccount,
    [pscredential]$ServiceCredential,
    [string]$NssmPath,
    [string]$LegacyTaskName = 'DBA Monitoring - SSAS Prometheus Metrics',
    [ValidateRange(1, 60)][int]$IntervalMinutes = 1,
    [ValidateRange(5, 300)][int]$ServiceTimeoutSec = 60,
    [ValidateRange(5, 300)][int]$CommandTimeoutSec = 30,
    [ValidateRange(1, 168)][int]$StaleAfterHours = 24,
    [ValidateRange(1, 1440)][int]$LongSessionMinutes = 30,
    [ValidateRange(1, 1440)][int]$IdleSessionMinutes = 15,
    [switch]$EnableXEvents,
    [string]$ProgramDataRoot = '',
    [string]$XEventsDirectory = '',
    [string]$SecretsDirectory = '',
    [string]$AuditDirectory = '',
    [string]$SiemOutputPath = '',
    [long]$AuditLogMaxBytes = 0,
    [long]$XelFileMaxBytes = 0,
    [long]$XelDirectoryMaxBytes = 0,
    [ValidateRange(1, 100)][int]$KeepRotatedFiles = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:InstallLogPath = $null

function Write-InstallLog([string]$Message, [string]$Color = 'Cyan') {
    $entry = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $entry -ForegroundColor $Color
    if ($script:InstallLogPath) {
        [IO.File]::AppendAllText($script:InstallLogPath, $entry + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    }
}

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

$helperCandidates = @(
    (Join-Path $PSScriptRoot '..\common\Observability-NssmServiceHelpers.ps1'),
    (Join-Path $PSScriptRoot 'Observability-NssmServiceHelpers.ps1'),
    (Join-Path (Split-Path $PSScriptRoot -Parent) 'common\Observability-NssmServiceHelpers.ps1')
)
$helperPath = $helperCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $helperPath) {
    throw "Required helper script was not found. Tried: $($helperCandidates -join '; ')"
}
. $helperPath

$scriptNames = @(
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
    try {
        foreach ($directory in @($targetDir, $collectorDir, $textfileDir, $logDir)) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        }
        $script:InstallLogPath = Join-Path $logDir "$ServiceName.install.log"
        Write-InstallLog "Starting installation. Mode=$ServiceMode; ServiceAccount=$account; InstallRoot=$InstallRoot"
        foreach ($name in $scriptNames) {
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $targetDir $name) -Force
        }
        Write-InstallLog 'Collector and service-host scripts deployed.'

        . (Join-Path $targetDir 'Ssas-CollectorConfig.ps1')

        $existingConfig = $null
        if (Test-Path -LiteralPath $configPath) {
            try { $existingConfig = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json } catch {}
        }

        $installParameters = @{
            Instance                          = $Instance
            Endpoint                          = $Endpoint
            BackupPath                        = $BackupPath
            ReadOnlyProbeConnectionStringFile = $ReadOnlyProbeConnectionStringFile
            XelPath                           = $XelPath
            ProgramDataRoot                   = $ProgramDataRoot
            XEventsDirectory                  = $XEventsDirectory
            SecretsDirectory                  = $SecretsDirectory
            AuditDirectory                    = $AuditDirectory
            SiemOutputPath                    = $SiemOutputPath
            CommandTimeoutSec                 = $CommandTimeoutSec
            StaleAfterHours                   = $StaleAfterHours
            LongSessionMinutes                = $LongSessionMinutes
            IdleSessionMinutes                = $IdleSessionMinutes
            AuditLogMaxBytes                  = $AuditLogMaxBytes
            XelFileMaxBytes                   = $XelFileMaxBytes
            XelDirectoryMaxBytes              = $XelDirectoryMaxBytes
            KeepRotatedFiles                  = $KeepRotatedFiles
            EnableXEvents                     = $EnableXEvents
        }
        $collectorConfig = Merge-SsasCollectorConfig -Existing $existingConfig -Install $installParameters
        Ensure-SsasProgramDataLayoutFromConfig -Config $collectorConfig | Out-Null
        Write-InstallLog "SSAS ProgramData layout ensured under $($collectorConfig.Paths.ProgramDataRoot)."

        if (-not [Diagnostics.EventLog]::SourceExists($ServiceName)) {
            New-EventLog -LogName Application -Source $ServiceName
        }

        $collectorConfig | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $configPath -Encoding UTF8
        Write-InstallLog "Collector configuration written: $configPath"

        $legacyTask = Get-ScheduledTask -TaskName $LegacyTaskName -ErrorAction SilentlyContinue
        if ($legacyTask) {
            Unregister-ScheduledTask -TaskName $LegacyTaskName -Confirm:$false
            Write-InstallLog "Legacy scheduled task removed: $LegacyTaskName"
        }

        $existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($existing -and $existing.Status -ne 'Stopped') {
            Write-InstallLog "Stopping existing service: $ServiceName"
            Stop-Service -Name $ServiceName -Force
            $existing.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
        }

        $powershellExe = Join-Path $PSHOME 'powershell.exe'
        Write-InstallLog "Configuring Windows service using $ServiceMode."
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
        Invoke-Nssm -Arguments @('install', $ServiceName, $powershellExe)
        $parameters = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName\Parameters"
        if (-not (Test-Path -LiteralPath $parameters)) {
            throw "NSSM parameters key was not found: $parameters"
        }
        Set-ItemProperty -LiteralPath $parameters -Name Application -Value $powershellExe
        Set-ItemProperty -LiteralPath $parameters -Name AppParameters -Value $loopArguments
        Set-ItemProperty -LiteralPath $parameters -Name AppDirectory -Value $InstallRoot
        Set-ObservabilityNssmLogging -ParametersKey $parameters -StdoutLog (Join-Path $logDir 'prometheus_windows_ssas.out.log') -StderrLog (Join-Path $logDir 'prometheus_windows_ssas.err.log')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'AppExit', 'Default', 'Restart')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'DisplayName', $DisplayName)
        Invoke-Nssm -Arguments @('set', $ServiceName, 'Description', 'Collects Microsoft SSAS metrics for Prometheus windows_exporter.')
        Invoke-Nssm -Arguments @('set', $ServiceName, 'Start', 'SERVICE_AUTO_START')
        Invoke-ObservabilitySc -Arguments @('config', $ServiceName, ('binPath= ' + ('"{0}"' -f $NssmPath)))
        Register-ObservabilityNssmEventSource -NssmExe $NssmPath
        }
        else {
        $serviceArguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -ServiceName "{1}" -CollectorScript "{2}" -ConfigPath "{3}" -IntervalMinutes {4}' -f `
            $serviceHost, $ServiceName, $collectorScript, $configPath, $IntervalMinutes
        $binaryPath = '"{0}" {1}' -f $powershellExe, $serviceArguments
        if (-not $existing) {
            New-Service -Name $ServiceName -DisplayName $DisplayName -BinaryPathName $binaryPath -StartupType Automatic | Out-Null
        }
        else {
            Invoke-ObservabilitySc -Arguments @('config', $ServiceName, ('binPath= ' + $binaryPath), 'start= auto', ('DisplayName= ' + $DisplayName))
        }
        }
        $accountArgs = @('config', $ServiceName, ('obj= ' + $account))
        if ($password) { $accountArgs += ('password= ' + $password) }
        Invoke-ObservabilitySc -Arguments $accountArgs
        Write-InstallLog "Service Log On account configured: $account"
        Invoke-ObservabilitySc -Arguments @('description', $ServiceName, 'Collects Microsoft SSAS metrics for Prometheus windows_exporter.')
        Invoke-ObservabilitySc -Arguments @('failure', $ServiceName, 'reset= 86400', 'actions= restart/60000/restart/60000/restart/60000')
        Invoke-ObservabilitySc -Arguments @('failureflag', $ServiceName, '1')

        $service = Start-ObservabilityManagedService -Name $ServiceName -TimeoutSec $ServiceTimeoutSec -LogDirectory $logDir -ProcessLabel 'powershell.exe'
        Write-EventLog -LogName Application -Source $ServiceName -EntryType Information -EventId 1001 `
            -Message "Windows service installed and started. Mode=$ServiceMode; ConfigPath=$configPath; IntervalMinutes=$IntervalMinutes"
        Write-InstallLog "Installation completed. Service status=$($service.Status); ConfigPath=$configPath" 'Green'

        [pscustomobject]@{
        Service = $ServiceName
        Status = $service.Status.ToString()
        StartType = 'Automatic'
        ServiceAccount = $account
        ConfigPath = $configPath
        IntervalMinutes = $IntervalMinutes
        Mode = $ServiceMode
        LegacyTaskRemoved = [bool]$legacyTask
        InstallLogPath = $script:InstallLogPath
        }
    }
    catch {
        $message = "Installation failed: $($_.Exception.Message)"
        Write-InstallLog $message 'Red'
        try {
            if ([Diagnostics.EventLog]::SourceExists($ServiceName)) {
                Write-EventLog -LogName Application -Source $ServiceName -EntryType Error -EventId 1002 -Message $message
            }
        } catch {}
        throw
    }
}
