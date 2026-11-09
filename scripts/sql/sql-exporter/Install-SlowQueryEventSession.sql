/*
  Server Extended Events session: observability_slow_queries

  Captures user statements at or above @DurationMicroseconds.
  The installer sets that value from -DurationMs. The default is
  5000000 (5000 ms). A store install passes -DurationMs 100.
  Events:
    sql_statement_completed, rpc_completed, sp_statement_completed.

  Duration is microseconds. client_app_name values for sql_exporter,
  telegraf, and this install script are left out of the file.
  The collector reads the files and keeps the 50 slowest executions
  from the last 6 hours. It does not create this session.

  Run as a principal that can create an event session and a directory
  (sysadmin in practice). The sql_exporter login only needs
  VIEW SERVER STATE to read the file. On SQL Server 2022+ also grant
  VIEW SERVER PERFORMANCE STATE (scripts/sql/sql-exporter/Create-SqlExporterLogin.sql).

  Idempotent. @Replace = 0 starts an existing session and does not recreate it.
  @Replace = 1 stops, drops, and creates it again. Existing XEL files are left
  on disk either way.

  Rollback: set @Uninstall = 1, or run
  Install-SlowQueryEventSession.ps1 -Uninstall. The session is dropped.
  XEL files are not deleted.

  NULL @XelDirectory uses
  {drive}:\Databases\Temp\XEvent\Machine\Instance\observability_slow_queries\.
  The drive letter comes from InstanceDefaultDataPath, then
  InstanceDefaultLogPath, then the master data file. A default instance
  folder is MSSQLSERVER. The SQL Server service account must be able to
  create that folder.

  The event-file buffer is 20 MB x 8. If that buffer rolls over faster
  than 6 hours, the collector list is shorter than 6 hours.
  ALLOW_SINGLE_EVENT_LOSS can drop events during a burst.
*/

USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @XelDirectory nvarchar(260) = NULL; -- observability-slow-queries:directory
DECLARE @Replace bit = 0; -- observability-slow-queries:replace
DECLARE @Uninstall bit = 0; -- observability-slow-queries:uninstall
DECLARE @DurationMicroseconds bigint = 5000000; -- observability-slow-queries:duration-us

DECLARE @SessionName sysname = N'observability_slow_queries';
DECLARE @FileName nvarchar(260);
DECLARE @XelFolder nvarchar(260);
DECLARE @XelMachine nvarchar(128);
DECLARE @XelInstance nvarchar(128);
DECLARE @ExistingFile nvarchar(260);
DECLARE @CreateSql nvarchar(max);
DECLARE @IsRunning float = 0;
DECLARE @DurationMatches float = 0;
DECLARE @Predicate nvarchar(max);

IF @Uninstall = 1 AND @Replace = 1
    THROW 50420, 'Set only one of @Uninstall or @Replace.', 1;

IF @Uninstall = 0 AND (@DurationMicroseconds < 100000 OR @DurationMicroseconds > 60000000)
    THROW 50426, 'Duration must be between 100 and 60000 milliseconds.', 1;

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
        ALTER EVENT SESSION [observability_slow_queries] ON SERVER STATE = STOP;

    IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
        DROP EVENT SESSION [observability_slow_queries] ON SERVER;

    SELECT
        CAST(0 AS float) AS is_running,
        @SessionName AS session_name,
        ISNULL(@ExistingFile, N'') AS xel_file,
        CAST(@DurationMicroseconds / 1000 AS float) AS duration_ms,
        CAST(0 AS float) AS duration_matches;
    RETURN;
END;

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName) AND @Replace = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
        ALTER EVENT SESSION [observability_slow_queries] ON SERVER STATE = START;

    SELECT @IsRunning = CASE
        WHEN EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName) THEN 1
        ELSE 0
    END;

    SELECT TOP (1) @Predicate = e.predicate
    FROM sys.server_event_sessions AS s
    INNER JOIN sys.server_event_session_events AS e
        ON e.event_session_id = s.event_session_id
    WHERE s.name = @SessionName
      AND e.name = N'sql_statement_completed';

    IF @Predicate LIKE N'%(' + CONVERT(varchar(20), @DurationMicroseconds) + N')%'
        SET @DurationMatches = 1;

    SELECT
        @IsRunning AS is_running,
        @SessionName AS session_name,
        ISNULL(@ExistingFile, N'') AS xel_file,
        CAST(@DurationMicroseconds / 1000 AS float) AS duration_ms,
        @DurationMatches AS duration_matches;
    RETURN;
