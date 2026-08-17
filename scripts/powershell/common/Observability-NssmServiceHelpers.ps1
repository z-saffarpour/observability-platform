#Requires -Version 5.1
<#
.SYNOPSIS
  Shared helpers for NSSM-managed Prometheus exporter Windows services.
#>
Set-StrictMode -Version Latest

function Invoke-ObservabilitySc {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $normalized = foreach ($arg in $Arguments) {
        if ($arg -match '^(?<k>[A-Za-z]+=) (?<v>.+)$') {
            $Matches['k']
            $Matches['v']
        }
        else {
            $arg
        }
    }
    $out = & sc.exe @normalized 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ("sc.exe failed: sc.exe {0}`n{1}" -f ($normalized -join ' '), ($out -join [Environment]::NewLine))
    }
}

function Grant-ObservabilityServiceLogAccess {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Account
    )
    if ([string]::IsNullOrWhiteSpace($Account)) { return }
    if ($Account -in @(
            'LocalSystem', 'NT AUTHORITY\SYSTEM',
            'NT AUTHORITY\LocalService', 'NT AUTHORITY\NetworkService'
        )) { return }
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $acl = Get-Acl -LiteralPath $Path
    $inherit = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit
    $rule = New-Object Security.AccessControl.FileSystemAccessRule(
        $Account,
        'Modify',
        $inherit,
        [Security.AccessControl.PropagationFlags]::None,
        'Allow'
    )
    $acl.AddAccessRule($rule)
    Set-Acl -LiteralPath $Path -AclObject $acl
}

function Register-ObservabilityNssmEventSource {
    param([Parameter(Mandatory)][string]$NssmExe)
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\nssm'
    if (-not (Test-Path -LiteralPath $key)) {
        New-Item -Path $key -Force | Out-Null
    }
    New-ItemProperty -LiteralPath $key -Name EventMessageFile -Value ('"{0}"' -f $NssmExe) -PropertyType ExpandString -Force | Out-Null
    New-ItemProperty -LiteralPath $key -Name TypesSupported -Value 7 -PropertyType DWord -Force | Out-Null
}

function Get-ObservabilityNssmLogTail {
    param(
        [Parameter(Mandatory)][string]$LogDirectory,
        [Parameter(Mandatory)][string]$ServiceName,
        [string]$ProcessLabel = 'exporter'
    )
    $chunks = New-Object System.Collections.Generic.List[string]
    foreach ($leaf in @("$ServiceName.err.log", "$ServiceName.out.log")) {
        $path = Join-Path $LogDirectory $leaf
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $chunks.Add(('--- {0} ---' -f $leaf)) | Out-Null
            $lines = @(Get-Content -LiteralPath $path -Tail 50 -ErrorAction SilentlyContinue)
            if ($lines.Count -gt 0) { $chunks.Add(($lines -join [Environment]::NewLine)) | Out-Null }
        }
    }
    if ($chunks.Count -eq 0) {
        return "No NSSM stdout/stderr files yet. Event 1013 from source nssm means $ProcessLabel exited; open the event Details tab for the exit code."
    }
    $chunks -join [Environment]::NewLine
}

function Set-ObservabilityNssmLogging {
    param(
        [Parameter(Mandatory)][string]$ParametersKey,
        [Parameter(Mandatory)][string]$StdoutLog,
        [Parameter(Mandatory)][string]$StderrLog,
        [int]$AppThrottleMs = 5000
    )
    Set-ItemProperty -LiteralPath $ParametersKey -Name AppStdout -Value $StdoutLog
    Set-ItemProperty -LiteralPath $ParametersKey -Name AppStderr -Value $StderrLog
    Set-ItemProperty -LiteralPath $ParametersKey -Name AppRotateFiles -Value 1 -Type DWord
    Set-ItemProperty -LiteralPath $ParametersKey -Name AppRotateBytes -Value 10485760 -Type DWord
    Set-ItemProperty -LiteralPath $ParametersKey -Name AppThrottle -Value $AppThrottleMs -Type DWord
    Set-ItemProperty -LiteralPath $ParametersKey -Name AppNoConsole -Value 1 -Type DWord
}

function Get-ObservabilityListenAddressFromAppParameters {
    param(
        [string]$AppParameters,
        [string]$Default = ':9399'
    )
    if ($AppParameters -match '--web\.listen-address="([^"]+)"') { return $Matches[1] }
    if ($AppParameters -match '--web\.listen-address=([^\s]+)') { return $Matches[1] }
    return $Default
}

function Get-ObservabilitySqlServerEngineServiceNames {
    @(
        Get-Service -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq 'MSSQLSERVER' -or $_.Name -like 'MSSQL$*' } |
            Select-Object -ExpandProperty Name |
            Sort-Object
    )
}

