/*
  Server Extended Events session: observability_security_ddl

  Records the commit of CREATE / ALTER / DROP for logins, users, and roles,
  including the actor (server_principal_name). The default trace does not
  record modern CREATE LOGIN / CREATE USER / CREATE ROLE, so catalog dates
  alone cannot name who made the change.

  Statement text is not collected. CREATE LOGIN and ALTER LOGIN put the
  password in the batch text, and that text must not be written to the XEL file.

  GRANT, DENY, and REVOKE are not available as user Extended Events (the
  SecAudit package is internal to SQL Server Audit). Those events stay on
  the default trace and are already read by mssql_security_ddl.

  ALTER ROLE ... ADD MEMBER is stored as an alter of the role. The member
  name is not in the event payload; membership detail stays on the default trace.

  Run as a principal with ALTER ANY EVENT SESSION (sysadmin in practice).
  The sql_exporter login only needs VIEW SERVER STATE to read the file.
  On SQL Server 2022+ also grant VIEW SERVER PERFORMANCE STATE (already in
  scripts/sql/sql-exporter/Create-SqlExporterLogin.sql).

  Idempotent. @Replace = 0 starts an existing session and does not recreate it.
  @Replace = 1 stops, drops, and creates it again. Existing XEL files are left
  on disk either way.

  Rollback: set @Uninstall = 1, or run
  Install-SecurityDdlEventSession.ps1 -Uninstall. The session is dropped.
  XEL files are not deleted.

  NULL @XelDirectory uses {drive}:\Databases\Temp\XEvent\Machine\Instance\session\.
  The drive letter comes from InstanceDefaultDataPath, then
  InstanceDefaultLogPath, then the master data file. A default instance
  folder is MSSQLSERVER. The SQL Server service account must be able to
  create that folder.

  This script creates the event-file buffer only. Long-term rows go to
  dbo.security_ddl_event on the same instance. Install that archive with
  Install-SecurityDdlArchive.sql and pass the database name.
*/

USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @XelDirectory nvarchar(260) = NULL; -- observability-security-ddl:directory
DECLARE @Replace bit = 0; -- observability-security-ddl:replace
DECLARE @Uninstall bit = 0; -- observability-security-ddl:uninstall

DECLARE @SessionName sysname = N'observability_security_ddl';
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
    THROW 50010, 'Set only one of @Uninstall or @Replace.', 1;

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
        ALTER EVENT SESSION [observability_security_ddl] ON SERVER STATE = STOP;

    IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
        DROP EVENT SESSION [observability_security_ddl] ON SERVER;

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
        ALTER EVENT SESSION [observability_security_ddl] ON SERVER STATE = START;

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
        THROW 50011, 'XEvent directory could not be derived as {drive}:\Databases\Temp\XEvent. Pass @XelDirectory.', 1;

    SET @XelDirectory = UPPER(LEFT(@DataPath, 1)) + N':\Databases\Temp\XEvent';
END;

