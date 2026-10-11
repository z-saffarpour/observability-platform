#Requires -Version 5.1
<#
.SYNOPSIS
  Fills servers.csv from Prometheus scrape targets and exporter metrics.

.DESCRIPTION
  Reads an existing servers.csv inventory file, queries Prometheus for active
  targets and role-specific SQL/Windows exporter metrics, then updates:
    - DataArea from the owner label (OKCS / FMR)
    - SQL Profile from sql_exporter collector signatures
    - Windows Profile from windows_exporter collector signatures

  Existing servers are preserved. Servers present in Prometheus but missing from
  the CSV are not added automatically; run a separate inventory step first if
  needed.

.PARAMETER CsvPath
  Path to servers.csv. Default: C:\Dump\servers.csv

.PARAMETER PrometheusUrl
  Prometheus query API base URL. Default: http://10.192.30.14:9090/api/v1/query

.EXAMPLE
  .\scripts\powershell\common\Update-ServersCsvFromPrometheus.ps1

.EXAMPLE
  .\scripts\powershell\common\Update-ServersCsvFromPrometheus.ps1 `
    -CsvPath D:\inventory\servers.csv `
    -PrometheusUrl http://prometheus.example.com:9090/api/v1/query
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvPath = 'C:\Dump\servers.csv',

    [Parameter(Mandatory = $false)]
    [string]$PrometheusUrl = 'http://10.192.30.14:9090/api/v1/query'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-PrometheusQuery {
    param([Parameter(Mandatory = $true)][string]$Query)

    $response = Invoke-RestMethod -Uri $PrometheusUrl -Method Post -Body @{ query = $Query }
    return $response
}

function Get-PrometheusInstances {
    param([Parameter(Mandatory = $true)][string]$Query)

    $response = Invoke-PrometheusQuery -Query $Query
    $instances = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    if ($response.data.result) {
        foreach ($row in $response.data.result) {
            if ($row.metric.instance) {
                [void]$instances.Add(($row.metric.instance -split ':')[0])
            }
        }
    }

    return $instances
}

function Get-PrometheusOwnerMap {
    $response = Invoke-PrometheusQuery -Query @'
count by (instance, owner) ({job=~"sql_exporter|windows_exporter|telegraf_client"})
'@

    $owners = @{}
    if ($response.data.result) {
        foreach ($row in $response.data.result) {
            $instance = ($row.metric.instance -split ':')[0]
            if ($row.metric.owner) {
                $owners[$instance] = $row.metric.owner
            }
        }
    }

    return $owners
}

function Get-DataAreaFromOwner {
    param([string]$Owner)

    if ($Owner -match '^FMR') { return 'FMR' }
    return 'OKCS'
}

function Get-SqlProfileFromMetrics {
    param(
        [Parameter(Mandatory = $true)][string]$ShortName,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$SqlExporter,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$ServiceBroker,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$PolybaseEnabled,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$Restore,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$BufferPoolDatabase,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$HadrCluster,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$AlwaysOn,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$Replication,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$ReplicationPublication,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$SsisActive
    )

    if (-not $SqlExporter.Contains($ShortName)) { return '' }
    if ($ServiceBroker.Contains($ShortName)) { return 'service-broker.yml' }
    if ($PolybaseEnabled.Contains($ShortName)) { return 'polybase.yml' }
    if ($Restore.Contains($ShortName)) {
        if ($BufferPoolDatabase.Contains($ShortName)) { return 'dwh-restore.yml' }
        return 'restore-secondary.yml'
    }
    # Role signatures win over generic AG. Those profiles now include the HADR
    # collectors, so an AG warehouse or publisher must not be rewritten to
    # oltp-cluster.yml / oltp-alwayson.yml.
    if ($ReplicationPublication.Contains($ShortName) -or $Replication.Contains($ShortName)) {
        return 'replication.yml'
    }
    if ($SsisActive.Contains($ShortName) -and -not $BufferPoolDatabase.Contains($ShortName)) {
        return 'ssis.yml'
    }
    if ($BufferPoolDatabase.Contains($ShortName)) {
        if ($HadrCluster.Contains($ShortName) -or $AlwaysOn.Contains($ShortName)) {
            return 'dwh-alwayson.yml'
        }
        return 'dwh.yml'
    }
    if ($HadrCluster.Contains($ShortName)) { return 'oltp-cluster.yml' }
    if ($AlwaysOn.Contains($ShortName)) { return 'oltp-alwayson.yml' }
    return 'oltp.yml'
}

