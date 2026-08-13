#Requires -Version 5.1
<#
.SYNOPSIS
  Upgrades an existing sql_exporter Windows service to version 0.24.4.

.DESCRIPTION
  Supports both installation methods used by this project:
    - Native Windows service (the service ImagePath points to sql_exporter.exe)
    - NSSM (the service ImagePath points to nssm.exe and Application points to sql_exporter.exe)

  The script detects the installation method and executable path automatically. It deploys
  sql_exporter.exe, web-config.yml, version metadata, profiles\, and the complete
  collectors directory using bin\, config\, version\, and collectors\ on the server
  from the project source directory. The service account and service arguments are preserved.
  Before replacement, it creates a backup. If the new service does not start or its version
  cannot be verified, all deployed files are restored and the service is started again.

  Without -Profile the existing sql_exporter.yml collectors list is left unchanged
  (config file is not overwritten). With -Profile <name>.yml the collectors list from
  profiles/<name>.yml is applied into the remote sql_exporter.yml (DSN and other
  settings are preserved), matching windows_exporter -Profile sql-server.yml UX.

.EXAMPLE
  .\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf

.EXAMPLE
  .\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
    -Computers (Get-Content .\scripts\powershell\sql-exporter\servers.txt) `
    -RemoteCredential (Get-Credential)

.EXAMPLE
  .\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -Profile oltp.yml `
    -RemoteCredential (Get-Credential)