SET @XelDirectory = LTRIM(RTRIM(@XelDirectory));
IF RIGHT(@XelDirectory, 1) NOT IN (N'\', N'/')
    SET @XelDirectory = @XelDirectory + N'\';

IF CHARINDEX(N'''', @XelDirectory) > 0 OR CHARINDEX(N';', @XelDirectory) > 0
    THROW 50012, 'XEL directory must not contain quotes or semicolons.', 1;

SET @XelMachine = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CAST(SERVERPROPERTY(N'MachineName') AS nvarchar(128)), N''), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
SET @XelInstance = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(CAST(SERVERPROPERTY(N'InstanceName') AS nvarchar(128)), N''), N'MSSQLSERVER'), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
IF @XelMachine = N'' OR @XelInstance = N''
    THROW 50011, 'XEL instance folder could not be built from the server name.', 1;

SET @FileName = @XelDirectory + @SessionName + N'.xel';

IF LEN(@FileName) > 240
    THROW 50013, 'XEL file path is longer than 240 characters.', 1;

EXEC sys.xp_create_subdir @XelDirectory;

IF OBJECT_ID(N'tempdb..#xe_principal_type') IS NOT NULL
    DROP TABLE #xe_principal_type;

CREATE TABLE #xe_principal_type (
    map_key int NOT NULL,
    map_value nvarchar(128) NOT NULL
);

INSERT INTO #xe_principal_type (map_key, map_value)
SELECT mv.map_key, mv.map_value
FROM sys.dm_xe_map_values AS mv
INNER JOIN sys.dm_xe_packages AS p
    ON p.guid = mv.object_package_guid
WHERE mv.name = N'object_type'
  AND p.name = N'sqlserver'
  AND (
        mv.map_value IN (
            N'LOGIN', N'SQL_LOGIN', N'WINDOWS_LOGIN', N'WINDOWS_GROUP', N'EXTERNAL_LOGIN', N'EXTERNAL_GROUP',
            N'USER', N'SQL_USER', N'WINDOWS_USER', N'DATABASE_USER', N'EXTERNAL_USER',
            N'ROLE', N'DATABASE_ROLE', N'SERVER_ROLE', N'APPLICATION_ROLE'
        )
        OR mv.map_value LIKE N'%LOGIN'
        OR mv.map_value LIKE N'%USER'
        OR mv.map_value LIKE N'%ROLE'
        OR mv.map_value LIKE N'%GROUP'
      )
  AND mv.map_value NOT LIKE N'%TABLE%'
  AND mv.map_value NOT LIKE N'%PROCEDURE%'
  AND mv.map_value NOT LIKE N'%FUNCTION%'
  AND mv.map_value NOT LIKE N'%VIEW%'
  AND mv.map_value NOT LIKE N'%INDEX%'
  AND mv.map_value NOT LIKE N'%CONSTRAINT%'
  AND mv.map_value NOT LIKE N'%TRIGGER%'
  AND mv.map_value NOT LIKE N'%TYPE%'
  AND mv.map_value NOT LIKE N'%SCHEMA%'
  AND mv.map_value NOT LIKE N'%ASSEMBLY%'
  AND mv.map_value NOT LIKE N'%QUEUE%'
  AND mv.map_value NOT LIKE N'%CERTIFICATE%'
  AND mv.map_value NOT LIKE N'%KEY%'
  AND mv.map_value NOT LIKE N'%AUDIT%'
  AND mv.map_value NOT LIKE N'%STAT%'
  AND mv.map_value NOT LIKE N'%MESSAGE%'
  AND mv.map_value NOT LIKE N'%CONTRACT%'
  AND mv.map_value NOT LIKE N'%BINDING%'
  AND mv.map_value NOT LIKE N'%ROUTE%'
  AND mv.map_value NOT LIKE N'%FILE%'
  AND mv.map_value NOT LIKE N'%OBJECT%';

IF NOT EXISTS (SELECT 1 FROM #xe_principal_type)
    THROW 50014, 'No login, user, or role values were found in sys.dm_xe_map_values for object_type.', 1;

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
        FROM #xe_principal_type
        ORDER BY map_value
        FOR XML PATH(''), TYPE
    ).value(N'.', N'nvarchar(max)'), 1, 4, N'');
END
ELSE
BEGIN
    SELECT @TypePredicate = STUFF((
        SELECT N' OR [object_type]=(' + CONVERT(varchar(11), map_key) + N')'
        FROM #xe_principal_type
        ORDER BY map_key
        FOR XML PATH(''), TYPE
    ).value(N'.', N'nvarchar(max)'), 1, 4, N'');
END;

SELECT @TypeList = STUFF((
    SELECT N',' + map_value
    FROM #xe_principal_type
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
    SET @NamePredicate = N'sqlserver.not_like_i_sql_unicode_string([object_name], N''##%'')';
ELSE IF EXISTS (
    SELECT 1
    FROM sys.dm_xe_objects AS o
    INNER JOIN sys.dm_xe_packages AS p
        ON p.guid = o.package_guid
    WHERE o.object_type = N'pred_compare'
      AND p.name = N'sqlserver'
      AND o.name = N'like_i_sql_unicode_string'
)
    SET @NamePredicate = N'NOT sqlserver.like_i_sql_unicode_string([object_name], N''##%'')';

SET @EventSql = N'';
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
        AND ' + @NamePredicate + N'
        AND (' + @TypePredicate + N')
    )
),'
FROM (VALUES (N'object_created'), (N'object_altered'), (N'object_deleted')) AS e(event_name);

SET @EventSql = LEFT(@EventSql, LEN(@EventSql) - 1);

SET @CreateSql = N'
CREATE EVENT SESSION [observability_security_ddl] ON SERVER
' + @EventSql + N'
ADD TARGET package0.event_file (
    SET filename = N''' + REPLACE(@FileName, N'''', N'''''') + N''',
        max_file_size = (20),
        max_rollover_files = (5)
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
    ALTER EVENT SESSION [observability_security_ddl] ON SERVER STATE = STOP;

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
    DROP EVENT SESSION [observability_security_ddl] ON SERVER;

EXEC sys.sp_executesql @CreateSql;
ALTER EVENT SESSION [observability_security_ddl] ON SERVER STATE = START;

IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
    THROW 50015, 'observability_security_ddl was created but is not running.', 1;

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
