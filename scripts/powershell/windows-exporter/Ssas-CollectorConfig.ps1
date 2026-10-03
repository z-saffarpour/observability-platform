#Requires -Version 5.1
<#
.SYNOPSIS
  Builds and merges ssas-collector.json defaults for install/upgrade.
#>
. (Join-Path $PSScriptRoot 'Ssas-CollectorPaths.ps1')

function Get-SsasDefaultRotationSettings {
    [ordered]@{
        AuditLogMaxBytes     = 52428800      # 50 MB
        XelFileMaxBytes      = 1073741824    # 1 GB
        XelDirectoryMaxBytes = 5368709120    # 5 GB
        KeepRotatedFiles     = 10
    }
}

function New-SsasCollectorPathSettings {
    param(
        [string]$ProgramDataRoot = '',
        [string]$XEventsDirectory = '',
        [string]$SecretsDirectory = '',
        [string]$AuditDirectory = '',
        [string]$SiemOutputPath = '',
        [string[]]$XelPath = @()
    )

    $root = if ($ProgramDataRoot) { $ProgramDataRoot } else { Get-SsasProgramDataRoot }
    $xevents = if ($XEventsDirectory) { $XEventsDirectory } else { Join-Path $root 'xevents' }
    $secrets = if ($SecretsDirectory) { $SecretsDirectory } else { Join-Path $root 'secrets' }
    $audit = if ($AuditDirectory) { $AuditDirectory } else { Join-Path $root 'audit' }
    $siem = if ($SiemOutputPath) { $SiemOutputPath } else { Join-Path $audit 'ssas-security-audit.jsonl' }
    $xel = @()
    if ($XelPath.Count) { $xel = @($XelPath) }

    [ordered]@{
        ProgramDataRoot  = $root
        XEventsDirectory = $xevents
        SecretsDirectory = $secrets
        AuditDirectory   = $audit
        XelPath          = $xel
        SiemOutputPath   = $siem
    }
}

function New-SsasCollectorConfig {
    param(
        [string[]]$Instance = @('localhost'),
        [string[]]$Endpoint = @(),
        [string[]]$BackupPath = @(),
        [string[]]$ReadOnlyProbeConnectionStringFile = @(),
        [string[]]$XelPath = @(),
        [string]$ProgramDataRoot = '',
        [string]$XEventsDirectory = '',
        [string]$SecretsDirectory = '',
        [string]$AuditDirectory = '',
        [string]$SiemOutputPath = '',
        [int]$CommandTimeoutSec = 30,
        [int]$StaleAfterHours = 24,
        [int]$LongSessionMinutes = 30,
        [int]$IdleSessionMinutes = 15,
        [long]$AuditLogMaxBytes = 0,
        [long]$XelFileMaxBytes = 0,
        [long]$XelDirectoryMaxBytes = 0,
        [int]$KeepRotatedFiles = 0,
        [switch]$EnableXEvents
    )

    $paths = New-SsasCollectorPathSettings -ProgramDataRoot $ProgramDataRoot `
        -XEventsDirectory $XEventsDirectory -SecretsDirectory $SecretsDirectory `
        -AuditDirectory $AuditDirectory -SiemOutputPath $SiemOutputPath -XelPath $XelPath

    if ($EnableXEvents -and -not $XelPath.Count) {
        $paths.XelPath = @(Join-Path $paths.XEventsDirectory '*.xel')
    }

    $rotationDefaults = Get-SsasDefaultRotationSettings
    $rotation = [ordered]@{
        AuditLogMaxBytes     = if ($AuditLogMaxBytes -gt 0) { $AuditLogMaxBytes } else { $rotationDefaults.AuditLogMaxBytes }
        XelFileMaxBytes      = if ($XelFileMaxBytes -gt 0) { $XelFileMaxBytes } else { $rotationDefaults.XelFileMaxBytes }
        XelDirectoryMaxBytes = if ($XelDirectoryMaxBytes -gt 0) { $XelDirectoryMaxBytes } else { $rotationDefaults.XelDirectoryMaxBytes }
        KeepRotatedFiles     = if ($KeepRotatedFiles -gt 0) { $KeepRotatedFiles } else { $rotationDefaults.KeepRotatedFiles }
    }

    [ordered]@{
        Instance                          = @($Instance)
        Endpoint                          = @($Endpoint)
        BackupPath                        = @($BackupPath)
        ReadOnlyProbeConnectionStringFile = @($ReadOnlyProbeConnectionStringFile)
        Paths                             = [ordered]@{
            ProgramDataRoot  = $paths.ProgramDataRoot
            XEventsDirectory = $paths.XEventsDirectory
            SecretsDirectory = $paths.SecretsDirectory
            AuditDirectory   = $paths.AuditDirectory
        }
        XelPath                           = @($paths.XelPath)
        SiemOutputPath                    = $paths.SiemOutputPath
        CommandTimeoutSec                 = $CommandTimeoutSec
        StaleAfterHours                   = $StaleAfterHours
        LongSessionMinutes                = $LongSessionMinutes
        IdleSessionMinutes                = $IdleSessionMinutes
        Rotation                          = $rotation
    }
}

