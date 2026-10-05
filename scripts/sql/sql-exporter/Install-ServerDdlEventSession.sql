/*
  Server Extended Events session: observability_server_ddl

  Records the commit of CREATE / ALTER / DROP for server-scoped objects that
  are not logins (observability_security_ddl) and not databases, tables, views,
  procedures, or database triggers (observability_database_ddl):

    event sessions, server audits, server and database audit specifications,
    credentials, endpoints, server triggers, event notifications,
    availability groups, resource pools, workload groups,
    cryptographic providers, backup devices

  ALTER EVENT SESSION ... STATE = START / STOP is the only object_altered
  event in this session, and it stores sql_text so the collector can label
  it started or stopped. sql_text is not collected for any other object.
  CREATE / DROP of the other types are collected without statement text.
  Their ALTER rows come from the default trace or from catalog dates.

  sp_configure is error 15457 (configuration option changed). The message
  has the option name and the integer values. Statement text is not stored.

  Actions are the actor (server_principal_name), database, client host, and
  client application. The collector exports actor, client host, and time.
  It does not export application name or statement text.

  Run as a principal with ALTER ANY EVENT SESSION (sysadmin in practice).
  The sql_exporter login only needs VIEW SERVER STATE to read the file.
  On SQL Server 2022+ also grant VIEW SERVER PERFORMANCE STATE (already in
  scripts/sql/sql-exporter/Create-SqlExporterLogin.sql).

  Idempotent. @Replace = 0 starts an existing session and does not recreate it.
  @Replace = 1 stops, drops, and creates it again. Existing XEL files are left
  on disk either way.

  Rollback: set @Uninstall = 1, or run
  Install-ServerDdlEventSession.ps1 -Uninstall. The session is dropped.
  XEL files are not deleted.

  NULL @XelDirectory uses {drive}:\Databases\Temp\XEvent\Machine\Instance\session\.
  The drive letter comes from InstanceDefaultDataPath, then
  InstanceDefaultLogPath, then the master data file. A default instance
  folder is MSSQLSERVER. The SQL Server service account must be able to
  create that folder.

  This script creates the event-file buffer only (20 MB x 8). Server DDL is
  rare, so that buffer is the collector source. It is not a seven-year archive.
*/

USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @XelDirectory nvarchar(260) = NULL; -- observability-server-ddl:directory
DECLARE @Replace bit = 0; -- observability-server-ddl:replace
DECLARE @Uninstall bit = 0; -- observability-server-ddl:uninstall

DECLARE @SessionName sysname = N'observability_server_ddl';
DECLARE @FileName nvarchar(260);
DECLARE @XelMachine nvarchar(128);
DECLARE @XelInstance nvarchar(128);
DECLARE @ExistingFile nvarchar(260);
DECLARE @PhasePredicate nvarchar(200);
DECLARE @OtherPredicate nvarchar(max);
DECLARE @SessionPredicate nvarchar(max);
DECLARE @AllPredicate nvarchar(max);
DECLARE @ObjectTypeKind nvarchar(60);
DECLARE @PhaseKind nvarchar(60);
DECLARE @EventSql nvarchar(max);
DECLARE @CreateSql nvarchar(max);
DECLARE @TypeList nvarchar(max);
DECLARE @IsRunning float = 0;

IF @Uninstall = 1 AND @Replace = 1
    THROW 50410, 'Set only one of @Uninstall or @Replace.', 1;

SELECT @ExistingFile = CAST(f.value AS nvarchar(260))
FROM sys.server_event_sessions AS s
INNER JOIN sys.server_event_session_targets AS t
    ON t.event_session_id = s.event_session_id
INNER JOIN sys.server_event_session_fields AS f
    ON f.event_session_id = t.event_session_id
   AND f.object_id = t.target_id
WHERE s.name = @SessionName
  AND t.name = N'event_file'
  AND f.name = N'filename';

IF @Uninstall = 1
BEGIN
    IF EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
        ALTER EVENT SESSION [observability_server_ddl] ON SERVER STATE = STOP;

    IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
        DROP EVENT SESSION [observability_server_ddl] ON SERVER;

    SELECT
        CAST(0 AS float) AS is_running,
        @SessionName AS session_name,
        ISNULL(@ExistingFile, N'') AS xel_file,
        N'' AS object_types;
    RETURN;
