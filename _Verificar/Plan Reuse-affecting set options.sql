/*
  Demo 9 - Plan Reuse-affecting set options
*/

-- Limpar cache
DBCC FREEPROCCACHE
GO
SELECT * FROM Customers WHERE 1=1 AND ContactName = 'Fabiano';
GO

-- Rodar a mesma query 5 vezes no SQLQueryStress
GO

-- Query executada no SSMS
SELECT ecp.memory_object_address, ecp.usecounts, dm_exec_plan_attributes.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
CROSS APPLY sys.dm_exec_plan_attributes(ECP.plan_handle)
WHERE "text" LIKE '%AND ContactName =%'
AND "text" NOT LIKE '%dm_exec_cached_plans%'
AND ECP.usecounts <> 5
GO

-- Query executada no SQLQueryStress
SELECT ecp.memory_object_address, ecp.usecounts, dm_exec_plan_attributes.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
CROSS APPLY sys.dm_exec_plan_attributes(ECP.plan_handle)
WHERE "text" LIKE '%AND ContactName =%'
AND "text" NOT LIKE '%dm_exec_cached_plans%'
AND ECP.usecounts = 5
GO

-- Traduzindo o SetOptions
declare @set_options int = 251
if ((1 & @set_options) = 1) print 'ANSI_PADDING'
if ((4 & @set_options) = 4) print 'FORCEPLAN'
if ((8 & @set_options) = 8) print 'CONCAT_NULL_YIELDS_NULL'
if ((16 & @set_options) = 16) print 'ANSI_WARNINGS'
if ((32 & @set_options) = 32) print 'ANSI_NULLS'
if ((64 & @set_options) = 64) print 'QUOTED_IDENTIFIER'
if ((128 & @set_options) = 128) print 'ANSI_NULL_DFLT_ON'
if ((256 & @set_options) = 256) print 'ANSI_NULL_DFLT_OFF'
if ((512 & @set_options) = 512) print 'NoBrowseTable'
if ((4096 & @set_options) = 4096) print 'ARITHABORT'
if ((8192 & @set_options) = 8192) print 'NUMERIC_ROUNDABORT'
if ((16384 & @set_options) = 16384) print 'DATEFIRST'
if ((32768 & @set_options) = 32768) print 'DATEFORMAT'
if ((65536 & @set_options) = 65536) print 'LanguageID'
GO