function Merge-SsasCollectorConfig {
    param(
        [object]$Existing,
        [hashtable]$Install
    )

    $created = New-SsasCollectorConfig @Install
    if (-not $Existing) { return $created }

    foreach ($key in @('Instance', 'Endpoint', 'BackupPath', 'ReadOnlyProbeConnectionStringFile')) {
        if (-not ($Existing.PSObject.Properties.Name -contains $key)) { continue }
        $existingValue = @($Existing.$key | ForEach-Object { $_ })
        $installValue = @()
        if ($Install.ContainsKey($key)) { $installValue = @($Install[$key] | ForEach-Object { $_ }) }

        if ($key -eq 'Instance' -and $installValue.Count -eq 1 -and ($installValue[0] -eq 'localhost') -and $existingValue.Count) {
            $created[$key] = $existingValue
            continue
        }
        if (-not $installValue.Count -and $existingValue.Count) {
            $created[$key] = $existingValue
        }
    }

    foreach ($key in @('CommandTimeoutSec', 'StaleAfterHours', 'LongSessionMinutes', 'IdleSessionMinutes')) {
        if ($Install.ContainsKey($key)) { continue }
        if ($Existing.PSObject.Properties.Name -contains $key) {
            $created[$key] = [int]$Existing.$key
        }
    }

    foreach ($rotationKey in @('AuditLogMaxBytes', 'XelFileMaxBytes', 'XelDirectoryMaxBytes', 'KeepRotatedFiles')) {
        if ($Install.ContainsKey($rotationKey) -and [long]$Install[$rotationKey] -gt 0) { continue }
        if ($Existing.PSObject.Properties.Name -contains 'Rotation' -and ($Existing.Rotation.PSObject.Properties.Name -contains $rotationKey)) {
            $created.Rotation[$rotationKey] = [long]$Existing.Rotation.$rotationKey
        }
    }

    $installXel = @()
    if ($Install.ContainsKey('XelPath')) { $installXel = @($Install.XelPath | ForEach-Object { $_ }) }
    $enableXEvents = $false
    if ($Install.ContainsKey('EnableXEvents')) { $enableXEvents = [bool]$Install.EnableXEvents }
    if (-not $installXel.Count -and -not $enableXEvents -and ($Existing.PSObject.Properties.Name -contains 'XelPath')) {
        $existingXel = @($Existing.XelPath | ForEach-Object { $_ })
        if ($existingXel.Count) { $created.XelPath = $existingXel }
    }

    return $created
}

function Resolve-SsasCollectorPathsFromConfig {
    param([object]$Config)

    $paths = if ($Config -and $Config.Paths) { $Config.Paths } else { $null }
    $root = if ($paths -and $paths.ProgramDataRoot) { [string]$paths.ProgramDataRoot } else { Get-SsasProgramDataRoot }
    $xevents = if ($paths -and $paths.XEventsDirectory) { [string]$paths.XEventsDirectory } else { Join-Path $root 'xevents' }
    $secrets = if ($paths -and $paths.SecretsDirectory) { [string]$paths.SecretsDirectory } else { Join-Path $root 'secrets' }
    $audit = if ($paths -and $paths.AuditDirectory) { [string]$paths.AuditDirectory } else { Join-Path $root 'audit' }
    $siem = if ($Config -and $Config.SiemOutputPath) { [string]$Config.SiemOutputPath } else { Join-Path $audit 'ssas-security-audit.jsonl' }
    $xel = if ($Config -and $Config.XelPath) { @($Config.XelPath | ForEach-Object { $_ }) } else { @(Join-Path $xevents '*.xel') }

    [pscustomobject]@{
        ProgramDataRoot  = $root
        XEventsDirectory = $xevents
        SecretsDirectory = $secrets
        AuditDirectory   = $audit
        SiemOutputPath   = $siem
        XelPath          = $xel
    }
}

function Resolve-SsasRotationFromConfig {
    param([object]$Config)

    $defaults = Get-SsasDefaultRotationSettings
    if (-not $Config -or -not $Config.Rotation) { return $defaults }

    [ordered]@{
        AuditLogMaxBytes     = if ($Config.Rotation.AuditLogMaxBytes) { [long]$Config.Rotation.AuditLogMaxBytes } else { $defaults.AuditLogMaxBytes }
        XelFileMaxBytes      = if ($Config.Rotation.XelFileMaxBytes) { [long]$Config.Rotation.XelFileMaxBytes } else { $defaults.XelFileMaxBytes }
        XelDirectoryMaxBytes = if ($Config.Rotation.XelDirectoryMaxBytes) { [long]$Config.Rotation.XelDirectoryMaxBytes } else { $defaults.XelDirectoryMaxBytes }
        KeepRotatedFiles     = if ($Config.Rotation.KeepRotatedFiles) { [int]$Config.Rotation.KeepRotatedFiles } else { $defaults.KeepRotatedFiles }
    }
}

