#Requires -Version 5.1
<#
.SYNOPSIS
  Deploy sql_exporter.yml to target servers and restart exporter service.

.DESCRIPTION
  - Resolves base sql_exporter.yml from -Source (project root by default)
  - Optional -Profile applies profiles/<name>.yml collectors into the config
    before copy (same UX as windows_exporter -Profile sql-server.yml)
  - Copies sql_exporter.yml (and profiles\ when -Profile is set) to:
      C:\Program Files\Observability\PrometheusExporters\sql-exporter\config
  - Restarts prometheus_sql_exporter service on each server

.EXAMPLE
  .\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 -WhatIf

.EXAMPLE
  .\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 `
    -Computers sql-host-01,sql-host-02 `
    -Profile oltp.yml `
    -WhatIf

.EXAMPLE
  .\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 `
    -Computers (Get-Content .\scripts\powershell\sql-exporter\servers.txt) `
    -Profile dwh.yml
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Computers = @(
        'sql-host-01'
        'sql-host-02'
        'sql-host-03'
        'sql-host-04'
    ),

    [Parameter(Mandatory = $false)]
    [string]$Source,

    [Parameter(Mandatory = $false)]
    [string]$DestinationRoot = 'C:\Program Files\Observability\PrometheusExporters\sql-exporter',

    [Parameter(Mandatory = $false)]
    [string]$ServiceName = 'prometheus_sql_exporter',

    [Parameter(Mandatory = $false)]
    [string]$Profile,

    [Parameter(Mandatory = $false)]
    [int]$ServiceTimeoutSec = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Source)) {
    $Source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\exporters\sql-exporter'))
}

function Write-Step {
    param([string]$Message, [string]$Color = 'Cyan')
    Write-Host $Message -ForegroundColor $Color
}

function Resolve-ComputerList {
    param([string[]]$InputComputers)

    return @(
        $InputComputers |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Convert-ToUncPath {
    param(
        [string]$ComputerName,
        [string]$LocalPath
    )

    if ($LocalPath -notmatch '^([A-Za-z]):\\(.+)$') {
        throw "DestinationRoot must be a local path (example: C:\Path\To\Folder). Current value: $LocalPath"
    }

    $drive = $Matches[1]
    $rest = $Matches[2]
    return "\\$ComputerName\$($drive)$\$rest"
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

function New-SqlExporterConfigWithProfile {
    param(
        [Parameter(Mandatory)][string]$BaseConfigPath,
        [Parameter(Mandatory)][string]$ProfilePath,
        [Parameter(Mandatory)][string]$ProfileLeaf,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $config = Get-Content -LiteralPath $BaseConfigPath -Raw
    if ([string]::IsNullOrWhiteSpace($config)) {
        throw "Base config is empty: $BaseConfigPath"
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
        throw "Could not find an active target.collectors entry in: $BaseConfigPath"
    }

    $last = $found[$found.Count - 1]
    $newConfig = $config.Substring(0, $last.Index) + $replacement + $config.Substring($last.Index + $last.Length)

    $outDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($OutputPath, $newConfig, $utf8)
}

function Resolve-SourceFile {
    param(
        [string]$Root,
        [string]$ProfileLeaf
    )

    $baseCandidates = @(
        (Join-Path $Root 'config\sql_exporter.yml'),
        (Join-Path $Root 'sql_exporter.yml'),
        (Join-Path $Root 'oltp\sql_exporter.yml'),
        (Join-Path $Root 'bi\sql_exporter.yml'),
        (Join-Path $Root 'ssis\sql_exporter.yml')
    )

    $base = $null
    foreach ($candidate in $baseCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $base = (Resolve-Path -LiteralPath $candidate).Path
            break
        }
    }

    if (-not $base) {
        throw ("sql_exporter.yml not found under '{0}'. Tried: {1}" -f $Root, ($baseCandidates -join ', '))
    }

    if ([string]::IsNullOrWhiteSpace($ProfileLeaf)) {
        return [pscustomobject]@{
            ConfigPath  = $base
            ProfileLeaf = $null
            TempPath    = $null
        }
    }

    $profilesRoot = Join-Path $Root 'profiles'
    if (-not (Test-Path -LiteralPath $profilesRoot -PathType Container)) {
        throw "profiles folder not found: $profilesRoot"
    }

    $tempPath = Join-Path $env:TEMP ("sql_exporter-deploy-{0}-{1}.yml" -f ([IO.Path]::GetFileNameWithoutExtension($ProfileLeaf)), [guid]::NewGuid().ToString('N'))
    New-SqlExporterConfigWithProfile `
        -BaseConfigPath $base `
        -ProfilePath (Join-Path $profilesRoot $ProfileLeaf) `
        -ProfileLeaf $ProfileLeaf `
        -OutputPath $tempPath

    return [pscustomobject]@{
        ConfigPath  = $tempPath
        ProfileLeaf = $ProfileLeaf
        TempPath    = $tempPath
        ProfilesDir = $profilesRoot
    }
}

function Assert-RemoteFilePresent {
    param(
        [string]$RemoteFilePath
    )

    if (-not (Test-Path -LiteralPath $RemoteFilePath -PathType Leaf)) {
        throw "Remote file verification failed: $RemoteFilePath"
    }
}

function Restart-ExporterService {
    param(
        [string]$ComputerName,
        [string]$Name,
        [int]$TimeoutSec
    )

    $script = {
        param($SvcName, $Timeout)

        $svc = Get-Service -Name $SvcName -ErrorAction Stop

        if ($svc.Status -ne 'Stopped') {
            Stop-Service -Name $SvcName -Force -ErrorAction Stop
            $svc.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($Timeout))
        }

        Start-Service -Name $SvcName -ErrorAction Stop
        $svc.Refresh()
        $svc.WaitForStatus('Running', [TimeSpan]::FromSeconds($Timeout))

        [pscustomobject]@{ Name = $svc.Name; Status = $svc.Status.ToString() }
    }

    Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $Name, $TimeoutSec
}

$Computers = Resolve-ComputerList -InputComputers $Computers
if ($Computers.Count -eq 0) {
    throw 'No target servers were resolved.'
}

$Source = (Resolve-Path -LiteralPath $Source).Path
$profilesRoot = Join-Path $Source 'profiles'
$profileLeaf = $null
if (-not [string]::IsNullOrWhiteSpace($Profile)) {
    if (-not (Test-Path -LiteralPath $profilesRoot -PathType Container)) {
        throw "profiles folder not found: $profilesRoot"
    }
    $profileLeaf = Resolve-ProfileLeaf -Name $Profile -ProfilesRoot $profilesRoot
}

$resolved = Resolve-SourceFile -Root $Source -ProfileLeaf $profileLeaf
$layoutTempPath = Join-Path $env:TEMP ("sql_exporter-config-deploy-{0}.yml" -f [guid]::NewGuid().ToString('N'))
$layoutConfig = (Get-Content -LiteralPath $resolved.ConfigPath -Raw).Replace('"collector/*.collector.yml"', '"../collectors/*.collector.yml"')
[IO.File]::WriteAllText($layoutTempPath, $layoutConfig, (New-Object Text.UTF8Encoding $false))
$sourceFilePath = $layoutTempPath
$sourceInfo = Get-Item -LiteralPath $sourceFilePath

Write-Step ("Source file : {0}" -f $sourceFilePath)
Write-Step ("Source bytes: {0}" -f $sourceInfo.Length)
Write-Step ("Profile     : {0}" -f ($(if ($profileLeaf) { $profileLeaf } else { '<none — deploy base sql_exporter.yml as-is>' })))
Write-Step ("Destination: {0}" -f $DestinationRoot)
Write-Step ("Service    : {0}" -f $ServiceName)
Write-Step ("Hosts      : {0}" -f ($Computers -join ', '))
Write-Host ''

$results = @()

try {
foreach ($computer in $Computers) {
    $row = [ordered]@{
        Computer = $computer
        Profile  = $profileLeaf
        Copy     = 'Skipped'
        Service  = 'Skipped'
        Error    = $null
    }

    Write-Step ("===== {0} =====" -f $computer) 'Yellow'

    try {
        $remoteRoot = Convert-ToUncPath -ComputerName $computer -LocalPath $DestinationRoot

        if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
            throw 'Host unreachable (ping failed).'
        }

        if (-not (Test-Path -LiteralPath $remoteRoot -PathType Container)) {
            throw "Destination not accessible: $remoteRoot (check admin share / permissions)."
        }

        $remoteConfig = Join-Path $remoteRoot 'config'
        $remoteFile = Join-Path $remoteConfig 'sql_exporter.yml'

        if ($PSCmdlet.ShouldProcess($remoteFile, 'Copy sql_exporter.yml')) {
            if (-not (Test-Path -LiteralPath $remoteConfig -PathType Container)) {
                New-Item -Path $remoteConfig -ItemType Directory -Force | Out-Null
            }
            Copy-Item -LiteralPath $sourceFilePath -Destination $remoteFile -Force
            Assert-RemoteFilePresent -RemoteFilePath $remoteFile
            $row.Copy = 'OK'
            Write-Step ("  File copied: {0}" -f $remoteFile) 'Green'

            if ($profileLeaf) {
                $remoteProfiles = Join-Path $remoteRoot 'profiles'
                if (-not (Test-Path -LiteralPath $remoteProfiles -PathType Container)) {
                    New-Item -Path $remoteProfiles -ItemType Directory -Force | Out-Null
                }
                Copy-Item -Path (Join-Path $profilesRoot '*') -Destination $remoteProfiles -Force
                Write-Step ("  Profiles synced: {0}" -f $remoteProfiles) 'DarkGray'
            }
        }

        if ($PSCmdlet.ShouldProcess(("$computer\$ServiceName"), 'Restart service')) {
            $svc = Restart-ExporterService -ComputerName $computer -Name $ServiceName -TimeoutSec $ServiceTimeoutSec
            $row.Service = $svc.Status
            Write-Step ("  Service restarted: {0}" -f $svc.Status) 'Green'
        }
    }
    catch {
        $row.Error = $_.Exception.Message
        Write-Step ("  ERROR: {0}" -f $_.Exception.Message) 'Red'
    }

    $results += [pscustomobject]$row
    Write-Host ''
}
}
finally {
    if (Test-Path -LiteralPath $layoutTempPath) {
        [IO.File]::Delete($layoutTempPath)
    }
    if ($resolved.TempPath -and (Test-Path -LiteralPath $resolved.TempPath)) {
        [IO.File]::Delete($resolved.TempPath)
    }
}

Write-Step '===== Summary =====' 'Yellow'
$results | Format-Table -AutoSize | Out-String | Write-Host

$failed = @($results | Where-Object { $_.Error })
if ($failed.Count -gt 0) {
    exit 1
}

exit 0
