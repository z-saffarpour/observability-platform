/*
  Extended Events session observability_security_ddl, plus a local archive.

  Records the commit of CREATE / ALTER / DROP for logins, users, and roles.
  Actions are the actor, client host, and client application. Statement text
  is not collected. GRANT, DENY, REVOKE, and the member name of ALTER ROLE
  stay on the default trace; they are not written to this table.

  The event file is a buffer (50 MB x 16) under
  {drive}:\Databases\Temp\XEvent\Machine\Instance\observability_security_ddl\.
  The drive letter comes from the instance data path. It is not the long-term store.
  SQL Agent job observability_security_ddl_ingest runs on this same instance,
  loads new events into @AuditDatabase, and deletes rows older than
  @RetentionDays. Default retention is 2555 days (about seven years).
  A database created by this script uses SIMPLE recovery. Take full backups
  of @AuditDatabase; the archive is local to this instance and is not copied
  to another server.

  @AuditDatabase is required for install. The name is supplied by the caller.
  The database is created on the instance default data and log paths when it
  does not exist and @CreateDatabase = 1. Uninstall drops the session and the
  job. It does not drop the database or the archived rows.

  Idempotent. @Replace = 0 keeps an existing session file target and an
  existing retention value. @Replace = 1 recreates the session, keeps XEL
  files on disk, clears the read watermark, and updates retention.
  Existing archive rows are kept either way.

  Rollback: @Uninstall = 1, or Install-SecurityDdlArchive.ps1 -Uninstall.
  XEL files and archive rows are not deleted.

  Run as sysadmin. The job owner is the installing login, which is what
  allows the T-SQL steps to read server Extended Events files.
*/

USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @AuditDatabase sysname = N''; -- observability-security-ddl:database
DECLARE @RetentionDays int = 2555; -- observability-security-ddl:retention-days
DECLARE @XelDirectory nvarchar(260) = NULL; -- observability-security-ddl:directory
DECLARE @CreateDatabase bit = 1; -- observability-security-ddl:create-database
DECLARE @Replace bit = 0; -- observability-security-ddl:replace
DECLARE @Uninstall bit = 0; -- observability-security-ddl:uninstall

DECLARE @SessionName sysname = N'observability_security_ddl';
DECLARE @JobName sysname = N'observability_security_ddl_ingest';
DECLARE @ScheduleName sysname = N'observability_security_ddl_ingest_5min';
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
DECLARE @JobDatabase sysname;
DECLARE @Runner nvarchar(max);
DECLARE @Deploy nvarchar(max);
DECLARE @Ingest nvarchar(max);
DECLARE @Purge nvarchar(max);
DECLARE @ReadFn nvarchar(max);

IF @Uninstall = 1 AND @Replace = 1
    THROW 50210, 'Set only one of @Uninstall or @Replace.', 1;

IF @RetentionDays < 365 OR @RetentionDays > 36500
    THROW 50211, '@RetentionDays must be from 365 through 36500.', 1;

IF IS_SRVROLEMEMBER(N'sysadmin') <> 1
    THROW 50212, 'Install as sysadmin so the Agent job can read the Extended Events files.', 1;

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
    IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @JobName)
        EXEC msdb.dbo.sp_delete_job @job_name = @JobName, @delete_unused_schedule = 1;

    IF EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
        ALTER EVENT SESSION [observability_security_ddl] ON SERVER STATE = STOP;

    IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
        DROP EVENT SESSION [observability_security_ddl] ON SERVER;

    SELECT
        CAST(0 AS float) AS is_running,
        @SessionName AS session_name,
        ISNULL(@ExistingFile, N'') AS xel_file,
        N'' AS object_types,
        ISNULL(@AuditDatabase, N'') AS audit_database,
        @JobName AS job_name,
        @RetentionDays AS retention_days;
    RETURN;
END;

