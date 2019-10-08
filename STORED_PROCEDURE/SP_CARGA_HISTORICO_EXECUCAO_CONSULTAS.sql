--SELECT * FROM Northwind.dbo.Historico_Execucao_Consultas

CREATE OR ALTER  PROCEDURE [dbo].[SP_CARGA_HISTORICO_EXECUCAO_CONSULTAS]
AS BEGIN


    IF (OBJECT_ID('Northwind.dbo.Historico_Execucao_Consultas') IS NULL)
    BEGIN
    
     -- DROP TABLE Northwind.dbo.Historico_Execucao_Consultas
     CREATE TABLE Northwind.dbo.Historico_Execucao_Consultas
     (
         Id_Coleta BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
         Dt_Coleta datetime NOT NULL,
         [database] sys.sysname NOT NULL,
         [text] NVARCHAR(MAX) NULL,
         [TSQL] XML NULL,
         [query_plan] XML NULL,
         last_execution_time datetime NULL,
         execution_count bigint NOT NULL,
         total_elapsed_time_ms bigint NULL,
         last_elapsed_time_ms bigint NULL,
         min_elapsed_time_ms bigint NULL,
         max_elapsed_time_ms bigint NULL,
         avg_elapsed_time_ms bigint NULL,
         total_worker_time_ms bigint NULL,
         last_worker_time_ms bigint NULL,
         min_worker_time_ms bigint NULL,
         max_worker_time_ms bigint NULL,
         avg_worker_time_ms bigint NULL,
         total_physical_reads bigint NOT NULL,
         last_physical_reads bigint NOT NULL,
         min_physical_reads bigint NOT NULL,
         max_physical_reads bigint NOT NULL,
         total_logical_reads bigint NOT NULL,
         last_logical_reads bigint NOT NULL,
         min_logical_reads bigint NOT NULL,
         max_logical_reads bigint NOT NULL,
         total_logical_writes bigint NOT NULL,
         last_logical_writes bigint NOT NULL,
         min_logical_writes bigint NOT NULL,
         max_logical_writes bigint NOT NULL
     ) WITH(DATA_COMPRESSION=PAGE)
	
     CREATE INDEX SK01_Historico_Execucao_Consultas ON dbo.Historico_Execucao_Consultas(Dt_Coleta, [database])
	
    END

    
    DECLARE 
        @Dt_Referencia DATETIME = GETDATE(),
        @Query VARCHAR(MAX)


    SET @Query = '
IF (''?'' NOT IN (''master'', ''model'', ''msdb'', ''tempdb''))
BEGIN

    INSERT INTO Northwind.dbo.Historico_Execucao_Consultas
    SELECT
        ''' + CONVERT(VARCHAR(19), @Dt_Referencia, 120) + ''' AS Dt_Coleta,
        ''?'' AS [database],
        B.[text],
        (SELECT CAST(SUBSTRING(B.[text], (A.statement_start_offset/2)+1, (((CASE A.statement_end_offset WHEN -1 THEN DATALENGTH(B.[text]) ELSE A.statement_end_offset END) - A.statement_start_offset)/2) + 1) AS NVARCHAR(MAX)) FOR XML PATH(''''),TYPE) AS [T
SQL],
        C.query_plan,

        A.last_execution_time,
        A.execution_count,

        A.total_elapsed_time / 1000 AS total_elapsed_time_ms,
        A.last_elapsed_time / 1000 AS last_elapsed_time_ms,
        A.min_elapsed_time / 1000 AS min_elapsed_time_ms,
        A.max_elapsed_time / 1000 AS max_elapsed_time_ms,
        ((A.total_elapsed_time / A.execution_count) / 1000) AS avg_elapsed_time_ms,

        A.total_worker_time / 1000 AS total_worker_time_ms,
        A.last_worker_time / 1000 AS last_worker_time_ms,
        A.min_worker_time / 1000 AS min_worker_time_ms,
        A.max_worker_time / 1000 AS max_worker_time_ms,
        ((A.total_worker_time / a.execution_count) / 1000) AS avg_worker_time_ms,
    
        A.total_physical_reads,
        A.last_physical_reads,
        A.min_physical_reads,
        A.max_physical_reads,
    
        A.total_logical_reads,
        A.last_logical_reads,
        A.min_logical_reads,
        A.max_logical_reads,
    
        A.total_logical_writes,
        A.last_logical_writes,
        A.min_logical_writes,
        A.max_logical_writes
    FROM
        [?].sys.dm_exec_query_stats A
        CROSS APPLY [?].sys.dm_exec_sql_text(A.[sql_handle]) B
        OUTER APPLY [?].sys.dm_exec_query_plan (A.plan_handle) AS C

END'
	
    
    EXEC master.dbo.sp_MSforeachdb
        @command1 = @Query


END