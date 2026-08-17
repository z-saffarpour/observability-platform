#Requires -Version 5.1
<#
.SYNOPSIS
  Installs or refreshes windows_exporter remotely over WinRM.
.DESCRIPTION
  Copies the packaged executable, web config, default YAML, profiles/, and
  scripts/ (powershell + ssas) to each target, creates collector/ and
  textfile_inputs/, creates a
  timestamped backup, and creates or updates the native Windows service. Re-running
  is safe. Run this from a client; do not start windows_exporter.exe locally.
  The prometheus_windows_ssas service is installed separately with
  Install-SsasMetricsTask.ps1 on SSAS hosts.
.EXAMPLE
  .\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 -Computers SERVER01,SERVER02 -WhatIf
.EXAMPLE
  .\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 -Computers SERVER01 -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 -Computers SQL01 -Profile sql-server.yml -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 -Computers SQL01,SQL02 -AutoProfile -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 -Computers SQL01 -ServiceAccountMode NtService -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
    -Computers SERVER01 `
    -ListenAddress ':9182' `
    -BasicAuthUsername 'scrape_user' `
    -BasicAuthHash '$2a$12$...' `
    -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
    -Computers SERVER01 `
    -ListenAddress '0.0.0.0:9182' `
    -WebConfigPath 'C:\Secrets\windows-exporter-web-config.yml' `
    -RemoteCredential (Get-Credential)
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string[]]$Computers,
    [string]$SourceRoot,
    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter',
    [string]$ServiceName = 'prometheus_windows_exporter',
    [string]$ServiceDisplayName = 'Prometheus Windows Exporter',
    [string]$ServiceDescription = 'Prometheus Windows Exporter service',
    [string]$ListenAddress = ':9182',
    [string]$WebConfigPath,
    [string]$BasicAuthUsername,
    [SecureString]$BasicAuthPassword,
    [string]$BasicAuthHash,
    [string]$Profile,
    [switch]$AutoProfile,
    [ValidateSet('LocalSystem','LocalService','NetworkService','Credential','gMSA','NtService')]
    [string]$ServiceAccountMode = 'LocalSystem',
    [string]$ServiceAccount,
    [pscredential]$ServiceCredential,
    [pscredential]$RemoteCredential,
    [ValidateSet('ServiceBase','NSSM')][string]$ServiceMode = 'ServiceBase',
    [ValidateRange(5,600)][int]$ServiceTimeoutSec = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$serviceHelpersPath = Join-Path $PSScriptRoot '..\common\Observability-NssmServiceHelpers.ps1'
$webConfigHelpersPath = Join-Path $PSScriptRoot '..\common\Observability-WebConfigHelpers.ps1'
if (-not (Test-Path -LiteralPath $serviceHelpersPath -PathType Leaf)) {
    throw "Required helper script was not found: $serviceHelpersPath"
}
if (-not (Test-Path -LiteralPath $webConfigHelpersPath -PathType Leaf)) {
    throw "Required helper script was not found: $webConfigHelpersPath"
}
. $webConfigHelpersPath

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
}

function Get-PlainText([Security.SecureString]$Value) {
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

function Resolve-ProfileFile([string]$Name) {
    $leaf = [IO.Path]::GetFileName($Name)
    if ($leaf -notmatch '\.ya?ml$') { $leaf = "$leaf.yml" }
    if ($leaf -eq 'performancecounter.example.yml') {
        throw 'performancecounter.example.yml is a template and cannot be deployed as a service profile.'
    }
    $path = Join-Path $profilesSource $leaf
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Profile was not found: $leaf"
    }
    $leaf
}

$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$exporterSource = Join-Path $SourceRoot 'exporters\windows-exporter'
$package = @('windows_exporter.exe','windows_exporter.yml','web-config.yml','windows_exporter_version.ini','nssm.exe')
$packageSources = @{
    'windows_exporter.exe' = Join-Path $exporterSource 'bin\windows_exporter.exe'
    'windows_exporter.yml' = Join-Path $exporterSource 'config\windows_exporter.yml'
    'web-config.yml'       = Join-Path $exporterSource 'config\web-config.yml'
    'windows_exporter_version.ini' = Join-Path $exporterSource 'version\windows_exporter_version.ini'
    'nssm.exe' = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
}
foreach ($item in $package) {
    if (-not (Test-Path -LiteralPath $packageSources[$item] -PathType Leaf)) {
        throw "Required package file was not found: $($packageSources[$item])"
    }
}
$profilesSource = Join-Path $exporterSource 'profiles'
if (-not (Test-Path -LiteralPath $profilesSource -PathType Container)) {
    throw "Required profiles directory was not found: $profilesSource"
}
$scriptsPowerShellSource = Join-Path $SourceRoot 'scripts\powershell\windows-exporter'
$scriptsSsasSource = Join-Path $SourceRoot 'scripts\ssas\windows-exporter'
if (-not (Test-Path -LiteralPath $scriptsPowerShellSource -PathType Container)) {
    throw "Required scripts directory was not found: $scriptsPowerShellSource"
}
$discoverScript = Join-Path $scriptsPowerShellSource 'Discover-WindowsExporterRole.ps1'
if ($AutoProfile -and -not (Test-Path -LiteralPath $discoverScript -PathType Leaf)) {
    throw "Role discovery script was not found: $discoverScript"
}
if ($Profile -and $AutoProfile) { throw 'Use either -Profile or -AutoProfile, not both.' }
$profileFile = if ($Profile) { Resolve-ProfileFile $Profile } else { $null }
$Computers = @($Computers | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
if ($Computers.Count -eq 0) { throw 'No target servers were resolved.' }

$account = switch ($ServiceAccountMode) {
    'LocalSystem'    { 'LocalSystem' }
    'LocalService'   { 'NT AUTHORITY\LocalService' }
    'NetworkService' { 'NT AUTHORITY\NetworkService' }
    'NtService' {
        # Virtual service account; name must match the Windows service name.
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

Test-ObservabilityListenAddress -Address $ListenAddress
$webConfigToDeploy = Resolve-ObservabilityWebConfigDeployment `
    -TemplatePath $packageSources['web-config.yml'] `
    -WebConfigPath $WebConfigPath `
    -BasicAuthUsername $BasicAuthUsername `
    -BasicAuthPassword $BasicAuthPassword `
    -BasicAuthHash $BasicAuthHash
