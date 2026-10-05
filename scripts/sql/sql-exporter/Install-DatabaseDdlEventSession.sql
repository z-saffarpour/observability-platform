/*
  Database Extended Events session: observability_database_ddl

  Pair with observability_server_ddl. This session is database-scoped:
  databases, user tables, views, stored procedures, and database triggers.
  Server triggers stay on observability_server_ddl.
  Logins, users, and roles stay on observability_security_ddl.

  Records the commit of CREATE / ALTER / DROP. ENABLE TRIGGER and
  DISABLE TRIGGER are included. Actions are the actor, client host, and
  client application. sql_text is collected only so ENABLE and DISABLE can
  be told apart. The archive table does not store the statement text.

  Run as a principal with ALTER ANY EVENT SESSION (sysadmin in practice).
  The sql_exporter login only needs VIEW SERVER STATE to read the file.
  On SQL Server 2022+ also grant VIEW SERVER PERFORMANCE STATE (already in
  scripts/sql/sql-exporter/Create-SqlExporterLogin.sql).

  Idempotent. @Replace = 0 starts an existing session and does not recreate it.
  @Replace = 1 stops, drops, and creates it again. Existing XEL files are left
  on disk either way.

  Rollback: set @Uninstall = 1. The session is dropped.
  XEL files are not deleted.

  NULL @XelDirectory uses {drive}:\Databases\Temp\XEvent\observability_database_ddl.xel.
  The drive letter comes from InstanceDefaultDataPath, then
  InstanceDefaultLogPath, then the master data file. The SQL Server service
  account must be able to create that folder.

  This script creates the event-file buffer only (50 MB x 16). It is not
  the long-term store. Rollover still deletes the oldest file. Long-term
  rows go to dbo.schema_ddl_event on the same instance. Install that archive
  with Install-DatabaseDdlArchive.sql and pass the database name.
*/

USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @XelDirectory nvarchar(260) = NULL; -- observability-schema-ddl-session:directory
DECLARE @Replace bit = 0; -- observability-schema-ddl-session:replace
DECLARE @Uninstall bit = 0; -- observability-schema-ddl-session:uninstall

DECLARE @SessionName sysname = N'observability_database_ddl';
DECLARE @FileName nvarchar(260);
DECLARE @XelMachine nvarchar(128);
DECLARE @XelInstance nvarchar(128);
DECLARE @ExistingFile nvarchar(260);
DECLARE @PhasePredicate nvarchar(200);
DECLARE @TypePredicate nvarchar(max);
DECLARE @ObjectTypeKind nvarchar(60);
DECLARE @PhaseKind nvarchar(60);
DECLARE @EventSql nvarchar(max);
DECLARE @CreateSql nvarchar(max);
DECLARE @TypeList nvarchar(max);
DECLARE @IsRunning float = 0;

IF @Uninstall = 1 AND @Replace = 1
    THROW 50310, 'Set only one of @Uninstall or @Replace.', 1;

IF EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = N'observability_schema_ddl')
    ALTER EVENT SESSION [observability_schema_ddl] ON SERVER STATE = STOP;
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'observability_schema_ddl')
    DROP EVENT SESSION [observability_schema_ddl] ON SERVER;

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
        ALTER EVENT SESSION [observability_database_ddl] ON SERVER STATE = STOP;

    IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
        DROP EVENT SESSION [observability_database_ddl] ON SERVER;

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
        ALTER EVENT SESSION [observability_database_ddl] ON SERVER STATE = START;

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
        THROW 50311, 'XEvent directory could not be derived as {drive}:\Databases\Temp\XEvent. Pass @XelDirectory.', 1;

    SET @XelDirectory = UPPER(LEFT(@DataPath, 1)) + N':\Databases\Temp\XEvent';
END;

