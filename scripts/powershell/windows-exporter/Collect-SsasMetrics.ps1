#Requires -Version 5.1
<#
.SYNOPSIS
  Exports SSAS Tabular and Multidimensional health/security metrics for windows_exporter.
.DESCRIPTION
  Uses the SSAS ADOMD client for DMVs and AMO for role membership. Active session
  breakdowns include login, application, and database labels. The output file is replaced
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
$script:SeriesKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$script:DuplicateSeries = 0

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
    $seriesKey = '{0}{1}' -f $Name,(Labels $Label)
    if (-not $script:SeriesKeys.Add($seriesKey)) {
        $script:DuplicateSeries++
        return
    }
    $Lines.Add(('{0} {1}' -f $seriesKey,$Value.ToString('R',$inv)))
}
function Unix([object]$Value) {
    if ($null -eq $Value -or $Value -is [DBNull]) { return 0 }
    try { [DateTimeOffset]::new(([datetime]$Value).ToUniversalTime()).ToUnixTimeSeconds() } catch { 0 }
}
function Query([object]$Connection,[string]$Text) {
    $cmd = $Connection.CreateCommand(); $cmd.CommandText = $Text; $cmd.CommandTimeout = $CommandTimeoutSec
    $adapter = [Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter]::new($cmd)
    $table = [Data.DataTable]::new(); [void]$adapter.Fill($table); ,$table
}
function Field([Data.DataRow]$Row,[string[]]$Names,[object]$Default = $null) {
    foreach ($name in $Names) { if ($Row.Table.Columns.Contains($name) -and $Row[$name] -isnot [DBNull]) { return $Row[$name] } }
    $Default
}
function Get-SessionDatabase([Data.DataRow]$Session) {
    $db = [string](Field $Session @(
        'SESSION_CURRENT_DATABASE',
        'SESSION_CATALOG_NAME',
        'CATALOG_NAME',
        'SessionCurrentDatabase',
        'SessionCatalogName'
    ))
    if ([string]::IsNullOrWhiteSpace($db)) { return 'unknown' }
    $db
}
function Get-ConnectionClientHost([Data.DataRow]$Connection) {
    $hostName = [string](Field $Connection @(
        'CONNECTION_HOST_NAME',
        'CONNECTION_CLIENT_HOST_NAME',
        'CLIENT_HOST_NAME'
    ))
    if ([string]::IsNullOrWhiteSpace($hostName)) { return 'unknown' }
    $hostOnly = ($hostName -split ':', 2)[0].Trim()
    if ($hostOnly) { return $hostOnly }
    'unknown'
}
function Get-ConnectionApplication([Data.DataRow]$Connection) {
    $app = [string](Field $Connection @(
        'CONNECTION_HOST_APPLICATION',
        'CONNECTION_CLIENT_APPLICATION_NAME',
        'CLIENT_APPLICATION_NAME'
    ))
    if (-not [string]::IsNullOrWhiteSpace($app)) { return $app.Trim() }
    $hostName = [string](Field $Connection @('CONNECTION_HOST_NAME', 'CONNECTION_CLIENT_HOST_NAME'))
    if (-not [string]::IsNullOrWhiteSpace($hostName)) {
        $hostOnly = ($hostName -split ':', 2)[0]
        if ($hostOnly) { return "client@$hostOnly" }
    }
    'unknown'
}
function Get-SessionClientHost([Data.DataRow]$Session, [hashtable]$ClientHostsByConnection) {
    $hostName = [string](Field $Session @(
        'SESSION_CLIENT_HOST_NAME',
        'SESSION_HOST_NAME',
        'CLIENT_HOST_NAME'
    ))
    if (-not [string]::IsNullOrWhiteSpace($hostName)) {
        return ($hostName -split ':', 2)[0].Trim()
    }
    $connectionId = [string](Field $Session @('SESSION_CONNECTION_ID'))
    if ($connectionId -and $ClientHostsByConnection.ContainsKey($connectionId)) {
        return $ClientHostsByConnection[$connectionId]
    }
    'unknown'
}
function Get-SessionLogin([Data.DataRow]$Session) {
    $login = [string](Field $Session @('SESSION_USER_NAME', 'SESSION_USER'))
    if ([string]::IsNullOrWhiteSpace($login)) { return 'unknown' }
    $login.Trim()
}
function Get-SessionApplication([Data.DataRow]$Session, [hashtable]$ApplicationsByConnection) {
    $app = [string](Field $Session @('SESSION_CLIENT_APPLICATION_NAME', 'SESSION_APPLICATION_NAME'))
    if (-not [string]::IsNullOrWhiteSpace($app)) { return $app.Trim() }
    $connectionId = [string](Field $Session @('SESSION_CONNECTION_ID'))
    if ($connectionId -and $ApplicationsByConnection.ContainsKey($connectionId)) {
        return $ApplicationsByConnection[$connectionId]
    }
    'unknown'
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
function Get-ProcessedUnix([object]$Object) {
    foreach ($propName in @('LastProcessed', 'LastIncrementalProcessed', 'RefreshedTime')) {
        try {
            $prop = $Object.$propName
            if ($null -eq $prop) { continue }
            if ($prop -is [datetime] -and $prop.Year -gt 1900) { return (Unix $prop) }
        } catch {}
    }
    0
}
function Convert-ToObjectArray([object]$Value) {
    if ($null -eq $Value) { return @() }
    if ($Value -is [string]) { return @($Value) }
    try {
        if ($Value -is [System.Collections.IEnumerable]) {
            return @($Value | ForEach-Object { $_ })
        }
    } catch {}
    return @($Value)
}
function Test-SsasDatabaseIsTabular([object]$Database) {
    try {
        if ($Database.CompatibilityLevel -ge 1200) { return $true }
        if (-not $Database.Model) { return $false }
        $tables = @($Database.Model.Tables | Where-Object { $_ })
        return $tables.Count -gt 0
    } catch {}
    $false
}
function Get-SsasServerInfoFromDiscover([Data.DataTable]$Props) {
    $mode = 'unknown'; $version = ''; $edition = ''
    foreach ($r in $Props.Rows) {
        $name = [string](Field $r @('PROPERTY_NAME', 'PropertyName', 'property_name'))
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        $value = [string](Field $r @('VALUE', 'Value', 'value'))
        if ($name -ieq 'ServerMode') { $mode = $value }
        elseif ($name -ieq 'ProductVersion') { $version = $value }
        elseif ($name -ieq 'Edition') { $edition = $value }
    }
    if ([string]::IsNullOrWhiteSpace($mode)) { $mode = 'unknown' }
    @{ mode = $mode; version = $version; edition = $edition }
}
function Merge-SsasServerInfo([hashtable]$Primary, [hashtable]$Fallback) {
    if ($Primary.mode -eq 'unknown' -and $Fallback.mode -and $Fallback.mode -ne 'unknown') { $Primary.mode = $Fallback.mode }
    if ([string]::IsNullOrWhiteSpace($Primary.version) -and $Fallback.version) { $Primary.version = $Fallback.version }
    if ([string]::IsNullOrWhiteSpace($Primary.edition) -and $Fallback.edition) { $Primary.edition = $Fallback.edition }
    $Primary
}
function Add-SsasServerInfoMetric([Collections.Generic.List[string]]$Lines,[hashtable]$Base,[hashtable]$Info) {
    $labels = $Base + @{ mode = $(if ([string]::IsNullOrWhiteSpace($Info.mode)) { 'unknown' } else { $Info.mode }) }
    if (-not [string]::IsNullOrWhiteSpace($Info.version)) { $labels.version = $Info.version }
    if (-not [string]::IsNullOrWhiteSpace($Info.edition)) { $labels.edition = $Info.edition }
    Add-Metric $Lines 'ssas_server_info' 1 $labels
}
function Add-ObjectProcessingMetrics([Collections.Generic.List[string]]$Lines,[hashtable]$Base,[hashtable]$Labels,[double]$Processed,[int]$StaleAfterHours) {
    $stale = [int]($Processed -eq 0 -or ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $Processed) -gt ($StaleAfterHours * 3600))
    Add-Metric $Lines 'ssas_object_last_processed_timestamp_seconds' $Processed ($Base + $Labels)
    Add-Metric $Lines 'ssas_object_processing_stale' $stale ($Base + $Labels)
    $stale
}
function Get-MemoryObjectTotalBytes([Data.DataRow]$Row) {
    $objectMemory = (To-Double (Field $Row @('OBJECT_MEMORY_SHRINKABLE'))) +
        (To-Double (Field $Row @('OBJECT_MEMORY_NONSHRINKABLE'))) +
        (To-Double (Field $Row @('OBJECT_MEMORY_CHILD_SHRINKABLE'))) +
        (To-Double (Field $Row @('OBJECT_MEMORY_CHILD_NONSHRINKABLE')))
    if ($objectMemory -gt 0) { return $objectMemory }
    To-Double (Field $Row @('MemoryUsed', 'MEMORY_USED', 'MemoryAllocated', 'MEMORY_ALLOCATED', 'MEMORY_USAGE', 'MEMORY_BYTES', 'VALUE'))
}
function Get-MemoryObjectPath([Data.DataRow]$Row) {
    [string](Field $Row @('OBJECT_PARENT_PATH', 'ObjectParentPath'))
}
function Get-MemoryObjectGroup([Data.DataRow]$Row) {
    $group = [string](Field $Row @('OBJECT_GROUP', 'Group', 'GROUP') '')
    if ([string]::IsNullOrWhiteSpace($group)) { return 'ungrouped' }
    $group
}
function Get-DatabaseNameFromMemoryPath([string]$Path, [string[]]$KnownDatabases) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    foreach ($dbName in $KnownDatabases) {
        if ($Path -match "\.Databases\.$([regex]::Escape($dbName))(\.|$)") { return $dbName }
    }
    $null
}
function Export-ObjectMemoryUsageMetrics([Collections.Generic.List[string]]$Lines, [hashtable]$Base, [object]$Connection, [string[]]$DatabaseNames) {
    if (-not $DatabaseNames -or $DatabaseNames.Count -eq 0) { return }
    $queries = @(
        'SELECT * FROM $SYSTEM.DISCOVER_OBJECT_MEMORY_USAGE',
        'SELECT * FROM $SYSTEM.DISCOVER_MEMORY_OBJECT_USAGE',
        'SELECT * FROM $SYSTEM.DISCOVER_MEMORYUSAGE'
    )
    $memoryRows = $null
    foreach ($query in $queries) {
        try {
            $table = Query $Connection $query
            if ($table.Rows.Count -gt 0) {
                $memoryRows = @($table.Rows)
                break
            }
        } catch { }
    }
    if (-not $memoryRows -or $memoryRows.Count -eq 0) { return }

    $dbTotals = @{}
    $groupAgg = @{}
    foreach ($dbName in $DatabaseNames) { $dbTotals[$dbName] = 0.0 }

    foreach ($row in $memoryRows) {
        $path = Get-MemoryObjectPath $row
        if ([string]::IsNullOrWhiteSpace($path) -or $path -notmatch '\.Databases\.') { continue }
        $dbName = Get-DatabaseNameFromMemoryPath $path $DatabaseNames
        if (-not $dbName) {
            $dbName = [string](Field $row @('DATABASE_NAME', 'CATALOG_NAME', 'DATABASE') '')
            if ($DatabaseNames -notcontains $dbName) { continue }
        }
        $bytes = Get-MemoryObjectTotalBytes $row
        if ($bytes -le 0) { continue }
        if (-not $dbTotals.ContainsKey($dbName)) { $dbTotals[$dbName] = 0.0 }
        $dbTotals[$dbName] += $bytes
        $group = Get-MemoryObjectGroup $row
        $key = '{0}|{1}' -f $dbName, $group
        if (-not $groupAgg.ContainsKey($key)) { $groupAgg[$key] = 0.0 }
        $groupAgg[$key] += $bytes
    }

    foreach ($dbName in $DatabaseNames) {
        if ($dbTotals[$dbName] -gt 0) {
            Add-Metric $Lines 'ssas_database_memory_bytes' $dbTotals[$dbName] ($Base + @{database=$dbName})
        }
    }
    foreach ($key in $groupAgg.Keys) {
        if ($groupAgg[$key] -le 0) { continue }
        $parts = $key -split '\|', 2
        Add-Metric $Lines 'ssas_memory_object_usage_bytes' $groupAgg[$key] ($Base + @{database=$parts[0]; object_group=$parts[1]})
    }
}
function Test-SsasCatalogIsTabular([string]$CompatibilityLevel) {
    try { return ([int]$CompatibilityLevel) -ge 1200 } catch {}
    $false
}
function Get-SsasAmoDatabase([object]$Server, [string]$DatabaseName) {
    try {
        if ($Server.Databases.Contains($DatabaseName)) { return $Server.Databases[$DatabaseName] }
    } catch {}
    try {
        $match = $Server.Databases.Find($DatabaseName)
        if ($match) { return $match }
    } catch {}
    try {
        foreach ($candidate in $Server.Databases) {
            if ([string]$candidate.Name -ieq $DatabaseName) { return $candidate }
        }
    } catch {}
    $null
}
function Get-TabularRolePermission([string]$ModelPermission, [string]$RoleName) {
    if ($ModelPermission -match 'Administrator') { return 'administrator' }
    if ($ModelPermission -match 'ReadRefresh') { return 'read_refresh' }
    if ($ModelPermission -match 'Refresh') { return 'refresh' }
    if ($ModelPermission -match 'Read') { return 'read' }
    if ($RoleName -match 'admin') { return 'administrator' }
    'read'
}
function Export-TabularDatabaseRoleMetricsFromDmv(
    [Collections.Generic.List[string]]$Lines,
    [hashtable]$Base,
    [string]$EndpointValue,
    [string]$DatabaseName,
    [Collections.Generic.HashSet[string]]$Privileged
) {
    $conn = $null
    try {
        $conn = [Microsoft.AnalysisServices.AdomdClient.AdomdConnection]::new("Data Source=$EndpointValue;Initial Catalog=$DatabaseName;Application Name=Prometheus SSAS Role Collector")
        $conn.Open()
        $roles = Query $conn 'SELECT [Name], [ModelPermission] FROM $SYSTEM.TMSCHEMA_ROLES'
        Add-Metric $Lines 'ssas_roles' $roles.Rows.Count ($Base + @{database=$DatabaseName})
        $membersByRole = @{}
        try {
            $membersTable = Query $conn 'SELECT [RoleName], [MemberName] FROM $SYSTEM.TMSCHEMA_ROLE_MEMBERSHIPS'
            foreach ($row in $membersTable.Rows) {
                $roleName = [string](Field $row @('RoleName','NAME'))
                $memberName = [string](Field $row @('MemberName','MEMBER_NAME'))
                if ([string]::IsNullOrWhiteSpace($roleName) -or [string]::IsNullOrWhiteSpace($memberName)) { continue }
                if (-not $membersByRole.ContainsKey($roleName)) { $membersByRole[$roleName] = [Collections.Generic.List[string]]::new() }
                [void]$membersByRole[$roleName].Add($memberName)
            }
        } catch {}
        foreach ($row in $roles.Rows) {
            $roleName = [string](Field $row @('Name','ROLE_NAME'))
            if ([string]::IsNullOrWhiteSpace($roleName)) { continue }
            $permission = Get-TabularRolePermission ([string](Field $row @('ModelPermission','MODEL_PERMISSION') '')) $roleName
            $members = if ($membersByRole.ContainsKey($roleName)) { @($membersByRole[$roleName]) } else { @() }
            Add-Metric $Lines 'ssas_role_members' $members.Count ($Base + @{database=$DatabaseName;role=$roleName;permission=$permission})
            Add-Metric $Lines 'ssas_database_role_members' $members.Count ($Base + @{database=$DatabaseName;role=$roleName;permission=$permission})
            if ($permission -eq 'administrator') { Add-Metric $Lines 'ssas_database_admin_role_members' $members.Count ($Base + @{database=$DatabaseName;role=$roleName}) }
            if ($permission -in @('process','refresh','read_refresh')) { Add-Metric $Lines 'ssas_process_role_members' $members.Count ($Base + @{database=$DatabaseName;role=$roleName}) }
            if ($permission -in @('administrator','process','readwrite','refresh','read_refresh')) {
                foreach ($m in $members) { if ($m) { [void]$Privileged.Add([string]$m) } }
            }
        }
    } catch {
        Add-Metric $Lines 'ssas_roles' 0 ($Base + @{database=$DatabaseName})
    } finally {
        if ($conn) { try { $conn.Dispose() } catch {} }
    }
}
function Export-CatalogRoleMetrics(
    [Collections.Generic.List[string]]$Lines,
    [hashtable]$Base,
    [string]$EndpointValue,
    [string]$DatabaseName,
    [string]$CompatibilityLevel,
    [object]$AmoDatabase,
    [Collections.Generic.HashSet[string]]$Privileged,
    [object]$Server = $null
) {
    if (Test-SsasCatalogIsTabular $CompatibilityLevel) {
        Export-TabularDatabaseRoleMetricsFromDmv $Lines $Base $EndpointValue $DatabaseName $Privileged
        return
    }
    $database = $AmoDatabase
    if ($Server -and $DatabaseName) {
        try {
            if ($Server.Databases.Contains($DatabaseName)) { $database = $Server.Databases[$DatabaseName] }
        } catch {}
    }
    if ($database) {
        Export-DatabaseRoleMetrics $Lines $Base $database $Privileged
        return
    }
    Add-Metric $Lines 'ssas_roles' 0 ($Base + @{database=$DatabaseName})
}
function Export-DatabaseProcessingMetrics([Collections.Generic.List[string]]$Lines,[hashtable]$Base,[object]$Database,[int]$StaleAfterHours) {
    try {
        Export-DatabaseProcessingMetricsCore $Lines $Base $Database $StaleAfterHours
    } catch {}
}
function Export-DatabaseProcessingMetricsCore([Collections.Generic.List[string]]$Lines,[hashtable]$Base,[object]$Database,[int]$StaleAfterHours) {
    $maxProcessed = 0.0
    $stalePartitions = 0
    $staleDimensions = 0
    $hasObjects = $false

    $isTabular = Test-SsasDatabaseIsTabular $Database

    if ($isTabular) {
        foreach ($table in Convert-ToObjectArray $Database.Model.Tables) {
            foreach ($partition in Convert-ToObjectArray $table.Partitions) {
                $processed = Get-ProcessedUnix $partition
                if ($processed -gt $maxProcessed) { $maxProcessed = $processed }
                $labels = @{
                    database = [string]$Database.Name
                    cube = [string]$Database.Name
                    measure_group = [string]$table.Name
                    object_name = [string]$partition.Name
                    object_type = 'partition'
                }
                if (Add-ObjectProcessingMetrics $Lines $Base $labels $processed $StaleAfterHours) { $stalePartitions++ }
                $hasObjects = $true
            }
        }
    } else {
        foreach ($cube in Convert-ToObjectArray $Database.Cubes) {
            foreach ($mg in Convert-ToObjectArray $cube.MeasureGroups) {
                foreach ($partition in Convert-ToObjectArray $mg.Partitions) {
                    $processed = Get-ProcessedUnix $partition
                    if ($processed -gt $maxProcessed) { $maxProcessed = $processed }
                    $labels = @{
                        database = [string]$Database.Name
                        cube = [string]$cube.Name
                        measure_group = [string]$mg.Name
                        object_name = [string]$partition.Name
                        object_type = 'partition'
                    }
                    if (Add-ObjectProcessingMetrics $Lines $Base $labels $processed $StaleAfterHours) { $stalePartitions++ }
                    $hasObjects = $true
                }
            }
            foreach ($dim in Convert-ToObjectArray $cube.Dimensions) {
                $processed = Get-ProcessedUnix $dim
                if ($processed -gt $maxProcessed) { $maxProcessed = $processed }
                $labels = @{
                    database = [string]$Database.Name
                    cube = [string]$cube.Name
                    measure_group = 'dimension'
                    object_name = [string]$dim.Name
                    object_type = 'dimension'
                }
                if (Add-ObjectProcessingMetrics $Lines $Base $labels $processed $StaleAfterHours) { $staleDimensions++ }
                $hasObjects = $true
            }
        }
    }

    if (-not $hasObjects) {
        $processed = Get-ProcessedUnix $Database
        if ($processed -gt 0) {
            $maxProcessed = $processed
            $labels = @{
                database = [string]$Database.Name
                cube = [string]$Database.Name
                measure_group = 'database'
                object_name = 'database'
                object_type = 'database'
            }
            if (Add-ObjectProcessingMetrics $Lines $Base $labels $processed $StaleAfterHours) { $stalePartitions++ }
            $hasObjects = $true
        }
    }

    $dbLabels = @{ database = [string]$Database.Name }
    Add-Metric $Lines 'ssas_database_last_processed_timestamp_seconds' $maxProcessed ($Base + $dbLabels)
    Add-Metric $Lines 'ssas_database_stale_partitions' $stalePartitions ($Base + $dbLabels)
    Add-Metric $Lines 'ssas_database_stale_dimensions' $staleDimensions ($Base + $dbLabels)
    Add-Metric $Lines 'ssas_database_processing_stale' ([int](($stalePartitions + $staleDimensions) -gt 0)) ($Base + $dbLabels)
}
function Get-SsasDatabaseRoles([object]$Database) {
    if (Test-SsasDatabaseIsTabular $Database) {
        try {
            $model = $Database.Model
            if (-not $model) { return @() }
            return Convert-ToObjectArray $model.Roles
        } catch { return @() }
    }
    try {
        $roles = [Collections.Generic.List[object]]::new()
        foreach ($role in $Database.Roles) { if ($role) { [void]$roles.Add($role) } }
        return @($roles)
    } catch { return @() }
}
function Get-SsasDatabaseRoleCount([object]$Database, [bool]$IsTabular) {
    $roles = @()
    try { $roles = @(Get-SsasDatabaseRoles $Database) } catch {}
    if ($roles.Count -gt 0) { return $roles.Count }
    if ($IsTabular) { return 0 }
    try {
        $roleIds = @($Database.DatabasePermissions | ForEach-Object { $_.RoleID } | Where-Object { $_ } | Sort-Object -Unique)
        return $roleIds.Count
    } catch { return 0 }
}
function Get-SsasRolePermission([object]$Role, [object]$Database, [bool]$IsTabular) {
    if ($IsTabular) {
        try {
            $permission = [string]$Role.ModelPermission
            if ($permission -match 'Administrator') { return 'administrator' }
            if ($permission -match 'ReadRefresh') { return 'read_refresh' }
            if ($permission -match 'Refresh') { return 'refresh' }
            if ($permission -match 'Read') { return 'read' }
        } catch {}
        if ($Role.Name -match 'admin') { return 'administrator' }
        return 'read'
    }
    try {
        $dbp = @($Database.DatabasePermissions | ForEach-Object { $_ }) | Where-Object { $_ -and $_.RoleID -eq $Role.ID } | Select-Object -First 1
        if ($dbp) {
            if ($dbp.Administer) { return 'administrator' }
            if ($dbp.Process) { return 'process' }
            if ([string]$dbp.Read -match 'ReadWrite') { return 'readwrite' }
        }
    } catch {}
    if ($Role.Name -match 'admin') { return 'administrator' }
    return 'read'
}
function Export-DatabaseRoleMetrics(
    [Collections.Generic.List[string]]$Lines,
    [hashtable]$Base,
    [object]$Database,
    [Collections.Generic.HashSet[string]]$Privileged
) {
    $dbName = ''
    try { $dbName = [string]$Database.Name } catch { return }
    $isTabular = $false
    try { $isTabular = Test-SsasDatabaseIsTabular $Database } catch {}
    $roleItems = @()
    try { $roleItems = @(Get-SsasDatabaseRoles $Database) } catch {}
    Add-Metric $Lines 'ssas_roles' (Get-SsasDatabaseRoleCount $Database $isTabular) ($Base + @{database=$dbName})
    foreach ($role in $roleItems) {
        if ($null -eq $role) { continue }
        try {
            $members = Convert-ToObjectArray $role.Members
            $permission = Get-SsasRolePermission $role $Database $isTabular
            Add-Metric $Lines 'ssas_role_members' $members.Count ($Base + @{database=$dbName;role=$role.Name;permission=$permission})
            Add-Metric $Lines 'ssas_database_role_members' $members.Count ($Base + @{database=$dbName;role=$role.Name;permission=$permission})
            if ($permission -eq 'administrator') { Add-Metric $Lines 'ssas_database_admin_role_members' $members.Count ($Base + @{database=$dbName;role=$role.Name}) }
            if ($permission -in @('process','refresh','read_refresh')) { Add-Metric $Lines 'ssas_process_role_members' $members.Count ($Base + @{database=$dbName;role=$role.Name}) }
            if ($permission -eq 'readwrite') { Add-Metric $Lines 'ssas_readwrite_role_members' $members.Count ($Base + @{database=$dbName;role=$role.Name}) }
            if ($permission -in @('administrator','process','readwrite','refresh','read_refresh')) {
                foreach ($m in $members) { if ($m) { [void]$Privileged.Add([string]$m) } }
            }
        } catch {}
    }
}

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
        "$env:ProgramFiles\Microsoft SQL Server\*\SDK\Assemblies\Microsoft.AnalysisServices.AdomdClient.dll",
        "$env:WINDIR\Microsoft.NET\assembly\GAC_MSIL\Microsoft.AnalysisServices.AdomdClient\*\Microsoft.AnalysisServices.AdomdClient.dll"
    )
    try { Import-SsasAssembly 'Microsoft.AnalysisServices.Core' @("$env:ProgramFiles\Microsoft SQL Server\*\SDK\Assemblies\Microsoft.AnalysisServices.Core.dll","$env:WINDIR\Microsoft.NET\assembly\GAC_MSIL\Microsoft.AnalysisServices.Core\*\Microsoft.AnalysisServices.Core.dll") } catch { }
    try { Import-SsasAssembly 'Microsoft.AnalysisServices' @("$env:ProgramFiles\Microsoft SQL Server\*\SDK\Assemblies\Microsoft.AnalysisServices.dll","$env:WINDIR\Microsoft.NET\assembly\GAC_MSIL\Microsoft.AnalysisServices\*\Microsoft.AnalysisServices.dll") } catch { $errors++ }

    foreach ($target in $Instance) {
        $base = @{ ssas_instance = $target }
        $endpointValue = Find-Endpoint $target
        $conn = [Microsoft.AnalysisServices.AdomdClient.AdomdConnection]::new("Data Source=$endpointValue;Application Name=Prometheus SSAS Collector")
        try {
            $probeFile=Find-ProbeFile $target;$probeMode=if($probeFile){'dedicated_readonly'}else{'collector_identity'};$probeString=if($probeFile){Get-Content -Raw -LiteralPath $probeFile}else{"Data Source=$endpointValue;Application Name=Prometheus SSAS ReadOnly Probe"};$probeStarted=Get-Date
            try{$probe=[Microsoft.AnalysisServices.AdomdClient.AdomdConnection]::new($probeString.Trim());$probe.Open();$probeTable=Query $probe 'SELECT * FROM $SYSTEM.DBSCHEMA_CATALOGS';Add-Metric $lines 'ssas_readonly_probe_success' 1 ($base+@{probe_mode=$probeMode});$probe.Close();$probe.Dispose()}catch{Add-Metric $lines 'ssas_readonly_probe_success' 0 ($base+@{probe_mode=$probeMode})}
            Add-Metric $lines 'ssas_readonly_probe_response_seconds' ((Get-Date)-$probeStarted).TotalSeconds ($base+@{probe_mode=$probeMode})
            $conn.Open()
            $props = Query $conn 'SELECT * FROM $SYSTEM.DISCOVER_PROPERTIES'
            $serverInfo = Get-SsasServerInfoFromDiscover $props
            try {
                if ([string]::IsNullOrWhiteSpace($serverInfo.version) -and $conn.ServerVersion) {
                    $serverInfo.version = [string]$conn.ServerVersion
                }
            } catch {}
            Add-Metric $lines 'ssas_up' 1 $base

            $catalogs = Query $conn 'SELECT * FROM $SYSTEM.DBSCHEMA_CATALOGS'
            Add-Metric $lines 'ssas_databases' $catalogs.Rows.Count $base
            $catalogDatabaseNames = [Collections.Generic.List[string]]::new()
            $databaseCompatibilityLevels = @{}
            foreach ($r in $catalogs.Rows) {
                $db = [string](Field $r @('CATALOG_NAME'))
                $compat = [string](Field $r @('COMPATIBILITY_LEVEL') '')
                [void]$catalogDatabaseNames.Add($db)
                $databaseCompatibilityLevels[$db] = $compat
                $labels = $base + @{ database=$db; compatibility_level=[string](Field $r @('COMPATIBILITY_LEVEL') '') }
                Add-Metric $lines 'ssas_database_info' 1 $labels
                Add-Metric $lines 'ssas_database_last_modified_timestamp_seconds' (Unix (Field $r @('DATE_MODIFIED','LAST_SCHEMA_UPDATE'))) ($base + @{database=$db})
            }

            $connections = Query $conn 'SELECT * FROM $SYSTEM.DISCOVER_CONNECTIONS'
            $applicationsByConnection = @{}
            $clientHostsByConnection = @{}
            foreach ($connection in $connections.Rows) {
                $connectionId = [string](Field $connection @('CONNECTION_ID'))
                if ($connectionId) {
                    $applicationsByConnection[$connectionId] = Get-ConnectionApplication $connection
                    $clientHostsByConnection[$connectionId] = Get-ConnectionClientHost $connection
                }
            }
            Add-Metric $lines 'ssas_connections' $connections.Rows.Count $base
            Add-Metric $lines 'ssas_active_connections' $connections.Rows.Count $base

            $sessions = Query $conn 'SELECT * FROM $SYSTEM.DISCOVER_SESSIONS'
            $users = @($sessions.Rows | ForEach-Object { [string](Field $_ @('SESSION_USER_NAME','SESSION_USER')) } | Where-Object { $_ } | Sort-Object -Unique)
            Add-Metric $lines 'ssas_sessions' $sessions.Rows.Count $base
            Add-Metric $lines 'ssas_active_sessions' $sessions.Rows.Count $base
            Add-Metric $lines 'ssas_unique_logins' $users.Count $base
            Add-Metric $lines 'ssas_active_users' $users.Count $base
            $long=0;$idle=0
            $byDb=@{};$byApp=@{};$byLoginAppDb=@{}
            foreach($session in $sessions.Rows){
                $elapsed=To-Double (Field $session @('SESSION_ELAPSED_TIME_MS','SESSION_DURATION_MS'))
                $idleMs=To-Double (Field $session @('SESSION_IDLE_TIME_MS','SESSION_LAST_COMMAND_ELAPSED_TIME_MS'))
                if($elapsed -ge $LongSessionMinutes*60000){$long++};if($idleMs -ge $IdleSessionMinutes*60000){$idle++}
                $db = Get-SessionDatabase $session; if (-not $byDb.ContainsKey($db)) { $byDb[$db] = 0 }; $byDb[$db]++
                $app = Get-SessionApplication $session $applicationsByConnection
                if(-not $byApp.ContainsKey($app)){$byApp[$app]=0};$byApp[$app]++
                $login = Get-SessionLogin $session
                $clientHost = Get-SessionClientHost $session $clientHostsByConnection
                $loginAppDbKey = '{0}|{1}|{2}|{3}' -f $login, $app, $db, $clientHost
                if (-not $byLoginAppDb.ContainsKey($loginAppDbKey)) { $byLoginAppDb[$loginAppDbKey] = 0 }
                $byLoginAppDb[$loginAppDbKey]++
            }
            Add-Metric $lines 'ssas_long_running_sessions' $long $base
            Add-Metric $lines 'ssas_idle_sessions' $idle $base
            foreach($key in $byDb.Keys){Add-Metric $lines 'ssas_sessions_by_database' $byDb[$key] ($base+@{database=$key})}
            foreach($key in $byApp.Keys){Add-Metric $lines 'ssas_sessions_by_application' $byApp[$key] ($base+@{application=$key})}
            foreach($key in $byLoginAppDb.Keys){
                $parts = $key -split '\|', 4
                Add-Metric $lines 'ssas_sessions_by_login' $byLoginAppDb[$key] ($base+@{login=$parts[0];application=$parts[1];database=$parts[2];client_host=$parts[3]})
            }
            Add-Metric $lines 'ssas_session_cpu_time_seconds_total' (($sessions.Rows | Measure-Object -Property SESSION_CPU_TIME_MS -Sum -ErrorAction SilentlyContinue).Sum / 1000) $base
            try {
                $commands = Query $conn 'SELECT * FROM $SYSTEM.DISCOVER_COMMANDS'
                Add-Metric $lines 'ssas_commands_active' $commands.Rows.Count $base
            } catch { $errors++ }

            try {
                $server = [Microsoft.AnalysisServices.Server]::new(); $server.Connect($endpointValue)
                $serverInfo = Merge-SsasServerInfo $serverInfo @{
                    mode = [string]$server.ServerMode
                    version = [string]$server.Version
                    edition = [string]$server.Edition
                }
                $admins = @(); if ($server.Roles) { foreach ($role in $server.Roles) { if ($role.Name -match 'admin') { $admins += @($role.Members) } } }
                Add-Metric $lines 'ssas_server_administrators' @($admins | Sort-Object -Unique).Count $base
                Add-Metric $lines 'ssas_server_admins' @($admins | Sort-Object -Unique).Count $base
                $implicitAdmin=0;try{$prop=$server.ServerProperties|Where-Object{$_.Name -eq 'BuiltinAdminsAreServerAdmins'}|Select-Object -First 1;if([string]$prop.Value -match '^(1|true)$'){$implicitAdmin=1}}catch{}
                Add-Metric $lines 'ssas_implicit_local_admin_enabled' $implicitAdmin $base
                $localAdminCount=0;if($implicitAdmin){try{$localAdminCount=@(Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop).Count}catch{}}
                Add-Metric $lines 'ssas_implicit_local_admin_members' $localAdminCount $base
                foreach($svc in $services){Add-Metric $lines 'ssas_service_account_is_direct_admin' ([int](@($admins)-contains [string]$svc.StartName)) ($base+@{service=$svc.Name;service_account=$svc.StartName})}
                $privileged = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
                $databaseNames = [Collections.Generic.List[string]]::new()
                foreach ($dbName in $catalogDatabaseNames) {
                    try {
                        [void]$databaseNames.Add($dbName)
                        $db = Get-SsasAmoDatabase $server $dbName
                        if (-not $db) {
                            Export-CatalogRoleMetrics $lines $base $endpointValue $dbName $databaseCompatibilityLevels[$dbName] $db $privileged $server
                            continue
                        }
                        Export-CatalogRoleMetrics $lines $base $endpointValue $dbName $databaseCompatibilityLevels[$dbName] $db $privileged $server
                        Export-DatabaseProcessingMetrics $lines $base $db $StaleAfterHours
                        # Tabular VertiPaq size via DMV; Multidimensional falls back to AMO EstimateSize.
                        $sizeExported = $false
                        $storageConn=$null;try{
                            if (Test-SsasCatalogIsTabular $databaseCompatibilityLevels[$dbName]) {
                                $storageConn=[Microsoft.AnalysisServices.AdomdClient.AdomdConnection]::new("Data Source=$endpointValue;Initial Catalog=$dbName;Application Name=Prometheus SSAS Storage Collector");$storageConn.Open()
                                $segments=Query $storageConn 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS';$aggregate=@{};$dbSizeBytes=0.0
                                foreach($segment in $segments.Rows){$tableId=[string](Field $segment @('TABLE_ID') 'unknown');$columnId=[string](Field $segment @('COLUMN_ID') 'unknown');$key="$tableId|$columnId";if(-not$aggregate.ContainsKey($key)){$aggregate[$key]=@{bytes=0.0;rows=0.0;segments=0}};$segmentBytes=To-Double(Field $segment @('USED_SIZE','ALLOCATED_SIZE'));$aggregate[$key].bytes+=$segmentBytes;$dbSizeBytes+=$segmentBytes;$aggregate[$key].rows+=To-Double(Field $segment @('RECORDS_COUNT'));$aggregate[$key].segments++}
                                foreach($key in $aggregate.Keys){$part=$key -split '\|',2;$l=$base+@{database=$dbName;table_id=$part[0];column_id=$part[1]};Add-Metric $lines 'ssas_tabular_object_size_bytes' $aggregate[$key].bytes $l;Add-Metric $lines 'ssas_tabular_object_rows' $aggregate[$key].rows $l;Add-Metric $lines 'ssas_tabular_object_segments' $aggregate[$key].segments $l}
                                if ($dbSizeBytes -gt 0) { Add-Metric $lines 'ssas_database_size_bytes' $dbSizeBytes ($base + @{database=$dbName}); $sizeExported = $true }
                                $storageConn.Close();$storageConn.Dispose();$storageConn=$null
                            }
                        }catch{if($storageConn){try{$storageConn.Dispose()}catch{}}}
                        if (-not $sizeExported) {
                            try {
                                $estimateSize = [double]$db.EstimateSize
                                if ($estimateSize -gt 0) {
                                    Add-Metric $lines 'ssas_database_size_bytes' $estimateSize ($base + @{database=$dbName})
                                }
                            } catch {}
                        }
                    } catch {
                        $errors++
                        try { Add-Metric $lines 'ssas_roles' 0 ($base + @{database=$dbName}) } catch {}
                    }
                }
                Export-ObjectMemoryUsageMetrics $lines $base $conn @($databaseNames)
                Add-Metric $lines 'ssas_high_privilege_logins' ($privileged.Count + @($admins | Sort-Object -Unique).Count) $base
                Add-Metric $lines 'ssas_privileged_active_sessions' @($sessions.Rows | Where-Object { $privileged.Contains([string](Field $_ @('SESSION_USER_NAME','SESSION_USER'))) }).Count $base
                $server.Disconnect()
            } catch { $errors++ }
            Add-SsasServerInfoMetric $lines $base $serverInfo
        } catch {
            $errors++; Add-Metric $lines 'ssas_up' 0 $base
        } finally { if ($conn.State -ne 'Closed') { $conn.Close() }; $conn.Dispose() }
    }
} catch { $errors++; foreach ($target in $Instance) { Add-Metric $lines 'ssas_up' 0 @{ssas_instance=$target} } }

foreach($path in $BackupPath){
    $file=Get-ChildItem -LiteralPath $path -File -Filter '*.abf' -ErrorAction SilentlyContinue|Sort-Object LastWriteTimeUtc -Descending|Select-Object -First 1
    Add-Metric $lines 'ssas_last_backup_timestamp_seconds' (if($file){[DateTimeOffset]::new($file.LastWriteTimeUtc).ToUnixTimeSeconds()}else{0}) @{backup_path=$path}
}

Add-Metric $lines 'ssas_collector_duplicate_series' $script:DuplicateSeries
Add-Metric $lines 'ssas_collector_errors' $errors
Add-Metric $lines 'ssas_collector_duration_seconds' ((Get-Date)-$started).TotalSeconds
Add-Metric $lines 'ssas_collector_last_run_timestamp_seconds' ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllLines($tmp,$lines,$utf8)
Move-Item -LiteralPath $tmp -Destination $OutputPath -Force
$state|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $StatePath -Encoding UTF8
if ($script:DuplicateSeries) { Write-Warning "Skipped $($script:DuplicateSeries) duplicate Prometheus series in ssas.prom." }
if ($errors) { Write-Warning "SSAS metrics completed with $errors partial error(s)." }
