USE Northwind
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

SELECT TOP 100
       s.plan_id,
       q.query_id,
       t.query_sql_text AS QueryText,
       OBJECT_NAME(q.object_id) AS parent_object,
       SUM(s.count_executions) AS CountExecutions,
       CONVERT(DECIMAL(18,2),AVG(s.avg_logical_io_reads)) AS AvgLogicalReads,
       CONVERT(DECIMAL(18,2),AVG(s.avg_physical_io_reads)) AS AvgPhysicalReads,
       CONVERT(DECIMAL(18,2),AVG(s.avg_cpu_time)) AS AvgCpuTime,
       CONVERT(DECIMAL(18,2),AVG(s.avg_duration)) AS AvgDuration
FROM sys.query_store_query_text t
    JOIN sys.query_store_query q
        ON t.query_text_id = q.query_text_id
    JOIN sys.query_store_plan p 
       ON q.query_id = p.query_id 
    JOIN sys.query_store_runtime_stats s 
       ON p.plan_id = s.plan_id
--WHERE t.query_sql_text LIKE N'%CustomersBig%'
GROUP BY s.plan_id,
       q.query_id, 
       t.query_sql_text,
       OBJECT_NAME(q.object_id) 
ORDER BY CountExecutions DESC
GO

-- Find Plan(s) Associated with a Query
SELECT  t.query_sql_text, q.query_id, p.plan_id, object_name(q.object_id) AS parent_object, 
        CONVERT(XML, p.query_plan) AS qPlan
 FROM sys.query_store_query_text t JOIN sys.query_store_query q
  ON t.query_text_id = q.query_text_id 
 JOIN sys.query_store_plan p ON q.query_id = p.query_id 
WHERE q.query_id = 6 
 -- OR t.query_sql_text LIKE  N'%SELECT c1, c2 FROM  dbo.db_store%'
 -- OR object_name(q.object_id) = 'proc_1'