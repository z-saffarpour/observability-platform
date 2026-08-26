#Requires -Version 5.1
<#
.SYNOPSIS
  Installs or upgrades Alertmanager as an automatic Windows service using NSSM.
.EXAMPLE
  .\scripts\powershell\alertmanager\Install-Alertmanager.ps1 `
    -ConfigPath .\alertmanager\windows-exporter\alertmanager.yml
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [string]$SourceRoot,
    [string]$InstallRoot = 'C:\Program Files\Observability\Alertmanager',
    [string]$DataRoot,
    [string]$LogRoot,
    [string]$ServiceName = 'prometheus_alert_manager',
    [string]$ServiceDisplayName = 'Prometheus Alert Manager',
    [string]$ServiceDescription = 'Prometheus Alertmanager notification service',
    [string]$ListenAddress = '0.0.0.0:9093',
    [switch]$OpenFirewall,
    [ValidateRange(5, 300)][int]$ServiceTimeoutSec = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this installer from an elevated PowerShell session (Run as Administrator).'
    }
}

function Resolve-SafeAbsolutePath {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name)
    $resolved = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Path.TrimEnd('\')))
    if (-not [IO.Path]::IsPathRooted($resolved) -or $resolved -eq [IO.Path]::GetPathRoot($resolved)) {
        throw "Unsafe $Name path: $resolved"
    }
    $resolved
}

function Invoke-Nssm {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = & $script:NssmTarget @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "NSSM failed: nssm $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }
}

Assert-Administrator
if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
}
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$ConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
$InstallRoot = Resolve-SafeAbsolutePath -Path $InstallRoot -Name InstallRoot
if (-not $DataRoot) { $DataRoot = Join-Path $InstallRoot 'data' }
if (-not $LogRoot) { $LogRoot = Join-Path $InstallRoot 'logs' }
$DataRoot = Resolve-SafeAbsolutePath -Path $DataRoot -Name DataRoot
$LogRoot = Resolve-SafeAbsolutePath -Path $LogRoot -Name LogRoot

if ($ListenAddress -notmatch '^(?:\d{1,3}(?:\.\d{1,3}){3}|localhost|\*|):\d+$') {
    throw "Invalid ListenAddress: $ListenAddress"
}

$binarySource = Join-Path $SourceRoot 'alertmanager\bin\windows-amd64\alertmanager.exe'
$amtoolSource = Join-Path $SourceRoot 'alertmanager\bin\windows-amd64\amtool.exe'
$nssmSource = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
foreach ($required in @($binarySource, $amtoolSource, $nssmSource, $ConfigPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required file was not found: $required" }
}

$existingService = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $ServiceName.Replace("'", "''")) -ErrorAction SilentlyContinue
if ($existingService -and $existingService.PathName -notmatch '(?i)nssm\.exe') {
    throw "Service '$ServiceName' already exists but is not managed by NSSM."
}
if (-not $PSCmdlet.ShouldProcess($InstallRoot, "Install Alertmanager and configure service '$ServiceName'")) { return }

if ($existingService) {
    $service = Get-Service -Name $ServiceName
    if ($service.Status -ne 'Stopped') {
        Stop-Service -Name $ServiceName -Force
        $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
    }
}

$binTarget = Join-Path $InstallRoot 'bin'
$configTarget = Join-Path $InstallRoot 'config'
$templateTarget = Join-Path $configTarget 'templates'
foreach ($directory in @($binTarget, $configTarget, $templateTarget, $DataRoot, $LogRoot)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

$alertmanagerTarget = Join-Path $binTarget 'alertmanager.exe'
$amtoolTarget = Join-Path $binTarget 'amtool.exe'
$script:NssmTarget = Join-Path $binTarget 'nssm.exe'
$deployedConfig = Join-Path $configTarget 'alertmanager.yml'
Copy-Item -LiteralPath $binarySource -Destination $alertmanagerTarget -Force
Copy-Item -LiteralPath $amtoolSource -Destination $amtoolTarget -Force
Copy-Item -LiteralPath $nssmSource -Destination $script:NssmTarget -Force
Copy-Item -LiteralPath $ConfigPath -Destination $deployedConfig -Force

$sourceTemplates = Join-Path (Split-Path -Parent $ConfigPath) 'templates'
if (Test-Path -LiteralPath $sourceTemplates -PathType Container) {
    Get-ChildItem -LiteralPath $sourceTemplates -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $templateTarget -Force
    }
}

Push-Location $configTarget
try {
    & $amtoolTarget check-config $deployedConfig
    if ($LASTEXITCODE -ne 0) { throw 'Alertmanager configuration validation failed.' }
}
finally {
    Pop-Location
}

$appParameters = @(
    "--config.file=`"$deployedConfig`""
    "--storage.path=`"$DataRoot`""
    "--web.listen-address=`"$ListenAddress`""
) -join ' '

if (-not $existingService) { Invoke-Nssm -Arguments @('install', $ServiceName, $alertmanagerTarget) }
Invoke-Nssm -Arguments @('set', $ServiceName, 'Application', $alertmanagerTarget)
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppDirectory', $configTarget)
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppParameters', $appParameters)
Invoke-Nssm -Arguments @('set', $ServiceName, 'DisplayName', $ServiceDisplayName)
Invoke-Nssm -Arguments @('set', $ServiceName, 'Description', $ServiceDescription)
Invoke-Nssm -Arguments @('set', $ServiceName, 'Start', 'SERVICE_DELAYED_AUTO_START')
Invoke-Nssm -Arguments @('set', $ServiceName, 'ObjectName', 'LocalSystem')
Invoke-Nssm -Arguments @('set', $ServiceName, 'DependOnService', 'Tcpip')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppExit', 'Default', 'Restart')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRestartDelay', '5000')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppThrottle', '5000')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppStdout', (Join-Path $LogRoot "$ServiceName.out.log"))
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppStderr', (Join-Path $LogRoot "$ServiceName.err.log"))
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateFiles', '1')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateOnline', '1')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateBytes', '10485760')

& sc.exe failure $ServiceName 'reset=' 86400 'actions=' 'restart/5000/restart/15000/restart/60000' | Out-Null
& sc.exe failureflag $ServiceName 1 | Out-Null

if ($OpenFirewall) {
    $port = [int](($ListenAddress -split ':')[-1])
    $firewallName = "Alertmanager TCP $port"
    if (-not (Get-NetFirewallRule -DisplayName $firewallName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $firewallName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -Profile Domain,Private | Out-Null
    }
}

Start-Service -Name $ServiceName
$runningService = Get-Service -Name $ServiceName
$runningService.WaitForStatus('Running', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
Start-Sleep -Seconds 3
$runningService.Refresh()
if ($runningService.Status -ne 'Running') {
    $errorLog = Join-Path $LogRoot "$ServiceName.err.log"
    $tail = if (Test-Path -LiteralPath $errorLog) { Get-Content -LiteralPath $errorLog -Tail 50 | Out-String } else { 'No error log was created.' }
    throw "Alertmanager service stopped after startup.`n$tail"
}

[pscustomobject]@{
    Service = $ServiceName
    DisplayName = $ServiceDisplayName
    Status = $runningService.Status
    InstallRoot = $InstallRoot
    DataRoot = $DataRoot
    ListenAddress = $ListenAddress
}