END;

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName) AND @Replace = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
        ALTER EVENT SESSION [observability_server_ddl] ON SERVER STATE = START;

    SELECT @IsRunning = CASE
        WHEN EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName) THEN 1
        ELSE 0
    END;

    SELECT
        @IsRunning AS is_running,
        @SessionName AS session_name,
        ISNULL(@ExistingFile, N'') AS xel_file,
        N'existing-session' AS object_types;
    RETURN;
END;

IF @XelDirectory IS NULL OR LTRIM(RTRIM(@XelDirectory)) = N''
BEGIN
    DECLARE @DataPath nvarchar(260);

    SET @DataPath = CAST(SERVERPROPERTY(N'InstanceDefaultDataPath') AS nvarchar(260));
    IF @DataPath IS NULL OR LTRIM(RTRIM(@DataPath)) = N''
        SET @DataPath = CAST(SERVERPROPERTY(N'InstanceDefaultLogPath') AS nvarchar(260));
    IF @DataPath IS NULL OR LTRIM(RTRIM(@DataPath)) = N''
        SELECT TOP (1) @DataPath = mf.physical_name
        FROM sys.master_files AS mf
        WHERE mf.database_id = DB_ID(N'master')
          AND mf.type_desc = N'ROWS';

    SET @DataPath = LTRIM(RTRIM(@DataPath));
    IF @DataPath IS NULL OR @DataPath NOT LIKE N'[A-Za-z]:\%'
        THROW 50411, 'XEvent directory could not be derived as {drive}:\Databases\Temp\XEvent. Pass @XelDirectory.', 1;

    SET @XelDirectory = UPPER(LEFT(@DataPath, 1)) + N':\Databases\Temp\XEvent';
END;

