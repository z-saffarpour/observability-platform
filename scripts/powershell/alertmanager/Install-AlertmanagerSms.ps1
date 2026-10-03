#Requires -Version 5.1
<#
.SYNOPSIS
  Installs or upgrades the Alertmanager SMS gateway as an NSSM Windows service.
.DESCRIPTION
  Copies Receive-AlertmanagerSms.ps1 and a local config file, then registers
  powershell.exe under NSSM. The config file holds the API key and owner phone
  map and is not written to the repository.
.EXAMPLE
  Copy sms-gateway.json.example to a path outside the repo, fill the API key
  and phone numbers, then run elevated:

  .\scripts\powershell\alertmanager\Install-AlertmanagerSms.ps1 `
    -ConfigPath C:\Secure\sms-gateway.json
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [string]$SourceRoot,
    [string]$InstallRoot = 'C:\Program Files\Observability\Alertmanager\sms',
    [string]$LogRoot,
    [string]$ServiceName = 'prometheus_alert_sms',
    [string]$ServiceDisplayName = 'Prometheus Alert SMS Gateway',
    [string]$ServiceDescription = 'Receives Alertmanager webhooks and sends SMS',
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

function Protect-SmsConfig {
    param([Parameter(Mandatory)][string]$Path)
    $acl = New-Object Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($sid in @('S-1-5-18', 'S-1-5-32-544')) {
        $identity = [Security.Principal.SecurityIdentifier]::new($sid)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'Allow')
        $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $Path -AclObject $acl
}

Assert-Administrator
if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
}
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$ConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
$InstallRoot = Resolve-SafeAbsolutePath -Path $InstallRoot -Name InstallRoot
if (-not $LogRoot) { $LogRoot = Join-Path $InstallRoot 'logs' }
$LogRoot = Resolve-SafeAbsolutePath -Path $LogRoot -Name LogRoot

$scriptSource = Join-Path $PSScriptRoot 'Receive-AlertmanagerSms.ps1'
$nssmSource = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
foreach ($required in @($scriptSource, $nssmSource, $ConfigPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required file was not found: $required" }
}

$config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$prefix = [string]$config.listenPrefix
if ($prefix -notmatch '^http://(127\.0\.0\.1|localhost):(?<port>\d+)/$') {
    throw "listenPrefix must be a loopback HTTP prefix, for example http://127.0.0.1:49177/"
}
$listenPort = [int]$Matches['port']
if ([string]::IsNullOrWhiteSpace([string]$config.authorizationValue) -or [string]$config.authorizationValue -eq 'CHANGE_ME') {
    throw 'authorizationValue in the SMS config is still CHANGE_ME. Fill the local config before installing.'
}
if (-not $config.phones) { throw 'The SMS config must contain a phones map.' }

$existingService = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $ServiceName.Replace("'", "''")) -ErrorAction SilentlyContinue
if ($existingService -and $existingService.PathName -notmatch '(?i)nssm\.exe') {
    throw "Service '$ServiceName' already exists but is not managed by NSSM. Pass the existing NSSM service name with -ServiceName."
}
if (-not $PSCmdlet.ShouldProcess($InstallRoot, "Install SMS gateway and configure service '$ServiceName'")) { return }

if ($existingService) {
    $service = Get-Service -Name $ServiceName
    if ($service.Status -ne 'Stopped') {
        Stop-Service -Name $ServiceName -Force
        $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
    }
}

$binTarget = Join-Path $InstallRoot 'bin'
$configTarget = Join-Path $InstallRoot 'config'
foreach ($directory in @($binTarget, $configTarget, $LogRoot)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

$scriptTarget = Join-Path $InstallRoot 'Receive-AlertmanagerSms.ps1'
$script:NssmTarget = Join-Path $binTarget 'nssm.exe'
$deployedConfig = Join-Path $configTarget 'sms-gateway.json'
Copy-Item -LiteralPath $scriptSource -Destination $scriptTarget -Force
Copy-Item -LiteralPath $nssmSource -Destination $script:NssmTarget -Force
Copy-Item -LiteralPath $ConfigPath -Destination $deployedConfig -Force
Protect-SmsConfig -Path $deployedConfig

$urlAcl = & netsh.exe http show urlacl "url=$prefix" 2>&1 | Out-String
if ($urlAcl -notmatch [regex]::Escape($prefix)) {
    & netsh.exe http add urlacl url=$prefix user='NT AUTHORITY\SYSTEM' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to reserve HTTP prefix $prefix for LocalSystem." }
}

$powershellExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $powershellExe -PathType Leaf)) { throw "powershell.exe was not found: $powershellExe" }
$appParameters = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -ConfigPath "{1}"' -f $scriptTarget, $deployedConfig

if (-not $existingService) { Invoke-Nssm -Arguments @('install', $ServiceName, $powershellExe) }
Invoke-Nssm -Arguments @('set', $ServiceName, 'Application', $powershellExe)
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppDirectory', $InstallRoot)
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppParameters', $appParameters)
Invoke-Nssm -Arguments @('set', $ServiceName, 'DisplayName', $ServiceDisplayName)
Invoke-Nssm -Arguments @('set', $ServiceName, 'Description', $ServiceDescription)
Invoke-Nssm -Arguments @('set', $ServiceName, 'Start', 'SERVICE_DELAYED_AUTO_START')
Invoke-Nssm -Arguments @('set', $ServiceName, 'ObjectName', 'LocalSystem')
Invoke-Nssm -Arguments @('set', $ServiceName, 'DependOnService', 'Tcpip')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppExit', 'Default', 'Restart')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRestartDelay', '5000')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppThrottle', '5000')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppNoConsole', '1')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppStdout', (Join-Path $LogRoot "$ServiceName.out.log"))
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppStderr', (Join-Path $LogRoot "$ServiceName.err.log"))
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateFiles', '1')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateOnline', '1')
Invoke-Nssm -Arguments @('set', $ServiceName, 'AppRotateBytes', '10485760')

& sc.exe failure $ServiceName 'reset=' 86400 'actions=' 'restart/5000/restart/15000/restart/60000' | Out-Null
& sc.exe failureflag $ServiceName 1 | Out-Null

Start-Service -Name $ServiceName
$runningService = Get-Service -Name $ServiceName
$runningService.WaitForStatus('Running', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
Start-Sleep -Seconds 2
$runningService.Refresh()
if ($runningService.Status -ne 'Running') {
    $errorLog = Join-Path $LogRoot "$ServiceName.err.log"
    $tail = if (Test-Path -LiteralPath $errorLog) { Get-Content -LiteralPath $errorLog -Tail 50 | Out-String } else { 'No error log was created.' }
    throw "SMS gateway service stopped after startup.`n$tail"
}

try {
    $health = Invoke-WebRequest -Uri ($prefix + 'metrics') -UseBasicParsing -TimeoutSec 10
    if ($health.StatusCode -ne 200) { throw "Health check returned HTTP $($health.StatusCode)." }
}
catch {
    throw "SMS gateway is running but did not answer on ${prefix}metrics. $($_.Exception.Message)"
}

[pscustomobject]@{
    Service = $ServiceName
    DisplayName = $ServiceDisplayName
    Status = $runningService.Status
    InstallRoot = $InstallRoot
    ListenPrefix = $prefix
    ListenPort = $listenPort
}
