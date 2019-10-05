/*

Estatísticas há mais de DD dias sem atualizar

*/

DECLARE @DD INT = 7

SELECT
    D.last_updated AS [LastUpdate],
    B.[name] AS [Table],
    A.[name] AS [Statistic],
    D.modification_counter AS ModificationCounter,
    'UPDATE STATISTICS [' + E.[name] + '].[' + B.[name] + '] [' + A.[name] + '] WITH FULLSCAN' AS UpdateStatisticsCommand
FROM
    sys.stats A
    JOIN sys.objects B ON A.[object_id] = B.[object_id]
    JOIN sys.indexes C ON C.[object_id] = B.[object_id] AND A.[name] = C.[name]
    OUTER APPLY sys.dm_db_stats_properties(A.[object_id], A.stats_id) D
    JOIN sys.schemas E ON B.[schema_id] = E.[schema_id]
WHERE
    D.last_updated < GETDATE() - @DD
    AND E.[name] NOT IN ( 'sys', 'dtp' )
    AND B.[name] NOT LIKE '[_]%'
    AND D.modification_counter > 1000
ORDER BY
    D.modification_counter DESC