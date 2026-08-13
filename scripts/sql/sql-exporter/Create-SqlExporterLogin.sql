/*
  Creates a least-privilege SQL Server login for this repository's sql_exporter.

  Run in SSMS as sysadmin after changing @LoginName and @Password.
  The script is idempotent and targets the current configuration: collectors: [mssql_*].

  Notes:
    - Set @CreateSqlLogin = 0 for a Windows account (DOMAIN\service-account).
    - @GrantUserDatabaseAccess enables collectors that inspect Query Store, indexes,
      statistics, columnstore, CDC, database configuration, and integrity metadata.
    - @GrantReadErrorLog enables error-log collectors without granting sysadmin.
    - SQL Audit file metrics are intentionally not granted: they require CONTROL SERVER,
      which is not least privilege. Those metrics will remain empty.
    - DBCC DBINFO used for last-known-good CHECKDB is undocumented and can require
      elevated rights on some SQL Server versions; the collector catches denial.
*/

USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @LoginName sysname = N'sql_exporter';
DECLARE @Password nvarchar(256) = N'CHANGE_ME_TO_A_LONG_RANDOM_PASSWORD';
DECLARE @CreateSqlLogin bit = 1;
DECLARE @GrantUserDatabaseAccess bit = 1;
DECLARE @GrantReadErrorLog bit = 1;
DECLARE @GrantMsdbRead bit = 1;
DECLARE @GrantSsisdbRead bit = 1;
DECLARE @GrantDistributionRead bit = 1;

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

-- Server-scoped metadata and DMV access required by the base collectors.
DECLARE @GrantServerSql nvarchar(max) =
    N'GRANT CONNECT SQL TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
    N'GRANT VIEW SERVER STATE TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
    N'GRANT VIEW ANY DEFINITION TO ' + QUOTENAME(@LoginName) + N';' + CHAR(10) +
    N'GRANT VIEW ANY DATABASE TO ' + QUOTENAME(@LoginName) + N';';
EXEC sys.sp_executesql @GrantServerSql;

-- SQL Server 2022+ splits many performance DMVs into this permission.
IF TRY_CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) >= 16
BEGIN
    DECLARE @Grant2022Sql nvarchar(max) =
        N'GRANT VIEW SERVER PERFORMANCE STATE TO ' + QUOTENAME(@LoginName) + N';';
    EXEC sys.sp_executesql @Grant2022Sql;
END;

-- Create a contained database principal mapped to the login, then apply grants.
DECLARE @DbName sysname;
DECLARE @DbSql nvarchar(max);

IF @GrantUserDatabaseAccess = 1
BEGIN
    DECLARE dbs CURSOR LOCAL FAST_FORWARD FOR
        SELECT name
        FROM sys.databases
        WHERE database_id > 4
          AND state_desc = N'ONLINE'
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
GRANT VIEW DATABASE PERFORMANCE STATE TO ' + QUOTENAME(@LoginName) + N';'
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
    SET @DbSql = N'USE [msdb];
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
GRANT CONNECT TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[backupmediafamily] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[backupset] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[cdc_jobs] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[restorehistory] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[suspect_pages] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[syscategories] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[sysjobactivity] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[sysjobhistory] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[sysjobs] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[sysjobschedules] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[sysjobservers] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[sysjobsteps] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[sysproxies] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[syssessions] TO ' + QUOTENAME(@LoginName) + N';';
    EXEC sys.sp_executesql @DbSql;
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
    EXEC sys.sp_executesql @DbSql;
END;

IF @GrantDistributionRead = 1 AND DB_ID(N'distribution') IS NOT NULL
BEGIN
    SET @DbSql = N'USE [distribution];
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
GRANT CONNECT TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSpublications] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSsubscriptions] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSdistribution_history] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSdistribution_agents] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSdistribution_status] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSlogreader_history] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSlogreader_agents] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSsnapshot_history] TO ' + QUOTENAME(@LoginName) + N';
GRANT SELECT ON [dbo].[MSsnapshot_agents] TO ' + QUOTENAME(@LoginName) + N';';
    EXEC sys.sp_executesql @DbSql;
END;

IF @GrantReadErrorLog = 1
BEGIN
    -- xp_readerrorlog is used by mssql_errorlog_signals and mssql_security.
    SET @DbSql = N'USE [master];
IF DATABASE_PRINCIPAL_ID(' + QUOTENAME(@LoginName, '''') + N') IS NULL
    CREATE USER ' + QUOTENAME(@LoginName) + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';
GRANT EXECUTE ON [sys].[xp_readerrorlog] TO ' + QUOTENAME(@LoginName) + N';';
    EXEC sys.sp_executesql @DbSql;
END;

SELECT
    sp.name AS login_name,
    sp.type_desc,
    sp.is_disabled,
    permission_name,
    state_desc
FROM sys.server_principals AS sp
LEFT JOIN sys.server_permissions AS perm
    ON perm.grantee_principal_id = sp.principal_id
WHERE sp.name = @LoginName
ORDER BY permission_name;

PRINT N'sql_exporter login provisioning completed.';
