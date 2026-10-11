#Requires -Version 5.1
<#
.SYNOPSIS
  Creates the sql_exporter Windows login and the grants required by a profile.

.DESCRIPTION
  Runs scripts/sql/sql-exporter/Create-SqlExporterLogin.sql as a Windows login
  (@CreateSqlLogin = 0). Base server grants are always applied. msdb, user
  database, error log, SSISDB, and distribution grants follow the collector
  list. CONTROL SERVER is not granted.

  The script does not run unless -SqlInstance is supplied. Connects with
  System.Data.SqlClient from this process. Windows authentication is the
  default. Pass -SqlCredential for a SQL login. Encrypt is on.
  TrustServerCertificate matches the on-prem sql_exporter.yml default.

  The caller needs permission to create the login and grant the selected
  rights, typically sysadmin. The Windows service account must already exist
  on that instance's computer.

.EXAMPLE
  .\scripts\powershell\sql-exporter\Grant-SqlExporterProfileAccess.ps1 `
    -SqlInstance 'sql-host-01\DYNAMICSAX' `
    -LoginName 'NT SERVICE\prometheus_sql_exporter' `
    -CollectorSourcePath .\exporters\sql-exporter\profiles\oltp.yml

.EXAMPLE
  .\scripts\powershell\sql-exporter\Grant-SqlExporterProfileAccess.ps1 `
    -SqlInstance 'sql-host-01,49159','sql-host-02,49159' `
    -SqlCredential (Get-Credential) `
    -LoginName 'NT SERVICE\prometheus_sql_exporter' `
    -CollectorSourcePath .\exporters\sql-exporter\profiles\oltp.yml
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$SqlInstance,

    [pscredential]$SqlCredential,

    [Parameter(Mandatory = $true)]
    [string]$LoginName,

    [string]$CollectorSourcePath,

    [string[]]$Collector,

    [ValidateRange(30, 3600)]
    [int]$CommandTimeoutSec = 300,

    [bool]$TrustServerCertificate = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SqlExporterCollectorNames {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Collector source was not found: $Path"
    }

    $names = New-Object System.Collections.Generic.List[string]
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*-\s+(mssql_[A-Za-z0-9_*?]+)\s*(?:#.*)?$') {
            $names.Add($Matches[1])
        }
        elseif ($line -match '^\s*collectors:\s*\[([^\]]+)\]') {
            foreach ($part in ($Matches[1] -split ',')) {
                $token = $part.Trim().Trim("'").Trim('"')
                if ($token) { $names.Add($token) }
            }
        }
    }

    if ($names.Count -eq 0) {
        throw "No collectors were found in: $Path"
    }

    @($names)
}

function Get-SqlExporterGrantFlags {
    param([string[]]$Collectors)

    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $Collectors) {
        [void]$set.Add($name)
    }

    if (@($Collectors | Where-Object { $_ -match '[*?]' }).Count -gt 0) {
        return [pscustomobject]@{
            UserDatabase = $true
            Msdb         = $true
            ErrorLog     = $true
            Ssisdb       = $true
            Distribution = $true
        }
    }

    $hasCollector = {
        param([string[]]$Names)
        foreach ($name in $Names) {
            if ($set.Contains($name)) { return $true }
        }
        return $false
    }

    [pscustomobject]@{
        UserDatabase = & $hasCollector @(
            'mssql_database_configuration', 'mssql_database_integrity', 'mssql_stats',
            'mssql_query_store', 'mssql_columnstore', 'mssql_index_fragmentation',
            'mssql_index_usage', 'mssql_missing_index', 'mssql_cdc_change_tracking',
            'mssql_certificates', 'mssql_service_broker', 'mssql_schema_ddl'
        )
        Msdb = & $hasCollector @(
            'mssql_backup', 'mssql_restore', 'mssql_job_inventory', 'mssql_job_running',
            'mssql_job_failed', 'mssql_job_history', 'mssql_database_integrity',
            'mssql_cdc_change_tracking', 'mssql_security', 'mssql_replication'
        )
        ErrorLog = & $hasCollector @('mssql_errorlog_signals', 'mssql_security')
        Ssisdb = & $hasCollector @('mssql_ssis')
        Distribution = & $hasCollector @('mssql_replication')
    }
}

function Get-SqlExporterLoginBatch {
    param(
        [string]$Template,
        [string]$LoginName,
        $Flags
    )

    if ($LoginName -notmatch '^[^\[\]'';\r\n]+$') {
        throw "Login name contains unsupported characters: $LoginName"
    }

    $loginLiteral = "N'" + $LoginName.Replace("'", "''") + "'"
    $sql = $Template

    $replacements = @(
        @{
            Pattern = "(?m)^DECLARE @LoginName sysname = N'(?:[^']|'')*'; -- observability-sql-login:name\s*$"
            Value   = "DECLARE @LoginName sysname = $loginLiteral; -- observability-sql-login:name"
        }
        @{
            Pattern = '(?m)^DECLARE @CreateSqlLogin bit = [01]; -- observability-sql-login:create-sql-login\s*$'
            Value   = 'DECLARE @CreateSqlLogin bit = 0; -- observability-sql-login:create-sql-login'
        }
        @{
            Pattern = '(?m)^DECLARE @GrantUserDatabaseAccess bit = [01]; -- observability-sql-login:user-db\s*$'
            Value   = ('DECLARE @GrantUserDatabaseAccess bit = {0}; -- observability-sql-login:user-db' -f [int]$Flags.UserDatabase)
        }
        @{
            Pattern = '(?m)^DECLARE @GrantReadErrorLog bit = [01]; -- observability-sql-login:errorlog\s*$'
            Value   = ('DECLARE @GrantReadErrorLog bit = {0}; -- observability-sql-login:errorlog' -f [int]$Flags.ErrorLog)
        }
        @{
            Pattern = '(?m)^DECLARE @GrantMsdbRead bit = [01]; -- observability-sql-login:msdb\s*$'
            Value   = ('DECLARE @GrantMsdbRead bit = {0}; -- observability-sql-login:msdb' -f [int]$Flags.Msdb)
        }
        @{
            Pattern = '(?m)^DECLARE @GrantSsisdbRead bit = [01]; -- observability-sql-login:ssisdb\s*$'
            Value   = ('DECLARE @GrantSsisdbRead bit = {0}; -- observability-sql-login:ssisdb' -f [int]$Flags.Ssisdb)
        }
        @{
            Pattern = '(?m)^DECLARE @GrantDistributionRead bit = [01]; -- observability-sql-login:distribution\s*$'
            Value   = ('DECLARE @GrantDistributionRead bit = {0}; -- observability-sql-login:distribution' -f [int]$Flags.Distribution)
        }
    )

    foreach ($item in $replacements) {
        if ($sql -notmatch $item.Pattern) {
            throw "Create-SqlExporterLogin.sql is missing marker: $($item.Pattern)"
        }
        $replacement = $item.Value.Replace('$', '$$')
        $sql = [regex]::Replace($sql, $item.Pattern, $replacement)
    }

    $sql
}

$sqlPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\sql\sql-exporter\Create-SqlExporterLogin.sql'))
if (-not (Test-Path -LiteralPath $sqlPath -PathType Leaf)) {
    throw "SQL script not found: $sqlPath"
}

$collectors = @($Collector | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($collectors.Count -eq 0) {
    if ([string]::IsNullOrWhiteSpace($CollectorSourcePath)) {
        throw 'Pass -Collector or -CollectorSourcePath.'
    }
    $collectors = @(Get-SqlExporterCollectorNames -Path $CollectorSourcePath)
}

$flags = Get-SqlExporterGrantFlags -Collectors $collectors
$grantNames = @('server')
if ($flags.Msdb) { $grantNames += 'msdb' }
if ($flags.UserDatabase) { $grantNames += 'user-db' }
if ($flags.ErrorLog) { $grantNames += 'errorlog' }
if ($flags.Ssisdb) { $grantNames += 'ssisdb' }
if ($flags.Distribution) { $grantNames += 'distribution' }

Add-Type -AssemblyName System.Data

$template = [IO.File]::ReadAllText($sqlPath)
$batch = Get-SqlExporterLoginBatch -Template $template -LoginName $LoginName.Trim() -Flags $flags
$action = "Grant sql_exporter login $LoginName ($($grantNames -join ', '))"
$failures = New-Object System.Collections.Generic.List[string]

foreach ($instance in $SqlInstance) {
    $target = $instance.Trim()
    if (-not $target) {
        continue
    }

    if (-not $PSCmdlet.ShouldProcess($target, $action)) {
        continue
    }

    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder['Data Source'] = $target
    $builder['Application Name'] = 'observability-sql-exporter-login'
    $builder['Connect Timeout'] = 15
    $builder.Encrypt = $true
    $builder.TrustServerCertificate = [bool]$TrustServerCertificate

    if ($SqlCredential) {
        $builder['Integrated Security'] = $false
        $builder['User ID'] = $SqlCredential.UserName
        $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlCredential.Password)
        try {
            $builder['Password'] = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
        }
        finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
        }
    }
    else {
        $builder['Integrated Security'] = $true
    }

    $connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
    $connection.add_InfoMessage({
            param($sender, $eventArgs)
            if ($eventArgs.Message) {
                Write-Host $eventArgs.Message
            }
        })

    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandTimeout = $CommandTimeoutSec
        $command.CommandText = $batch
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        $table = New-Object System.Data.DataTable
        [void]$adapter.Fill($table)
        $command.Dispose()

        if ($table.Rows.Count -lt 1) {
            throw 'Create-SqlExporterLogin.sql returned no login row.'
        }

        [pscustomobject]@{
            SqlInstance = $target
            LoginName   = $LoginName.Trim()
            Grants      = ($grantNames -join ', ')
        }
    }
    catch {
        $failures.Add("$target : $($_.Exception.Message)")
        Write-Error -ErrorAction Continue "Failed on ${target}: $($_.Exception.Message)"
    }
    finally {
        if ($connection.State -ne 'Closed') {
            $connection.Close()
        }
        $connection.Dispose()
    }
}

if ($failures.Count -gt 0) {
    throw ("sql_exporter login was not created on {0} instance(s).`n{1}" -f $failures.Count, ($failures -join "`n"))
}
