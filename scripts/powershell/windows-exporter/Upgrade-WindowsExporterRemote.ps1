#Requires -Version 5.1
<#
.SYNOPSIS
  Safely upgrades an existing native or NSSM windows_exporter service over WinRM.
.DESCRIPTION
  Auto-detects the executable, preserves service metadata, backs up all deployed files,
  copies profiles/ and scripts/ (powershell + ssas), ensures collector/ and
  textfile_inputs/, verifies
  version 0.31.8, and rolls back if validation or service startup fails. Run this from a
  client; do not start windows_exporter.exe locally. Without -Profile/-AutoProfile the
  existing --config.file is left unchanged. The prometheus_windows_ssas service is
  installed separately with Install-SsasMetricsTask.ps1 on SSAS hosts.
.EXAMPLE
  .\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 -Computers SERVER01,SERVER02 -WhatIf
.EXAMPLE
  .\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 -Computers SQL01 -Profile sql-server.yml -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 -Computers SQL01,SQL02 -AutoProfile -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 -Computers SQL01 -ServiceAccountMode NtService -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
    -Computers SERVER01 `
    -ListenAddress ':9182' `
    -PreserveWebConfig `
    -RemoteCredential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
    -Computers SERVER01 `
    -BasicAuthUsername 'scrape_user' `
    -BasicAuthPassword (Read-Host -AsSecureString 'Password') `
    -RemoteCredential (Get-Credential)
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][string[]]$Computers,
    [string]$SourceRoot,
    [string]$ExpectedVersion = '0.31.8',
    [string]$ServiceName = 'prometheus_windows_exporter',
    [string]$InstallRoot,
    [string]$ListenAddress,
    [string]$WebConfigPath,
    [string]$BasicAuthUsername,
    [SecureString]$BasicAuthPassword,
    [string]$BasicAuthHash,
    [switch]$PreserveWebConfig,
    [string]$Profile,
    [switch]$AutoProfile,
    [ValidateSet('LocalSystem','LocalService','NetworkService','Credential','gMSA','NtService')]
    [string]$ServiceAccountMode,
    [string]$ServiceAccount,
    [pscredential]$ServiceCredential,
    [pscredential]$RemoteCredential,
    [ValidateSet('Preserve','ServiceBase','NSSM')][string]$ServiceMode = 'Preserve',
    [ValidateRange(5,600)][int]$ServiceTimeoutSec = 60,
    [ValidateRange(1,100)][int]$KeepBackups = 5
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

