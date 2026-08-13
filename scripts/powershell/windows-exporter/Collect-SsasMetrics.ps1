#Requires -Version 5.1
<#
.SYNOPSIS
  Exports SSAS Tabular and Multidimensional health/security metrics for windows_exporter.
.DESCRIPTION
  Uses the SSAS ADOMD client for DMVs and AMO for role membership. It deliberately
  exports aggregate login counts rather than login names. The output file is replaced
  atomically, so windows_exporter never reads a partially written exposition.
#>
[CmdletBinding()]
param(
    [string[]]$Instance = @('localhost'),
    [string]$OutputPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'textfile_inputs\ssas.prom'),
    [string]$StatePath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'state\ssas-collector-state.json'),
    [string[]]$Endpoint = @(),
    [string[]]$BackupPath = @(),
    [string[]]$ReadOnlyProbeConnectionStringFile = @(),
    [ValidateRange(5,300)][int]$CommandTimeoutSec = 30,
    [ValidateRange(1,168)][int]$StaleAfterHours = 24,
    [ValidateRange(1,1440)][int]$LongSessionMinutes = 30,
    [ValidateRange(1,1440)][int]$IdleSessionMinutes = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture

function Import-SsasAssembly([string]$Name, [string[]]$Candidates) {
    try { Add-Type -AssemblyName $Name -ErrorAction Stop; return }
    catch {
        foreach ($path in $Candidates) {
            $resolved = Get-ChildItem $path -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
            if ($resolved) { Add-Type -Path $resolved.FullName -ErrorAction Stop; return }
        }
        throw "Required SSAS client assembly '$Name' was not found. Install Microsoft Analysis Services client libraries or the SqlServer PowerShell module."
    }
}

