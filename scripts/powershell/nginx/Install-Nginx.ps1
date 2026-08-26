#Requires -Version 5.1
<#
.SYNOPSIS
  Installs or upgrades nginx/Windows as an automatic NSSM service.
.EXAMPLE
  .\scripts\powershell\nginx\Install-Nginx.ps1 -OpenFirewall
.EXAMPLE
  .\scripts\powershell\nginx\Install-Nginx.ps1 -DependencyServiceNames prometheus,Grafana -ForceConfig
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SourceRoot,
    [string]$InstallRoot = 'C:\Program Files\Observability\Nginx',
    [string]$LogRoot,
    [string]$ServiceName = 'nginx',
    [string]$ServiceDisplayName = 'Nginx Observability Reverse Proxy',
    [string]$ServiceDescription = 'Reverse proxy for Grafana and Prometheus',
    [string[]]$DependencyServiceNames = @(),
    [ValidateRange(1, 65535)][int]$ListenPort = 80,
    [switch]$ForceConfig,
    [switch]$OpenFirewall,
    [ValidateRange(5, 300)][int]$ServiceTimeoutSec = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Nssm([string[]]$Arguments) {
    $output = & $script:NssmTarget @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "NSSM failed: nssm $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)" }
}
function Resolve-SafePath([string]$Path, [string]$Name) {
    $resolved = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Path.TrimEnd('\')))
    if ($resolved -eq [IO.Path]::GetPathRoot($resolved)) { throw "Unsafe $Name path: $resolved" }
    $resolved
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run from an elevated PowerShell session.' }
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..')) }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$InstallRoot = Resolve-SafePath $InstallRoot 'InstallRoot'
$LogRoot = if ($LogRoot) { Resolve-SafePath $LogRoot 'LogRoot' } else { Join-Path $InstallRoot 'logs' }

$nginxSource = Join-Path $SourceRoot 'nginx\bin\windows-amd64\nginx.exe'
$binarySource = Join-Path $SourceRoot 'nginx\bin\windows-amd64'
$configSource = Join-Path $SourceRoot 'nginx\config'
$nssmSource = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
foreach ($required in @($nginxSource, (Join-Path $configSource 'nginx.conf'), (Join-Path $configSource 'mime.types'), $nssmSource)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required source file not found: $required" }
}

$existing = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $ServiceName.Replace("'", "''")) -ErrorAction SilentlyContinue
if ($existing -and $existing.PathName -notmatch '(?i)nssm\.exe') { throw "Service '$ServiceName' exists but is not managed by NSSM." }
$dependencies = @($DependencyServiceNames | Where-Object { $_ } | ForEach-Object { $_.Trim() })
foreach ($dependency in $dependencies) {
    if (-not (Get-Service -Name $dependency -ErrorAction SilentlyContinue)) { throw "Dependency service not found: $dependency" }
}
if (-not $PSCmdlet.ShouldProcess($InstallRoot, "Install nginx service '$ServiceName'")) { return }

if ($existing) {
    $service = Get-Service $ServiceName
    if ($service.Status -ne 'Stopped') { Stop-Service $ServiceName -Force; $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($ServiceTimeoutSec)) }
}
$binTarget = Join-Path $InstallRoot 'bin'
$configTarget = Join-Path $InstallRoot 'config'
$runtimeDirectories = @(
    $binTarget, $configTarget, (Join-Path $configTarget 'conf.d'), (Join-Path $InstallRoot 'html'), $LogRoot,
    (Join-Path $InstallRoot 'temp\client_body_temp'), (Join-Path $InstallRoot 'temp\proxy_temp'),
    (Join-Path $InstallRoot 'temp\fastcgi_temp'), (Join-Path $InstallRoot 'temp\uwsgi_temp'),
    (Join-Path $InstallRoot 'temp\scgi_temp')
)
foreach ($directory in $runtimeDirectories) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
$nginxTarget = Join-Path $binTarget 'nginx.exe'
$script:NssmTarget = Join-Path $binTarget 'nssm.exe'
Copy-Item $nginxSource $nginxTarget -Force
Copy-Item $nssmSource $script:NssmTarget -Force
Get-ChildItem $binarySource -File | Where-Object Name -ne 'nginx.exe' | Copy-Item -Destination $binTarget -Force
$deployedConfig = Join-Path $configTarget 'nginx.conf'
$deployRepositoryConfig = $ForceConfig -or -not (Test-Path $deployedConfig)
if ($deployRepositoryConfig) {
    Copy-Item (Join-Path $configSource 'nginx.conf') $deployedConfig -Force
    Copy-Item (Join-Path $configSource 'mime.types') (Join-Path $configTarget 'mime.types') -Force
    Copy-Item (Join-Path $configSource 'conf.d\observability.conf') (Join-Path $configTarget 'conf.d\observability.conf') -Force
    $siteConfig = Join-Path $configTarget 'conf.d\observability.conf'
    $text = Get-Content $siteConfig -Raw
    $text = $text -replace '(?m)^\s*listen\s+\d+\s+default_server;', "    listen $ListenPort default_server;"
    Set-Content $siteConfig $text -Encoding UTF8
}
& $nginxTarget -t -p "$InstallRoot\" -c 'config/nginx.conf'
if ($LASTEXITCODE -ne 0) { throw 'nginx configuration validation failed.' }

$parameters = "-p `"$InstallRoot\`" -c config/nginx.conf -g `"daemon off;`""
if (-not $existing) { Invoke-Nssm @('install', $ServiceName, $nginxTarget) }
$settings = @(
    @('Application', $nginxTarget), @('AppDirectory', $InstallRoot), @('AppParameters', $parameters),
    @('DisplayName', $ServiceDisplayName), @('Description', $ServiceDescription), @('Start', 'SERVICE_DELAYED_AUTO_START'),
    @('ObjectName', 'LocalSystem'), @('AppExit', 'Default', 'Restart'),
    @('AppRestartDelay', '5000'), @('AppThrottle', '5000'), @('AppStdout', (Join-Path $LogRoot "$ServiceName.out.log")),
    @('AppStderr', (Join-Path $LogRoot "$ServiceName.err.log")), @('AppRotateFiles', '1'), @('AppRotateOnline', '1'), @('AppRotateBytes', '10485760')
)
foreach ($setting in $settings) { Invoke-Nssm (@('set', $ServiceName) + $setting) }
Invoke-Nssm (@('set', $ServiceName, 'DependOnService') + $dependencies + 'Tcpip')
& sc.exe failure $ServiceName 'reset=' 86400 'actions=' 'restart/5000/restart/15000/restart/60000' | Out-Null
& sc.exe failureflag $ServiceName 1 | Out-Null
if ($OpenFirewall) {
    $rule = "Nginx Observability TCP $ListenPort"
    if (-not (Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue)) { New-NetFirewallRule -DisplayName $rule -Direction Inbound -Action Allow -Protocol TCP -LocalPort $ListenPort -Profile Domain,Private | Out-Null }
}
Start-Service $ServiceName
$service = Get-Service $ServiceName
$service.WaitForStatus('Running', [TimeSpan]::FromSeconds($ServiceTimeoutSec))
Start-Sleep 3
$service.Refresh()
if ($service.Status -ne 'Running') { throw "nginx stopped after startup. Check $LogRoot." }
[pscustomobject]@{ Service=$ServiceName; Status=$service.Status; InstallRoot=$InstallRoot; LogRoot=$LogRoot; ListenPort=$ListenPort; Dependencies=($dependencies -join ', ') }