SET @AuditDatabase = LTRIM(RTRIM(@AuditDatabase));
IF @AuditDatabase = N''
    OR @AuditDatabase LIKE N'%[''\]%'
    OR CHARINDEX(N';', @AuditDatabase) > 0
    OR CHARINDEX(N']', @AuditDatabase) > 0
    THROW 50213, '@AuditDatabase must be a non-empty name without quotes, brackets, backslashes, or semicolons.', 1;

IF @AuditDatabase IN (N'master', N'model', N'msdb', N'tempdb')
    THROW 50214, '@AuditDatabase must not be master, model, msdb, or tempdb.', 1;

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName) AND @Replace = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
        ALTER EVENT SESSION [observability_security_ddl] ON SERVER STATE = START;
END
ELSE
BEGIN
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
            THROW 50215, 'XEvent directory could not be derived as {drive}:\Databases\Temp\XEvent. Pass @XelDirectory.', 1;

        SET @XelDirectory = UPPER(LEFT(@DataPath, 1)) + N':\Databases\Temp\XEvent';
    END;

    SET @XelDirectory = LTRIM(RTRIM(@XelDirectory));
    IF RIGHT(@XelDirectory, 1) NOT IN (N'\', N'/')
        SET @XelDirectory = @XelDirectory + N'\';

    IF CHARINDEX(N'''', @XelDirectory) > 0 OR CHARINDEX(N';', @XelDirectory) > 0
        THROW 50216, 'XEL directory must not contain quotes or semicolons.', 1;

    SET @XelMachine = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CAST(SERVERPROPERTY(N'MachineName') AS nvarchar(128)), N''), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
    SET @XelInstance = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(CAST(SERVERPROPERTY(N'InstanceName') AS nvarchar(128)), N''), N'MSSQLSERVER'), N'\', N''), N'/', N''), N':', N''), N'*', N''), N'?', N''), N'"', N''), N'<', N''), N'>', N''), N'|', N'');
    IF @XelMachine = N'' OR @XelInstance = N''
        THROW 50215, 'XEL instance folder could not be built from the server name.', 1;

    SET @FileName = @XelDirectory + @SessionName + N'.xel';

    IF LEN(@FileName) > 240
        THROW 50217, 'XEL file path is longer than 240 characters.', 1;

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
        THROW 50218, 'No login, user, or role values were found in sys.dm_xe_map_values for object_type.', 1;

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
        ALTER EVENT SESSION [observability_security_ddl] ON SERVER STATE = STOP;

    IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = @SessionName)
        DROP EVENT SESSION [observability_security_ddl] ON SERVER;

    EXEC sys.sp_executesql @CreateSql;
    ALTER EVENT SESSION [observability_security_ddl] ON SERVER STATE = START;
END;

IF NOT EXISTS (SELECT 1 FROM sys.dm_xe_sessions WHERE name = @SessionName)
    THROW 50219, 'observability_security_ddl was created but is not running.', 1;

SELECT @ExistingFile = CAST(t.target_data AS xml).value(N'(EventFileTarget/File/@name)[1]', N'nvarchar(260)')
FROM sys.dm_xe_sessions AS s
INNER JOIN sys.dm_xe_session_targets AS t
    ON t.event_session_address = s.address
WHERE s.name = @SessionName
  AND t.target_name = N'event_file';

SELECT @IsRunning = 1;

IF DB_ID(@AuditDatabase) IS NULL
BEGIN
    IF @CreateDatabase = 0
        THROW 50220, 'Audit database does not exist. Set @CreateDatabase = 1 to create it on the default data and log paths.', 1;

    SET @CreateSql = N'CREATE DATABASE ' + QUOTENAME(@AuditDatabase) + N';';
    EXEC sys.sp_executesql @CreateSql;
    SET @CreateSql = N'ALTER DATABASE ' + QUOTENAME(@AuditDatabase) + N' SET RECOVERY SIMPLE;';
    EXEC sys.sp_executesql @CreateSql;
END;

SET @Deploy = N'
IF OBJECT_ID(N''dbo.security_ddl_event'', N''U'') IS NULL
BEGIN
    CREATE TABLE dbo.security_ddl_event (
        security_ddl_event_id bigint IDENTITY(1, 1) NOT NULL,
        event_time_utc datetime2(3) NOT NULL,
        event_time_local datetime2(0) NOT NULL,
        event_type nvarchar(20) NOT NULL,
        database_name sysname NOT NULL,
        principal_name sysname NOT NULL,
        principal_type nvarchar(32) NOT NULL,
        login_name nvarchar(128) NOT NULL,
        client_host nvarchar(256) NOT NULL,
        client_app_name nvarchar(256) NOT NULL,
        xe_file_name nvarchar(512) NOT NULL,
        xe_file_offset bigint NOT NULL,
        collected_at_utc datetime2(0) NOT NULL
            CONSTRAINT DF_security_ddl_event_collected DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_security_ddl_event PRIMARY KEY CLUSTERED (event_time_utc, security_ddl_event_id),
        CONSTRAINT UQ_security_ddl_event_xe UNIQUE (xe_file_name, xe_file_offset),
        CONSTRAINT CK_security_ddl_event_type CHECK (event_type IN (N''created'', N''altered'', N''dropped'')),
        CONSTRAINT CK_security_ddl_event_principal_type CHECK (principal_type IN (
            N''login'', N''user'', N''role'', N''server_role'', N''application_role'', N''windows_group''
        ))
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N''dbo.security_ddl_event'')
      AND name = N''IX_security_ddl_event_principal''
)
    CREATE INDEX IX_security_ddl_event_principal
        ON dbo.security_ddl_event (database_name, principal_name, event_time_utc);

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N''dbo.security_ddl_event'')
      AND name = N''IX_security_ddl_event_login''
)
    CREATE INDEX IX_security_ddl_event_login
        ON dbo.security_ddl_event (login_name, event_time_utc);

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N''dbo.security_ddl_event'')
      AND name = N''IX_security_ddl_event_host''
)
    CREATE INDEX IX_security_ddl_event_host
        ON dbo.security_ddl_event (client_host, event_time_utc);

IF OBJECT_ID(N''dbo.security_ddl_retention'', N''U'') IS NULL
BEGIN
    CREATE TABLE dbo.security_ddl_retention (
        retention_id tinyint NOT NULL,
        retention_days int NOT NULL,
        CONSTRAINT PK_security_ddl_retention PRIMARY KEY CLUSTERED (retention_id),
        CONSTRAINT CK_security_ddl_retention_id CHECK (retention_id = 1),
        CONSTRAINT CK_security_ddl_retention_days CHECK (retention_days BETWEEN 365 AND 36500)
    );
END;

IF OBJECT_ID(N''dbo.security_ddl_xe_watermark'', N''U'') IS NULL
BEGIN
    CREATE TABLE dbo.security_ddl_xe_watermark (
        watermark_id tinyint NOT NULL,
        xe_file_name nvarchar(512) NOT NULL,
        xe_file_offset bigint NOT NULL,
        updated_at_utc datetime2(0) NOT NULL,
        CONSTRAINT PK_security_ddl_xe_watermark PRIMARY KEY CLUSTERED (watermark_id),
        CONSTRAINT CK_security_ddl_xe_watermark_id CHECK (watermark_id = 1)
    );
END;

IF NOT EXISTS (SELECT 1 FROM dbo.security_ddl_retention)
    INSERT INTO dbo.security_ddl_retention (retention_id, retention_days)
    VALUES (1, @RetentionDays);
ELSE IF @Replace = 1
    UPDATE dbo.security_ddl_retention
    SET retention_days = @RetentionDays
    WHERE retention_id = 1;

IF @Replace = 1
    DELETE FROM dbo.security_ddl_xe_watermark;
';

SET @Ingest = N'
CREATE OR ALTER PROCEDURE dbo.proc_ingest_security_ddl
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @xe_file nvarchar(260);
    DECLARE @xe_glob nvarchar(260);
    DECLARE @start_file nvarchar(512);
    DECLARE @start_offset bigint;
    DECLARE @folder nvarchar(260);

    SELECT @xe_file = CAST(t.target_data AS xml).value(N''(EventFileTarget/File/@name)[1]'', N''nvarchar(260)'')
    FROM sys.dm_xe_sessions AS s
    INNER JOIN sys.dm_xe_session_targets AS t
        ON t.event_session_address = s.address
    WHERE s.name = N''observability_security_ddl''
      AND t.target_name = N''event_file'';

    IF @xe_file IS NULL OR @xe_file = N''''
        THROW 50230, ''observability_security_ddl is not running or has no event file.'', 1;

    SET @folder = LEFT(@xe_file, LEN(@xe_file) - CHARINDEX(N''\'', REVERSE(@xe_file)) + 1);
    SET @xe_glob = @folder + N''observability_security_ddl*.xel'';

    SELECT
        @start_file = xe_file_name,
        @start_offset = xe_file_offset
    FROM dbo.security_ddl_xe_watermark
    WHERE watermark_id = 1;

    IF OBJECT_ID(N''tempdb..#security_ddl_batch'') IS NOT NULL
        DROP TABLE #security_ddl_batch;

    CREATE TABLE #security_ddl_batch (
        event_time_utc datetime2(3) NOT NULL,
        event_time_local datetime2(0) NOT NULL,
        event_type nvarchar(20) NOT NULL,
        database_name sysname NOT NULL,
        principal_name sysname NOT NULL,
        principal_type nvarchar(32) NOT NULL,
        login_name nvarchar(128) NOT NULL,
        client_host nvarchar(256) NOT NULL,
        client_app_name nvarchar(256) NOT NULL,
        xe_file_name nvarchar(512) NOT NULL,
        xe_file_offset bigint NOT NULL
    );

    BEGIN TRY
        INSERT INTO #security_ddl_batch (
            event_time_utc, event_time_local, event_type, database_name, principal_name,
            principal_type, login_name, client_host, client_app_name,
            xe_file_name, xe_file_offset
        )
        EXEC dbo.proc_read_security_ddl_file
            @xe_glob = @xe_glob,
            @start_file = @start_file,
            @start_offset = @start_offset;
    END TRY
    BEGIN CATCH
        IF @start_file IS NULL
            THROW;

        INSERT INTO #security_ddl_batch (
            event_time_utc, event_time_local, event_type, database_name, principal_name,
            principal_type, login_name, client_host, client_app_name,
            xe_file_name, xe_file_offset
        )
        EXEC dbo.proc_read_security_ddl_file
            @xe_glob = @xe_glob,
            @start_file = NULL,
            @start_offset = NULL;
    END CATCH;

    INSERT INTO dbo.security_ddl_event (
        event_time_utc, event_time_local, event_type, database_name, principal_name,
        principal_type, login_name, client_host, client_app_name,
        xe_file_name, xe_file_offset
    )
    SELECT
        b.event_time_utc, b.event_time_local, b.event_type, b.database_name, b.principal_name,
        b.principal_type, b.login_name, b.client_host, b.client_app_name,
        b.xe_file_name, b.xe_file_offset
    FROM #security_ddl_batch AS b
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.security_ddl_event AS e
        WHERE e.xe_file_name = b.xe_file_name
          AND e.xe_file_offset = b.xe_file_offset
    );

    IF EXISTS (SELECT 1 FROM #security_ddl_batch)
    BEGIN
        ;WITH last_pos AS (
            SELECT TOP (1)
                xe_file_name,
                xe_file_offset
            FROM #security_ddl_batch
            ORDER BY xe_file_name DESC, xe_file_offset DESC
        )
        MERGE dbo.security_ddl_xe_watermark AS tgt
        USING last_pos AS src
            ON tgt.watermark_id = 1
        WHEN MATCHED THEN
            UPDATE SET
                xe_file_name = src.xe_file_name,
                xe_file_offset = src.xe_file_offset,
                updated_at_utc = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (watermark_id, xe_file_name, xe_file_offset, updated_at_utc)
            VALUES (1, src.xe_file_name, src.xe_file_offset, SYSUTCDATETIME());
    END;
END
';

SET @Purge = N'
CREATE OR ALTER PROCEDURE dbo.proc_purge_security_ddl
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @days int;
    DECLARE @cut datetime2(3);
    DECLARE @deleted int = 1;

    SELECT @days = retention_days
    FROM dbo.security_ddl_retention
    WHERE retention_id = 1;

    IF @days IS NULL
        THROW 50231, ''security_ddl_retention has no row.'', 1;

    SET @cut = DATEADD(DAY, -@days, SYSUTCDATETIME());

    WHILE @deleted > 0
    BEGIN
        DELETE TOP (5000)
        FROM dbo.security_ddl_event
        WHERE event_time_utc < @cut;

        SET @deleted = @@ROWCOUNT;
    END;
END
';

SET @Runner = N'USE ' + QUOTENAME(@AuditDatabase) + N'; EXEC sys.sp_executesql @stmt, N''@RetentionDays int, @Replace bit'', @RetentionDays = @RetentionDays, @Replace = @Replace;';
EXEC sys.sp_executesql
    @Runner,
    N'@stmt nvarchar(max), @RetentionDays int, @Replace bit',
    @stmt = @Deploy,
    @RetentionDays = @RetentionDays,
    @Replace = @Replace;

SET @ReadFn = N'
CREATE OR ALTER PROCEDURE dbo.proc_read_security_ddl_file
    @xe_glob nvarchar(260),
    @start_file nvarchar(512),
    @start_offset bigint
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(SWITCHOFFSET(parsed.event_utc, ''+00:00'') AS datetime2(3)) AS event_time_utc,
        CAST(SWITCHOFFSET(parsed.event_utc, DATENAME(TZOFFSET, SYSDATETIMEOFFSET())) AS datetime2(0)) AS event_time_local,
        parsed.event_type,
        parsed.database_name,
        parsed.principal_name,
        parsed.principal_type,
        parsed.login_name,
        parsed.client_host,
        parsed.client_app_name,
        parsed.xe_file_name,
        parsed.xe_file_offset
    FROM (
        SELECT
            CASE f.object_name
                WHEN N''object_created'' THEN N''created''
                WHEN N''object_deleted'' THEN N''dropped''
                ELSE N''altered''
            END AS event_type,
            CASE
                WHEN ot.raw_type LIKE N''%APPLICATION%'' AND ot.raw_type LIKE N''%ROLE%'' THEN N''application_role''
                WHEN ot.raw_type LIKE N''%SERVER%'' AND ot.raw_type LIKE N''%ROLE%'' THEN N''server_role''
                WHEN ot.raw_type LIKE N''%ROLE%'' THEN N''role''
                WHEN ot.raw_type LIKE N''%GROUP%'' THEN N''windows_group''
                WHEN ot.raw_type LIKE N''%USER%'' THEN N''user''
                WHEN ot.raw_type LIKE N''%LOGIN%'' THEN N''login''
                ELSE N''''
            END AS principal_type,
            CASE
                WHEN ot.raw_type LIKE N''%LOGIN%''
                  OR (ot.raw_type LIKE N''%SERVER%'' AND ot.raw_type LIKE N''%ROLE%'') THEN N''-''
                ELSE ISNULL(NULLIF(LEFT(REPLACE(REPLACE(LTRIM(RTRIM(ot.database_name)), NCHAR(13), N''''), NCHAR(10), N''''), 128), N''''), N''-'')
            END AS database_name,
            LEFT(REPLACE(REPLACE(LTRIM(RTRIM(ot.object_name)), NCHAR(13), N''''), NCHAR(10), N''''), 128) AS principal_name,
            ISNULL(NULLIF(LEFT(REPLACE(REPLACE(LTRIM(RTRIM(ot.actor)), NCHAR(13), N''''), NCHAR(10), N''''), 128), N''''), N''unknown'') AS login_name,
            ISNULL(NULLIF(LEFT(REPLACE(REPLACE(LTRIM(RTRIM(ot.client_host)), NCHAR(13), N''''), NCHAR(10), N''''), 256), N''''), N''-'') AS client_host,
            ISNULL(NULLIF(LEFT(REPLACE(REPLACE(LTRIM(RTRIM(ot.client_app_name)), NCHAR(13), N''''), NCHAR(10), N''''), 256), N''''), N''-'') AS client_app_name,
            ot.event_utc,
            LEFT(f.file_name, 512) AS xe_file_name,
            CAST(f.file_offset AS bigint) AS xe_file_offset,
            ot.raw_type
        FROM sys.fn_xe_file_target_read_file(@xe_glob, NULL, @start_file, @start_offset) AS f
        CROSS APPLY (SELECT CAST(f.event_data AS xml) AS event_data) AS xd
        CROSS APPLY (
            SELECT
                COALESCE(
                    NULLIF(xd.event_data.value(N''(event/data[@name="object_type"]/text)[1]'', N''nvarchar(128)''), N''''),
                    NULLIF(xd.event_data.value(N''(event/data[@name="object_type"]/value)[1]'', N''nvarchar(128)''), N''''),
                    N''''
                ) AS raw_type,
                ISNULL(xd.event_data.value(N''(event/data[@name="object_name"]/value)[1]'', N''nvarchar(256)''), N'''') AS object_name,
                COALESCE(
                    NULLIF(xd.event_data.value(N''(event/action[@name="database_name"]/value)[1]'', N''nvarchar(256)''), N''''),
                    NULLIF(xd.event_data.value(N''(event/data[@name="database_name"]/value)[1]'', N''nvarchar(256)''), N''''),
                    N''''
                ) AS database_name,
                ISNULL(xd.event_data.value(N''(event/action[@name="server_principal_name"]/value)[1]'', N''nvarchar(256)''), N'''') AS actor,
                ISNULL(xd.event_data.value(N''(event/action[@name="client_hostname"]/value)[1]'', N''nvarchar(256)''), N'''') AS client_host,
                ISNULL(xd.event_data.value(N''(event/action[@name="client_app_name"]/value)[1]'', N''nvarchar(256)''), N'''') AS client_app_name,
                xd.event_data.value(N''(event/@timestamp)[1]'', N''datetimeoffset(7)'') AS event_utc,
                COALESCE(
                    NULLIF(xd.event_data.value(N''(event/data[@name="ddl_phase"]/text)[1]'', N''nvarchar(32)''), N''''),
                    NULLIF(xd.event_data.value(N''(event/data[@name="ddl_phase"]/value)[1]'', N''nvarchar(32)''), N''''),
                    N''Commit''
                ) AS ddl_phase
        ) AS ot
        WHERE f.object_name IN (N''object_created'', N''object_altered'', N''object_deleted'')
          AND ot.ddl_phase = N''Commit''
          AND ot.object_name <> N''''
          AND ot.object_name NOT LIKE N''##%''
          AND ot.event_utc IS NOT NULL
          AND (
                ot.raw_type LIKE N''%LOGIN%''
                OR ot.raw_type LIKE N''%USER%''
                OR ot.raw_type LIKE N''%ROLE%''
                OR ot.raw_type LIKE N''%GROUP%''
              )
          AND (
                ot.database_name <> N''tempdb''
                OR ot.raw_type LIKE N''%LOGIN%''
                OR (ot.raw_type LIKE N''%SERVER%'' AND ot.raw_type LIKE N''%ROLE%'')
              )
    ) AS parsed
    WHERE parsed.principal_type <> N''''
      AND parsed.principal_name <> N'''';
END
';

SET @Runner = N'USE ' + QUOTENAME(@AuditDatabase) + N'; EXEC sys.sp_executesql @stmt;';
EXEC sys.sp_executesql @Runner, N'@stmt nvarchar(max)', @stmt = @ReadFn;
EXEC sys.sp_executesql @Runner, N'@stmt nvarchar(max)', @stmt = @Ingest;
EXEC sys.sp_executesql @Runner, N'@stmt nvarchar(max)', @stmt = @Purge;

SELECT @JobDatabase = s.database_name
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobsteps AS s
    ON s.job_id = j.job_id
WHERE j.name = @JobName
  AND s.step_id = 1;

IF @JobDatabase IS NOT NULL AND @JobDatabase <> @AuditDatabase AND @Replace = 0
    THROW 50221, 'Job observability_security_ddl_ingest already targets a different database. Re-run with @Replace = 1.', 1;

IF @JobDatabase IS NOT NULL AND @Replace = 1
    EXEC msdb.dbo.sp_delete_job @job_name = @JobName, @delete_unused_schedule = 1;

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @JobName)
BEGIN
    DECLARE @JobId uniqueidentifier;
    DECLARE @Owner sysname = SUSER_SNAME();

    EXEC msdb.dbo.sp_add_job
        @job_name = @JobName,
        @enabled = 1,
        @description = N'Loads observability_security_ddl into the audit database and purges rows past retention.',
        @owner_login_name = @Owner,
        @job_id = @JobId OUTPUT;

    EXEC msdb.dbo.sp_add_jobstep
        @job_id = @JobId,
        @step_name = N'Ingest security DDL',
        @subsystem = N'TSQL',
        @database_name = @AuditDatabase,
        @command = N'EXEC dbo.proc_ingest_security_ddl;',
        @on_success_action = 3,
        @on_fail_action = 2,
        @retry_attempts = 1,
        @retry_interval = 1;

    EXEC msdb.dbo.sp_add_jobstep
        @job_id = @JobId,
        @step_name = N'Purge security DDL',
        @subsystem = N'TSQL',
        @database_name = @AuditDatabase,
        @command = N'EXEC dbo.proc_purge_security_ddl;',
        @on_success_action = 1,
        @on_fail_action = 2;

    IF EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = @ScheduleName)
        EXEC msdb.dbo.sp_delete_schedule @schedule_name = @ScheduleName, @force_delete = 1;

    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = @ScheduleName,
        @freq_type = 4,
        @freq_interval = 1,
        @freq_subday_type = 4,
        @freq_subday_interval = 5,
        @active_start_time = 0;

    EXEC msdb.dbo.sp_attach_schedule @job_id = @JobId, @schedule_name = @ScheduleName;
    EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId, @server_name = N'(LOCAL)';
END;

BEGIN TRY
    EXEC msdb.dbo.sp_start_job @job_name = @JobName;
END TRY
BEGIN CATCH
END CATCH;

IF @TypeList IS NULL
    SET @TypeList = N'existing-session';

DECLARE @StoredRetention int;
SET @CreateSql = N'SELECT @days = retention_days FROM ' + QUOTENAME(@AuditDatabase) + N'.dbo.security_ddl_retention WHERE retention_id = 1;';
EXEC sys.sp_executesql @CreateSql, N'@days int OUTPUT', @days = @StoredRetention OUTPUT;

SELECT
    @IsRunning AS is_running,
    @SessionName AS session_name,
    ISNULL(@ExistingFile, N'') AS xel_file,
    ISNULL(@TypeList, N'') AS object_types,
    @AuditDatabase AS audit_database,
    @JobName AS job_name,
    ISNULL(@StoredRetention, @RetentionDays) AS retention_days;
