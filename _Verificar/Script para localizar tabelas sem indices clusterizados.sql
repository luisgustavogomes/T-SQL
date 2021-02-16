-- ============================================= 
-- Author:       Bruno Perroni
-- Create date:  15/08/2018
-- Description:  Script para localizar tabelas sem indices clusterizados
-- ============================================= 

DECLARE @tbl TABLE (
	 ID INT IDENTITY(1, 1)
	,DBNome NVARCHAR(100)
	,SchemaNome NVARCHAR(100)
	,TabelaNome NVARCHAR(100)
	)
DECLARE @SQL NVARCHAR(MAX)

SELECT @SQL = '
       SELECT ''?'',ss.name, ts.Name
         FROM ?.sys.tables ts
 LEFT JOIN ?.sys.indexes si
           ON  ts.object_id = si.object_id
          AND  si.type = 1
		    INNER JOIN ?.sys.schemas ss on ts.schema_id = ss.schema_id
INNER JOIN ?. sys.databases d
              ON d.Name=''?'' AND d.name NOT IN ( ''tempdb'',''master'',''msdb'',''ReportServer'')
     WHERE  si.index_id IS NULL
       '

INSERT INTO @tbl
EXECUTE sp_MSforeachdb @SQL

SELECT DBNome
	  ,CONCAT (SchemaNome,'.',TabelaNome) Tabela
FROM @tbl
ORDER BY ID