function Escape-Label([object]$Value) {
    if ($null -eq $Value -or $Value -is [DBNull]) { return '' }
    ([string]$Value).Replace('\','\\').Replace("`n",'\n').Replace('"','\"')
}
function Labels([hashtable]$Values) {
    if (-not $Values -or $Values.Count -eq 0) { return '' }
    '{' + (($Values.Keys | Sort-Object | ForEach-Object { '{0}="{1}"' -f $_,(Escape-Label $Values[$_]) }) -join ',') + '}'
}
function Add-Metric([Collections.Generic.List[string]]$Lines,[string]$Name,[double]$Value,[hashtable]$Label = @{}) {
    $Lines.Add(('{0}{1} {2}' -f $Name,(Labels $Label),$Value.ToString('R',$inv)))
}
function Unix([object]$Value) {
    if ($null -eq $Value -or $Value -is [DBNull]) { return 0 }
    try { [DateTimeOffset]::new(([datetime]$Value).ToUniversalTime()).ToUnixTimeSeconds() } catch { 0 }
}
function Query([object]$Connection,[string]$Text) {
    $cmd = $Connection.CreateCommand(); $cmd.CommandText = $Text; $cmd.CommandTimeout = $CommandTimeoutSec
    $adapter = [Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter]::new($cmd)
    $table = [Data.DataTable]::new(); [void]$adapter.Fill($table); $table
}
function Field([Data.DataRow]$Row,[string[]]$Names,[object]$Default = $null) {
    foreach ($name in $Names) { if ($Row.Table.Columns.Contains($name) -and $Row[$name] -isnot [DBNull]) { return $Row[$name] } }
    $Default
}
function To-Double([object]$Value,[double]$Default=0) {
    if ($null -eq $Value -or $Value -is [DBNull]) { return $Default }
    $result=0.0; if ([double]::TryParse([string]$Value,[Globalization.NumberStyles]::Any,$inv,[ref]$result)) { return $result }; $Default
}
function Find-Endpoint([string]$Target) {
    foreach ($item in $Endpoint) {
        $parts=$item -split '=',2
        if ($parts.Count -eq 2 -and $parts[0] -ieq $Target) { return $parts[1] }
    }
    $hostName=($Target -split '\\',2)[0]
    "$hostName`:2383"
}
function Find-ProbeFile([string]$Target){foreach($item in $ReadOnlyProbeConnectionStringFile){$parts=$item -split '=',2;if($parts.Count -eq 2 -and $parts[0] -ieq $Target){return $parts[1]}};$null}

$root = Split-Path $OutputPath -Parent
New-Item -ItemType Directory -Path $root -Force | Out-Null
$tmp = Join-Path $root ('.ssas.{0}.tmp' -f [guid]::NewGuid().ToString('N'))
$lines = [Collections.Generic.List[string]]::new()
$started = Get-Date
$errors = 0
$stateDir=Split-Path $StatePath -Parent; New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
$state=@{ services=@{} }
if(Test-Path -LiteralPath $StatePath){ try { $old=Get-Content -Raw $StatePath|ConvertFrom-Json; foreach($p in $old.services.PSObject.Properties){$state.services[$p.Name]=@{start=[string]$p.Value.start;restarts=[int64]$p.Value.restarts}} } catch{} }

# Windows service/process availability is independent of ADOMD/AMO availability.
$services=@(Get-CimInstance Win32_Service -Filter "Name='MSSQLServerOLAPService' OR Name LIKE 'MSOLAP$%'" -ErrorAction SilentlyContinue)
foreach($svc in $services){
    $svcLabels=@{service=$svc.Name;display_name=$svc.DisplayName}
    Add-Metric $lines 'ssas_service_running' ([int]($svc.State -eq 'Running')) $svcLabels
    $start=''; $uptime=0
    if($svc.ProcessId){ try{$proc=Get-Process -Id $svc.ProcessId -ErrorAction Stop;$start=$proc.StartTime.ToUniversalTime().ToString('o');$uptime=((Get-Date)-$proc.StartTime).TotalSeconds}catch{} }
    Add-Metric $lines 'ssas_service_uptime_seconds' $uptime $svcLabels
    $previous=$state.services[$svc.Name]; $restarts=if($previous){[int64]$previous.restarts}else{0}
    if($previous -and $start -and $previous.start -and $previous.start -ne $start){$restarts++}
    $state.services[$svc.Name]=@{start=$start;restarts=$restarts}
    Add-Metric $lines 'ssas_service_restarts_total' $restarts $svcLabels
}
foreach($target in $Instance){
    $base=@{ssas_instance=$target};$endpointValue=Find-Endpoint $target;$endpointParts=$endpointValue -split ':',2;$tcpOk=0;$tcpStarted=Get-Date
    try{$tcp=[Net.Sockets.TcpClient]::new();$async=$tcp.BeginConnect($endpointParts[0],[int]$endpointParts[1],$null,$null);if($async.AsyncWaitHandle.WaitOne($CommandTimeoutSec*1000)){$tcp.EndConnect($async);$tcpOk=1};$tcp.Dispose()}catch{}
    Add-Metric $lines 'ssas_endpoint_up' $tcpOk ($base+@{endpoint=$endpointValue});Add-Metric $lines 'ssas_endpoint_response_seconds' ((Get-Date)-$tcpStarted).TotalSeconds ($base+@{endpoint=$endpointValue})
}

try {
    Import-SsasAssembly 'Microsoft.AnalysisServices.AdomdClient' @(
        "$env:ProgramFiles\Microsoft.NET\ADOMD.NET\*\Microsoft.AnalysisServices.AdomdClient.dll",
        "$env:ProgramFiles\Microsoft SQL Server\*\SDK\Assemblies\Microsoft.AnalysisServices.AdomdClient.dll"
    )
    try { Import-SsasAssembly 'Microsoft.AnalysisServices.Core' @("$env:ProgramFiles\Microsoft SQL Server\*\SDK\Assemblies\Microsoft.AnalysisServices.Core.dll") } catch { }
    try { Import-SsasAssembly 'Microsoft.AnalysisServices' @("$env:ProgramFiles\Microsoft SQL Server\*\SDK\Assemblies\Microsoft.AnalysisServices.dll") } catch { $errors++ }

    foreach ($target in $Instance) {
        $base = @{ ssas_instance = $target }
        $conn = [Microsoft.AnalysisServices.AdomdClient.AdomdConnection]::new("Data Source=$target;Application Name=Prometheus SSAS Collector")
        try {
            $probeFile=Find-ProbeFile $target;$probeMode=if($probeFile){'dedicated_readonly'}else{'collector_identity'};$probeString=if($probeFile){Get-Content -Raw -LiteralPath $probeFile}else{"Data Source=$target;Application Name=Prometheus SSAS ReadOnly Probe"};$probeStarted=Get-Date
            try{$probe=[Microsoft.AnalysisServices.AdomdClient.AdomdConnection]::new($probeString.Trim());$probe.Open();$probeTable=Query $probe 'SELECT CATALOG_NAME FROM $SYSTEM.DBSCHEMA_CATALOGS';Add-Metric $lines 'ssas_readonly_probe_success' 1 ($base+@{probe_mode=$probeMode});$probe.Close();$probe.Dispose()}catch{Add-Metric $lines 'ssas_readonly_probe_success' 0 ($base+@{probe_mode=$probeMode})}
            Add-Metric $lines 'ssas_readonly_probe_response_seconds' ((Get-Date)-$probeStarted).TotalSeconds ($base+@{probe_mode=$probeMode})
            $conn.Open()
            $props = Query $conn 'SELECT * FROM $SYSTEM.DISCOVER_PROPERTIES'
            $mode = 'unknown'; $version = ''; $edition = ''
            foreach ($r in $props.Rows) {
                $n = [string](Field $r @('PROPERTY_NAME'))
                if ($n -eq 'ServerMode') { $mode = [string](Field $r @('VALUE')) }
                elseif ($n -eq 'ProductVersion') { $version = [string](Field $r @('VALUE')) }
                elseif ($n -eq 'Edition') { $edition = [string](Field $r @('VALUE')) }
            }
            Add-Metric $lines 'ssas_up' 1 $base
            Add-Metric $lines 'ssas_server_info' 1 ($base + @{ mode=$mode; version=$version; edition=$edition })

            $catalogs = Query $conn 'SELECT * FROM $SYSTEM.DBSCHEMA_CATALOGS'
            Add-Metric $lines 'ssas_databases' $catalogs.Rows.Count $base
            foreach ($r in $catalogs.Rows) {
                $db = [string](Field $r @('CATALOG_NAME'))
                $labels = $base + @{ database=$db; compatibility_level=[string](Field $r @('COMPATIBILITY_LEVEL') '') }
                Add-Metric $lines 'ssas_database_info' 1 $labels
                Add-Metric $lines 'ssas_database_last_modified_timestamp_seconds' (Unix (Field $r @('DATE_MODIFIED','LAST_SCHEMA_UPDATE'))) ($base + @{database=$db})
            }

            $sessions = Query $conn 'SELECT * FROM $SYSTEM.DISCOVER_SESSIONS'
            $users = @($sessions.Rows | ForEach-Object { [string](Field $_ @('SESSION_USER_NAME','SESSION_USER')) } | Where-Object { $_ } | Sort-Object -Unique)
            Add-Metric $lines 'ssas_sessions' $sessions.Rows.Count $base
            Add-Metric $lines 'ssas_active_sessions' $sessions.Rows.Count $base
            Add-Metric $lines 'ssas_unique_logins' $users.Count $base
            Add-Metric $lines 'ssas_active_users' $users.Count $base
            $long=0;$idle=0
            $byDb=@{};$byApp=@{}
            foreach($session in $sessions.Rows){
                $elapsed=To-Double (Field $session @('SESSION_ELAPSED_TIME_MS','SESSION_DURATION_MS'))
                $idleMs=To-Double (Field $session @('SESSION_IDLE_TIME_MS','SESSION_LAST_COMMAND_ELAPSED_TIME_MS'))
                if($elapsed -ge $LongSessionMinutes*60000){$long++};if($idleMs -ge $IdleSessionMinutes*60000){$idle++}
                $db=[string](Field $session @('SESSION_CATALOG_NAME','CATALOG_NAME') 'unknown');if(-not $byDb.ContainsKey($db)){$byDb[$db]=0};$byDb[$db]++
                $app=[string](Field $session @('SESSION_CLIENT_APPLICATION_NAME','SESSION_APPLICATION_NAME') 'unknown');if(-not $byApp.ContainsKey($app)){$byApp[$app]=0};$byApp[$app]++
            }
            Add-Metric $lines 'ssas_long_running_sessions' $long $base
            Add-Metric $lines 'ssas_idle_sessions' $idle $base
            foreach($key in $byDb.Keys){Add-Metric $lines 'ssas_sessions_by_database' $byDb[$key] ($base+@{database=$key})}
            foreach($key in $byApp.Keys){Add-Metric $lines 'ssas_sessions_by_application' $byApp[$key] ($base+@{application=$key})}
            Add-Metric $lines 'ssas_session_cpu_time_seconds_total' (($sessions.Rows | Measure-Object -Property SESSION_CPU_TIME_MS -Sum -ErrorAction SilentlyContinue).Sum / 1000) $base
            $connections = Query $conn 'SELECT * FROM $SYSTEM.DISCOVER_CONNECTIONS'
            Add-Metric $lines 'ssas_connections' $connections.Rows.Count $base
            Add-Metric $lines 'ssas_active_connections' $connections.Rows.Count $base

            try {
                $commands = Query $conn 'SELECT * FROM $SYSTEM.DISCOVER_COMMANDS'
                Add-Metric $lines 'ssas_commands_active' $commands.Rows.Count $base
            } catch { $errors++ }

            try {
                $server = [Microsoft.AnalysisServices.Server]::new(); $server.Connect($target)
                $admins = @(); if ($server.Roles) { foreach ($role in $server.Roles) { if ($role.Name -match 'admin') { $admins += @($role.Members) } } }
                Add-Metric $lines 'ssas_server_administrators' @($admins | Sort-Object -Unique).Count $base
                Add-Metric $lines 'ssas_server_admins' @($admins | Sort-Object -Unique).Count $base
                $implicitAdmin=0;try{$prop=$server.ServerProperties|Where-Object{$_.Name -eq 'BuiltinAdminsAreServerAdmins'}|Select-Object -First 1;if([string]$prop.Value -match '^(1|true)$'){$implicitAdmin=1}}catch{}
                Add-Metric $lines 'ssas_implicit_local_admin_enabled' $implicitAdmin $base
                $localAdminCount=0;if($implicitAdmin){try{$localAdminCount=@(Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop).Count}catch{}}
                Add-Metric $lines 'ssas_implicit_local_admin_members' $localAdminCount $base
                foreach($svc in $services){Add-Metric $lines 'ssas_service_account_is_direct_admin' ([int](@($admins)-contains [string]$svc.StartName)) ($base+@{service=$svc.Name;service_account=$svc.StartName})}
                $privileged = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
                foreach ($db in $server.Databases) {
                    $processed = 0
                    try { $processed = Unix $db.LastProcessed } catch {}
                    Add-Metric $lines 'ssas_database_last_processed_timestamp_seconds' $processed ($base + @{database=$db.Name})
                    Add-Metric $lines 'ssas_database_processing_stale' ([int]($processed -eq 0 -or ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()-$processed) -gt ($StaleAfterHours*3600))) ($base + @{database=$db.Name})
                    Add-Metric $lines 'ssas_roles' $db.Roles.Count ($base + @{database=$db.Name})
                    foreach ($role in $db.Roles) {
                        $members = @($role.Members)
                        $permission = 'read'
                        try {
                            if ($role.ModelPermission -match 'Administrator') { $permission='administrator' }
                            elseif ($role.ModelPermission -match 'ReadRefresh') { $permission='read_refresh' }
                            elseif ($role.ModelPermission -match 'Refresh') { $permission='refresh' }
                        } catch {
                            try{$dbp=@($db.DatabasePermissions)|Where-Object{$_.RoleID -eq $role.ID}|Select-Object -First 1;if($dbp.Administer){$permission='administrator'}elseif($dbp.Process){$permission='process'}elseif([string]$dbp.Read -match 'ReadWrite'){$permission='readwrite'}}catch{if ($role.Name -match 'admin') { $permission='administrator' }}
                        }
                        Add-Metric $lines 'ssas_role_members' $members.Count ($base + @{database=$db.Name;role=$role.Name;permission=$permission})
                        Add-Metric $lines 'ssas_database_role_members' $members.Count ($base + @{database=$db.Name;role=$role.Name;permission=$permission})
                        if($permission -eq 'administrator'){Add-Metric $lines 'ssas_database_admin_role_members' $members.Count ($base+@{database=$db.Name;role=$role.Name})}
                        if($permission -in @('process','refresh','read_refresh')){Add-Metric $lines 'ssas_process_role_members' $members.Count ($base+@{database=$db.Name;role=$role.Name})}
                        if($permission -eq 'readwrite'){Add-Metric $lines 'ssas_readwrite_role_members' $members.Count ($base+@{database=$db.Name;role=$role.Name})}
                        if ($permission -in @('administrator','process','readwrite','refresh','read_refresh')) { foreach ($m in $members) { [void]$privileged.Add([string]$m) } }
                    }
                    # Tabular-only VertiPaq storage metrics. Unsupported rowsets are a normal no-data case on multidimensional instances.
                    $storageConn=$null;try{
                        $storageConn=[Microsoft.AnalysisServices.AdomdClient.AdomdConnection]::new("Data Source=$target;Initial Catalog=$($db.Name);Application Name=Prometheus SSAS Storage Collector");$storageConn.Open()
                        $segments=Query $storageConn 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS';$aggregate=@{}
                        foreach($segment in $segments.Rows){$tableId=[string](Field $segment @('TABLE_ID') 'unknown');$columnId=[string](Field $segment @('COLUMN_ID') 'unknown');$key="$tableId|$columnId";if(-not$aggregate.ContainsKey($key)){$aggregate[$key]=@{bytes=0.0;rows=0.0;segments=0}};$aggregate[$key].bytes+=To-Double(Field $segment @('USED_SIZE','ALLOCATED_SIZE'));$aggregate[$key].rows+=To-Double(Field $segment @('RECORDS_COUNT'));$aggregate[$key].segments++}
                        foreach($key in $aggregate.Keys){$part=$key -split '\|',2;$l=$base+@{database=$db.Name;table_id=$part[0];column_id=$part[1]};Add-Metric $lines 'ssas_tabular_object_size_bytes' $aggregate[$key].bytes $l;Add-Metric $lines 'ssas_tabular_object_rows' $aggregate[$key].rows $l;Add-Metric $lines 'ssas_tabular_object_segments' $aggregate[$key].segments $l}
                        $storageConn.Close();$storageConn.Dispose()
                    }catch{if($storageConn){try{$storageConn.Dispose()}catch{}}}
                }
                Add-Metric $lines 'ssas_high_privilege_logins' ($privileged.Count + @($admins | Sort-Object -Unique).Count) $base
                Add-Metric $lines 'ssas_privileged_active_sessions' @($sessions.Rows | Where-Object { $privileged.Contains([string](Field $_ @('SESSION_USER_NAME','SESSION_USER'))) }).Count $base
                $server.Disconnect()
            } catch { $errors++ }
        } catch {
            $errors++; Add-Metric $lines 'ssas_up' 0 $base
        } finally { if ($conn.State -ne 'Closed') { $conn.Close() }; $conn.Dispose() }
    }
} catch { $errors++; foreach ($target in $Instance) { Add-Metric $lines 'ssas_up' 0 @{ssas_instance=$target} } }

foreach($path in $BackupPath){
    $file=Get-ChildItem -LiteralPath $path -File -Filter '*.abf' -ErrorAction SilentlyContinue|Sort-Object LastWriteTimeUtc -Descending|Select-Object -First 1
    Add-Metric $lines 'ssas_last_backup_timestamp_seconds' (if($file){[DateTimeOffset]::new($file.LastWriteTimeUtc).ToUnixTimeSeconds()}else{0}) @{backup_path=$path}
}

Add-Metric $lines 'ssas_collector_errors' $errors
Add-Metric $lines 'ssas_collector_duration_seconds' ((Get-Date)-$started).TotalSeconds
Add-Metric $lines 'ssas_collector_last_run_timestamp_seconds' ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllLines($tmp,$lines,$utf8)
Move-Item -LiteralPath $tmp -Destination $OutputPath -Force
$state|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $StatePath -Encoding UTF8
if ($errors) { Write-Warning "SSAS metrics completed with $errors partial error(s)." }
