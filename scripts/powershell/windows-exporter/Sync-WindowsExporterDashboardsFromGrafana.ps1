#Requires -Version 5.1
<#
.SYNOPSIS
  Pull live Windows Exporter dashboards into grafana/dashboards/windows-exporter/.

.DESCRIPTION
  Exports role and/or collector dashboards from Grafana and writes
  provisioning-ready JSON under grafana/dashboards/.
  Strips volatile fields (id, version) so git diffs stay meaningful.

  Requires environment variables:
    GRAFANA_URL
    GRAFANA_SERVICE_ACCOUNT_TOKEN

.PARAMETER Scope
  Role      - role dashboards under grafana/dashboards/
  Collector - collector dashboards under grafana/dashboards/collector/
  All       - both (default)

.EXAMPLE
  .\scripts\powershell\windows-exporter\Sync-WindowsExporterDashboardsFromGrafana.ps1
.EXAMPLE
  .\scripts\powershell\windows-exporter\Sync-WindowsExporterDashboardsFromGrafana.ps1 -Scope Collector
.EXAMPLE
  .\scripts\powershell\windows-exporter\Sync-WindowsExporterDashboardsFromGrafana.ps1 -Scope Role
#>
[CmdletBinding()]
param(
    [ValidateSet('Role', 'Collector', 'All')]
    [string]$Scope = 'All'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$RoleDir = Join-Path $RepoRoot 'grafana\dashboards\windows-exporter'
$CollectorDir = Join-Path $RoleDir 'collector'

$GrafanaUrl = $env:GRAFANA_URL
$GrafanaToken = $env:GRAFANA_SERVICE_ACCOUNT_TOKEN
if ([string]::IsNullOrWhiteSpace($GrafanaUrl)) {
    throw 'GRAFANA_URL is missing.'
}
if ([string]::IsNullOrWhiteSpace($GrafanaToken)) {
    throw 'GRAFANA_SERVICE_ACCOUNT_TOKEN is missing.'
}

$RoleMap = [ordered]@{
    'winexp-00-overview-v02'       = 'winexp-00-overview-v02.json'
    'winexp-00-overview-v03'       = 'winexp-00-overview-v03.json'
    'winexp-00-dba-overview'       = 'winexp-00-dba-overview.json'
    'winexp-00-host-resources'     = 'winexp-00-host-resources.json'
    'winexp-00-mssql'              = 'winexp-00-mssql.json'
    'winexp-00-services-processes' = 'winexp-00-services-processes.json'
    'winexp-00-mssql-waits-ha'     = 'winexp-00-mssql-waits-ha.json'
    'winexp-00-ssas'               = 'winexp-00-ssas.json'
    'winexp-00-ax2012'             = 'winexp-00-ax2012.json'
    'winexp-00-cluster'            = 'winexp-00-cluster.json'
    'winexp-00-d365'               = 'winexp-00-d365.json'
    'winexp-00-terminal-server'    = 'winexp-00-terminal-server.json'
    'winexp-00-pbirs'              = 'winexp-00-pbirs.json'
}

$CollectorMap = [ordered]@{
    'winexp-col-cpu'               = 'winexp-col-cpu.json'
    'winexp-col-license'           = 'winexp-col-license.json'
    'winexp-col-logical-disk'      = 'winexp-col-logical-disk.json'
    'winexp-col-logon'             = 'winexp-col-logon.json'
    'winexp-col-memory'            = 'winexp-col-memory.json'
    'winexp-col-mscluster'         = 'winexp-col-mscluster.json'
    'winexp-col-mssql'             = 'winexp-col-mssql.json'
    'winexp-col-net'               = 'winexp-col-net.json'
    'winexp-col-os'                = 'winexp-col-os.json'
    'winexp-col-pagefile'          = 'winexp-col-pagefile.json'
    'winexp-col-physical-disk'     = 'winexp-col-physical-disk.json'
    'winexp-col-process'           = 'winexp-col-process.json'
    'winexp-col-service'           = 'winexp-col-service.json'
    'winexp-col-system'            = 'winexp-col-system.json'
    'winexp-col-tcp'               = 'winexp-col-tcp.json'
    'winexp-col-terminal-services' = 'winexp-col-terminal-services.json'
    'winexp-col-textfile'          = 'winexp-col-textfile.json'
    'winexp-col-time'              = 'winexp-col-time.json'
}

function Export-GrafanaDashboard {
    param(
        [Parameter(Mandatory)][string]$BaseUri,
        [Parameter(Mandatory)][hashtable]$Headers,
        [Parameter(Mandatory)][string]$Uid,
        [Parameter(Mandatory)][string]$OutPath
    )

    $resp = Invoke-RestMethod -Uri "$BaseUri/api/dashboards/uid/$Uid" -Method Get -Headers $Headers -TimeoutSec 120
    $dash = $resp.dashboard

    foreach ($prop in @('id', 'version')) {
        if ($dash.PSObject.Properties[$prop]) {
            $dash.PSObject.Properties.Remove($prop)
        }
    }

    $outDir = Split-Path -Parent $OutPath
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $json = $dash | ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText($OutPath, $json, [Text.UTF8Encoding]::new($false))

    [pscustomobject]@{
        Uid     = $Uid
        File    = Split-Path -Leaf $OutPath
        Title   = [string]$dash.title
        Panels  = @($dash.panels).Count
        Version = [string]$resp.meta.version
        Updated = [string]$resp.meta.updated
        Status  = 'ok'
        Error   = ''
    }
}

$headers = @{ Authorization = "Bearer $GrafanaToken" }
$baseUri = $GrafanaUrl.TrimEnd('/')
$jobs = [System.Collections.Generic.List[object]]::new()
$results = [System.Collections.Generic.List[object]]::new()

if ($Scope -in @('Role', 'All')) {
    foreach ($entry in $RoleMap.GetEnumerator()) {
        [void]$jobs.Add([pscustomobject]@{
            Uid      = [string]$entry.Key
            FileName = [string]$entry.Value
            OutDir   = $RoleDir
        })
    }
}

if ($Scope -in @('Collector', 'All')) {
    foreach ($entry in $CollectorMap.GetEnumerator()) {
        [void]$jobs.Add([pscustomobject]@{
            Uid      = [string]$entry.Key
            FileName = [string]$entry.Value
            OutDir   = $CollectorDir
        })
    }
}

Write-Host "Syncing $($jobs.Count) dashboard(s) from $baseUri (scope=$Scope)"

foreach ($job in $jobs) {
    $outPath = Join-Path $job.OutDir $job.FileName
    try {
        $row = Export-GrafanaDashboard -BaseUri $baseUri -Headers $headers -Uid $job.Uid -OutPath $outPath
        Write-Host ("OK  {0} -> {1} (v{2})" -f $job.Uid, $job.FileName, $row.Version)
    }
    catch {
        $row = [pscustomobject]@{
            Uid     = $job.Uid
            File    = $job.FileName
            Title   = ''
            Panels  = ''
            Version = ''
            Updated = ''
            Status  = 'error'
            Error   = $_.Exception.Message
        }
        Write-Host ("FAIL {0} -> {1} | {2}" -f $job.Uid, $job.FileName, $_.Exception.Message) -ForegroundColor Red
    }
    [void]$results.Add($row)
}

Write-Host ''
Write-Host '=== Sync Summary ==='
$results | Format-Table -AutoSize Uid, File, Title, Panels, Version, Status, Error

$failed = @($results | Where-Object Status -ne 'ok')
if ($failed.Count -gt 0) {
    throw ("Sync failed for {0} dashboard(s)." -f $failed.Count)
}

Write-Host ("Synced {0} dashboard(s) successfully." -f $results.Count)
