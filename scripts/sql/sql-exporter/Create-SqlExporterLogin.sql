/*
  Creates a least-privilege SQL Server login for this repository's sql_exporter.

  Run in SSMS as sysadmin after changing @LoginName and @Password.
  Install-SqlExporterRemote.ps1 calls Grant-SqlExporterProfileAccess.ps1, which
  sets these variables from the service account and the installed profile.
  The marker comments on the DECLARE lines are required for that substitution.
  The script is idempotent and targets the current configuration: collectors: [mssql_*].

  Notes:
    - Set @CreateSqlLogin = 0 for a Windows account (DOMAIN\service-account).
    - @GrantUserDatabaseAccess enables collectors that inspect Query Store, indexes,
      statistics, columnstore, CDC, database configuration, and integrity metadata.
    - @GrantReadErrorLog grants EXECUTE on xp_readerrorlog. The master user is
      created either way: without it, catalog views such as sys.servers are checked
      in mssqlsystemresource and the scrape fails.
    - ALTER TRACE is required by sys.traces and sys.fn_trace_gettable
      (mssql_autogrowth, mssql_schema_ddl, mssql_security_ddl, mssql_server_ddl).
      VIEW SERVER STATE does not cover those objects, and a denial fails the scrape.
    - CONTROL SERVER is required by sys.dm_server_audit_status and
      sys.fn_get_audit_file (mssql_security). SQL Server has no narrower permission
      for those two. The same grant covers server catalog rows used by mssql_server_ddl
      (audits, credentials, endpoints).
    - @GrantSysadmin = 0 keeps the limited grants above. DBCC DBINFO
      (mssql_checkdb_age) and DBCC TRACESTATUS(-1) then stay empty.
    - @GrantSysadmin = 1 also adds the login to the sysadmin server role.
      That is what makes CHECKDB age and global trace flags return real values.
      Re-running with 0 does not remove an existing sysadmin membership.
*/

USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @LoginName sysname = N'sql_exporter'; -- observability-sql-login:name
DECLARE @Password nvarchar(256) = N'CHANGE_ME_TO_A_LONG_RANDOM_PASSWORD'; -- observability-sql-login:password
DECLARE @CreateSqlLogin bit = 1; -- observability-sql-login:create-sql-login
DECLARE @GrantUserDatabaseAccess bit = 1; -- observability-sql-login:user-db
DECLARE @GrantReadErrorLog bit = 1; -- observability-sql-login:errorlog
DECLARE @GrantMsdbRead bit = 1; -- observability-sql-login:msdb
DECLARE @GrantSsisdbRead bit = 1; -- observability-sql-login:ssisdb
DECLARE @GrantDistributionRead bit = 1; -- observability-sql-login:distribution
DECLARE @GrantSysadmin bit = 0; -- observability-sql-login:sysadmin

IF @LoginName IS NULL OR LTRIM(RTRIM(@LoginName)) = N''
    THROW 50000, 'Login name cannot be empty.', 1;

