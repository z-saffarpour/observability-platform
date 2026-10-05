#Requires -Version 5.1
<#
.SYNOPSIS
  Installs or removes the observability_server_ddl Extended Events session.

.DESCRIPTION
  Runs scripts/sql/sql-exporter/Install-ServerDdlEventSession.sql on each
  SQL Server instance. The session records CREATE and DROP of server-scoped
  objects (event sessions, audits, credentials, endpoints, and related
  types), ALTER of event sessions including STATE = START/STOP, and
  sp_configure error 15457. Statement text is stored only for event-session
  alters. Credential batches are not stored.

  When -XelDirectory is omitted, files go under
  {drive}:\Databases\Temp\XEvent\Machine\Instance\observability_server_ddl\.
  The drive is the instance default data path, so it is not hardcoded.

  The script does not run unless -SqlInstance is supplied. It does not delete
  XEL files. -Replace recreates an existing session. -Uninstall stops and drops
  the session.

  Connects with System.Data.SqlClient. Windows authentication is the default.
  Encrypt is on. TrustServerCertificate matches the on-prem sql_exporter.yml
  default; pass -TrustServerCertificate:$false when the instance certificate
  is issued by a trusted CA.

  The caller needs ALTER ANY EVENT SESSION. This script is not part of
  Deploy-Collectors.ps1 and does not restart sql_exporter.

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-ServerDdlEventSession.ps1 `
    -SqlInstance 'sql-host-01' -WhatIf

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-ServerDdlEventSession.ps1 `
    -SqlInstance 'sql-host-01','sql-host-02\INST02'

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-ServerDdlEventSession.ps1 `
    -SqlInstance 'sql-host-01' -XelDirectory 'E:\SQLXE' -Replace

.EXAMPLE
  .\scripts\powershell\sql-exporter\Install-ServerDdlEventSession.ps1 `
    -SqlInstance 'sql-host-01' -Uninstall
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$SqlInstance,

    [pscredential]$SqlCredential,

    [string]$XelDirectory,

    [switch]$Replace,

    [switch]$Uninstall,

    [ValidateRange(15, 600)]
    [int]$CommandTimeoutSec = 60,

    [bool]$TrustServerCertificate = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Replace -and $Uninstall) {
    throw 'Pass only one of -Replace or -Uninstall.'
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

$sqlPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\sql\sql-exporter\Install-ServerDdlEventSession.sql'))
if (-not (Test-Path -LiteralPath $sqlPath -PathType Leaf)) {
    throw "SQL script not found: $sqlPath"
}

$action = 'Install observability_server_ddl'
if ($Uninstall) {
    $action = 'Uninstall observability_server_ddl'
}
elseif ($Replace) {
    $action = 'Replace observability_server_ddl'
}

function ConvertTo-SqlNvarcharLiteral {
    param([string]$Value)
    if ($null -eq $Value -or $Value -eq '') {
        return 'NULL'
    }
    return "N'" + $Value.Replace("'", "''") + "'"
}

function Get-ServerDdlSessionSql {
    param(
        [string]$Template,
        [string]$DirectoryLiteral,
        [int]$ReplaceFlag,
        [int]$UninstallFlag
    )

    $directoryLine = 'DECLARE @XelDirectory nvarchar(260) = NULL; -- observability-server-ddl:directory'
    $replaceLine = 'DECLARE @Replace bit = 0; -- observability-server-ddl:replace'
    $uninstallLine = 'DECLARE @Uninstall bit = 0; -- observability-server-ddl:uninstall'

    if ($Template.IndexOf($directoryLine) -lt 0 -or
        $Template.IndexOf($replaceLine) -lt 0 -or
        $Template.IndexOf($uninstallLine) -lt 0) {
        throw 'SQL script is missing the observability-server-ddl parameter markers.'
    }

    $sql = $Template.Replace(
        $directoryLine,
        "DECLARE @XelDirectory nvarchar(260) = $DirectoryLiteral; -- observability-server-ddl:directory"
    )
    $sql = $sql.Replace(
        $replaceLine,
        "DECLARE @Replace bit = $ReplaceFlag; -- observability-server-ddl:replace"
    )
    $sql = $sql.Replace(
        $uninstallLine,
        "DECLARE @Uninstall bit = $UninstallFlag; -- observability-server-ddl:uninstall"
    )
    return $sql
}

Add-Type -AssemblyName System.Data

$template = [IO.File]::ReadAllText($sqlPath)
$directoryLiteral = ConvertTo-SqlNvarcharLiteral $(if ($PSBoundParameters.ContainsKey('XelDirectory')) { $XelDirectory } else { $null })
$batch = Get-ServerDdlSessionSql -Template $template -DirectoryLiteral $directoryLiteral -ReplaceFlag ([int][bool]$Replace) -UninstallFlag ([int][bool]$Uninstall)

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
    $builder['Application Name'] = 'observability-server-ddl'
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
            SqlInstance  = $target
            IsRunning    = [int]$row['is_running']
            SessionName  = [string]$row['session_name']
            XelFile      = [string]$row['xel_file']
            ObjectTypes  = [string]$row['object_types']
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
    throw ("Server DDL event session was not applied on {0} instance(s).`n{1}" -f $failures.Count, ($failures -join "`n"))
}
