#Requires -Version 5.1
<#
.SYNOPSIS
  Sync local sql_exporter collector .yml files to remote servers, then restart the service.

.DESCRIPTION
  Structured collector deployment matching sql_exporter.yml
  collector_files: ../collectors/*.collector.yml.

  Collector
  - Copies allowed *.collector.yml into remote collectors\
  - Creates collectors\ if missing
  - Removes legacy *.collector.yml from the sql-exporter root
  - Purges extra files inside collectors\

  Filtering:
  - ExcludeEverywhere : never deployed; removed from every server if present
  - AllowOnlyOn       : deployed only to listed servers; removed from all others

.EXAMPLE
  .\scripts\powershell\sql-exporter\Deploy-Collectors.ps1

.EXAMPLE
  .\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Layout Collector

.EXAMPLE
  .\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers (Get-Content .\scripts\powershell\sql-exporter\servers.txt)
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Collector')]
    [string]$Layout = 'Collector',

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
    [int]$ServiceTimeoutSec = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Source)) {
    $Source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\exporters\sql-exporter\collector'))
}

# ---------------------------------------------------------------------------
# Collector deploy filters
# ---------------------------------------------------------------------------

# Never deploy to any server (also purged remotely).
$ExcludeEverywhere = @(
    'mssql_missing_index.collector.yml'
    'mssql_index_usage.collector.yml'
    'mssql_index_fragmentation.collector.yml'
)

# Deploy only to the listed server(s). On all other hosts the file is purged.
$AllowOnlyOn = @{
    'mssql_restore.collector.yml' = @('sql-host-02')
}

# ---------------------------------------------------------------------------

function Write-Step {
    param([string]$Message, [string]$Color = 'Cyan')
    Write-Host $Message -ForegroundColor $Color
}

function Test-AdminSharePath {
    param([string]$UncPath)
    Test-Path -LiteralPath $UncPath -PathType Container
}

function Normalize-CollectorFileName {
    param([string]$Name)
    $n = $Name.Trim()
    if ($n -notmatch '\.yml$') {
        if ($n -notmatch '\.collector$') {
            $n = "$n.collector.yml"
        }
        else {
            $n = "$n.yml"
        }
    }
    return $n
}

function Normalize-ComputerName {
    param([string]$Name)
    return $Name.Trim().ToUpperInvariant()
}

function Convert-AllowOnlyOnMap {
    param([hashtable]$Map)

    $normalizedMap = @{}
    foreach ($key in $Map.Keys) {
        $normalizedKey = Normalize-CollectorFileName $key
        $hostSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        foreach ($targetHost in @($Map[$key])) {
            $normalizedHost = Normalize-ComputerName $targetHost
            if (-not [string]::IsNullOrWhiteSpace($normalizedHost)) {
                [void]$hostSet.Add($normalizedHost)
            }
        }

        $normalizedMap[$normalizedKey] = $hostSet
    }

    return $normalizedMap
}

function Convert-ToUncPath {
    param(
        [string]$ComputerName,
        [string]$LocalPath
    )

    if ($LocalPath -match '^([A-Za-z]):\\?(.*)$') {
        $drive = $Matches[1]
        $rest = $Matches[2]
        if ([string]::IsNullOrWhiteSpace($rest)) {
            return "\\{0}\{1}$" -f $ComputerName, $drive
        }
        return "\\{0}\{1}$\{2}" -f $ComputerName, $drive, $rest
    }

    throw "DestinationRoot must be a local drive path, for example C:\Path\To\sql-exporter"
}

function Test-CollectorAllowed {
    param(
        [string]$FileName,
        [string]$ComputerName,
        [string[]]$ExcludeEverywhere,
        [hashtable]$AllowOnlyOn
    )

    $normalizedFileName = Normalize-CollectorFileName $FileName
    $normalizedComputerName = Normalize-ComputerName $ComputerName

    $excludeSet = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]($ExcludeEverywhere | ForEach-Object { Normalize-CollectorFileName $_ }),
        [StringComparer]::OrdinalIgnoreCase
    )
    if ($excludeSet.Contains($normalizedFileName)) {
        return $false
    }

    if ($AllowOnlyOn.ContainsKey($normalizedFileName)) {
        return $AllowOnlyOn[$normalizedFileName].Contains($normalizedComputerName)
    }

    return $true
}

function Assert-RemoteCollectorFilesPresent {
    param(
        [System.IO.FileInfo[]]$AllowedFiles,
        [string]$RemotePath
    )

    $missing = @()
    foreach ($file in $AllowedFiles) {
        $remoteFile = Join-Path $RemotePath $file.Name
        if (-not (Test-Path -LiteralPath $remoteFile -PathType Leaf)) {
            $missing += $file.Name
        }
    }

    if ($missing.Count -gt 0) {
        throw ("Missing remote collector file(s) after sync: {0}" -f ($missing -join ', '))
    }
}

function Get-AllowedCollectorFiles {
    param(
        [string]$LocalSource,
        [string]$ComputerName,
        [string[]]$ExcludeEverywhere,
        [hashtable]$AllowOnlyOn
    )

    Get-ChildItem -LiteralPath $LocalSource -File -Filter '*.collector.yml' |
        Where-Object {
            Test-CollectorAllowed -FileName $_.Name -ComputerName $ComputerName `
                -ExcludeEverywhere $ExcludeEverywhere -AllowOnlyOn $AllowOnlyOn
        }
}

function Ensure-RemoteCollectorFolder {
    param([string]$RemoteRoot)

    $collectorDir = Join-Path $RemoteRoot 'collectors'
    if (-not (Test-Path -LiteralPath $collectorDir)) {
        New-Item -ItemType Directory -Path $collectorDir -Force | Out-Null
        Write-Step ("  collector folder created: {0}" -f $collectorDir) 'Green'
    }
    else {
        Write-Step ("  collector folder exists : {0}" -f $collectorDir) 'DarkGray'
    }

    return $collectorDir
}

function Remove-RemoteCollectorFolder {
    param([string]$RemoteRoot)

    $collectorDir = Join-Path $RemoteRoot 'collectors'
    if (-not (Test-Path -LiteralPath $collectorDir)) {
        Write-Step '  collector folder: not present' 'DarkGray'
        return $false
    }

    $items = @(Get-ChildItem -LiteralPath $collectorDir -Force -Recurse -ErrorAction SilentlyContinue)
    Write-Step ("  Removing collector folder ({0} item(s)): {1}" -f $items.Count, $collectorDir) 'DarkYellow'

    Get-ChildItem -LiteralPath $collectorDir -Force -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {
            try { $_.Attributes = 'Normal' } catch { }
        }

    Remove-Item -LiteralPath $collectorDir -Recurse -Force -ErrorAction Stop

    if (Test-Path -LiteralPath $collectorDir) {
        throw ("Failed to delete collector folder: {0}" -f $collectorDir)
    }

    Write-Step '  collector folder deleted (with contents)' 'Green'
    return $true
}

function Remove-RootCollectorFiles {
    param([string]$RemoteRoot)

    $removed = 0
    $rootFiles = @(Get-ChildItem -LiteralPath $RemoteRoot -File -Filter '*.collector.yml' -ErrorAction SilentlyContinue)

    foreach ($file in $rootFiles) {
        Remove-Item -LiteralPath $file.FullName -Force
        $removed++
        Write-Step ("  Removed root file: {0}" -f $file.Name) 'DarkYellow'
    }

    return $removed
}

function Sync-CollectorFilesToCollectorLayout {
    param(
        [System.IO.FileInfo[]]$AllowedFiles,
        [string]$RemoteRoot
    )

    $remoteCollector = Ensure-RemoteCollectorFolder -RemoteRoot $RemoteRoot

    $allowedNames = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $AllowedFiles) {
        [void]$allowedNames.Add($file.Name)
    }

    $copied = 0
    foreach ($file in $AllowedFiles) {
        $dest = Join-Path $remoteCollector $file.Name
        Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
        $copied++
    }

    $removedFromCollector = 0
    $remoteCollectorFiles = @(Get-ChildItem -LiteralPath $remoteCollector -File -Filter '*.collector.yml' -ErrorAction SilentlyContinue)
    foreach ($remoteFile in $remoteCollectorFiles) {
        if (-not $allowedNames.Contains($remoteFile.Name)) {
            Remove-Item -LiteralPath $remoteFile.FullName -Force
            $removedFromCollector++
            Write-Step ("  Removed extra from collector: {0}" -f $remoteFile.Name) 'DarkYellow'
        }
    }

    $removedFromRoot = Remove-RootCollectorFiles -RemoteRoot $RemoteRoot

    Assert-RemoteCollectorFilesPresent -AllowedFiles $AllowedFiles -RemotePath $remoteCollector

    [pscustomobject]@{
        Copied               = $copied
        RemovedFromCollector = $removedFromCollector
        RemovedFromRoot      = $removedFromRoot
        FolderRemoved        = $false
        TargetPath           = $remoteCollector
    }
}

function Sync-CollectorFilesToRootLayout {
    param(
        [System.IO.FileInfo[]]$AllowedFiles,
        [string]$RemoteRoot
    )

    $allowedNames = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $AllowedFiles) {
        [void]$allowedNames.Add($file.Name)
    }

    $copied = 0
    foreach ($file in $AllowedFiles) {
        $dest = Join-Path $RemoteRoot $file.Name
        Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
        $copied++
    }

    $removed = 0
    $remoteYml = @(Get-ChildItem -LiteralPath $RemoteRoot -File -Filter '*.collector.yml' -ErrorAction SilentlyContinue)
    foreach ($remoteFile in $remoteYml) {
        if (-not $allowedNames.Contains($remoteFile.Name)) {
            Remove-Item -LiteralPath $remoteFile.FullName -Force
            $removed++
            Write-Step ("  Removed extra: {0}" -f $remoteFile.Name) 'DarkYellow'
        }
    }

    Assert-RemoteCollectorFilesPresent -AllowedFiles $AllowedFiles -RemotePath $RemoteRoot

    $folderRemoved = Remove-RemoteCollectorFolder -RemoteRoot $RemoteRoot

    [pscustomobject]@{
        Copied               = $copied
        RemovedFromCollector = 0
        RemovedFromRoot      = $removed
        FolderRemoved        = $folderRemoved
        TargetPath           = $RemoteRoot
    }
}

function Sync-CollectorFiles {
    param(
        [System.IO.FileInfo[]]$AllowedFiles,
        [string]$RemoteRoot,
        [ValidateSet('Collector', 'Root')]
        [string]$Layout
    )

    if ($Layout -eq 'Collector') {
        return Sync-CollectorFilesToCollectorLayout -AllowedFiles $AllowedFiles -RemoteRoot $RemoteRoot
    }

    return Sync-CollectorFilesToRootLayout -AllowedFiles $AllowedFiles -RemoteRoot $RemoteRoot
}

function Stop-ExporterService {
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
        $svc.Refresh()
        [pscustomobject]@{ Name = $svc.Name; Status = $svc.Status.ToString() }
    }

    Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $Name, $TimeoutSec
}

function Start-ExporterService {
    param(
        [string]$ComputerName,
        [string]$Name,
        [int]$TimeoutSec
    )

    $script = {
        param($SvcName, $Timeout)

        $svc = Get-Service -Name $SvcName -ErrorAction Stop
        if ($svc.Status -ne 'Running') {
            Start-Service -Name $SvcName -ErrorAction Stop
        }
        $svc.Refresh()
        $svc.WaitForStatus('Running', [TimeSpan]::FromSeconds($Timeout))
        [pscustomobject]@{ Name = $svc.Name; Status = $svc.Status.ToString() }
    }

    Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $Name, $TimeoutSec
}

# --- preflight ---
if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "Source folder not found: $Source"
}

$sourceFiles = @(Get-ChildItem -LiteralPath $Source -File -Filter '*.collector.yml')
if ($sourceFiles.Count -eq 0) {
    throw "No *.collector.yml files found in: $Source"
}

$ExcludeEverywhere = @($ExcludeEverywhere | ForEach-Object { Normalize-CollectorFileName $_ })
$AllowOnlyOn = Convert-AllowOnlyOnMap -Map $AllowOnlyOn

Write-Step ("Layout : {0}" -f $Layout) 'Magenta'
Write-Step ("Source : {0} ({1} collector file(s))" -f $Source, $sourceFiles.Count)
if ($Layout -eq 'Collector') {
    Write-Step ("Remote : {0}\collectors  (legacy root *.collector.yml will be removed)" -f $DestinationRoot)
}
else {
    throw 'The Root layout is no longer supported. Use the structured collectors\ directory.'
}
Write-Step ("Service: {0}" -f $ServiceName)
Write-Step ("Hosts  : {0}" -f ($Computers -join ', '))
Write-Step ("Exclude everywhere: {0}" -f ($ExcludeEverywhere -join ', ')) 'DarkYellow'
foreach ($key in ($AllowOnlyOn.Keys | Sort-Object)) {
    $hosts = @($AllowOnlyOn[$key] | Sort-Object)
    $hostText = if ($hosts.Count -eq 0) { '(none)' } else { $hosts -join ', ' }
    Write-Step ("Allow only on  : {0} -> {1}" -f $key, $hostText) 'DarkYellow'
}
Write-Host ''

$results = @()

foreach ($computer in $Computers) {
    $computer = $computer.Trim()
    if ([string]::IsNullOrWhiteSpace($computer)) { continue }

    Write-Step "===== $computer =====" 'Yellow'

    $row = [ordered]@{
        Computer = $computer
        Layout   = $Layout
        Files    = 0
        Sync     = 'Skipped'
        Service  = 'Skipped'
        Error    = $null
    }

    try {
        $remoteRoot = Convert-ToUncPath -ComputerName $computer -LocalPath $DestinationRoot

        if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
            throw "Host unreachable (ping failed)."
        }

        if (-not (Test-AdminSharePath -UncPath $remoteRoot)) {
            throw "Destination not accessible: $remoteRoot (check admin share / permissions)."
        }

        $allowed = @(
            Get-AllowedCollectorFiles -LocalSource $Source -ComputerName $computer `
                -ExcludeEverywhere $ExcludeEverywhere -AllowOnlyOn $AllowOnlyOn
        )
        $row.Files = $allowed.Count

        $skipped = @(
            $sourceFiles | Where-Object {
                $name = $_.Name
                -not ($allowed | Where-Object { $_.Name -eq $name })
            } | ForEach-Object { $_.Name }
        )
        if ($skipped.Count -gt 0) {
            Write-Step ("  Skipped ({0}): {1}" -f $skipped.Count, ($skipped -join ', ')) 'DarkYellow'
        }
        Write-Step ("  Deploy  ({0}): {1}" -f $allowed.Count, ($allowed.Name -join ', '))

        if ($PSCmdlet.ShouldProcess(("$computer\$ServiceName"), 'Stop service')) {
            $stopped = Stop-ExporterService -ComputerName $computer -Name $ServiceName -TimeoutSec $ServiceTimeoutSec
            Write-Step ("  Service stopped: {0}" -f $stopped.Status) 'Green'
        }

        $syncTarget = if ($Layout -eq 'Collector') {
            'Sync collectors\ folder and purge legacy root yml files'
        }
        else {
            'Sync yml files to root and delete collector folder'
        }

        if ($PSCmdlet.ShouldProcess($remoteRoot, $syncTarget)) {
            $sync = Sync-CollectorFiles -AllowedFiles $allowed -RemoteRoot $remoteRoot -Layout $Layout
            if ($Layout -eq 'Collector') {
                $row.Sync = ("OK (copied={0}, removedFromCollector={1}, removedFromRoot={2})" -f `
                    $sync.Copied, $sync.RemovedFromCollector, $sync.RemovedFromRoot)
            }
            else {
                $row.Sync = ("OK (copied={0}, removed={1}, collectorFolderRemoved={2})" -f `
                    $sync.Copied, $sync.RemovedFromRoot, $sync.FolderRemoved)
            }
            Write-Step ("  Sync OK -> {0}" -f $sync.TargetPath) 'Green'
        }

        if ($PSCmdlet.ShouldProcess(("$computer\$ServiceName"), 'Start service')) {
            $svc = Start-ExporterService -ComputerName $computer -Name $ServiceName -TimeoutSec $ServiceTimeoutSec
            $row.Service = $svc.Status
            Write-Step ("  Service started: {0}" -f $svc.Status) 'Green'
        }
    }
    catch {
        $row.Error = $_.Exception.Message
        Write-Step ("  ERROR: {0}" -f $_.Exception.Message) 'Red'
    }

    $results += [pscustomobject]$row
    Write-Host ''
}

Write-Step '===== Summary =====' 'Yellow'
$results | Format-Table -AutoSize | Out-String | Write-Host

$failed = @($results | Where-Object { $_.Error })
if ($failed.Count -gt 0) {
    exit 1
}
exit 0