SET @XelDirectory = LTRIM(RTRIM(@XelDirectory));
IF RIGHT(@XelDirectory, 1) NOT IN (N'\', N'/')
    SET @XelDirectory = @XelDirectory + N'\';

IF CHARINDEX(N'''', @XelDirectory) > 0 OR CHARINDEX(N';', @XelDirectory) > 0
    THROW 50312, 'XEL directory must not contain quotes or semicolons.', 1;

SET @XelMachine = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CAST(SERVERPROPERTY(N'MachineName') AS nvarchar(128)), N''), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
SET @XelInstance = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(CAST(SERVERPROPERTY(N'InstanceName') AS nvarchar(128)), N''), N'MSSQLSERVER'), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
IF @XelMachine = N'' OR @XelInstance = N''
    THROW 50311, 'XEL instance folder could not be built from the server name.', 1;

SET @FileName = @XelDirectory + @SessionName + N'.xel';

IF LEN(@FileName) > 240
    THROW 50313, 'XEL file path is longer than 240 characters.', 1;

EXEC sys.xp_create_subdir @XelDirectory;

IF OBJECT_ID(N'tempdb..#xe_schema_type') IS NOT NULL
    DROP TABLE #xe_schema_type;

CREATE TABLE #xe_schema_type (
    map_key int NOT NULL,
    map_value nvarchar(128) NOT NULL
);

INSERT INTO #xe_schema_type (map_key, map_value)
SELECT mv.map_key, mv.map_value
FROM sys.dm_xe_map_values AS mv
INNER JOIN sys.dm_xe_packages AS p
    ON p.guid = mv.object_package_guid
WHERE mv.name = N'object_type'
  AND p.name = N'sqlserver'
  AND mv.map_value IN (
        N'DATABASE',
        N'USER_TABLE',
        N'TABLE',
        N'VIEW',
        N'PROCEDURE',
        N'SQL_STORED_PROCEDURE',
        N'CLR_STORED_PROCEDURE',
        N'TRIGGER',
        N'SQL_TRIGGER',
        N'CLR_TRIGGER',
        N'DATABASE_DDL_TRIGGER'
      );

IF NOT EXISTS (SELECT 1 FROM #xe_schema_type)
    THROW 50314, 'No database, table, view, procedure, or trigger values were found in sys.dm_xe_map_values for object_type.', 1;

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
    SELECT @TypePredicate = STUFF((
        SELECT N' OR [object_type]=N''' + REPLACE(map_value, N'''', N'''''') + N''''
        FROM #xe_schema_type
        ORDER BY map_value
        FOR XML PATH(''), TYPE
    ).value(N'.', N'nvarchar(max)'), 1, 4, N'');
END
ELSE
BEGIN
    SELECT @TypePredicate = STUFF((
        SELECT N' OR [object_type]=(' + CONVERT(varchar(11), map_key) + N')'
        FROM #xe_schema_type
        ORDER BY map_key
        FOR XML PATH(''), TYPE
    ).value(N'.', N'nvarchar(max)'), 1, 4, N'');
END;

SELECT @TypeList = STUFF((
    SELECT N',' + map_value
    FROM #xe_schema_type
    ORDER BY map_value
    FOR XML PATH(''), TYPE
).value(N'.', N'nvarchar(max)'), 1, 1, N'');

DECLARE @NamePredicate nvarchar(300) = N'1 = 1';
IF EXISTS (
    SELECT 1
    FROM sys.dm_xe_objects AS o
    INNER JOIN sys.dm_xe_packages AS p
        ON p.guid = o.package_guid
    WHERE o.object_type = N'pred_compare'
      AND p.name = N'sqlserver'
      AND o.name = N'not_like_i_sql_unicode_string'
)
    SET @NamePredicate = N'sqlserver.not_like_i_sql_unicode_string([object_name], N''#%'')';
ELSE IF EXISTS (
    SELECT 1
    FROM sys.dm_xe_objects AS o
    INNER JOIN sys.dm_xe_packages AS p
        ON p.guid = o.package_guid
    WHERE o.object_type = N'pred_compare'
      AND p.name = N'sqlserver'
      AND o.name = N'like_i_sql_unicode_string'
)
    SET @NamePredicate = N'NOT sqlserver.like_i_sql_unicode_string([object_name], N''#%'')';

SET @EventSql = N'';
SELECT @EventSql = @EventSql + N'
ADD EVENT sqlserver.' + e.event_name + N'(
    ACTION (
        sqlserver.server_principal_name,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.client_app_name,
        sqlserver.sql_text
    )
    WHERE (
        ' + @PhasePredicate + N'
        AND [database_id]<>(2)
        AND [database_id]<>(32767)
        AND ' + @NamePredicate + N'
        AND (' + @TypePredicate + N')
    )
),'
FROM (VALUES (N'object_created'), (N'object_altered'), (N'object_deleted')) AS e(event_name);

SET @EventSql = LEFT(@EventSql, LEN(@EventSql) - 1);

SET @CreateSql = N'
CREATE EVENT SESSION [observability_database_ddl] ON SERVER
' + @EventSql + N'
ADD TARGET package0.event_file (
    SET filename = N''' + REPLACE(@FileName, N'''', N'''''') + N''',
        max_file_size = (50),
        max_rollover_files = (16)
)
WITH (
    MAX_MEMORY = 8 MB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0 KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = ON
);';

IF EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
    ALTER EVENT SESSION [observability_database_ddl] ON SERVER STATE = STOP;

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
    DROP EVENT SESSION [observability_database_ddl] ON SERVER;

EXEC sys.sp_executesql @CreateSql;
ALTER EVENT SESSION [observability_database_ddl] ON SERVER STATE = START;

IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
    THROW 50315, 'observability_database_ddl was created but is not running.', 1;

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