$tempWebConfigPath = if ($webConfigToDeploy -ne $packageSources['web-config.yml']) { $webConfigToDeploy } else { $null }

Write-Host "Source: $exporterSource`nTargets: $($Computers -join ', ')`nService account: $account`nListen address: $ListenAddress" -ForegroundColor Cyan
if ($WebConfigPath) { Write-Host "Web config: $WebConfigPath" -ForegroundColor Cyan }
elseif ($BasicAuthUsername) { Write-Host "Web config: Basic Auth user=$BasicAuthUsername" -ForegroundColor Cyan }
if ($profileFile) { Write-Host "Profile: $profileFile" -ForegroundColor Cyan }
elseif ($AutoProfile) { Write-Host 'Profile: auto-detect per server' -ForegroundColor Cyan }
$results = @()
foreach ($computer in $Computers) {
    $session = $null
    $stage = $null
    $row = [ordered]@{ Computer=$computer; Profile=$(if ($AutoProfile) { 'Auto' } else { $profileFile }); Deploy='Skipped'; Service='Skipped'; Backup=$null; Error=$null }
    Write-Host "`n===== $computer =====" -ForegroundColor Yellow
    try {
        if (-not $PSCmdlet.ShouldProcess($computer, "Install or refresh $ServiceName")) { $row.Deploy = 'WhatIf'; continue }
        $sessionArgs = @{ ComputerName=$computer; ErrorAction='Stop' }
        if ($RemoteCredential) { $sessionArgs.Credential = $RemoteCredential }
        $session = New-PSSession @sessionArgs
        $chosenProfile = $profileFile
        if ($AutoProfile) {
            $role = Invoke-Command -Session $session -FilePath $discoverScript
            $chosenProfile = Resolve-ProfileFile $role.RecommendedProfile
            $row.Profile = $chosenProfile
            Write-Host "Recommended profile: $chosenProfile" -ForegroundColor Cyan
        }
        $stage = Invoke-Command -Session $session -ScriptBlock {
            $path = Join-Path $env:ProgramData ('Observability\PrometheusExporters\staging\windows_exporter-' + [guid]::NewGuid().ToString('N'))
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            $path
        }
        foreach ($item in $package) {
            if ($item -eq 'web-config.yml') { continue }
            Copy-Item -LiteralPath $packageSources[$item] -Destination (Join-Path $stage $item) -ToSession $session -Force
        }
        Copy-Item -LiteralPath $webConfigToDeploy -Destination (Join-Path $stage 'web-config.yml') -ToSession $session -Force
        Copy-Item -LiteralPath $profilesSource -Destination $stage -ToSession $session -Recurse -Force
        $stageScripts = Join-Path $stage 'scripts'
        Invoke-Command -Session $session -ScriptBlock {
            param($Stage)
            New-Item -Path (Join-Path $Stage 'scripts') -ItemType Directory -Force | Out-Null
        } -ArgumentList $stage
        Copy-Item -LiteralPath $scriptsPowerShellSource -Destination (Join-Path $stageScripts 'powershell') -ToSession $session -Recurse -Force
        if (Test-Path -LiteralPath $scriptsSsasSource -PathType Container) {
            Copy-Item -LiteralPath $scriptsSsasSource -Destination (Join-Path $stageScripts 'ssas') -ToSession $session -Recurse -Force
        }
        Copy-Item -LiteralPath $serviceHelpersPath -Destination (Join-Path $stage 'Observability-NssmServiceHelpers.ps1') -ToSession $session -Force
        Copy-Item -LiteralPath $webConfigHelpersPath -Destination (Join-Path $stage 'Observability-WebConfigHelpers.ps1') -ToSession $session -Force

        $deployed = Invoke-Command -Session $session -ScriptBlock {
            param($Root,$Name,$Display,$Description,$Stage,$Account,$Password,$Timeout,$Items,$ProfileName,$ServiceMode,$Listen)
            Set-StrictMode -Version Latest; $ErrorActionPreference = 'Stop'
            . (Join-Path $Stage 'Observability-NssmServiceHelpers.ps1')
            . (Join-Path $Stage 'Observability-WebConfigHelpers.ps1')
            function Invoke-Nssm([string]$Executable,[string[]]$Arguments) {
                $text = & $Executable @Arguments 2>&1
                if ($LASTEXITCODE -ne 0) { throw "NSSM failed: nssm $($Arguments -join ' ')`n$($text -join [Environment]::NewLine)" }
            }
            function Wait-State([string]$State) {
                $svc = Get-Service -Name $Name -ErrorAction Stop
                $svc.WaitForStatus($State,[TimeSpan]::FromSeconds($Timeout)); $svc.Refresh()
                if ($svc.Status.ToString() -ne $State) { throw "Service did not reach $State." }
            }
            function Sync-Directory([string]$Source,[string]$Destination,[string]$Backup) {
                if (-not (Test-Path -LiteralPath $Source -PathType Container)) { return }
                New-Item -Path $Destination -ItemType Directory -Force | Out-Null
                Get-ChildItem -LiteralPath $Source -File -Recurse | ForEach-Object {
                    $relative = $_.FullName.Substring($Source.Length).TrimStart('\')
                    $old = Join-Path $Destination $relative
                    $oldDir = Split-Path $old -Parent
                    New-Item -Path $oldDir -ItemType Directory -Force | Out-Null
                    if (Test-Path -LiteralPath $old) {
                        $backupFile = Join-Path $Backup $relative
                        New-Item -Path (Split-Path $backupFile -Parent) -ItemType Directory -Force | Out-Null
                        Copy-Item -LiteralPath $old -Destination $backupFile -Force
                    }
                    Copy-Item -LiteralPath $_.FullName -Destination $old -Force
                }
            }
            New-Item -Path $Root -ItemType Directory -Force | Out-Null
            $backup = Join-Path $Root ('_backup\install_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
            New-Item -Path $backup -ItemType Directory -Force | Out-Null
            $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
            $detectedMethod = 'ServiceBase'
            $parameters = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name\Parameters"
            $serviceCim = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $Name.Replace("'", "''")) -ErrorAction SilentlyContinue
            $nssmApplication = if (Test-Path -LiteralPath $parameters) {
                (Get-ItemProperty -LiteralPath $parameters -Name Application -ErrorAction SilentlyContinue).Application
            }
            if ($nssmApplication -or ($serviceCim -and $serviceCim.PathName -match '(?i)nssm\.exe')) { $detectedMethod = 'NSSM' }
            if ($svc -and $svc.Status -ne 'Stopped') { Stop-Service $Name -Force; Wait-State 'Stopped' }
            foreach ($item in @('bin','config','version')) {
                $old = Join-Path $Root $item
                if (Test-Path -LiteralPath $old) { Copy-Item -LiteralPath $old -Destination $backup -Recurse -Force }
            }
            $binDir = Join-Path $Root 'bin'
            $configDir = Join-Path $Root 'config'
            $versionDir = Join-Path $Root 'version'
            foreach ($dir in @($binDir,$configDir,$versionDir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            Copy-Item -LiteralPath (Join-Path $Stage 'windows_exporter.exe') -Destination (Join-Path $binDir 'windows_exporter.exe') -Force
            Copy-Item -LiteralPath (Join-Path $Stage 'windows_exporter.yml') -Destination (Join-Path $configDir 'windows_exporter.yml') -Force
            Copy-Item -LiteralPath (Join-Path $Stage 'web-config.yml') -Destination (Join-Path $configDir 'web-config.yml') -Force
            Copy-Item -LiteralPath (Join-Path $Stage 'windows_exporter_version.ini') -Destination (Join-Path $versionDir 'windows_exporter_version.ini') -Force
            $nssmDir = 'C:\Program Files\Observability\Tools\NSSM'
            New-Item -Path $nssmDir -ItemType Directory -Force | Out-Null
            $nssmTarget = Join-Path $nssmDir 'nssm.exe'
            if (-not (Test-Path -LiteralPath $nssmTarget -PathType Leaf)) {
                Copy-Item -LiteralPath (Join-Path $Stage 'nssm.exe') -Destination $nssmTarget -Force
            }
            $srcProfiles = Join-Path $Stage 'profiles'
            $dstProfiles = Join-Path $Root 'profiles'
            New-Item -Path $dstProfiles -ItemType Directory -Force | Out-Null
            $backupProfiles = Join-Path $backup 'profiles'
            if (Test-Path -LiteralPath $srcProfiles -PathType Container) {
                Get-ChildItem -LiteralPath $srcProfiles -File | ForEach-Object {
                    $old = Join-Path $dstProfiles $_.Name
                    if (Test-Path -LiteralPath $old) {
                        New-Item -Path $backupProfiles -ItemType Directory -Force | Out-Null
                        Copy-Item -LiteralPath $old -Destination (Join-Path $backupProfiles $_.Name) -Force
                    }
                    Copy-Item -LiteralPath $_.FullName -Destination $old -Force
                }
            }
            Sync-Directory (Join-Path $Stage 'scripts\powershell') (Join-Path $Root 'scripts\powershell') (Join-Path $backup 'scripts\powershell')
            Sync-Directory (Join-Path $Stage 'scripts\ssas') (Join-Path $Root 'scripts\ssas') (Join-Path $backup 'scripts\ssas')
            New-Item -Path (Join-Path $Root 'collector') -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $Root 'textfile_inputs') -ItemType Directory -Force | Out-Null
            $exe = Join-Path $binDir 'windows_exporter.exe'
            $cfg = if ($ProfileName) { Join-Path $dstProfiles $ProfileName } else { Join-Path $configDir 'windows_exporter.yml' }
            $web = Join-Path $configDir 'web-config.yml'
            if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { throw "Config file was not found: $cfg" }
            $appParameters = Get-ObservabilityExporterAppParameters `
                -ConfigFile $cfg `
                -WebConfigFile $web `
                -ListenAddress $Listen `
                -LogFormat 'json'
            $imagePath = ('"{0}" {1}' -f $exe, $appParameters)
            if ($svc -and $detectedMethod -ne $ServiceMode) {
                Invoke-ObservabilitySc -Arguments @('delete',$Name)
                $deadline = (Get-Date).AddSeconds($Timeout)
                while ((Get-Service -Name $Name -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 250 }
                if (Get-Service -Name $Name -ErrorAction SilentlyContinue) { throw "Service could not be replaced within $Timeout seconds: $Name" }
                $svc = $null
            }
            if (-not $svc -and $ServiceMode -eq 'NSSM') {
                Invoke-Nssm $nssmTarget @('install',$Name,$exe)
            }
            elseif (-not $svc) { New-Service -Name $Name -DisplayName $Display -BinaryPathName $imagePath -StartupType Automatic | Out-Null }
            if ($ServiceMode -eq 'NSSM') {
                if (-not (Test-Path -LiteralPath $parameters)) { throw "NSSM parameters key was not found: $parameters" }
                $logDir = Join-Path $Root 'log'
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                $appParameters = Get-ObservabilityExporterAppParameters `
                    -ConfigFile $cfg `
                    -WebConfigFile $web `
                    -ListenAddress $Listen `
                    -LogFormat 'json'
                Set-ItemProperty -LiteralPath $parameters -Name Application -Value $exe
                Set-ItemProperty -LiteralPath $parameters -Name AppParameters -Value $appParameters
                Set-ItemProperty -LiteralPath $parameters -Name AppDirectory -Value $Root
                Set-ObservabilityNssmLogging -ParametersKey $parameters -StdoutLog (Join-Path $logDir "$Name.out.log") -StderrLog (Join-Path $logDir "$Name.err.log")
                Invoke-Nssm $nssmTarget @('set',$Name,'AppExit','Default','Restart')
                Invoke-Nssm $nssmTarget @('set',$Name,'DisplayName',$Display)
                Invoke-Nssm $nssmTarget @('set',$Name,'Description',$Description)
                Invoke-Nssm $nssmTarget @('set',$Name,'Start','SERVICE_AUTO_START')
                Invoke-ObservabilitySc -Arguments @('config',$Name,('binPath= ' + ('"{0}"' -f $nssmTarget)))
                Register-ObservabilityNssmEventSource -NssmExe $nssmTarget
                if ($Account) { Grant-ObservabilityServiceLogAccess -Path $logDir -Account $Account }
            }
            else { Invoke-ObservabilitySc -Arguments @('config',$Name,('binPath= ' + $imagePath),'start= auto',('DisplayName= ' + $Display)) }
            $accountArgs = @('config',$Name,('obj= ' + $Account)); if ($Password) { $accountArgs += ('password= ' + $Password) }
            Invoke-ObservabilitySc -Arguments $accountArgs; Invoke-ObservabilitySc -Arguments @('description',$Name,$Description)
            $runningSvc = Start-ObservabilityManagedService -Name $Name -TimeoutSec $Timeout -LogDirectory (Join-Path $Root 'log') -ProcessLabel 'windows_exporter.exe'
            if (-not [Diagnostics.EventLog]::SourceExists($Name)) { New-EventLog -LogName Application -Source $Name }
            Write-EventLog -LogName Application -Source $Name -EntryType Information -EventId 1001 `
                -Message "Windows service installed or refreshed. Mode=$ServiceMode; InstallPath=$Root; Profile=$ProfileName"
            [pscustomobject]@{ Status=$runningSvc.Status.ToString(); Backup=$backup; ImagePath=$imagePath; Profile=$ProfileName; Method=$ServiceMode }
        } -ArgumentList $InstallRoot,$ServiceName,$ServiceDisplayName,$ServiceDescription,$stage,$account,$password,$ServiceTimeoutSec,$package,$chosenProfile,$ServiceMode,$ListenAddress
        $row.Deploy='OK'; $row.Service=$deployed.Status; $row.Backup=$deployed.Backup
        if ($deployed.Profile) { $row.Profile = $deployed.Profile }
        Write-Host "Service: $($deployed.Status)`nProfile: $($row.Profile)`nBackup: $($deployed.Backup)" -ForegroundColor Green
    } catch { $row.Error=$_.Exception.Message; Write-Host "ERROR: $($row.Error)" -ForegroundColor Red }
    finally {
        if ($session) {
            if (-not [string]::IsNullOrWhiteSpace($stage)) {
                try {
                    Invoke-Command -Session $session -ScriptBlock {
                        param($StageDir)
                        if (Test-Path -LiteralPath $StageDir) { Remove-Item -LiteralPath $StageDir -Recurse -Force -ErrorAction Stop }
                        $stagingRoot = Split-Path -Parent $StageDir
                        if ((Test-Path -LiteralPath $stagingRoot -PathType Container) -and @((Get-ChildItem -LiteralPath $stagingRoot -Force -ErrorAction Stop)).Count -eq 0) { Remove-Item -LiteralPath $stagingRoot -Force -ErrorAction Stop }
                    } -ArgumentList $stage -ErrorAction Stop
                    Write-Host 'Staging files removed.' -ForegroundColor DarkGray
                } catch { Write-Host "WARNING: Could not remove staging files: $($_.Exception.Message)" -ForegroundColor DarkYellow }
            }
            Remove-PSSession $session -ErrorAction SilentlyContinue
        }
        $results += [pscustomobject]$row
    }
}
$results | Format-Table -AutoSize
if (@($results | Where-Object Error).Count) { exit 1 }
if ($tempWebConfigPath -and (Test-Path -LiteralPath $tempWebConfigPath)) {
    [IO.File]::Delete($tempWebConfigPath)
}
