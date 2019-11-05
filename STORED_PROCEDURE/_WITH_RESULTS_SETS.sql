CREATE OR ALTER PROCEDURE DBO.STPLISTA_TABELAS
AS
BEGIN
    
    SELECT 
        [OBJECT_ID],
        [NAME],
        [TYPE_DESC],
        CREATE_DATE
    FROM 
        SYS.TABLES
 
END
 
 
-- EXECUTA A STORED PROCEDURE
EXEC DBO.STPLISTA_TABELAS
GO
 
EXEC DBO.STPLISTA_TABELAS
WITH RESULT SETS ((
    [ID_TABELA] INT,
    [NOME_TABELA] VARCHAR(100),
    [TIPO] VARCHAR(50),
    [DATA_CRIACAO] DATE
))

select @@SERVERNAME
SELECT @@servicename


EXECUTE xp_regread @rootkey='HKEY_LOCAL_MACHINE',
                   @key='SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQl',
                   @value_name='MSSQLSERVER'

SELECT * into #temp 
from OPENROWSET('SQLNCLI11', 'Server=LOCALHOST;Trusted_Connection=yes;',
'EXEC DBO.STPLISTA_TABELAS')

select * from #temp




--sp_configure 'show advanced options', 1;  
--RECONFIGURE;
--GO 
--sp_configure 'Ad Hoc Distributed Queries', 1;  
--RECONFIGURE;  
--GO  
  
SELECT a.*  
FROM OPENROWSET('SQLNCLI', 'Server=LOCALHOST;Trusted_Connection=yes;',  
     'SELECT *
      FROM master.sys.tables') AS a;  
GO  