SET @XelDirectory = LTRIM(RTRIM(@XelDirectory));
IF RIGHT(@XelDirectory, 1) NOT IN (N'\', N'/')
    SET @XelDirectory = @XelDirectory + N'\';

IF CHARINDEX(N'''', @XelDirectory) > 0 OR CHARINDEX(N';', @XelDirectory) > 0
    THROW 50412, 'XEL directory must not contain quotes or semicolons.', 1;

SET @XelMachine = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CAST(SERVERPROPERTY(N'MachineName') AS nvarchar(128)), N''), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
SET @XelInstance = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(CAST(SERVERPROPERTY(N'InstanceName') AS nvarchar(128)), N''), N'MSSQLSERVER'), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
IF @XelMachine = N'' OR @XelInstance = N''
    THROW 50411, 'XEL instance folder could not be built from the server name.', 1;

SET @FileName = @XelDirectory + @SessionName + N'.xel';

IF LEN(@FileName) > 240
    THROW 50413, 'XEL file path is longer than 240 characters.', 1;

EXEC sys.xp_create_subdir @XelDirectory;

IF OBJECT_ID(N'tempdb..#xe_server_type') IS NOT NULL
    DROP TABLE #xe_server_type;

CREATE TABLE #xe_server_type (
    map_key int NOT NULL,
    map_value nvarchar(128) NOT NULL,
    is_event_session bit NOT NULL
);

INSERT INTO #xe_server_type (map_key, map_value, is_event_session)
SELECT
    mv.map_key,
    mv.map_value,
    CASE
        WHEN REPLACE(UPPER(mv.map_value), N' ', N'_') LIKE N'%EVENT_SESSION%'
          OR REPLACE(UPPER(mv.map_value), N' ', N'_') LIKE N'%XEVENT_SESSION%' THEN 1
        ELSE 0
    END
FROM sys.dm_xe_map_values AS mv
INNER JOIN sys.dm_xe_packages AS p
    ON p.guid = mv.object_package_guid
WHERE mv.name = N'object_type'
  AND p.name = N'sqlserver'
  AND REPLACE(UPPER(mv.map_value), N' ', N'_') IN (
        N'EVENT_SESSION',
        N'XEVENT_SESSION',
        N'SERVER_AUDIT',
        N'SERVER_AUDIT_SPECIFICATION',
        N'DATABASE_AUDIT_SPECIFICATION',
        N'CREDENTIAL',
        N'CRYPTOGRAPHIC_PROVIDER',
        N'ENDPOINT',
        N'EVENT_NOTIFICATION',
        N'AVAILABILITY_GROUP',
        N'RESOURCE_POOL',
        N'EXTERNAL_RESOURCE_POOL',
        N'WORKLOAD_GROUP',
        N'SERVER_TRIGGER',
        N'SERVER_DDL_TRIGGER',
        N'BACKUP_DEVICE'
      );

IF NOT EXISTS (SELECT 1 FROM #xe_server_type WHERE is_event_session = 1)
BEGIN
    INSERT INTO #xe_server_type (map_key, map_value, is_event_session)
    SELECT mv.map_key, mv.map_value, 1
    FROM sys.dm_xe_map_values AS mv
    INNER JOIN sys.dm_xe_packages AS p
        ON p.guid = mv.object_package_guid
    WHERE mv.name = N'object_type'
      AND p.name = N'sqlserver'
      AND (
            REPLACE(UPPER(mv.map_value), N' ', N'_') LIKE N'%EVENT_SESSION%'
            OR REPLACE(UPPER(mv.map_value), N' ', N'_') LIKE N'%XEVENT_SESSION%'
          )
      AND NOT EXISTS (
            SELECT 1
            FROM #xe_server_type AS x
            WHERE x.map_key = mv.map_key
              AND x.map_value = mv.map_value
      );
END;

IF NOT EXISTS (SELECT 1 FROM #xe_server_type)
    THROW 50414, 'No server-object values were found in sys.dm_xe_map_values for object_type.', 1;

SELECT @ObjectTypeKind = c.type_name
FROM sys.dm_xe_object_columns AS c
WHERE c.object_name = N'object_created'
  AND c.name = N'object_type'
  AND c.column_type = N'data';

SELECT @PhaseKind = c.type_name
FROM sys.dm_xe_object_columns AS c
WHERE c.object_name = N'object_created'
  AND c.name = N'ddl_phase'
  AND c.column_type = N'data';

IF @PhaseKind IN (N'unicode_string', N'ansi_string')
    SET @PhasePredicate = N'[ddl_phase]=N''Commit''';
ELSE
BEGIN
    DECLARE @PhaseKey int;
    SELECT @PhaseKey = mv.map_key
    FROM sys.dm_xe_map_values AS mv
    INNER JOIN sys.dm_xe_packages AS p
        ON p.guid = mv.object_package_guid
    WHERE mv.name = N'ddl_phase'
      AND mv.map_value = N'Commit'
      AND p.name = N'sqlserver';

    IF @PhaseKey IS NULL
        SET @PhaseKey = 1;

    SET @PhasePredicate = N'[ddl_phase]=(' + CONVERT(varchar(11), @PhaseKey) + N')';
END;

IF @ObjectTypeKind IN (N'unicode_string', N'ansi_string')
BEGIN
    SELECT @OtherPredicate = STUFF((
        SELECT N' OR [object_type]=N''' + REPLACE(map_value, N'''', N'''''') + N''''
        FROM #xe_server_type
        WHERE is_event_session = 0
        ORDER BY map_value
        FOR XML PATH(''), TYPE
    ).value(N'.', N'nvarchar(max)'), 1, 4, N'');

    SELECT @SessionPredicate = STUFF((
        SELECT N' OR [object_type]=N''' + REPLACE(map_value, N'''', N'''''') + N''''
        FROM #xe_server_type
        WHERE is_event_session = 1
        ORDER BY map_value
        FOR XML PATH(''), TYPE
    ).value(N'.', N'nvarchar(max)'), 1, 4, N'');
END
ELSE
BEGIN
    SELECT @OtherPredicate = STUFF((
        SELECT N' OR [object_type]=(' + CONVERT(varchar(11), map_key) + N')'
        FROM #xe_server_type
        WHERE is_event_session = 0
        ORDER BY map_key
        FOR XML PATH(''), TYPE
    ).value(N'.', N'nvarchar(max)'), 1, 4, N'');

    SELECT @SessionPredicate = STUFF((
        SELECT N' OR [object_type]=(' + CONVERT(varchar(11), map_key) + N')'
        FROM #xe_server_type
        WHERE is_event_session = 1
        ORDER BY map_key
        FOR XML PATH(''), TYPE
    ).value(N'.', N'nvarchar(max)'), 1, 4, N'');
END;

SELECT @TypeList = STUFF((
    SELECT N',' + map_value
    FROM #xe_server_type
    ORDER BY map_value
    FOR XML PATH(''), TYPE
).value(N'.', N'nvarchar(max)'), 1, 1, N'');

SET @EventSql = N'';

-- One object_altered only. sql_text is limited to event sessions so ALTER
-- EVENT SESSION STATE = START/STOP can be labeled started or stopped.
-- Credential and endpoint batches are not stored; those alters stay on the
-- default trace, which has the actor and does not keep the batch text.
IF @OtherPredicate IS NOT NULL AND @SessionPredicate IS NOT NULL
    SET @AllPredicate = N'(' + @OtherPredicate + N') OR (' + @SessionPredicate + N')';
ELSE
    SET @AllPredicate = COALESCE(@SessionPredicate, @OtherPredicate);

IF @AllPredicate IS NOT NULL
BEGIN
    SELECT @EventSql = @EventSql + N'
ADD EVENT sqlserver.' + e.event_name + N'(
    ACTION (
        sqlserver.server_principal_name,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.client_app_name
    )
    WHERE (
        ' + @PhasePredicate + N'
        AND (' + @AllPredicate + N')
    )
),'
    FROM (VALUES (N'object_created'), (N'object_deleted')) AS e(event_name);
END;

IF @SessionPredicate IS NOT NULL
BEGIN
    SET @EventSql = @EventSql + N'
ADD EVENT sqlserver.object_altered(
    ACTION (
        sqlserver.server_principal_name,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.client_app_name,
        sqlserver.sql_text
    )
    WHERE (
        ' + @PhasePredicate + N'
        AND (' + @SessionPredicate + N')
    )
),';
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.dm_xe_objects AS o
    INNER JOIN sys.dm_xe_packages AS p
        ON p.guid = o.package_guid
    WHERE o.name = N'error_reported'
      AND o.object_type = N'event'
      AND p.name = N'sqlserver'
)
    THROW 50416, 'sqlserver.error_reported is not available, so configuration changes cannot be captured.', 1;

SET @EventSql = @EventSql + N'
ADD EVENT sqlserver.error_reported(
    ACTION (
        sqlserver.server_principal_name,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.client_app_name
    )
    WHERE ([error_number]=(15457))
)';

SET @CreateSql = N'
CREATE EVENT SESSION [observability_server_ddl] ON SERVER
' + @EventSql + N'
ADD TARGET package0.event_file (
    SET filename = N''' + REPLACE(@FileName, N'''', N'''''') + N''',
        max_file_size = (20),
        max_rollover_files = (8)
)
WITH (
    MAX_MEMORY = 4 MB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0 KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = ON
);';

IF EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
    ALTER EVENT SESSION [observability_server_ddl] ON SERVER STATE = STOP;

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
    DROP EVENT SESSION [observability_server_ddl] ON SERVER;

EXEC sys.sp_executesql @CreateSql;
ALTER EVENT SESSION [observability_server_ddl] ON SERVER STATE = START;

IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
    THROW 50415, 'observability_server_ddl was created but is not running.', 1;

SELECT @ExistingFile = CAST(t.target_data AS xml).value(N'(EventFileTarget/File/@name)[1]', N'nvarchar(260)')
FROM sys.dm_xe_sessions AS s
INNER JOIN sys.dm_xe_session_targets AS t
    ON t.event_session_address = s.address
WHERE s.name = @SessionName
  AND t.target_name = N'event_file';

SELECT
    CAST(1 AS float) AS is_running,
    @SessionName AS session_name,
    ISNULL(@ExistingFile, @FileName) AS xel_file,
    ISNULL(@TypeList, N'') AS object_types;
