/*

Identificar tabelas HEAP (sem índice clustered)
https://www.dirceuresende.com/blog/sql-server-consultas-uteis-do-dia-a-dia-do-dba-que-voce-sempre-tem-que-ficar-procurando-na-internet/

*/

SELECT
    B.[name] + '.' + A.[name] AS table_name, A.*
FROM
    sys.tables A
    JOIN sys.schemas B ON A.[schema_id] = B.[schema_id]
    JOIN sys.indexes C ON A.[object_id] = C.[object_id]
WHERE
    C.[type] = 0 -- = Heap 
ORDER BY
    table_name