function Get-ObservabilitySqlServerServiceFromDataSourceName {
    param([string]$DataSourceName)

    if ([string]::IsNullOrWhiteSpace($DataSourceName)) { return $null }
    if ($DataSourceName -notmatch '(?i)^sqlserver://') { return $null }

    $withoutScheme = $DataSourceName -replace '(?i)^sqlserver://', ''
    $authority = ($withoutScheme -split '[/?#]')[0]
    if ($authority -match '@(.+)$') { $authority = $Matches[1] }

    if ($authority -match '\\([^:\\]+)$') {
        return ('MSSQL${0}' -f $Matches[1])
    }

    return 'MSSQLSERVER'
}

function Resolve-ObservabilitySqlServerServiceDependency {
    param(
        [string]$DependencyMode = 'Auto',
        [string]$DataSourceName
    )

    if ($DependencyMode -eq 'None') { return @() }

    if (-not [string]::IsNullOrWhiteSpace($DependencyMode) -and $DependencyMode -ne 'Auto') {
        return @(
            $DependencyMode -split '[,;/]' |
                ForEach-Object { $_.Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }

    $fromDsn = Get-ObservabilitySqlServerServiceFromDataSourceName -DataSourceName $DataSourceName
    if ($fromDsn) { return @($fromDsn) }

    $engineServices = @(Get-ObservabilitySqlServerEngineServiceNames)
    if ($engineServices.Count -eq 0) { return @() }
    if ($engineServices.Count -eq 1) { return $engineServices }
    if ($engineServices -contains 'MSSQLSERVER') { return @('MSSQLSERVER') }

    return $engineServices
}

function Set-ObservabilityServiceDependencies {
    param(
        [Parameter(Mandatory)][string]$ServiceName,
        [string[]]$DependencyServiceNames
    )

    $deps = @(
        $DependencyServiceNames |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    if ($deps.Count -eq 0) {
        Invoke-ObservabilitySc -Arguments @('config', $ServiceName, 'depend= /')
        return @()
    }

    $dependValue = $deps -join '/'
    Invoke-ObservabilitySc -Arguments @('config', $ServiceName, ('depend= ' + $dependValue))
    return $deps
}

function Set-ObservabilitySqlServerServiceDependency {
    param(
        [Parameter(Mandatory)][string]$ServiceName,
        [string]$DependencyMode = 'Auto',
        [string]$DataSourceName
    )

    if ($DependencyMode -eq 'None') { return @() }

    $deps = @(
        Resolve-ObservabilitySqlServerServiceDependency `
            -DependencyMode $DependencyMode `
            -DataSourceName $DataSourceName
    )

    if ($deps.Count -eq 0) { return @() }

    $missing = @()
    foreach ($dep in $deps) {
        if (-not (Get-Service -Name $dep -ErrorAction SilentlyContinue)) {
            $missing += $dep
        }
    }
    if ($missing.Count -gt 0) {
        throw "SQL Server dependency service(s) not found: $($missing -join ', ')"
    }

    Set-ObservabilityServiceDependencies -ServiceName $ServiceName -DependencyServiceNames $deps
    return $deps
}

function Get-ObservabilitySqlExporterDataSourceNameFromConfig {
    param([Parameter(Mandatory)][string]$ConfigPath)

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) { return $null }

    $content = Get-Content -LiteralPath $ConfigPath -Raw
    if ($content -match '(?m)^\s{2}data_source_name:\s*(.+)$') {
        $value = $Matches[1].Trim()
        if ($value -match '^[''""](.+)[''""]\s*$') { return $Matches[1] }
        if ($value -match '^([^#\s].*?)\s*$') { return $Matches[1].Trim() }
    }

    return $null
}

function Start-ObservabilityManagedService {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$TimeoutSec,
        [string]$LogDirectory,
        [string]$ProcessLabel = 'exporter'
    )

    $svc = Get-Service -Name $Name -ErrorAction Stop
    if ($svc.Status -eq 'Paused') {
        Resume-Service -Name $Name -ErrorAction Stop
    }
    elseif ($svc.Status -ne 'Running') {
        Start-Service -Name $Name -ErrorAction Stop
    }

    $svc.WaitForStatus('Running', [TimeSpan]::FromSeconds($TimeoutSec))
    $svc.Refresh()
    if ($svc.Status.ToString() -ne 'Running') {
        $tail = if ($LogDirectory) {
            Get-ObservabilityNssmLogTail -LogDirectory $LogDirectory -ServiceName $Name -ProcessLabel $ProcessLabel
        }
        else {
            "Service did not reach Running (NSSM Paused means $ProcessLabel exited during AppThrottle)."
        }
        throw ("Service did not reach Running.`n{0}" -f $tail)
    }

    Start-Sleep -Seconds 3
    $svc.Refresh()
    if ($svc.Status.ToString() -ne 'Running') {
        $tail = if ($LogDirectory) {
            Get-ObservabilityNssmLogTail -LogDirectory $LogDirectory -ServiceName $Name -ProcessLabel $ProcessLabel
        }
        else {
            "Service entered $($svc.Status) after start (NSSM Event 1013 = $ProcessLabel exited)."
        }
        throw ("Service entered {0} after start.`n{1}" -f $svc.Status, $tail)
    }

    return $svc
}