IF @CreateSqlLogin = 1
BEGIN
    IF @Password = N'CHANGE_ME_TO_A_LONG_RANDOM_PASSWORD' OR LEN(@Password) < 20
        THROW 50001, 'Set @Password to a strong value of at least 20 characters.', 1;

    IF SUSER_ID(@LoginName) IS NULL
    BEGIN
        DECLARE @CreateLoginSql nvarchar(max) =
            N'CREATE LOGIN ' + QUOTENAME(@LoginName) +
            N' WITH PASSWORD = ' + QUOTENAME(@Password, '''') +
            N', CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = [master];';
        EXEC sys.sp_executesql @CreateLoginSql;
    END;
END
ELSE IF SUSER_ID(@LoginName) IS NULL
BEGIN
    DECLARE @CreateWindowsLoginSql nvarchar(max) =
        N'CREATE LOGIN ' + QUOTENAME(@LoginName) + N' FROM WINDOWS WITH DEFAULT_DATABASE = [master];';
    EXEC sys.sp_executesql @CreateWindowsLoginSql;
END;

-- 0 = limited grants only. 1 = also add sysadmin (DBCC DBINFO / TRACESTATUS).
-- 0 does not drop an existing sysadmin membership.
IF @GrantSysadmin = 1 AND ISNULL(IS_SRVROLEMEMBER(N'sysadmin', @LoginName), 0) <> 1
BEGIN
    DECLARE @AddSysadminSql nvarchar(max) =
        N'ALTER SERVER ROLE [sysadmin] ADD MEMBER ' + QUOTENAME(@LoginName) + N';';
    EXEC sys.sp_executesql @AddSysadminSql;
END
ELSE IF @GrantSysadmin = 0 AND IS_SRVROLEMEMBER(N'sysadmin', @LoginName) = 1
    PRINT N'Login is already sysadmin. @GrantSysadmin = 0 does not remove that role.';

-- Server-scoped metadata and DMV access required by the base collectors.
DECLARE @GrantServerSql nvarchar(max) =
    N'GRANT CONNECT SQL TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
    N'GRANT VIEW SERVER STATE TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
    N'GRANT VIEW ANY DEFINITION TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
    N'GRANT VIEW ANY DATABASE TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
    N'GRANT ALTER TRACE TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
    N'GRANT CONTROL SERVER TO ' + QUOTENAME(@LoginName) + N';';
EXEC sys.sp_executesql @GrantServerSql;

-- SQL Server 2022+ splits performance and security DMVs into these permissions.
IF TRY_CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) >= 16
BEGIN
    DECLARE @Grant2022Sql nvarchar(max) =
        N'GRANT VIEW SERVER PERFORMANCE STATE TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
        N'GRANT VIEW SERVER SECURITY STATE TO ' + QUOTENAME(@LoginName) + N';';
    EXEC sys.sp_executesql @Grant2022Sql;
END;

-- sys.servers and the other master catalog views used by the collectors are
-- ownership-chained from master. A login with no user in master is checked
-- against mssqlsystemresource and the query fails the scrape.
DECLARE @DbName sysname;
DECLARE @DbSql nvarchar(max);

SET @DbSql = N'USE [master];
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
GRANT CONNECT TO ' + QUOTENAME(@LoginName) + N';';
BEGIN TRY
    EXEC sys.sp_executesql @DbSql;
END TRY
BEGIN CATCH
    PRINT N'Skipped master user: ' + ERROR_MESSAGE();
END CATCH;

-- Create a contained database principal mapped to the login, then apply grants.
IF @GrantUserDatabaseAccess = 1
BEGIN
    DECLARE dbs CURSOR LOCAL FAST_FORWARD FOR
        SELECT name
        FROM sys.databases
        WHERE database_id > 4
          AND state_desc = N'ONLINE'
          AND DATABASEPROPERTYEX(name, N'Updateability') = N'READ_WRITE'
          AND source_database_id IS NULL
          AND name NOT IN (N'SSISDB', N'distribution');

    OPEN dbs;
    FETCH NEXT FROM dbs INTO @DbName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @DbSql = N'USE ' + QUOTENAME(@DbName) + N';
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
GRANT CONNECT TO ' + QUOTENAME(@LoginName) + N';
GRANT VIEW DATABASE STATE TO ' + QUOTENAME(@LoginName) + N';
GRANT VIEW DEFINITION TO ' + QUOTENAME(@LoginName) + N';' +
CASE WHEN TRY_CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) >= 16
     THEN N'
GRANT VIEW DATABASE PERFORMANCE STATE TO ' + QUOTENAME(@LoginName) + N';
GRANT VIEW DATABASE SECURITY STATE TO ' + QUOTENAME(@LoginName) + N';'
     ELSE N'' END;
        BEGIN TRY
            EXEC sys.sp_executesql @DbSql;
        END TRY
        BEGIN CATCH
            PRINT N'Skipped database ' + QUOTENAME(@DbName) + N': ' + ERROR_MESSAGE();
        END CATCH;
        FETCH NEXT FROM dbs INTO @DbName;
    END;
    CLOSE dbs;
    DEALLOCATE dbs;
END;

IF @GrantMsdbRead = 1 AND DB_ID(N'msdb') IS NOT NULL
BEGIN
    -- cdc_jobs exists only after CDC is enabled. A missing object must not abort the other grants.
    SET @DbSql = N'USE [msdb];
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
GRANT CONNECT TO ' + QUOTENAME(@LoginName) + N';';

    SELECT @DbSql = @DbSql + N'
IF OBJECT_ID(N' + QUOTENAME(N'dbo.' + object_name, '''') + N') IS NOT NULL
    GRANT SELECT ON [dbo].' + QUOTENAME(object_name) + N' TO ' + QUOTENAME(@LoginName) + N';