function Read-Version([string]$Path) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $text = & $Path --version 2>&1 | Out-String; $exitCode = $LASTEXITCODE }
    finally { $ErrorActionPreference = $previousPreference }
    if ($exitCode -ne 0 -or $text -notmatch '(?im)windows_exporter,\s+version\s+([^\s]+)') { throw "Cannot read version from $Path`: $text" }
    $Matches[1]
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
$items = @('windows_exporter.exe','windows_exporter.yml','web-config.yml','windows_exporter_version.ini','nssm.exe')
$itemSources = @{
    'windows_exporter.exe' = Join-Path $exporterSource 'bin\windows_exporter.exe'
    'windows_exporter.yml' = Join-Path $exporterSource 'config\windows_exporter.yml'
    'web-config.yml'       = Join-Path $exporterSource 'config\web-config.yml'
    'windows_exporter_version.ini' = Join-Path $exporterSource 'version\windows_exporter_version.ini'
    'nssm.exe' = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
}
foreach ($item in $items) { if (-not (Test-Path -LiteralPath $itemSources[$item] -PathType Leaf)) { throw "Missing package file: $($itemSources[$item])" } }
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
$sourceVersion = Read-Version $itemSources['windows_exporter.exe']
if ($sourceVersion -ne $ExpectedVersion) { throw "Source version is $sourceVersion; expected $ExpectedVersion." }
$Computers = @($Computers | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
if (-not $Computers.Count) { throw 'No target servers were resolved.' }

$applyAccount = $PSBoundParameters.ContainsKey('ServiceAccountMode')
$account = $null
$password = ''
if ($applyAccount) {
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
}

if ($PreserveWebConfig -and (
        -not [string]::IsNullOrWhiteSpace($WebConfigPath) -or
        -not [string]::IsNullOrWhiteSpace($BasicAuthUsername) -or
        $null -ne $BasicAuthPassword -or
        -not [string]::IsNullOrWhiteSpace($BasicAuthHash))) {
    throw 'Use either -PreserveWebConfig or web-config/Basic Auth parameters, not both.'
}

if (-not [string]::IsNullOrWhiteSpace($ListenAddress)) {
    Test-ObservabilityListenAddress -Address $ListenAddress
}

$deployWebConfig = $null
$tempWebConfigPath = $null
if (-not $PreserveWebConfig) {
    $deployWebConfig = Resolve-ObservabilityWebConfigDeployment `
        -TemplatePath $itemSources['web-config.yml'] `
        -WebConfigPath $WebConfigPath `
        -BasicAuthUsername $BasicAuthUsername `
        -BasicAuthPassword $BasicAuthPassword `
        -BasicAuthHash $BasicAuthHash
    $tempWebConfigPath = if ($deployWebConfig -ne $itemSources['web-config.yml']) { $deployWebConfig } else { $null }
}

Write-Host "Source: $exporterSource`nTargets: $($Computers -join ', ')`nExpected version: $ExpectedVersion" -ForegroundColor Cyan
Write-Host ("Listen address: {0}" -f $(if ($ListenAddress) { $ListenAddress } else { '<preserve service>' })) -ForegroundColor Cyan
Write-Host ("Web config: {0}" -f $(if ($PreserveWebConfig) { '<preserve remote>' } elseif ($WebConfigPath) { $WebConfigPath } elseif ($BasicAuthUsername) { "Basic Auth user=$BasicAuthUsername" } else { '<package default>' })) -ForegroundColor Cyan
if ($applyAccount) { Write-Host "Service account: $account" -ForegroundColor Cyan }
else { Write-Host 'Service account: preserve existing' -ForegroundColor Cyan }
if ($profileFile) { Write-Host "Profile: $profileFile" -ForegroundColor Cyan }
elseif ($AutoProfile) { Write-Host 'Profile: auto-detect per server' -ForegroundColor Cyan }
else { Write-Host 'Profile: preserve existing --config.file' -ForegroundColor Cyan }

$results = @()
foreach ($computer in $Computers) {
    $session = $null
    $row = [ordered]@{Computer=$computer;Method=$null;Previous=$null;Current=$null;Profile=$(if ($AutoProfile) { 'Auto' } else { $profileFile });Status='Skipped';Backup=$null;Error=$null}
    Write-Host "`n===== $computer =====" -ForegroundColor Yellow
    try {
        if (-not $PSCmdlet.ShouldProcess($computer,"Upgrade $ServiceName to $ExpectedVersion")) { $row.Status='WhatIf'; continue }
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
            $path = Join-Path $env:ProgramData ('Observability\PrometheusExporters\staging\windows-upgrade-' + [guid]::NewGuid().ToString('N'))
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            $path
        }
        foreach ($item in $items) {
            if ($item -eq 'web-config.yml') { continue }
            Copy-Item -LiteralPath $itemSources[$item] -Destination (Join-Path $stage $item) -ToSession $session -Force
        }
        if (-not $PreserveWebConfig) {
            Copy-Item -LiteralPath $deployWebConfig -Destination (Join-Path $stage 'web-config.yml') -ToSession $session -Force
        }
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
        $result = Invoke-Command -Session $session -ScriptBlock {
            param($Name,$Stage,$Version,$RootOverride,$Timeout,$Limit,$Items,$ProfileName,$Account,$Password,$ApplyAccount,$ServiceMode,$ListenOverride,$PreserveWebConfig)
            Set-StrictMode -Version Latest; $ErrorActionPreference = 'Stop'
            . (Join-Path $Stage 'Observability-NssmServiceHelpers.ps1')
            . (Join-Path $Stage 'Observability-WebConfigHelpers.ps1')
            function Wait-State([string]$State) {
                $svc = Get-Service -Name $Name -ErrorAction Stop
                $svc.WaitForStatus($State,[TimeSpan]::FromSeconds($Timeout)); $svc.Refresh()
                if ($svc.Status.ToString() -ne $State) { throw "Service did not reach $State." }
            }
            function Version([string]$Path) {
                $oldPreference = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
                try { $text = & $Path --version 2>&1 | Out-String; $code = $LASTEXITCODE }
                finally { $ErrorActionPreference = $oldPreference }
                if ($code -ne 0 -or $text -notmatch '(?im)windows_exporter,\s+version\s+([^\s]+)') { throw "Cannot verify version: $text" }
                $Matches[1]
            }
            function CommandExe([string]$Line) {
                if ($Line -match '^\s*"([^"]+)"') { return $Matches[1] }
                if ($Line -match '^\s*(.+?\.exe)(?:\s|$)') { return $Matches[1].Trim() }
                $null
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
            function Restore-Directory([string]$Backup,[string]$Destination,[bool]$HadDirectory) {
                if ($HadDirectory -and (Test-Path -LiteralPath $Backup -PathType Container)) {
                    Remove-Item -LiteralPath $Destination -Recurse -Force -ErrorAction SilentlyContinue
                    Copy-Item -LiteralPath $Backup -Destination $Destination -Recurse -Force
                } elseif (-not $HadDirectory -and (Test-Path -LiteralPath $Destination)) {
                    Remove-Item -LiteralPath $Destination -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            $escaped = $Name.Replace("'","''")
            $service = Get-CimInstance Win32_Service -Filter "Name='$escaped'" -ErrorAction Stop
            $serviceExe = CommandExe $service.PathName
            $method = 'ServiceBase'
            $target = $serviceExe
            $parameters = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name\Parameters"
            $application = if (Test-Path $parameters) { (Get-ItemProperty $parameters -Name Application -ErrorAction SilentlyContinue).Application }
            if (($serviceExe -and [IO.Path]::GetFileName($serviceExe) -ieq 'nssm.exe') -or $application) {
                $method = 'NSSM'
                $target = $application
            }
            if ($ServiceMode -ne 'Preserve' -and $ServiceMode -ne $method) {
                throw "Requested ServiceMode '$ServiceMode' does not match installed mode '$method'. Run Install-WindowsExporterRemote.ps1 once to migrate the service mode."
            }
            if ($RootOverride) {
                $structuredTarget = Join-Path $RootOverride 'bin\windows_exporter.exe'
                $legacyTarget = Join-Path $RootOverride 'windows_exporter.exe'
                $target = if (Test-Path -LiteralPath $structuredTarget -PathType Leaf) { $structuredTarget } else { $legacyTarget }
            }
            if (-not $target) { throw 'Executable path cannot be detected; use -InstallRoot.' }
            $target = [Environment]::ExpandEnvironmentVariables($target.Trim('"'))
            if (-not (Test-Path -LiteralPath $target) -or [IO.Path]::GetFileName($target) -ine 'windows_exporter.exe') { throw "Invalid detected executable: $target" }
            $old = Version $target
            $targetParent = Split-Path $target
            $root = if ([IO.Path]::GetFileName($targetParent) -ieq 'bin') { Split-Path $targetParent } else { $targetParent }
            $backup = Join-Path $root ('_backup\upgrade_{0}_{1}' -f $old,(Get-Date -Format yyyyMMdd_HHmmss))
            New-Item -Path $backup -ItemType Directory -Force | Out-Null
            $binDir = Join-Path $root 'bin'
            $configDir = Join-Path $root 'config'
            $versionDir = Join-Path $root 'version'
            $backupBin = Join-Path $backup 'bin'
            $backupConfig = Join-Path $backup 'config'
            $backupVersion = Join-Path $backup 'version'
            $hadBin = Test-Path -LiteralPath $binDir -PathType Container
            $hadConfig = Test-Path -LiteralPath $configDir -PathType Container
            $hadVersion = Test-Path -LiteralPath $versionDir -PathType Container
            if ($hadBin) { Copy-Item -LiteralPath $binDir -Destination $backupBin -Recurse -Force }
            if ($hadConfig) { Copy-Item -LiteralPath $configDir -Destination $backupConfig -Recurse -Force }
            if ($hadVersion) { Copy-Item -LiteralPath $versionDir -Destination $backupVersion -Recurse -Force }
            foreach ($item in @('windows_exporter.exe','windows_exporter.yml','web-config.yml')) {
                $path = Join-Path $root $item
                if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination $backup -Force }
            }
            $dstProfiles = Join-Path $root 'profiles'
            $backupProfiles = Join-Path $backup 'profiles'
            $hadProfiles = Test-Path -LiteralPath $dstProfiles -PathType Container
            if ($hadProfiles) { Copy-Item -LiteralPath $dstProfiles -Destination $backupProfiles -Recurse -Force }
            $dstScriptsPs = Join-Path $root 'scripts\powershell'
            $dstScriptsSsas = Join-Path $root 'scripts\ssas'
            $backupScriptsPs = Join-Path $backup 'scripts\powershell'
            $backupScriptsSsas = Join-Path $backup 'scripts\ssas'
            $hadScriptsPs = Test-Path -LiteralPath $dstScriptsPs -PathType Container
            $hadScriptsSsas = Test-Path -LiteralPath $dstScriptsSsas -PathType Container
            if ($hadScriptsPs) { Copy-Item -LiteralPath $dstScriptsPs -Destination $backupScriptsPs -Recurse -Force }
            if ($hadScriptsSsas) { Copy-Item -LiteralPath $dstScriptsSsas -Destination $backupScriptsSsas -Recurse -Force }
            $originalPathName = $service.PathName
            $originalStartName = $service.StartName
            $originalApplication = $application
            $originalAppParameters = $null
            if (($method -eq 'NSSM') -and (Test-Path $parameters)) {
                $appParametersProperty = Get-ItemProperty -LiteralPath $parameters -Name AppParameters -ErrorAction SilentlyContinue
                if ($appParametersProperty) { $originalAppParameters = $appParametersProperty.AppParameters }
            }
            $wasRunning = $service.State -eq 'Running'
            $accountApplied = $false
            try {
                if ($service.State -ne 'Stopped') { Stop-Service $Name -Force; Wait-State 'Stopped' }
                foreach ($dir in @($binDir,$configDir,$versionDir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
                $target = Join-Path $binDir 'windows_exporter.exe'
                Copy-Item -LiteralPath (Join-Path $Stage 'windows_exporter.exe') -Destination $target -Force
                Copy-Item -LiteralPath (Join-Path $Stage 'windows_exporter.yml') -Destination (Join-Path $configDir 'windows_exporter.yml') -Force
                $web = Join-Path $configDir 'web-config.yml'
                if (-not $PreserveWebConfig) {
                    Copy-Item -LiteralPath (Join-Path $Stage 'web-config.yml') -Destination $web -Force
                }
                elseif (-not (Test-Path -LiteralPath $web -PathType Leaf)) {
                    throw "Remote web-config.yml was not found at $web and -PreserveWebConfig was set."
                }
                Copy-Item -LiteralPath (Join-Path $Stage 'windows_exporter_version.ini') -Destination (Join-Path $versionDir 'windows_exporter_version.ini') -Force
                $nssmDir = 'C:\Program Files\Observability\Tools\NSSM'
                New-Item -Path $nssmDir -ItemType Directory -Force | Out-Null
                $nssmTarget = Join-Path $nssmDir 'nssm.exe'
                if (-not (Test-Path -LiteralPath $nssmTarget -PathType Leaf)) {
                    Copy-Item -LiteralPath (Join-Path $Stage 'nssm.exe') -Destination $nssmTarget -Force
                }
                $srcProfiles = Join-Path $Stage 'profiles'
                New-Item -Path $dstProfiles -ItemType Directory -Force | Out-Null
                if (Test-Path -LiteralPath $srcProfiles -PathType Container) {
                    Get-ChildItem -LiteralPath $srcProfiles -File | ForEach-Object {
                        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dstProfiles $_.Name) -Force
                    }
                }
                Sync-Directory (Join-Path $Stage 'scripts\powershell') $dstScriptsPs $backupScriptsPs
                Sync-Directory (Join-Path $Stage 'scripts\ssas') $dstScriptsSsas $backupScriptsSsas
                New-Item -Path (Join-Path $root 'collector') -ItemType Directory -Force | Out-Null
                New-Item -Path (Join-Path $root 'textfile_inputs') -ItemType Directory -Force | Out-Null
                $cfg = if ($ProfileName) { Join-Path $dstProfiles $ProfileName } else { Join-Path $configDir 'windows_exporter.yml' }
                if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { throw "Config file was not found: $cfg" }
                $listenSource = if ($originalAppParameters) { $originalAppParameters } else { $originalPathName }
                $listenAddress = Resolve-ObservabilityListenAddressForUpgrade `
                    -RequestedAddress $ListenOverride `
                    -CurrentAppParameters $listenSource `
                    -CurrentServicePath $originalPathName `
                    -DefaultAddress ':9182'
                $appParameters = Get-ObservabilityExporterAppParameters -ConfigFile $cfg -WebConfigFile $web -ListenAddress $listenAddress
                if ($method -eq 'NSSM') {
                    if (-not (Test-Path $parameters)) { throw "NSSM parameters key was not found: $parameters" }
                    $logDir = Join-Path $root 'log'
                    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                    Set-ItemProperty -LiteralPath $parameters -Name Application -Value $target
                    Set-ItemProperty -LiteralPath $parameters -Name AppParameters -Value $appParameters
                    Set-ItemProperty -LiteralPath $parameters -Name AppDirectory -Value $root
                    Set-ObservabilityNssmLogging -ParametersKey $parameters -StdoutLog (Join-Path $logDir "$Name.out.log") -StderrLog (Join-Path $logDir "$Name.err.log")
                    $nssmExe = Join-Path $nssmDir 'nssm.exe'
                    & $nssmExe set $Name AppExit Default Restart | Out-Null
                    Register-ObservabilityNssmEventSource -NssmExe $nssmExe
                    $logAccount = if ($ApplyAccount -and $Account) { $Account } else { $originalStartName }
                    if ($logAccount) { Grant-ObservabilityServiceLogAccess -Path $logDir -Account $logAccount }
                    Invoke-ObservabilitySc -Arguments @('config',$Name,('binPath= ' + ('"{0}"' -f $nssmTarget)))
                } else {
                    Invoke-ObservabilitySc -Arguments @('config',$Name,('binPath= ' + ('"{0}" {1}' -f $target, $appParameters)))
                }
                if ($ApplyAccount -and $Account) {
                    $accountArgs = @('config',$Name,('obj= ' + $Account))
                    if ($Password) { $accountArgs += ('password= ' + $Password) }
                    Invoke-ObservabilitySc -Arguments $accountArgs
                    $accountApplied = $true
                }
                $new = Version $target
                if ($new -ne $Version) { throw "Installed version is $new; expected $Version." }
                Start-ObservabilityManagedService -Name $Name -TimeoutSec $Timeout -LogDirectory (Join-Path $root 'log') -ProcessLabel 'windows_exporter.exe' | Out-Null
                if (-not [Diagnostics.EventLog]::SourceExists($Name)) { New-EventLog -LogName Application -Source $Name }
                Write-EventLog -LogName Application -Source $Name -EntryType Information -EventId 1002 `
                    -Message "Windows service upgraded. Mode=$method; Version=$new; InstallPath=$root; Profile=$ProfileName"
                foreach ($legacyItem in @('windows_exporter.exe','windows_exporter.yml','web-config.yml')) {
                    $legacyPath = Join-Path $root $legacyItem
                    if (Test-Path -LiteralPath $legacyPath) { Remove-Item -LiteralPath $legacyPath -Force }
                }
            } catch {
                $cause = $_.Exception.Message
                Stop-Service $Name -Force -ErrorAction SilentlyContinue
                Restore-Directory $backupBin $binDir $hadBin
                Restore-Directory $backupConfig $configDir $hadConfig
                Restore-Directory $backupVersion $versionDir $hadVersion
                foreach ($item in @('windows_exporter.exe','windows_exporter.yml','web-config.yml')) {
                    $saved = Join-Path $backup $item
                    if (Test-Path -LiteralPath $saved) { Copy-Item -LiteralPath $saved -Destination (Join-Path $root $item) -Force }
                }
                Restore-Directory $backupProfiles $dstProfiles $hadProfiles
                Restore-Directory $backupScriptsPs $dstScriptsPs $hadScriptsPs
                Restore-Directory $backupScriptsSsas $dstScriptsSsas $hadScriptsSsas
                if ($method -eq 'NSSM' -and (Test-Path $parameters)) {
                    if ($originalApplication) { Set-ItemProperty -LiteralPath $parameters -Name Application -Value $originalApplication }
                    if ($null -ne $originalAppParameters) {
                        Set-ItemProperty -LiteralPath $parameters -Name AppParameters -Value $originalAppParameters
                    }
                } elseif ($method -eq 'ServiceBase' -and $originalPathName) {
                    Invoke-ObservabilitySc -Arguments @('config',$Name,('binPath= ' + $originalPathName))
                }
                if ($accountApplied -and $originalStartName) {
                    try { Invoke-ObservabilitySc -Arguments @('config',$Name,('obj= ' + $originalStartName)) } catch { }
                }
                if ($wasRunning) { Start-Service $Name -ErrorAction SilentlyContinue }
                throw "Upgrade failed and rollback to $old completed. Cause: $cause"
            } finally {
                Remove-Item -LiteralPath $Stage -Recurse -Force -ErrorAction SilentlyContinue
            }
            Get-ChildItem (Join-Path $root '_backup') -Directory -Filter 'upgrade_*' | Sort-Object LastWriteTime -Descending | Select-Object -Skip $Limit | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            [pscustomobject]@{
                Method     = $method
                Previous   = $old
                Current    = $new
                Status     = $(if ($old -eq $new) { 'Refreshed' } else { 'Upgraded' })
                Backup     = $backup
                Executable = $target
                Profile    = $ProfileName
                Account    = $(if ($ApplyAccount) { $Account } else { $originalStartName })
            }
        } -ArgumentList $ServiceName,$stage,$ExpectedVersion,$InstallRoot,$ServiceTimeoutSec,$KeepBackups,$items,$chosenProfile,$account,$password,$applyAccount,$ServiceMode,$ListenAddress,([bool]$PreserveWebConfig)
        foreach ($name in @('Method','Previous','Current','Status','Backup')) { $row[$name] = $result.$name }
        if ($result.Profile) { $row.Profile = $result.Profile }
        Write-Host "$($result.Previous) -> $($result.Current) [$($result.Method)] Profile=$($row.Profile)" -ForegroundColor Green
    } catch {
        $row.Status = 'Failed'
        $row.Error = $_.Exception.Message
        Write-Host "ERROR: $($row.Error)" -ForegroundColor Red
    } finally {
        if ($session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        $results += [pscustomobject]$row
    }
}
if ($tempWebConfigPath -and (Test-Path -LiteralPath $tempWebConfigPath)) {
    [IO.File]::Delete($tempWebConfigPath)
}
$results | Format-Table Computer,Method,Previous,Current,Profile,Status,Error -AutoSize
if (@($results | Where-Object Status -eq 'Failed').Count) { exit 1 }
