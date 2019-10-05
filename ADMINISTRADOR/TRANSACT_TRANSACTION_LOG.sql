/*

https://www.dirceuresende.com/blog/sql-server-consultas-uteis-do-dia-a-dia-do-dba-que-voce-sempre-tem-que-ficar-procurando-na-internet/
Identifica o uso da transaction log de cada database na inst�ncia (equivalente ao DBCC SQLPERF(LOGSPACE))

*/

SELECT
    RTRIM(A.instance_name) AS [Database Name],
    A.cntr_value / 1024.0 AS [Log Size (MB)],
    CAST(B.cntr_value * 100.0 / A.cntr_value AS DEC(18, 5)) AS [Log Space Used (%)]
FROM
    sys.dm_os_performance_counters A
    JOIN sys.dm_os_performance_counters B ON A.instance_name = B.instance_name
WHERE
    A.[object_name] LIKE '%Databases%'
    AND B.[object_name] LIKE '%Databases%'
    AND A.counter_name = 'Log File(s) Size (KB)'
    AND B.counter_name = 'Log File(s) Used Size (KB)'
    AND A.instance_name NOT IN ( '_Total', 'mssqlsystemresource' )
    AND A.cntr_value > 0