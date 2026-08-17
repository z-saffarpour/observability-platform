#Requires -Version 5.1
<#
.SYNOPSIS
  Export sqlx-* dashboards from Grafana into grafana/dashboards/sql-exporter/.

.DESCRIPTION
  Pulls live dashboards from Grafana (search type=dash-db, uid prefix sqlx-)
  and writes portable JSON files (id stripped) mirroring Grafana folders:
    AI-SQL Exporter root  -> grafana/dashboards/sql-exporter/
    Collector subfolder   -> grafana/dashboards/sql-exporter/Collector/

  Overview UIDs and file names are semantic (no -v02/-v03).

  Requires env (or -GrafanaUrl / -Token):
    GRAFANA_URL
    GRAFANA_SERVICE_ACCOUNT_TOKEN

  Uses Newtonsoft.Json for nested dashboard JSON (PS 5.1 ConvertTo-Json is lossy).

.EXAMPLE
  .\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1

.EXAMPLE
  .\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1 -WhatIf

.EXAMPLE
  .\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1 -RemoveOrphans
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$GrafanaUrl = $env:GRAFANA_URL,

    [Parameter(Mandatory = $false)]
    [string]$Token = $env:GRAFANA_SERVICE_ACCOUNT_TOKEN,

    [Parameter(Mandatory = $false)]
    [string]$OutDir,

    [Parameter(Mandatory = $false)]
    [string]$UidPrefix = 'sqlx-',

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeUid = @('sqlx-collector'),

    [Parameter(Mandatory = $false)]
    [string]$CollectorFolderUid = 'sqlx-collector',

    [Parameter(Mandatory = $false)]
    [string]$CollectorSubDir = 'Collector',

    [Parameter(Mandatory = $false)]
    [switch]$RemoveOrphans
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $OutDir = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot '..\..\..\grafana\dashboards\sql-exporter'))
}

function Resolve-NewtonsoftJsonDll {
    $candidates = @(
        'C:\Program Files\dotnet\sdk\10.0.302\Sdks\Microsoft.NET.Sdk\tools\net472\Newtonsoft.Json.dll'
        'C:\Program Files\dotnet\sdk\10.0.302\Newtonsoft.Json.dll'
        'C:\Program Files\Docker\Docker\Newtonsoft.Json.dll'
    )
    foreach ($dll in $candidates) {
        if (Test-Path -LiteralPath $dll) { return $dll }
    }
    $found = Get-ChildItem -Path 'C:\Program Files\dotnet\sdk' -Recurse -Filter 'Newtonsoft.Json.dll' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\net472\\' -or $_.DirectoryName -match '\\sdk\\\d' } |
        Select-Object -First 1
    if ($found) { return $found.FullName }
    return $null
}

function Get-DashboardFileName {
    param([string]$Uid)
    return "$Uid.json"
}

function Get-DashboardOutPath {
    param(
        [string]$BaseDir,
        [string]$Uid,
        [string]$FolderUid,
        [string]$CollectorUid,
        [string]$CollectorDir
    )
    $relDir = ''
    if ($FolderUid -eq $CollectorUid) {
        $relDir = $CollectorDir
    }
    $dir = if ($relDir) { Join-Path $BaseDir $relDir } else { $BaseDir }
    return (Join-Path $dir (Get-DashboardFileName -Uid $Uid))
}

if ([string]::IsNullOrWhiteSpace($GrafanaUrl)) {
    throw 'Grafana URL missing. Set GRAFANA_URL or pass -GrafanaUrl.'
}
if ([string]::IsNullOrWhiteSpace($Token)) {
    throw 'Grafana token missing. Set GRAFANA_SERVICE_ACCOUNT_TOKEN or pass -Token.'
}

$newtonsoft = Resolve-NewtonsoftJsonDll
if (-not $newtonsoft) {
    throw 'Newtonsoft.Json.dll not found under Program Files (dotnet SDK / Docker).'
}
Add-Type -Path $newtonsoft
Write-Host "Newtonsoft: $newtonsoft"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$collectorDirPath = Join-Path $OutDir $CollectorSubDir
New-Item -ItemType Directory -Force -Path $collectorDirPath | Out-Null