function Ensure-SsasProgramDataLayoutFromConfig {
    param([object]$Config)

    $resolved = Resolve-SsasCollectorPathsFromConfig -Config $Config
    foreach ($directory in @(
        $resolved.ProgramDataRoot,
        $resolved.XEventsDirectory,
        (Join-Path $resolved.XEventsDirectory 'archive'),
        $resolved.SecretsDirectory,
        $resolved.AuditDirectory,
        (Join-Path $resolved.AuditDirectory 'archive')
    )) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    return $resolved
}

function Invoke-SsasRotateFileIfNeeded {
    param(
        [Parameter(Mandatory)][string]$Path,
        [long]$MaxBytes,
        [int]$KeepRotatedFiles = 10
    )

    if (-not $MaxBytes -or $MaxBytes -le 0) { return $false }
    if (-not (Test-Path -LiteralPath $Path)) { return $false }

    $item = Get-Item -LiteralPath $Path
    if ($item.Length -lt $MaxBytes) { return $false }

    $directory = Split-Path -Parent $Path
    $archiveDir = Join-Path $directory 'archive'
    New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null

    $fileName = [IO.Path]::GetFileName($Path)
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
    $archivePath = Join-Path $archiveDir ("{0}.{1}{2}" -f [IO.Path]::GetFileNameWithoutExtension($fileName), $stamp, [IO.Path]::GetExtension($fileName))
    Move-Item -LiteralPath $Path -Destination $archivePath -Force

    $pattern = [IO.Path]::GetFileNameWithoutExtension($fileName) + '.*' + [IO.Path]::GetExtension($fileName)
    Get-ChildItem -LiteralPath $archiveDir -Filter $pattern -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -Skip $KeepRotatedFiles |
        Remove-Item -Force -ErrorAction SilentlyContinue

    return $true
}

function Invoke-SsasXelFileRotation {
    param(
        [Parameter(Mandatory)][string]$XEventsDirectory,
        [hashtable]$StateFiles = @{},
        [long]$XelFileMaxBytes = 0,
        [long]$XelDirectoryMaxBytes = 0,
        [int]$KeepRotatedFiles = 10
    )

    if (-not (Test-Path -LiteralPath $XEventsDirectory)) { return }

    $archiveDir = Join-Path $XEventsDirectory 'archive'
    New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    $now = Get-Date

    $files = @(Get-ChildItem -LiteralPath $XEventsDirectory -Filter '*.xel' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending)
    if (-not $files.Count) { return }

    $activeFile = $files[0]
    $candidates = @($files | Select-Object -Skip 1)

    foreach ($file in $candidates) {
        $isStale = ($now - $file.LastWriteTimeUtc).TotalMinutes -ge 5
        if (-not $isStale) { continue }

        $shouldArchive = $false
        if ($XelFileMaxBytes -gt 0 -and $file.Length -ge $XelFileMaxBytes) { $shouldArchive = $true }
        if ($StateFiles.ContainsKey($file.FullName)) { $shouldArchive = $true }

        if (-not $shouldArchive) { continue }

        $stamp = $file.LastWriteTimeUtc.ToString('yyyyMMddHHmmss')
        $destination = Join-Path $archiveDir ($file.BaseName + '.' + $stamp + $file.Extension)
        Move-Item -LiteralPath $file.FullName -Destination $destination -Force -ErrorAction SilentlyContinue
    }

    if ($XelDirectoryMaxBytes -gt 0) {
        $allFiles = @(
            Get-ChildItem -LiteralPath $XEventsDirectory -Filter '*.xel' -File -ErrorAction SilentlyContinue
            Get-ChildItem -LiteralPath $archiveDir -Filter '*.xel' -File -ErrorAction SilentlyContinue
        )
        $totalBytes = ($allFiles | Measure-Object -Property Length -Sum).Sum
        if ($totalBytes -gt $XelDirectoryMaxBytes) {
            $removable = @($allFiles | Where-Object { $_.FullName -ne $activeFile.FullName } | Sort-Object LastWriteTimeUtc)
            foreach ($file in $removable) {
                if ($totalBytes -le $XelDirectoryMaxBytes) { break }
                $totalBytes -= $file.Length
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Get-ChildItem -LiteralPath $archiveDir -Filter '*.xel' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -Skip $KeepRotatedFiles |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