ELSE
    PRINT N''Skipped msdb.' + QUOTENAME(object_name) + N': object does not exist.'';'
    FROM (VALUES
        (N'backupmediafamily'),
        (N'backupset'),
        (N'cdc_jobs'),
        (N'restorehistory'),
        (N'suspect_pages'),
        (N'syscategories'),
        (N'sysjobactivity'),
        (N'sysjobhistory'),
        (N'sysjobs'),
        (N'sysjobschedules'),
        (N'sysjobservers'),
        (N'sysjobsteps'),
        (N'sysproxies'),
        (N'syssessions')
    ) AS msdb_object(object_name);

    BEGIN TRY
        EXEC sys.sp_executesql @DbSql;
    END TRY
    BEGIN CATCH
        PRINT N'Skipped msdb grants: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF @GrantSsisdbRead = 1 AND DB_ID(N'SSISDB') IS NOT NULL
BEGIN
    SET @DbSql = N'USE [SSISDB];
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
GRANT CONNECT TO ' + QUOTENAME(@LoginName) + N';
IF IS_ROLEMEMBER(N''db_datareader'', ' + QUOTENAME(@LoginName, '''') + N') <> 1
    ALTER ROLE [db_datareader] ADD MEMBER ' + QUOTENAME(@LoginName) + N';
GRANT VIEW DATABASE STATE TO ' + QUOTENAME(@LoginName) + N';';
    BEGIN TRY
        EXEC sys.sp_executesql @DbSql;
    END TRY
    BEGIN CATCH
        PRINT N'Skipped SSISDB grants: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF @GrantDistributionRead = 1 AND DB_ID(N'distribution') IS NOT NULL
BEGIN
    SET @DbSql = N'USE [distribution];
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
GRANT CONNECT TO ' + QUOTENAME(@LoginName) + N';';

    SELECT @DbSql = @DbSql + N'
IF OBJECT_ID(N' + QUOTENAME(N'dbo.' + object_name, '''') + N') IS NOT NULL
    GRANT SELECT ON [dbo].' + QUOTENAME(object_name) + N' TO ' + QUOTENAME(@LoginName) + N';
ELSE
    PRINT N''Skipped distribution.' + QUOTENAME(object_name) + N': object does not exist.'';'
    FROM (VALUES
        (N'MSpublications'),
        (N'MSsubscriptions'),
        (N'MSdistribution_history'),
        (N'MSdistribution_agents'),
        (N'MSdistribution_status'),
        (N'MSlogreader_history'),
        (N'MSlogreader_agents'),
        (N'MSsnapshot_history'),
        (N'MSsnapshot_agents')
    ) AS distribution_object(object_name);

    BEGIN TRY
        EXEC sys.sp_executesql @DbSql;
    END TRY
    BEGIN CATCH
        PRINT N'Skipped distribution grants: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF @GrantReadErrorLog = 1
BEGIN
    -- xp_readerrorlog is used by mssql_errorlog_signals and mssql_security.
    SET @DbSql = N'USE [master];
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
IF OBJECT_ID(N''sys.xp_readerrorlog'') IS NOT NULL
    GRANT EXECUTE ON [sys].[xp_readerrorlog] TO ' + QUOTENAME(@LoginName) + N';';
    BEGIN TRY
        EXEC sys.sp_executesql @DbSql;
    END TRY
    BEGIN CATCH
        PRINT N'Skipped xp_readerrorlog grant: ' + ERROR_MESSAGE();
    END CATCH;
END;

SELECT
    sp.name AS login_name,
    sp.type_desc,
    sp.is_disabled,
    CAST(ISNULL(IS_SRVROLEMEMBER(N'sysadmin', sp.name), 0) AS bit) AS is_sysadmin,
    permission_name,
    state_desc
FROM sys.server_principals AS sp
LEFT JOIN sys.server_permissions AS perm
    ON perm.grantee_principal_id = sp.principal_id
WHERE sp.name = @LoginName
ORDER BY permission_name;

PRINT N'sql_exporter login provisioning completed.';
