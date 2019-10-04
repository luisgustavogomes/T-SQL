/*

https://www.dirceuresende.com/blog/executando-um-comando-em-todos-os-databases-da-instancia-no-sql-server/

Exemplo
IF (OBJECT_ID('tempdb..#Dbs') IS NOT NULL) DROP TABLE #Dbs
CREATE TABLE #Dbs (
    Nome SYSNAME
)

INSERT INTO #Dbs
EXEC dbo.stpExecuta_Query_Databases
    @Ds_Query = 'SELECT DB_NAME()'

SELECT * FROM #Dbs

*/

CREATE OR ALTER  PROCEDURE dbo.STPEXECUTA_QUERY_DATABASES (
    @Ds_Query VARCHAR(MAX),
    @Ds_Incluir_Database VARCHAR(MAX) = NULL,
    @Ds_Excluir_Database VARCHAR(MAX) = NULL
)
AS BEGIN

    IF (OBJECT_ID('tempdb..#Databases') IS NOT NULL) DROP TABLE #Databases
    CREATE TABLE #Databases (
        [name] SYSNAME,
        [database_id] INT,
        [Ordem] INT IDENTITY(1, 1)
    )

    IF (@Ds_Incluir_Database IS NULL AND @Ds_Excluir_Database IS NULL)
    BEGIN

        INSERT INTO #Databases
        SELECT [name], [database_id]
        FROM sys.databases	WITH(NOLOCK)
        WHERE state_desc = 'ONLINE'
        ORDER BY name

    END
    ELSE BEGIN
        
        IF (@Ds_Incluir_Database IS NOT NULL)
        BEGIN

            INSERT INTO #Databases
            SELECT [name], [database_id]
            FROM sys.databases	WITH(NOLOCK)
            WHERE [name] LIKE (@Ds_Incluir_Database)
            AND state_desc = 'ONLINE'
            ORDER BY name

        END
        ELSE BEGIN

            INSERT INTO #Databases
            SELECT [name], [database_id]
            FROM sys.databases	WITH(NOLOCK)
            WHERE [name] NOT LIKE (@Ds_Excluir_Database)
            AND state_desc = 'ONLINE'
            ORDER BY name

        END

    END	


    DECLARE
        @Qt_Databases INT = (SELECT COUNT(*) FROM #Databases),
        @Contador INT = 1,
        @Ds_Database SYSNAME,
        @Cmd VARCHAR(MAX)


    WHILE(@Contador <= @Qt_Databases)
    BEGIN
        
        SELECT @Ds_Database = name
        FROM #Databases
        WHERE Ordem = @Contador

        SET @Cmd = 'USE [' + @Ds_Database + ']; ' + CHAR(10) + @Ds_Query
        EXEC(@Cmd)
        
        SET @Contador = @Contador + 1

    END


END