$base = $GrafanaUrl.TrimEnd('/')
$headers = @{ Authorization = "Bearer $Token" }

Write-Host "Searching dashboards on $base ..."
$searchRaw = (Invoke-WebRequest -Method GET -Uri "$base/api/search?type=dash-db&limit=5000" -Headers $headers -UseBasicParsing).Content
$search = [Newtonsoft.Json.Linq.JArray]::Parse($searchRaw)

$exclude = @{}
foreach ($x in $ExcludeUid) { $exclude[$x] = $true }

$targets = New-Object System.Collections.Generic.List[object]
foreach ($item in $search) {
    $uid = [string]$item['uid']
    $type = [string]$item['type']
    if ($type -ne 'dash-db') { continue }
    if (-not $uid.StartsWith($UidPrefix)) { continue }
    if ($exclude.ContainsKey($uid)) { continue }
    $targets.Add([PSCustomObject]@{
            uid        = $uid
            title      = [string]$item['title']
            folderUid  = [string]$item['folderUid']
            folderTitle = [string]$item['folderTitle']
        }) | Out-Null
}
$targets = @($targets | Sort-Object uid)
Write-Host ("Found {0} dashboards -> {1}" -f $targets.Count, $OutDir)

if ($targets.Count -eq 0) {
    throw "No dashboards matched prefix '$UidPrefix'."
}

$ok = 0
$fail = New-Object System.Collections.Generic.List[string]
$exportedPaths = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)

foreach ($t in $targets) {
    $uid = $t.uid
    $outPath = Get-DashboardOutPath -BaseDir $OutDir -Uid $uid -FolderUid $t.folderUid `
        -CollectorUid $CollectorFolderUid -CollectorDir $CollectorSubDir
    $rel = $outPath.Substring($OutDir.Length).TrimStart('\', '/')

    if (-not $PSCmdlet.ShouldProcess($uid, "Export dashboard to $rel")) {
        continue
    }

    try {
        $parent = Split-Path -Parent $outPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }

        $uri = "$base/api/dashboards/uid/$([uri]::EscapeDataString($uid))"
        $raw = (Invoke-WebRequest -Method GET -Uri $uri -Headers $headers -UseBasicParsing).Content
        $rootObj = [Newtonsoft.Json.Linq.JObject]::Parse($raw)
        $dash = [Newtonsoft.Json.Linq.JObject]$rootObj['dashboard']
        if ($null -eq $dash) { throw 'Response has no dashboard object.' }

        $null = $dash.Remove('id')

        $json = $dash.ToString([Newtonsoft.Json.Formatting]::Indented)
        $utf8 = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($outPath, $json + "`n", $utf8)

        $null = $exportedPaths.Add($outPath)
        $bytes = (Get-Item -LiteralPath $outPath).Length
        $panelCount = 0
        if ($dash['panels']) { $panelCount = @($dash['panels']).Count }
        $folderLabel = if ($t.folderUid -eq $CollectorFolderUid) { $CollectorSubDir } else { 'root' }
        Write-Host ("OK  [{0,-9}] {1,-40} panels={2,3}  {3,10:N0} B  {4}" -f $folderLabel, $uid, $panelCount, $bytes, $t.title)
        $ok++
    }
    catch {
        $msg = "$uid :: $($_.Exception.Message)"
        $fail.Add($msg) | Out-Null
        Write-Host "FAIL $msg"
    }
}

if ($RemoveOrphans) {
    Get-ChildItem -LiteralPath $OutDir -Filter "$UidPrefix*.json" -File -Recurse | ForEach-Object {
        if ($exportedPaths.Contains($_.FullName)) { return }
        if ($exclude.ContainsKey($_.BaseName)) { return }
        if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove orphan local dashboard JSON')) {
            Remove-Item -LiteralPath $_.FullName -Force
            Write-Host "REMOVED orphan $($_.FullName.Substring($OutDir.Length).TrimStart('\','/'))"
        }
    }
}

Write-Host ("DONE export ok={0} fail={1}" -f $ok, $fail.Count)
if ($fail.Count -gt 0) {
    $fail | ForEach-Object { Write-Host $_ }
    exit 1
}