.EXAMPLE
  # Use this when the service metadata does not contain a resolvable executable path.
  .\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
    -Computers sql-host-01 `
    -InstallRoot 'D:\Monitoring\sql_exporter'
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Computers = @(
        'sql-host-01'
        'sql-host-02'
        'sql-host-03'
        'sql-host-04'
    ),

    [Parameter(Mandatory = $false)]
    [string]$SourceRoot,

    [Parameter(Mandatory = $false)]
    [string]$ExpectedVersion = '0.24.4',

    [Parameter(Mandatory = $false)]
    [string]$ServiceName = 'prometheus_sql_exporter',

    [Parameter(Mandatory = $false)]
    [string]$InstallRoot,

    [Parameter(Mandatory = $false)]
    [string]$Profile,

    [Parameter(Mandatory = $false)]
    [pscredential]$RemoteCredential,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Preserve', 'ServiceBase', 'NSSM')]
    [string]$ServiceMode = 'Preserve',

    [Parameter(Mandatory = $false)]
    [ValidateRange(5, 600)]
    [int]$ServiceTimeoutSec = 60,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$KeepBackups = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
}

function Write-Step {
    param([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::Cyan)
    Write-Host $Message -ForegroundColor $Color
}

function Get-ExporterVersion {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "sql_exporter executable not found: $Path"
    }

    $output = & $Path --version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to read sql_exporter version from '$Path': $output"
    }
    if ($output -notmatch '(?im)^sql_exporter,\s+version\s+([^\s]+)') {
        throw "Unexpected sql_exporter --version output from '$Path': $output"
    }
    $Matches[1]
}

function New-RemoteSession {
    param([string]$ComputerName, [pscredential]$Credential)
    if ($null -ne $Credential) {
        return New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
    }
    New-PSSession -ComputerName $ComputerName -ErrorAction Stop
}

function Resolve-ProfileLeaf {
    param(
        [string]$Name,
        [string]$ProfilesRoot
    )

    $leaf = [IO.Path]::GetFileName($Name)
    if ($leaf -notmatch '\.ya?ml$') { $leaf = "$leaf.yml" }
    $path = Join-Path $ProfilesRoot $leaf
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $available = (
            Get-ChildItem -LiteralPath $ProfilesRoot -File -Filter '*.yml' |
                ForEach-Object { [IO.Path]::GetFileName($_.FullName) }
        ) -join ', '
        throw "Profile was not found: $leaf. Available: $available"
    }
    $leaf
}

$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$exporterSource = Join-Path $SourceRoot 'exporters\sql-exporter'
$SourceExe = Join-Path $exporterSource 'bin\sql_exporter.exe'
$sourceWebConfig = Join-Path $exporterSource 'config\web-config.yml'
$sourceVersionFile = Join-Path $exporterSource 'version\sql_exporter_version.ini'
$sourceCollectors = Join-Path $exporterSource 'collector'
$sourceProfiles = Join-Path $exporterSource 'profiles'
$sourceNssm = Join-Path $SourceRoot 'deployment\windows\tools\nssm\nssm.exe'
foreach ($requiredPath in @($SourceExe, $sourceWebConfig, $sourceVersionFile, $sourceCollectors, $sourceProfiles, $sourceNssm)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required package item was not found: $requiredPath"
    }
}
if (@(Get-ChildItem -LiteralPath $sourceCollectors -File -Filter '*.collector.yml').Count -eq 0) {
    throw "No *.collector.yml files were found in: $sourceCollectors"
}
$sourceVersion = Get-ExporterVersion -Path $SourceExe
if ($sourceVersion -ne $ExpectedVersion) {
    throw "Source binary version is '$sourceVersion'; expected '$ExpectedVersion'."
}

$profileLeaf = $null
if (-not [string]::IsNullOrWhiteSpace($Profile)) {
    $profileLeaf = Resolve-ProfileLeaf -Name $Profile -ProfilesRoot $sourceProfiles
}

$Computers = @(
    $Computers |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique
)
if ($Computers.Count -eq 0) {
    throw 'No target servers were resolved.'
}

Write-Step "Source root      : $exporterSource"
Write-Step "Target version   : $ExpectedVersion"
Write-Step "Service          : $ServiceName"
Write-Step ("Install override : {0}" -f $(if ($InstallRoot) { $InstallRoot } else { '<auto-detect>' }))
Write-Step ("Profile          : {0}" -f $(if ($profileLeaf) { $profileLeaf } else { '<preserve remote sql_exporter.yml>' }))
Write-Step "Hosts            : $($Computers -join ', ')"
Write-Host ''

$results = @()
foreach ($computer in $Computers) {
    $row = [ordered]@{
        Computer     = $computer
        Method       = $null
        Previous     = $null
        Current      = $null
        Profile      = $profileLeaf
        Status       = 'Skipped'
        Backup       = $null
        Error        = $null
    }
    $session = $null
    Write-Step "===== $computer =====" Yellow

    try {
        if (-not $PSCmdlet.ShouldProcess($computer, "Upgrade $ServiceName to $ExpectedVersion")) {
            $row.Status = 'WhatIf'
            continue
        }

        $session = New-RemoteSession -ComputerName $computer -Credential $RemoteCredential
        $stageDir = Invoke-Command -Session $session -ScriptBlock {
            $path = Join-Path $env:ProgramData ('Observability\PrometheusExporters\staging\upgrade-' + [guid]::NewGuid().ToString('N'))
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $path 'collector') -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $path 'profiles') -ItemType Directory -Force | Out-Null
            $path
        }
        Copy-Item -LiteralPath $SourceExe -Destination (Join-Path $stageDir 'sql_exporter.exe') -ToSession $session -Force
        Copy-Item -LiteralPath $sourceWebConfig -Destination (Join-Path $stageDir 'web-config.yml') -ToSession $session -Force
        Copy-Item -LiteralPath $sourceVersionFile -Destination (Join-Path $stageDir 'sql_exporter_version.ini') -ToSession $session -Force
        Copy-Item -LiteralPath $sourceNssm -Destination (Join-Path $stageDir 'nssm.exe') -ToSession $session -Force
        Copy-Item -Path (Join-Path $sourceCollectors '*') -Destination (Join-Path $stageDir 'collector') -ToSession $session -Recurse -Force
        Copy-Item -Path (Join-Path $sourceProfiles '*') -Destination (Join-Path $stageDir 'profiles') -ToSession $session -Force

        $upgrade = Invoke-Command -Session $session -ScriptBlock {
            param($SvcName, $StageDir, $Version, $RootOverride, $TimeoutSec, $BackupLimit, $ProfileName, $ServiceMode)

            Set-StrictMode -Version Latest
            $ErrorActionPreference = 'Stop'

            function Wait-ServiceState {
                param([string]$Name, [string]$State, [int]$Timeout)
                $item = Get-Service -Name $Name -ErrorAction Stop
                $item.WaitForStatus($State, [TimeSpan]::FromSeconds($Timeout))
                $item.Refresh()
                if ($item.Status.ToString() -ne $State) {
                    throw "Service '$Name' did not reach state '$State'."
                }
            }

            function Read-Version {
                param([string]$Path)
                $text = & $Path --version 2>&1 | Out-String
                if ($LASTEXITCODE -ne 0 -or $text -notmatch '(?im)^sql_exporter,\s+version\s+([^\s]+)') {
                    throw "Cannot verify sql_exporter version at '$Path': $text"
                }
                $Matches[1]
            }

            function Get-CommandExecutable {
                param([string]$CommandLine)
                if ($CommandLine -match '^\s*"([^"]+)"') { return $Matches[1] }
                if ($CommandLine -match '^\s*(.+?\.exe)(?:\s|$)') { return $Matches[1].Trim() }
                $null
            }

            function Set-RemoteConfigProfile {
                param(
                    [string]$ConfigPath,
                    [string]$ProfilePath,
                    [string]$ProfileLeaf
                )

                $config = Get-Content -LiteralPath $ConfigPath -Raw
                if ([string]::IsNullOrWhiteSpace($config)) {
                    throw "Remote config is empty: $ConfigPath"
                }

                $profileRaw = Get-Content -LiteralPath $ProfilePath -Raw
                if ($profileRaw -notmatch '(?ms)^collectors:\s*\r?\n(?:[ \t]+-[ \t]+\S[^\r\n]*\r?\n?)+') {
                    throw "Profile does not contain a collectors list: $ProfilePath"
                }

                $rootBlock = $Matches[0].TrimEnd("`r", "`n")
                $indented = (($rootBlock -split '\r?\n') | ForEach-Object { '  ' + $_ }) -join [Environment]::NewLine
                $replacement = ('  # Applied by deploy script from profiles/{0}' -f $ProfileLeaf) +
                    [Environment]::NewLine + $indented

                $pattern = '(?m)^  collectors:\s*(?:\[[^\]]*\]|(?:\r?\n(?:[ \t]+-[ \t]+[^\r\n]+)+))'
                $found = [regex]::Matches($config, $pattern)
                if ($found.Count -eq 0) {
                    throw "Could not find an active target.collectors entry in: $ConfigPath"
                }

                $last = $found[$found.Count - 1]
                $newConfig = $config.Substring(0, $last.Index) + $replacement + $config.Substring($last.Index + $last.Length)
                $utf8 = New-Object System.Text.UTF8Encoding $false
                [IO.File]::WriteAllText($ConfigPath, $newConfig, $utf8)
            }

            $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($SvcName.Replace("'", "''"))'" -ErrorAction Stop
            if ($null -eq $service) { throw "Service '$SvcName' was not found." }

            $serviceExe = Get-CommandExecutable -CommandLine $service.PathName
            $method = 'ServiceBase'
            $targetExe = $serviceExe

            $serviceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$SvcName"
            $nssmParameters = Join-Path $serviceKey 'Parameters'
            $nssmApplication = $null
            if (Test-Path -LiteralPath $nssmParameters) {
                $nssmApplication = (Get-ItemProperty -LiteralPath $nssmParameters -Name Application -ErrorAction SilentlyContinue).Application
            }
            if (($serviceExe -and [IO.Path]::GetFileName($serviceExe) -ieq 'nssm.exe') -or $nssmApplication) {
                $method = 'NSSM'
                $targetExe = $nssmApplication
            }
            if ($ServiceMode -ne 'Preserve' -and $ServiceMode -ne $method) {
                throw "Requested ServiceMode '$ServiceMode' does not match installed mode '$method'. Run Install-SqlExporterRemote.ps1 once to migrate the service mode."
            }

            if ($RootOverride) {
                $structuredExe = Join-Path $RootOverride 'bin\sql_exporter.exe'
                $legacyExe = Join-Path $RootOverride 'sql_exporter.exe'
                $targetExe = if (Test-Path -LiteralPath $structuredExe -PathType Leaf) { $structuredExe } else { $legacyExe }
            }
            if ([string]::IsNullOrWhiteSpace($targetExe)) {
                throw "Could not resolve sql_exporter.exe from the $method service configuration. Use -InstallRoot."
            }
            $targetExe = [Environment]::ExpandEnvironmentVariables($targetExe.Trim('"'))
            if (-not (Test-Path -LiteralPath $targetExe -PathType Leaf)) {
                throw "Detected $method executable does not exist: $targetExe"
            }
            if ([IO.Path]::GetFileName($targetExe) -ine 'sql_exporter.exe') {
                throw "Detected executable is not sql_exporter.exe: $targetExe"
            }

            $oldVersion = Read-Version -Path $targetExe
            $exeParent = Split-Path -Parent $targetExe
            $installPath = if ([IO.Path]::GetFileName($exeParent) -ieq 'bin') { Split-Path -Parent $exeParent } else { $exeParent }
            $backupDir = Join-Path $installPath ("_backup\upgrade_{0}_{1}" -f $oldVersion, (Get-Date -Format 'yyyyMMdd_HHmmss'))
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

            $packageItems = @('bin', 'config', 'version', 'collectors', 'profiles', 'sql_exporter.exe', 'sql_exporter.yml', 'web-config.yml', 'collector')
            foreach ($item in $packageItems) {
                $currentItem = Join-Path $installPath $item
                if (Test-Path -LiteralPath $currentItem) {
                    Copy-Item -LiteralPath $currentItem -Destination $backupDir -Recurse -Force
                }
            }

            $wasRunning = $service.State -eq 'Running'
            $originalServicePath = $service.PathName
            $originalNssmApplication = $nssmApplication
            $originalNssmParameters = if (Test-Path -LiteralPath $nssmParameters) {
                (Get-ItemProperty -LiteralPath $nssmParameters -Name AppParameters -ErrorAction SilentlyContinue).AppParameters
            } else { $null }
            try {
                if ($service.State -ne 'Stopped') {
                    Stop-Service -Name $SvcName -Force -ErrorAction Stop
                    Wait-ServiceState -Name $SvcName -State 'Stopped' -Timeout $TimeoutSec
                }

                $binDir = Join-Path $installPath 'bin'
                $configDir = Join-Path $installPath 'config'
                $versionDir = Join-Path $installPath 'version'
                foreach ($dir in @($binDir, $configDir, $versionDir)) {
                    New-Item -Path $dir -ItemType Directory -Force | Out-Null
                }
                $targetExe = Join-Path $binDir 'sql_exporter.exe'
                $cfgPath = Join-Path $configDir 'sql_exporter.yml'
                $webPath = Join-Path $configDir 'web-config.yml'
                Copy-Item -LiteralPath (Join-Path $StageDir 'sql_exporter.exe') -Destination $targetExe -Force
                Copy-Item -LiteralPath (Join-Path $StageDir 'web-config.yml') -Destination $webPath -Force
                Copy-Item -LiteralPath (Join-Path $StageDir 'sql_exporter_version.ini') -Destination (Join-Path $versionDir 'sql_exporter_version.ini') -Force
                if (-not (Test-Path -LiteralPath $cfgPath -PathType Leaf)) {
                    $legacyConfig = Join-Path $installPath 'sql_exporter.yml'
                    if (-not (Test-Path -LiteralPath $legacyConfig -PathType Leaf)) {
                        throw "Remote sql_exporter.yml was not found at $cfgPath or $legacyConfig."
                    }
                    Copy-Item -LiteralPath $legacyConfig -Destination $cfgPath -Force
                }
                $configText = Get-Content -LiteralPath $cfgPath -Raw
                $configText = $configText.Replace('"collector/*.collector.yml"', '"../collectors/*.collector.yml"')
                [IO.File]::WriteAllText($cfgPath, $configText, (New-Object Text.UTF8Encoding $false))

                $targetCollectors = Join-Path $installPath 'collectors'
                if (Test-Path -LiteralPath $targetCollectors) {
                    Remove-Item -LiteralPath $targetCollectors -Recurse -Force
                }
                New-Item -Path $targetCollectors -ItemType Directory -Force | Out-Null
                Copy-Item -Path (Join-Path $StageDir 'collector\*') -Destination $targetCollectors -Recurse -Force

                $targetProfiles = Join-Path $installPath 'profiles'
                if (Test-Path -LiteralPath $targetProfiles) {
                    Remove-Item -LiteralPath $targetProfiles -Recurse -Force
                }
                New-Item -Path $targetProfiles -ItemType Directory -Force | Out-Null
                Copy-Item -Path (Join-Path $StageDir 'profiles\*') -Destination $targetProfiles -Force

                if ($ProfileName) {
                    Set-RemoteConfigProfile `
                        -ConfigPath $cfgPath `
                        -ProfilePath (Join-Path $targetProfiles $ProfileName) `
                        -ProfileLeaf $ProfileName
                }

                $serviceCommand = ('"{0}" --config.file "{1}" --web.config.file "{2}"' -f $targetExe, $cfgPath, $webPath)
                if ($method -eq 'NSSM') {
                    $nssmDir = 'C:\Program Files\Observability\Tools\NSSM'
                    New-Item -Path $nssmDir -ItemType Directory -Force | Out-Null
                    $centralNssm = Join-Path $nssmDir 'nssm.exe'
                    if (-not (Test-Path -LiteralPath $centralNssm -PathType Leaf)) {
                        Copy-Item -LiteralPath (Join-Path $StageDir 'nssm.exe') -Destination $centralNssm -Force
                    }
                    $logDir = Join-Path $installPath 'log'
                    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                    Set-ItemProperty -LiteralPath $nssmParameters -Name Application -Value $targetExe
                    Set-ItemProperty -LiteralPath $nssmParameters -Name AppParameters -Value ('--config.file "{0}" --web.config.file "{1}"' -f $cfgPath, $webPath)
                    Set-ItemProperty -LiteralPath $nssmParameters -Name AppDirectory -Value $installPath
                    Set-ItemProperty -LiteralPath $nssmParameters -Name AppStdout -Value (Join-Path $logDir "$SvcName.out.log")
                    Set-ItemProperty -LiteralPath $nssmParameters -Name AppStderr -Value (Join-Path $logDir "$SvcName.err.log")
                    Set-ItemProperty -LiteralPath $nssmParameters -Name AppRotateFiles -Value 1 -Type DWord
                    Set-ItemProperty -LiteralPath $nssmParameters -Name AppRotateBytes -Value 10485760 -Type DWord
                    $scNssm = & sc.exe config $SvcName ('binPath= ' + ('"{0}"' -f $centralNssm)) 2>&1
                    if ($LASTEXITCODE -ne 0) { throw "sc.exe config NSSM path failed: $($scNssm -join [Environment]::NewLine)" }
                }
                else {
                    $scOutput = & sc.exe config $SvcName ('binPath= ' + $serviceCommand) 2>&1
                    if ($LASTEXITCODE -ne 0) { throw "sc.exe config failed: $($scOutput -join [Environment]::NewLine)" }
                }

                $installedVersion = Read-Version -Path $targetExe
                if ($installedVersion -ne $Version) {
                    throw "Installed version is '$installedVersion'; expected '$Version'."
                }

                Start-Service -Name $SvcName -ErrorAction Stop
                Wait-ServiceState -Name $SvcName -State 'Running' -Timeout $TimeoutSec
                if (-not [Diagnostics.EventLog]::SourceExists($SvcName)) { New-EventLog -LogName Application -Source $SvcName }
                Write-EventLog -LogName Application -Source $SvcName -EntryType Information -EventId 1002 `
                    -Message "Windows service upgraded. Mode=$method; Version=$installedVersion; InstallPath=$installPath; Profile=$ProfileName"
                foreach ($legacyItem in @('sql_exporter.exe', 'sql_exporter.yml', 'web-config.yml', 'collector')) {
                    $legacyPath = Join-Path $installPath $legacyItem
                    if (Test-Path -LiteralPath $legacyPath) {
                        Remove-Item -LiteralPath $legacyPath -Recurse -Force
                    }
                }
            }
            catch {
                $upgradeError = $_.Exception.Message
                Stop-Service -Name $SvcName -Force -ErrorAction SilentlyContinue
                foreach ($item in $packageItems) {
                    $deployedItem = Join-Path $installPath $item
                    $savedItem = Join-Path $backupDir $item
                    if (Test-Path -LiteralPath $deployedItem) {
                        Remove-Item -LiteralPath $deployedItem -Recurse -Force
                    }
                    if (Test-Path -LiteralPath $savedItem) {
                        Copy-Item -LiteralPath $savedItem -Destination $installPath -Recurse -Force
                    }
                }
                if ($method -eq 'NSSM') {
                    if ($originalNssmApplication) {
                        Set-ItemProperty -LiteralPath $nssmParameters -Name Application -Value $originalNssmApplication
                    }
                    if ($null -ne $originalNssmParameters) {
                        Set-ItemProperty -LiteralPath $nssmParameters -Name AppParameters -Value $originalNssmParameters
                    }
                }
                elseif ($originalServicePath) {
                    & sc.exe config $SvcName ('binPath= ' + $originalServicePath) | Out-Null
                }
                if ($wasRunning) { Start-Service -Name $SvcName -ErrorAction SilentlyContinue }
                throw "Upgrade failed and executable was rolled back to $oldVersion. Cause: $upgradeError"
            }
            finally {
                Remove-Item -LiteralPath $StageDir -Recurse -Force -ErrorAction SilentlyContinue
            }

            $backupParent = Join-Path $installPath '_backup'
            if (Test-Path -LiteralPath $backupParent) {
                @(Get-ChildItem -LiteralPath $backupParent -Directory -Filter 'upgrade_*' |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -Skip $BackupLimit) |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }

            [pscustomobject]@{
                Method     = $method
                Previous   = $oldVersion
                Current    = $installedVersion
                Status     = $(if ($oldVersion -eq $installedVersion) { 'Refreshed' } else { 'Upgraded' })
                Backup     = $backupDir
                Executable = $targetExe
                Profile    = $ProfileName
            }
        } -ArgumentList $ServiceName, $stageDir, $ExpectedVersion, $InstallRoot, $ServiceTimeoutSec, $KeepBackups, $profileLeaf, $ServiceMode

        $row.Method = $upgrade.Method
        $row.Previous = $upgrade.Previous
        $row.Current = $upgrade.Current
        $row.Status = $upgrade.Status
        $row.Backup = $upgrade.Backup
        if ($upgrade.Profile) { $row.Profile = $upgrade.Profile }
        Write-Step "  Method     : $($upgrade.Method)" DarkGray
        Write-Step "  Executable : $($upgrade.Executable)" DarkGray
        Write-Step "  Version    : $($upgrade.Previous) -> $($upgrade.Current)" Green
        Write-Step ("  Profile    : {0}" -f $(if ($row.Profile) { $row.Profile } else { '<preserved>' })) DarkGray
        Write-Step "  Status     : $($upgrade.Status)" Green
        if ($upgrade.Backup) { Write-Step "  Backup     : $($upgrade.Backup)" DarkGray }
    }
    catch {
        $row.Status = 'Failed'
        $row.Error = $_.Exception.Message
        Write-Step "  ERROR: $($_.Exception.Message)" Red
    }
    finally {
        if ($null -ne $session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
        $results += [pscustomobject]$row
        Write-Host ''
    }
}

Write-Step '===== Summary =====' Yellow
$results | Format-Table Computer, Method, Previous, Current, Profile, Status, Error -AutoSize | Out-String | Write-Host
if (@($results | Where-Object Status -eq 'Failed').Count -gt 0) { exit 1 }
exit 0