function Get-WindowsProfileFromMetrics {
    param(
        [Parameter(Mandatory = $true)][string]$ShortName,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$WindowsExporter,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$WindowsMssql,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$WindowsSsasProcess
    )

    if (-not $WindowsExporter.Contains($ShortName)) { return '' }

    $hasMssql = $WindowsMssql.Contains($ShortName)
    $hasSsas = $WindowsSsasProcess.Contains($ShortName)

    if ($hasSsas -and -not $hasMssql) { return 'ssas.yml' }
    if ($hasSsas -and $hasMssql) { return 'data-platform.yml' }
    if ($hasMssql) { return 'sql-server.yml' }
    return 'windows-base.yml'
}

if (-not (Test-Path -LiteralPath $CsvPath -PathType Leaf)) {
    throw "CSV file was not found: $CsvPath"
}

Write-Verbose "Querying Prometheus at $PrometheusUrl"

$ownerMap = Get-PrometheusOwnerMap
$sqlExporter = Get-PrometheusInstances -Query '{job="sql_exporter"}'
$windowsExporter = Get-PrometheusInstances -Query '{job="windows_exporter"}'
$windowsMssql = Get-PrometheusInstances -Query 'windows_mssql_sqlstats_batch_requests{job="windows_exporter"}'
$windowsSsasProcess = Get-PrometheusInstances -Query 'windows_process_cpu_time_total{job="windows_exporter",process=~"msmdsrv"}'
$hadrCluster = Get-PrometheusInstances -Query 'mssql_hadr_cluster_quorum_state{job="sql_exporter"}'
$alwaysOn = Get-PrometheusInstances -Query 'mssql_alwayson_replica_role{job="sql_exporter"}'
$replication = Get-PrometheusInstances -Query 'mssql_replication_is_distributor{job="sql_exporter"}'
$replicationPublication = Get-PrometheusInstances -Query 'mssql_replication_publication{job="sql_exporter"}'
$bufferPoolDatabase = Get-PrometheusInstances -Query 'mssql_buffer_pool_database_pages{job="sql_exporter"}'
$restore = Get-PrometheusInstances -Query 'mssql_restore_lag_seconds{job="sql_exporter"}'
$polybaseEnabled = Get-PrometheusInstances -Query 'mssql_polybase_enabled{job="sql_exporter"} == 1'
$ssisActive = Get-PrometheusInstances -Query 'mssql_ssis_packages{job="sql_exporter"} > 0'
$serviceBroker = Get-PrometheusInstances -Query 'mssql_service_broker_enabled{job="sql_exporter"}'

$lines = Get-Content -LiteralPath $CsvPath
if ($lines.Count -lt 2) {
    throw "CSV file must contain a header row and at least one server: $CsvPath"
}

$rows = $lines[1..($lines.Count - 1)] |
    Where-Object { $_.Trim() } |
    ForEach-Object {
        $parts = $_ -split ',', 4
        [PSCustomObject]@{
            Server            = $parts[0]
            DataArea          = $parts[1]
            'SQL Profile'     = $parts[2]
            'Windows Profile' = $parts[3]
        }
    }

$output = [System.Collections.Generic.List[string]]::new()
[void]$output.Add('Server,DataArea,SQL Profile,Windows Profile')

foreach ($row in ($rows | Sort-Object Server)) {
    $shortName = ($row.Server -split '\.')[0]
    $owner = $ownerMap[$shortName]
    $dataArea = if ($owner) { Get-DataAreaFromOwner -Owner $owner } else { $row.DataArea }
    $sqlProfile = Get-SqlProfileFromMetrics `
        -ShortName $shortName `
        -SqlExporter $sqlExporter `
        -ServiceBroker $serviceBroker `
        -PolybaseEnabled $polybaseEnabled `
        -Restore $restore `
        -BufferPoolDatabase $bufferPoolDatabase `
        -HadrCluster $hadrCluster `
        -AlwaysOn $alwaysOn `
        -Replication $replication `
        -ReplicationPublication $replicationPublication `
        -SsisActive $ssisActive
    $windowsProfile = Get-WindowsProfileFromMetrics `
        -ShortName $shortName `
        -WindowsExporter $windowsExporter `
        -WindowsMssql $windowsMssql `
        -WindowsSsasProcess $windowsSsasProcess

    [void]$output.Add("$($row.Server),$dataArea,$sqlProfile,$windowsProfile")
}

if ($PSCmdlet.ShouldProcess($CsvPath, 'Update server inventory from Prometheus')) {
    $output | Set-Content -LiteralPath $CsvPath -Encoding UTF8
}

Write-Host "Updated $($rows.Count) servers in $CsvPath"