END;

IF (
    SELECT COUNT(*)
    FROM sys.dm_xe_objects AS o
    INNER JOIN sys.dm_xe_packages AS p
        ON p.guid = o.package_guid
    WHERE p.name = N'sqlserver'
      AND o.object_type = N'event'
      AND o.name IN (N'sql_statement_completed', N'rpc_completed', N'sp_statement_completed')
) < 3
    THROW 50421, 'sql_statement_completed, rpc_completed, or sp_statement_completed is not available.', 1;

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
        THROW 50422, 'XEvent directory could not be derived as {drive}:\Databases\Temp\XEvent. Pass @XelDirectory.', 1;

    SET @XelDirectory = UPPER(LEFT(@DataPath, 1)) + N':\Databases\Temp\XEvent';
END;

SET @XelDirectory = LTRIM(RTRIM(@XelDirectory));
IF RIGHT(@XelDirectory, 1) NOT IN (N'\', N'/')
    SET @XelDirectory = @XelDirectory + N'\';

IF CHARINDEX(N'''', @XelDirectory) > 0 OR CHARINDEX(N';', @XelDirectory) > 0
    THROW 50423, 'XEL directory must not contain quotes or semicolons.', 1;

SET @XelMachine = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CAST(SERVERPROPERTY(N'MachineName') AS nvarchar(128)), N''), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
SET @XelInstance = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(CAST(SERVERPROPERTY(N'InstanceName') AS nvarchar(128)), N''), N'MSSQLSERVER'), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
IF @XelMachine = N'' OR @XelInstance = N''
    THROW 50422, 'XEL instance folder could not be built from the server name.', 1;

SET @XelFolder = @XelDirectory + @XelMachine + N'\' + @XelInstance + N'\' + @SessionName;
SET @FileName = @XelFolder + N'\' + @SessionName + N'.xel';

IF LEN(@FileName) > 240
    THROW 50424, 'XEL file path is longer than 240 characters.', 1;

EXEC sys.xp_create_subdir @XelFolder;

SET @CreateSql = N'
CREATE EVENT SESSION [observability_slow_queries] ON SERVER
ADD EVENT sqlserver.sql_statement_completed(
    ACTION (
        sqlserver.database_name,
        sqlserver.session_id,
        sqlserver.query_hash
    )
    WHERE (
        [duration] >= (__DURATION_US__)
        AND [sqlserver].[is_system] = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%sql_exporter%'') = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%telegraf%'') = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%observability-slow-queries%'') = (0)
    )
),
ADD EVENT sqlserver.rpc_completed(
    ACTION (
        sqlserver.database_name,
        sqlserver.session_id,
        sqlserver.query_hash
    )
    WHERE (
        [duration] >= (__DURATION_US__)
        AND [sqlserver].[is_system] = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%sql_exporter%'') = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%telegraf%'') = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%observability-slow-queries%'') = (0)
    )
),
ADD EVENT sqlserver.sp_statement_completed(
    ACTION (
        sqlserver.database_name,
        sqlserver.session_id,
        sqlserver.query_hash
    )
    WHERE (
        [duration] >= (__DURATION_US__)
        AND [sqlserver].[is_system] = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%sql_exporter%'') = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%telegraf%'') = (0)
        AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name], N''%observability-slow-queries%'') = (0)
    )
)
ADD TARGET package0.event_file (
    SET filename = N''' + REPLACE(@FileName, N'''', N'''''') + N''',
        max_file_size = (20),
        max_rollover_files = (8)
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

SET @CreateSql = REPLACE(@CreateSql, N'__DURATION_US__', CONVERT(varchar(20), @DurationMicroseconds));

IF EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
    ALTER EVENT SESSION [observability_slow_queries] ON SERVER STATE = STOP;

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
    DROP EVENT SESSION [observability_slow_queries] ON SERVER;

EXEC sys.sp_executesql @CreateSql;
ALTER EVENT SESSION [observability_slow_queries] ON SERVER STATE = START;

IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
    THROW 50425, 'observability_slow_queries was created but is not running.', 1;

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
    CAST(@DurationMicroseconds / 1000 AS float) AS duration_ms,
    CAST(1 AS float) AS duration_matches;
