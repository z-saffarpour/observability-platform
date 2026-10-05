#Requires -Version 5.1
<#
.SYNOPSIS
  Installs the database DDL Extended Events session, archive, and Agent job.

.DESCRIPTION
  Runs scripts/sql/sql-exporter/Install-DatabaseDdlArchive.sql on each SQL
  Server instance. The session records CREATE, ALTER, and DROP of databases,
  user tables, views, and procedures, including actor and client host.

  When -XelDirectory is omitted, the file is
  {drive}:\Databases\Temp\XEvent\observability_database_ddl.xel.
  The drive is the instance default data path, so it is not hardcoded.

  -AuditDatabase is the archive database on that same instance. It is created
  on the default data and log paths when missing, unless -CreateDatabase:$false.
  The job observability_database_ddl_ingest loads the event files every five
  minutes and deletes rows older than -RetentionDays (default 2555).

  The script does not run unless -SqlInstance is supplied. It does not delete
  XEL files or archive rows. -Uninstall drops the session and the job only.

  Connects with System.Data.SqlClient. Windows authentication is the default.
  The caller must be sysadmin.

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-DatabaseDdlArchive.ps1 `
    -SqlInstance 'sql-host-01' -AuditDatabase 'AuditDdl' -WhatIf

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-DatabaseDdlArchive.ps1 `
    -SqlInstance 'sql-host-01' -AuditDatabase 'AuditDdl' -RetentionDays 3650

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-DatabaseDdlArchive.ps1 `
    -SqlInstance 'sql-host-01' -AuditDatabase 'AuditDdl' -Uninstall
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$SqlInstance,

    [Parameter(Mandatory = $true)]
    [string]$AuditDatabase,

    [pscredential]$SqlCredential,

    [string]$XelDirectory,

    [ValidateRange(365, 36500)]
    [int]$RetentionDays = 2555,

    [bool]$CreateDatabase = $true,

    [switch]$Replace,

    [switch]$Uninstall,

    [ValidateRange(30, 900)]
    [int]$CommandTimeoutSec = 180,

    [bool]$TrustServerCertificate = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Replace -and $Uninstall) {
    throw 'Pass only one of -Replace or -Uninstall.'
}

if ([string]::IsNullOrWhiteSpace($AuditDatabase) -or $AuditDatabase -match '[''";\r\n\]\\]') {
    throw 'AuditDatabase must be a non-empty name without quotes, brackets, backslashes, or semicolons.'
}

if ($AuditDatabase -in @('master', 'model', 'msdb', 'tempdb')) {
    throw 'AuditDatabase must not be master, model, msdb, or tempdb.'
}

if ($PSBoundParameters.ContainsKey('XelDirectory')) {
    if ([string]::IsNullOrWhiteSpace($XelDirectory)) {
        throw 'XelDirectory is empty.'
    }
    $directoryOk = $XelDirectory -match '^[A-Za-z]:\\[^''";\r\n]*$' -or
        $XelDirectory -match '^\\\\[^''";\r\n]+\\[^''";\r\n]*$'
    if (-not $directoryOk) {
        throw 'XelDirectory must be a drive path (D:\SQLXE) or a UNC path, without quotes or semicolons.'
    }
}

$sqlPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\sql\sql-exporter\Install-DatabaseDdlArchive.sql'))
if (-not (Test-Path -LiteralPath $sqlPath -PathType Leaf)) {
    throw "SQL script not found: $sqlPath"
}

$action = "Install observability_database_ddl into $AuditDatabase"
if ($Uninstall) {
    $action = 'Uninstall observability_database_ddl'
}
elseif ($Replace) {
    $action = "Replace observability_database_ddl into $AuditDatabase"
}

function ConvertTo-SqlNvarcharLiteral {
    param([string]$Value)
    if ($null -eq $Value -or $Value -eq '') {
        return 'NULL'
    }
    return "N'" + $Value.Replace("'", "''") + "'"
}

function Get-DatabaseDdlArchiveSql {
    param(
        [string]$Template,
        [string]$DatabaseLiteral,
        [int]$Retention,
        [string]$DirectoryLiteral,
        [int]$CreateDatabaseFlag,
        [int]$ReplaceFlag,
        [int]$UninstallFlag
    )

    $markers = [ordered]@{
        'DECLARE @AuditDatabase sysname = N''''; -- observability-schema-ddl:database' = "DECLARE @AuditDatabase sysname = $DatabaseLiteral; -- observability-schema-ddl:database"
        'DECLARE @RetentionDays int = 2555; -- observability-schema-ddl:retention-days' = "DECLARE @RetentionDays int = $Retention; -- observability-schema-ddl:retention-days"
        'DECLARE @XelDirectory nvarchar(260) = NULL; -- observability-schema-ddl:directory' = "DECLARE @XelDirectory nvarchar(260) = $DirectoryLiteral; -- observability-schema-ddl:directory"
        'DECLARE @CreateDatabase bit = 1; -- observability-schema-ddl:create-database' = "DECLARE @CreateDatabase bit = $CreateDatabaseFlag; -- observability-schema-ddl:create-database"
        'DECLARE @Replace bit = 0; -- observability-schema-ddl:replace' = "DECLARE @Replace bit = $ReplaceFlag; -- observability-schema-ddl:replace"
        'DECLARE @Uninstall bit = 0; -- observability-schema-ddl:uninstall' = "DECLARE @Uninstall bit = $UninstallFlag; -- observability-schema-ddl:uninstall"
    }

    $sql = $Template
    foreach ($marker in $markers.Keys) {
        if ($sql.IndexOf($marker) -lt 0) {
            throw "SQL script is missing marker: $marker"
        }
        $sql = $sql.Replace($marker, $markers[$marker])
    }
    return $sql
}

Add-Type -AssemblyName System.Data

$template = [IO.File]::ReadAllText($sqlPath)
$directoryLiteral = ConvertTo-SqlNvarcharLiteral $(if ($PSBoundParameters.ContainsKey('XelDirectory')) { $XelDirectory } else { $null })
$batch = Get-DatabaseDdlArchiveSql `
    -Template $template `
    -DatabaseLiteral (ConvertTo-SqlNvarcharLiteral $AuditDatabase) `
    -Retention $RetentionDays `
    -DirectoryLiteral $directoryLiteral `
    -CreateDatabaseFlag ([int][bool]$CreateDatabase) `
    -ReplaceFlag ([int][bool]$Replace) `
    -UninstallFlag ([int][bool]$Uninstall)

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
    $builder['Application Name'] = 'observability-schema-ddl'
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
            throw 'The install script returned no status row.'
        }

        $row = $table.Rows[0]
        [pscustomobject]@{
            SqlInstance    = $target
            IsRunning      = [int]$row['is_running']
            SessionName    = [string]$row['session_name']
            XelFile        = [string]$row['xel_file']
            ObjectTypes    = [string]$row['object_types']
            AuditDatabase  = [string]$row['audit_database']
            JobName        = [string]$row['job_name']
            RetentionDays  = [int]$row['retention_days']
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
    throw ("Schema DDL archive was not applied on {0} instance(s).`n{1}" -f $failures.Count, ($failures -join "`n"))
}
