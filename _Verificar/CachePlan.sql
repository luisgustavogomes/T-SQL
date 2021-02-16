/*
  Cachestore

  Os seguintes caches s�o inclu�dos no cachestore: 
  1.	Compiled Plans (CP)
  1.1 - Queries din�micas e prepared = sql CP
  1.2 - Triggers, functions e procs = obj CP
  2.	Execution plans (MXC)
  3.	Algebrizer tree (ProcHdr)
  4.	Extended Procs (XProcs)
  5.	Inactive Cursors

*/

USE Northwind
GO

-- Demo 1 - Vis�o geral e DMVs (dm_exec_cached_plans, dm_exec_query_stats e sys.syscacheobjects)

-- Limpar o cache
--ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
DBCC FREEPROCCACHE()
GO

EXEC sp_executesql N'SELECT * FROM Customers WHERE CustomerID = @i', N'@i int', @i = 10
GO 10

-- A cache de planos
-- Usando o CROSS APPLY para ver o texto e o plano
SELECT *
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) E
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
WHERE E.dbid = DB_ID()
ORDER BY ECP.usecounts DESC
GO

-- Qual a diferen�a entre os dois?
-- Bastante coisa aqui eim? ... 
SELECT *
FROM sys.dm_exec_query_stats as EQS
CROSS APPLY sys.dm_exec_sql_text(EQS.sql_handle)
CROSS APPLY sys.dm_exec_query_plan(EQS.plan_handle)
WHERE EQS.plan_handle = 0x06000500CC51772AF068D91D5802000001000000000000000000000000000000000000000000000000000000
GO

-- Note:
-- Por compatibilidade com o SQL Server 2000, mantida view
SELECT *
FROM sys.syscacheobjects
go


-- Demo 2 - T�, mas eu preciso mesmo do plan cache? 
/*
  T�, mas eu preciso mesmo do plan cache? 
*/

DBCC FREEPROCCACHE()
GO

-- Abrir App 
-- D:\Fabiano\Trabalho\Sr.Nimbus\Cursos\SQL26 - SQL Server - Mastering the database engine (former Internals)\Slides\M�dulo 02 - Mem�ria parte 1\6 - Memory clerks - CachePlan\Loop Delphi


SELECT *
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
ORDER BY ECP.usecounts DESC
GO

/*
  Ok, ainda n�o fui convencido de que isso realmente afeta performance.
*/
-- Limpar o PlanCache
DBCC FREEPROCCACHE
GO
SET STATISTICS TIME ON
GO
SELECT TOP 1 Aux = Orders.CustomerID
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 INNER JOIN Order_Details
    ON Orders.OrderID = Order_Details.OrderID
 WHERE Orders.OrderID = 10248
GO
SET STATISTICS TIME OFF
GO

-- Encapsular o c�digo em uma Procedure
CREATE PROC st_TestRecompile @ID Integer, 
                             @ID_Saida Integer OUTPUT
AS
SELECT TOP 1 @ID_Saida = Orders.CustomerID
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 INNER JOIN Order_Details
    ON Orders.OrderID = Order_Details.OrderID
 WHERE Orders.OrderID = @ID
GO


-- Test Proc
DECLARE @i Int
EXEC st_TestRecompile @ID = 10248, @ID_Saida = @i OUT
SELECT @i


/*
  Executar a proc acima 10 mil vezes
*/
DBCC FREEPROCCACHE
GO
DECLARE @i Integer, @Aux Int
SET @i = 0 
WHILE @i < 10000
BEGIN 
  EXEC st_TestRecompile @ID = @i, @ID_Saida = @Aux OUT

  SET @i = @i + 1 
END 
GO

-- Verificar quantas vezes o plano da proc foi reutilizado
SELECT a.usecounts,
       a.cacheobjtype,
       a.objtype,
       b.text AS Comando_SQL,
       c.query_plan, *
  FROM sys.dm_exec_cached_plans a
 CROSS APPLY sys.dm_exec_sql_text (a.plan_handle) b
 CROSS APPLY sys.dm_exec_query_plan (a.plan_handle) c
GO


/*
  Executar a mesma proc 10 mil vezes
  mas desta vez pedindo para recompilar o plano.
  Ouch!
*/
DBCC FREEPROCCACHE
GO
DECLARE @i Integer, @Aux Int
SET @i = 0 
WHILE @i < 10000
BEGIN 
  EXEC st_TestRecompile @ID = @i, @ID_Saida = @Aux OUT WITH RECOMPILE

  SET @i = @i + 1 
END 
GO


/*
  Demo 3 - Simple - AutoParam
*/

DBCC FREEPROCCACHE()
GO

-- Essa � uma query adhoc? 
SELECT * 
  FROM Employees
 WHERE FirstName = 'Nancy' 
GO

-- E essa?
SELECT * 
  FROM Employees
 WHERE FirstName = 'Robert' 
GO

-- Como ficam os planos? 
-- U�ee, mas ainda tem os planos l�, eu to vendo... Calma:
---- "These shell queries do not contain the full execution plan but only a pointer to the full plan in the corresponding prepared plan"
SELECT usecounts, cacheobjtype, objtype, size_in_bytes, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE cacheobjtype = 'Compiled Plan'
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO
-- SQL fez um bom trabalho definindo o parametro como VARCHAR(8000)...


DBCC FREEPROCCACHE()
GO

SELECT * 
  FROM Orders
 WHERE Value = 10.1
GO
SELECT * 
  FROM Orders
 WHERE Value = 10.11
GO
SELECT * 
  FROM Orders
 WHERE Value = 10.111
GO

-- Umm, not so good...
SELECT usecounts, cacheobjtype, objtype, size_in_bytes, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE cacheobjtype = 'Compiled Plan'
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO

-- Auto param raramente vai funcionar... na verdade, apenas pra consultas muito simples...

DBCC FREEPROCCACHE()
GO

-- Auto param? 
SELECT TOP 1 * 
  FROM Employees
 WHERE FirstName = 'Nancy'
GO

SELECT usecounts, cacheobjtype, objtype, size_in_bytes, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE cacheobjtype = 'Compiled Plan'
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO


/*
  https://docs.microsoft.com/en-us/previous-versions/tn-archive/cc293623%28v%3dtechnet.10%29
  There are many query constructs that normally disallow autoparameterization. Such constructs include any statements with the following elements:

  JOIN
  BULK INSERT
  IN lists
  UNION
  INTO
  FOR BROWSE
  OPTION <query hints>
  DISTINCT
  TOP
  WAITFOR statements
  GROUP BY, HAVING, COMPUTE
  Full-text predicates
  Subqueries
  FROM clause of a SELECT statement has table valued method or full-text table or OPENROWSET or OPENXML or OPENQUERY or OPENDATASOURCE
  Comparison predicate of the form EXPR <> a non-null constant
  Autoparameterization is also disallowed for data modification statements that use the following constructs:

  DELETE/UPDATE with FROM CLAUSE
  UPDATE with SET clause that has variables
*/


/*
  O correto � utilizar par�metros, mas fa�a isso corretamente.
*/

-- Demo 4 - Cuidados com parameteriza��o na App e TF144

DBCC FREEPROCCACHE()
GO

-- Abrir app 
-- D:\Fabiano\Trabalho\Sr.Nimbus\Cursos\SQL26 - SQL Server - Mastering the database engine (former Internals)\Slides\M�dulo 02 - Mem�ria parte 1\6 - Memory clerks - CachePlan\Cache Plans Test
/*
  Exemplo programa (Delphi) passando o tamanho do datatype errado
  
  Analisar a consulta utilizando a sp_executeSQL no Profiler:
  exec sp_executesql N'SELECT * FROM Orders
                        INNER JOIN Customers
                           ON Orders.CustomerID = Customers.CustomerID
                        INNER JOIN Order_Details
                           ON Orders.OrderID = Order_Details.OrderID
                        WHERE Customers.ContactName = @P1
                        ',N'@P1 varchar(3)','Liu Wong'

  No programa procurar por 
  "Ana"
  "Antonio Moreno"
  "Fabio"
  "Gilmar"
  "Gabriel"
  "Vinicius"
  "Alexandre"
  "Wellington"
*/

SELECT a.usecounts,
       a.cacheobjtype,
       a.objtype,
       b.text AS Comando_SQL,
       c.query_plan,
       d.query_hash, 
       *
  FROM sys.dm_exec_cached_plans a
 CROSS APPLY sys.dm_exec_sql_text (a.plan_handle) b
 CROSS APPLY sys.dm_exec_query_plan (a.plan_handle) c
 INNER JOIN sys.dm_exec_query_stats d
    ON a.plan_handle = d.plan_handle
 WHERE "text" NOT LIKE '%sys.%'
   AND "text" LIKE '%SELECT * FROM Orders%'
 ORDER BY creation_time ASC
GO

-- Se poss�vel, corrigir o app para passar o tamnanho do par�metro corretamente
-- Caso n�o seja poss�vel corrigir a app, considerar TF 144 -- http://blogs.msdn.microsoft.com/sqlprogrammability/2007/01/13/6-0-best-programming-practices

-- Habilitar T144 e rodar app novamnete...

-- Sucesso!

/*
  Demo 5 - Forced parameterization
*/

USE Northwind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

-- Setar o banco como PARAMETERIZATION FORCED
ALTER DATABASE NorthWind SET PARAMETERIZATION FORCED WITH NO_WAIT
GO

-- Limpar o PlanCache
DBCC FREEPROCCACHE
GO
SELECT *
  FROM OrdersBig
 WHERE OrderID < 100 AND ISNULL(CustomerID,0) = 100
GO
SELECT *
  FROM OrdersBig
 WHERE OrderID < 100 AND ISNULL(CustomerID,0) = 500
GO

-- Consulta o plano de execu��o em cache
SELECT a.usecounts,
       a.cacheobjtype,
       a.objtype,
       b.text AS Comando_SQL,
       c.query_plan, *
  FROM sys.dm_exec_cached_plans a
 CROSS APPLY sys.dm_exec_sql_text (a.plan_handle) b
 CROSS APPLY sys.dm_exec_query_plan (a.plan_handle) c
 WHERE "text" NOT LIKE '%sys.%'
   AND "text" LIKE '%OrdersBig%'
GO

-- Sucesso, forced param entrou


/*
  Forced param pode causar PSP
  http://blogs.msdn.com/b/sql_pfe_blog/archive/2013/09/03/forced-parameterization-can-lead-to-poor-performance.aspx
  
  Guided plans podem ser utilizados para for�ar plano na query
*/

-- Voltar ao padr�o, Setar o banco como PARAMETERIZATION SIMPLE
ALTER DATABASE NorthWind SET PARAMETERIZATION SIMPLE WITH NO_WAIT
GO

-- Query n�o � auto parametrizada
SELECT *
  FROM OrdersBig
 WHERE OrderID < 100 AND ISNULL(CustomerID,0) = 100
GO


DECLARE @stmt nvarchar(max);
DECLARE @params nvarchar(max);
EXEC sp_get_query_template 
N'SELECT *
  FROM OrdersBig
 WHERE OrderID < 100 
AND ISNULL(CustomerID,0) = 100',
	@stmt OUTPUT, @params OUTPUT;
	
EXEC sp_create_plan_guide 
	  N'TemplateGuide1', 
	  @stmt, 
	  N'TEMPLATE', 
	  NULL, 
	  @params, 
	  N'OPTION(PARAMETERIZATION FORCED)';
GO

-- Query parametrizada... via Forced
SELECT *
  FROM OrdersBig
 WHERE OrderID < 100 AND ISNULL(CustomerID,0) = 100
GO

-- Clean up
EXEC sp_control_plan_guide N'DROP', 'TemplateGuide1'
GO

-- Cleanup, setar o banco como PARAMETERIZATION SIMPLE
ALTER DATABASE NorthWind SET PARAMETERIZATION SIMPLE WITH NO_WAIT
GO



/*
  Demo 6 - Optimize for adhoc workloads
*/

-- Desabilitar optimize for ad hoc workloads
EXEC sys.sp_configure N'optimize for ad hoc workloads', N'0'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Limpar o PlanCache
DBCC FREEPROCCACHE
GO

-- Rodar batch abaixo no SQLQueryStress pra gerar cen�rio de v�rias queries AdHoc rodando... 
-- SQLQueryStressConfig = 10 threads, 50 iterarions = 500 itera��es... 
-- AdHocTest.sqlstress
DECLARE @Var VarChar(2000), @SQL VarChar(MAX)

SET @Var = NEWID()
SET @SQL = '/* AdHoc shit */ SELECT * FROM Products WHERE Products.ProductName = ''' + @Var + ''''

-- Print @SQL
EXEC (@SQL)


-- So far so good... 500 planos em cache... well, not good...
-- Considerando o coment�rio abaixo... Posso ter 16k desses lixos em cache... 
SELECT p.memory_object_address, p.bucketid, usecounts, cacheobjtype, objtype, size_in_bytes / 1024. AS size_in_kb, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE [text] LIKE '%AdHoc shit%' 
AND [text] NOT LIKE '%dm_exec_cached_plans%';

-- The maximum number of entries that a plan cache can hold is four times the bucket count. 
-- On 64-bit systems, the number of buckets for the SQL Server plan cache is 40,009. 
-- Therefore, the maximum number of entries that can fit inside the SQL Server plan cache is 160,036.

-- Tive um cliente que usou o TF 174 :-( ...
-- Trace flag "-T 174," the bucket count is increased to 160,001 on 64-bit systems. The plan cache is then able to hold a maximum of 640,004 plans.

-- E se eu rodar esse dem�nio no SQLQueryStress? 
-- SQLQueryStressConfig = 8 threads, 10 iterarions = 80 itera��es... 
-- AdHocTestDemonio.sqlstress
-- Veja CPU...

--SQL Server parse and compile time: CPU time = 688 ms, elapsed time = 703 ms.
--SQL Server Execution Times: CPU time = 15 ms,  elapsed time = 26 ms.

DECLARE @Var VarChar(2000), @SQL VarChar(MAX)

SET @Var = NEWID()
SET @SQL = '/* AdHoc shit */ SELECT Orders.OrderID, COUNT(DISTINCT Orders.CustomerID), SUM(Orders.Value) 
FROM Orders INNER JOIN Customers ON Customers.CustomerID = Orders.CustomerID INNER JOIN Order_Details ON Order_Details.OrderID = Orders.OrderID INNER JOIN Products ON Products.ProductID = Order_Details.ProductID INNER JOIN Products a ON a.ProductID = Order_Details.ProductID INNER JOIN Products b ON b.ProductID = Order_Details.ProductID INNER JOIN Products c ON c.ProductID = Order_Details.ProductID INNER JOIN Products d ON d.ProductID = Order_Details.ProductID INNER JOIN Products e ON e.ProductID = Order_Details.ProductID INNER JOIN Products f ON f.ProductID = Order_Details.ProductID INNER JOIN Products g ON g.ProductID = Order_Details.ProductID 
WHERE Products.ProductName = ''' + @Var + ''' 
AND Orders.EmployeeID IN (976736, 976737, 977810, 980914, 981921, 982937,
                              982938, 982939, 986280, 986299, 987372, 988403,
                              988404, 988405, 988406, 988407, 988408, 988409,
                              988410, 988411, 989454, 989456, 989457, 989458,
                              989459, 989460, 991571, 991572, 991573, 991574,
                              991575, 991576, 993757, 993758, 993759, 993760,
                              993761, 993762, 993763, 996894, 997862, 997866,
                              998893, 1001998, 1001999, 1002000, 1002984,
                              1002985, 1002986, 1002987, 1004047, 1008256,
                              1008257, 1008258, 1008259, 1009324, 1011521,
                              1012578, 1012579, 1012580, 1012581, 1012582,
                              1012583, 1012584, 1012585, 1014629, 1014630,
                              1014631, 1014632, 1014633, 1014634, 1016926,
                              1017861, 1017862, 1017864, 1019894, 1019895,
                              1022652, 1022653, 1022654, 1022655, 1022656,
                              1023579, 1023581, 1023582, 1023583, 1023584,
                              1024554, 1024555, 1024556, 1026576, 1026577,
                              1026578, 1026579, 1026580, 1026581, 1026582,
                              1027541, 1027542, 1028507, 1028508, 1030036,
                              1034232, 1034233, 1035670, 1035671, 1035672,
                              1035673, 1035674, 1035675, 1035676, 1038634,
                              1042568, 1043703, 1046633, 1046634, 1046635,
                              1046636, 1046637, 1046638, 1046639, 1046640,
                              1047686, 1051158, 1051159, 1053112, 1053113,
                              1054224, 1054226, 1054227, 1057811, 1057812,
                              1057813, 1057814, 1057815, 1057816, 1060362,
                              1060363, 1060364, 1060365, 1060366, 1060367,
                              1060368, 1060369, 1060370, 1060371, 1060372,
                              1061376, 1061377, 1061378, 1061379, 1063357,
                              1063359, 1063361, 1064373, 1064374, 1064375,
                              1064376, 1064377, 1067705, 1067706, 1068900,
                              1068901, 1073630, 1073631, 1073632, 1073633,
                              1073634, 1073635, 1073636, 1073637, 1073638,
                              1079086, 1079087, 1079088, 1079089, 1079090,
                              1079091, 1084701, 1085727, 1085728, 1085729,
                              1085730, 1085731, 1085732, 1087524, 1087525,
                              1087526, 1087527, 1087528, 1090608, 1090610,
                              1090611, 1090612, 1090613, 1090614, 1091537,
                              1091538, 1091539, 1091540, 1091541, 1091542,
                              1092558, 1093689, 1094865, 1094866, 1094867,
                              1094868, 1094869, 1095957, 1095958, 1095959,
                              1098000, 1098002, 1102130, 1102131, 1102132,
                              1102133, 1102134, 1102135, 1102136, 1102137,
                              1102138, 1103352, 1107427, 1112763, 1112765,
                              1112766, 1112767, 1112768, 1113756, 1114778,
                              1117041, 1117043, 1117044, 1117045, 1117046,
                              1117047, 1117048, 1117049, 1117050, 1117051,
                              1117052, 1117053, 1117054, 1117055, 1117056,
                              1117057, 1117058, 1117059, 1117061, 1118165,
                              1118167, 1118168, 1118169, 1118170, 1118171,
                              1118172, 1118173, 1118174, 1118176, 1120434,
                              1121468, 1121469, 1121470, 1121471, 1121472,
                              1121473, 1122766, 1122767, 1122768, 1122769,
                              1122770, 1122771, 1122772, 1127146, 1127147,
                              1127148, 1127149, 1127150, 1135477, 1135479,
                              1135480, 1136545, 1136546, 1137671, 1137672,
                              1137673, 1137674, 1139009, 1140067, 1141119,
                              1142518, 1143768, 1143769, 1143770, 1143771,
                              1143772, 1143773, 1143774, 1143775, 1145246,
                              1145247, 1145248, 1145249, 1145250, 1145251,
                              1145252, 1145253, 1145254, 1145255, 1145256,
                              1145257, 1145258, 1145259, 1145260, 1145261,
                              1145262, 1145263, 1145264, 1145265, 1145266,
                              1145267, 1145268, 1145269, 1145270, 1145271,
                              1145272, 1145273, 1145274, 1145275, 1145276,
                              1145277, 1145278, 1145279, 1145280, 1145281,
                              1145282, 1145283, 1145284, 1145285, 1145286,
                              1145287, 1152789, 1152790, 1152791, 1152792,
                              1152793, 1152794, 1152795, 1152796, 1152797,
                              1152798, 1152799, 1152800, 1152801, 1152802,
                              1155187, 1155188, 1155189, 1155190, 1155191,
                              1155192, 1155193, 1155194, 1155195, 1156440,
                              1156441, 1156442, 1156443, 1156444, 1158575,
                              1159636, 1160970, 1160971, 1161970, 1161971,
                              1161972, 1161973, 1161974, 1161975, 1161976,
                              1161977, 1161978, 1161979, 1161980, 1161981,
                              1161982, 1161983, 1163732, 1163733, 1166079,
                              1167200, 1167201, 1167202, 1167203, 1167204,
                              1167205, 1167207, 1169624, 1169625, 1169626,
                              1169627, 1169628, 1169629, 1169630, 1169631,
                              1169632, 1169633, 1169634, 1169635, 1169636,
                              1169637, 1169638, 1169639, 1169640, 1169641,
                              1169642, 1169643, 1169644, 1169645, 1169646,
                              1169647, 1169648, 1169649, 1169650, 1169651,
                              1169652, 1169653, 1169654, 1169655, 1169656,
                              1169657, 1169658, 1169659, 1169660, 1169661,
                              1169662, 1169663, 1169664, 1169665, 1169666,
                              1169667, 1169668, 1169669, 1169670, 1169671,
                              1169672, 1169673, 1169674, 1169675, 1169676,
                              1169677, 1169678, 1169679, 1169680, 1169681,
                              1169682, 1169683, 1169684, 1169685, 1179279,
                              1179281, 1180618, 1180619, 1180620, 1180621,
                              1180622, 1180623, 1180624, 1180625, 1180626,
                              1180627, 1180628, 1180629, 1180630, 1180631,
                              1180632, 1180633, 1180634, 1180635, 1180636,
                              1180637, 1180638, 1180639, 1180640, 1180641,
                              1180642, 1180643, 1180644, 1180645, 1180646,
                              1181861, 1181862, 1181863, 1181864, 1181865,
                              1185424, 1185425, 1185426, 1185427, 1185428,
                              1185429, 1185430, 1185431, 1185432, 1185433,
                              1185434, 1185435, 1185436, 1185437, 1186544,
                              1192888, 1192889, 1192890, 1192891, 1192892,
                              1192893, 1192894, 1192895, 1195099, 1208410,
                              1211787, 1211788, 1216457, 1216458, 1216459,
                              1216460, 1217670, 1217671, 1217672, 1217673,
                              1226154, 1231934, 1234616, 1234617, 1234618,
                              1234619, 1238967, 1238968, 1238969, 1238970,
                              1238971, 1238972, 1240078, 1240079, 1255125,
                              1255126, 1255127, 1255128, 1255129, 1255130,
                              1255131, 1258008, 1258009, 1258010, 1259371,
                              1259372, 1260491, 1260492, 1260493, 1266122,
                              1266123, 1266124, 1266125, 1266126, 1266127,
                              1266128, 1266129, 1266130, 1270529, 1270530,
                              1288282, 1288283, 1288284, 1288285, 1288286,
                              1288287, 1288288, 1288289, 1288290, 1289479,
                              1290481, 1290482, 1296177, 1296179, 1296180,
                              1296181, 1296182, 1296183, 1296184, 1296185,
                              1296186, 1296187, 1296188, 1296189, 1296190,
                              1297339, 1297340, 1297341, 1297342, 1297343,
                              1297344, 1297345, 1297346, 1297347, 1297348,
                              1297349, 1298555, 1298556, 1298557, 1298558,
                              1298559, 1298560, 1298561, 1298562, 1298563,
                              1298564, 1298565, 1298566, 1298567, 1298568,
                              1298569, 1298570, 1298571, 1298572, 1298573,
                              1298574, 1298575, 1298576, 1298577, 1298578,
                              1298579, 1298580, 1305030, 1305033, 1309156,
                              1309167, 1309168, 1309169, 1309170, 1309171,
                              1311419, 1311420, 1311421, 1311422, 1311423,
                              1311424, 1311425, 1311426, 1311427, 1315708,
                              1318651, 1318652, 1318653, 1318654, 1318655,
                              1318656, 1318657, 1318658, 1318659, 1318660,
                              1320798, 1328462, 1333409, 1335298, 1335300,
                              1340231, 1340232, 1340233, 1340234, 1341370,
                              1348296, 1352498, 1352499, 1352500, 1352501,
                              1352502, 1352503, 1354277, 1354278, 1354279,
                              1354280, 1354281, 1354282, 1354283, 1354284,
                              1354285, 1354286, 1354287, 1354288, 1354289,
                              1354290, 1354291, 1354292, 1354293, 1354294,
                              1354295, 1354296, 1354297, 1354298, 1354299,
                              1354300, 1354301, 1354302, 1354303, 1354304,
                              1354305, 1354306, 1354307, 1354309, 1354311,
                              1354312, 1354313, 1354314, 1354315, 1356192,
                              1357656, 1357657, 1357658, 1357660, 1391750,
                              1391754, 1391762, 1391763, 1391765, 1391768,
                              1391772, 1391774, 1391775, 1391781, 1391790,
                              1391791, 1391792, 1391799, 1391800, 1391809,
                              1400116, 1400135, 1400727, 1401421, 1401542,
                              1401586, 1401964, 1401993, 1402248, 1402366,
                              1402483, 1402744, 1402975, 1403084, 1403104,
                              1403271, 1403740, 1403856, 1403888, 1403921,
                              1403935, 1403976, 1404364, 1404510, 1404533,
                              1404611, 1404735, 1404827, 1404846, 1404906,
                              1404974, 1405043, 1405094, 1405836, 1405977,
                              1406078, 1406182, 1406208, 1406276, 1406331,
                              1406430, 1406476, 1406503, 1406530, 1406660,
                              1406792, 1406852, 1406897, 1406993, 1407062,
                              1407168, 1407389, 1407397, 1407440, 1407560,
                              1407853, 1407939, 1408103, 1408303, 1408350,
                              1408372, 1408561, 1408769, 1408817, 1408889,
                              1408925, 1409030, 1409237, 1409362, 1409462,
                              1409520, 1409533, 1409587, 1409599, 1409608,
                              1409669, 1409687, 1409729, 1409877, 1409945,
                              1410016, 1410057, 1410100, 1410219, 1410387,
                              1410397, 1410464, 1410638, 1410657, 1410861,
                              1411106, 1411201, 1411209, 1411224, 1411280,
                              1411793, 1412083, 1412180, 1412368, 1412540,
                              1412541, 1412597, 1412638, 1412826, 1412866,
                              1412887, 1412936, 1413182, 1413290, 1413357,
                              1413400, 1413539, 1413560, 1413609, 1413613,
                              1413894, 1414071, 1414183, 1414220, 1414308,
                              1414319, 1414347, 1414366, 1414608, 1414667,
                              1414795, 1414843, 1415017, 1415049, 1415059,
                              1415185, 1415383, 1415443, 1415548, 1415716,
                              1415740, 1415743, 1415753, 1415771, 1415847,
                              1415882, 1415951, 1415970, 1416226, 1416363,
                              1416522, 1416595, 1416859, 1417113, 1417156,
                              1417269, 1417298, 1417469, 1417535, 1417792,
                              1417832, 1417865, 1417875, 1417919, 1418052,
                              1418201, 1418226, 1418267)
OR Orders.CustomerID IN (1418467, 1418519, 1418680, 1418792, 1418842,
                                 1419021, 1419064, 1419093, 1419266, 1419276,
                                 1419385, 1419429, 1419461, 1419577, 1419608,
                                 1419637, 1419725, 1419811, 1420200, 1420213,
                                 1420231, 1420553, 1420583, 1420596, 1420708,
                                 1420895, 1420912, 1421003, 1421025, 1421069,
                                 1421091, 1421145, 1421213, 1421247, 1421358,
                                 1421615, 1421625, 1421680, 1421715, 1421717,
                                 1421836, 1421880, 1421910, 1422007, 1422065,
                                 1422116, 1422143, 1422377, 1422644, 1422832,
                                 1422861, 1422871, 1422951, 1423017, 1423273,
                                 1423282, 1423493, 1423591, 1423667, 1423674,
                                 1423705, 1423861, 1424006, 1424070, 1424335,
                                 1424349, 1424376, 1424420, 1424497, 1424635,
                                 1424689, 1424750, 1424752, 1424811, 1424880,
                                 1424912, 1425004, 1425060, 1425100, 1425121,
                                 1425217, 1425219, 1425287, 1425353, 1425357,
                                 1425464, 1425578, 1425669, 1425693, 1425746,
                                 1425750, 1425802, 1425928, 1426065, 1426091,
                                 1426387, 1426419, 1426598, 1426759, 1427006,
                                 1427139, 1427217, 1427231, 1427269, 1427277,
                                 1427415, 1427640, 1428073, 1428187, 1428195,
                                 1428276, 1428397, 1428511, 1428532, 1428551,
                                 1428611, 1428742, 1428795, 1428822, 1429038,
                                 1429060, 1429088, 1429131, 1429394, 1429407,
                                 1429463, 1429537, 1429581, 1429594, 1429730,
                                 1429750, 1429769, 1429834, 1430204, 1430348,
                                 1430406, 1430495, 1430669, 1430730, 1430753,
                                 1431002, 1431065, 1431254, 1431302, 1431347,
                                 1431571, 1431686, 1431874, 1431904, 1432006,
                                 1432072, 1432111, 1432213, 1432245, 1432327,
                                 1432420, 1432591, 1432713, 1432768, 1432771,
                                 1433187, 1433440, 1433464, 1433478, 1433632,
                                 1433637, 1433972, 1434033, 1434095, 1434182,
                                 1434254, 1434257, 1434277, 1434337, 1434500,
                                 1434656, 1434659, 1434718, 1434810, 1434942,
                                 1435056, 1435097, 1435100, 1435164, 1435191,
                                 1435292, 1435344, 1435464, 1435550, 1435578,
                                 1435746, 1435851, 1435941, 1436123, 1436193,
                                 1436284, 1436300, 1436568, 1436726, 1436868,
                                 1436878, 1436964, 1436969, 1437294, 1437334,
                                 1437421, 1437424, 1437431, 1437455, 1437530,
                                 1437532, 1437909, 1438013, 1438017, 1438159,
                                 1438182, 1438237, 1438805, 1438840, 1438885,
                                 1438908, 1438919, 1438973, 1439004, 1439134,
                                 1439189, 1439215, 1439326, 1439500, 1439537,
                                 1440026, 1440029, 1440050, 1440177, 1440194,
                                 1440215, 1440231, 1440240, 1440326, 1440388,
                                 1440427, 1440428, 1440438, 1440970, 1441092,
                                 1441206, 1441227, 1441267, 1441302, 1441400,
                                 1441446, 1441509, 1441577, 1441827, 1441941,
                                 1442042, 1442054, 1442060, 1442137, 1442189,
                                 1442435, 1442588, 1442679, 1442686, 1442690,
                                 1442691, 1442822, 1442876, 1443058, 1443070,
                                 1443104, 1443196, 1443283, 1443363, 1443396,
                                 1443446, 1443456, 1443511, 1443520, 1443582,
                                 1443663, 1443682, 1443988, 1444511, 1444526,
                                 1444566, 1444585, 1444650, 1444799, 1445017,
                                 1445051, 1445066, 1445191, 1445200, 1445235,
                                 1445267, 1445275, 1445307, 1445319, 1445469,
                                 1445763, 1445920, 1445942, 1446048, 1446083,
                                 1446357, 1446508, 1446733, 1446876, 1446887,
                                 1447095, 1447194, 1447282, 1447378, 1447410,
                                 1447411, 1447556, 1447576, 1447589, 1447658,
                                 1447731, 1447735, 1447947, 1447968, 1448099,
                                 1448182, 1448313, 1448339, 1448407, 1448463,
                                 1448559, 1448608, 1448634, 1448658, 1448793,
                                 1448924, 1448984, 1449029, 1449124, 1449193,
                                 1449300, 1449518, 1449530, 1449570, 1449690,
                                 1449724, 1449736, 1449759, 1449804, 1449818,
                                 1449847, 1449967, 1449970, 1450058, 1450102,
                                 1450174, 1450217, 1450227, 1450290, 1450291,
                                 1450362, 1450391, 1450551, 1450662, 1450837,
                                 1451323, 1451360, 1451375, 1451436, 1451538,
                                 1451725, 1451759, 1451877, 1452066, 1452123,
                                 1452205, 1452257, 1452286, 1452305, 1452381,
                                 1452426, 1452552, 1452645, 1452758, 1452838,
                                 1452842, 1452898, 1452901, 1453010, 1453225,
                                 1453416, 1453432, 1453455, 1453543, 1453547,
                                 1453557, 1453637, 1453668, 1453807, 1453844,
                                 1453845, 1453956, 1454168, 1454359, 1454374,
                                 1454752, 1454810, 1454811, 1454868, 1454907,
                                 1455278, 1455335, 1455396, 1455481, 1455522,
                                 1455602, 1455640, 1455648, 1455662, 1455718,
                                 1455815, 1455844, 1455858, 1455904, 1456208,
                                 1456252, 1456269, 1456369, 1456593, 1456767,
                                 1456775, 1456823, 1456826, 1456879, 1456982,
                                 1457224, 1457265, 1457367, 1457404, 1457424,
                                 1457474, 1457536, 1457542, 1457606, 1457906,
                                 1458014, 1458054, 1458245, 1458355, 1458356,
                                 1458399, 1458425, 1458532, 1458629, 1458697,
                                 1458800, 1458823, 1459026, 1459109, 1459371,
                                 1459385, 1459521, 1459548, 1459589, 1459764,
                                 1459827, 1459834, 1459997, 1459999, 1460342,
                                 1460354, 1460370, 1460608, 1460896, 1461021,
                                 1461048, 1461143, 1461161, 1461249, 1461281,
                                 1461290, 1461556, 1461663, 1461723, 1461795,
                                 1461806, 1461854, 1462104, 1462167, 1462253,
                                 1462254, 1462442, 1462800, 1462837, 1462875,
                                 1462928, 1462999, 1463126, 1463273, 1463355,
                                 1463456, 1463605, 1463648, 1463712, 1463743,
                                 1463915, 1464046, 1464165, 1464236, 1464281,
                                 1464347, 1464408, 1464460, 1464630, 1464705,
                                 1464718, 1464733, 1464849, 1464943, 1464955,
                                 1465037, 1465233, 1465423, 1465689, 1465692,
                                 1465717, 1465767, 1465770, 1465813, 1465910,
                                 1465965, 1465985, 1466311, 1466447, 1466461,
                                 1466485, 1466662, 1466695, 1466792, 1466868,
                                 1466890, 1467533, 1467919, 1468002, 1468134,
                                 1468193, 1468249, 1468279, 1468444, 1468485,
                                 1468724, 1468800, 1468824, 1468968, 1468995,
                                 1469429, 1469433, 1469489, 1469533, 1469622,
                                 1469704, 1469710, 1469910, 1470030, 1470049,
                                 1470054, 1470150, 1470161, 1470199, 1470315,
                                 1470399, 1470452, 1470465, 1470526, 1470631,
                                 1470796, 1471109, 1471264, 1471303, 1471373,
                                 1471502, 1471537, 1471595, 1472107, 1472437,
                                 1472500, 1472554, 1472634, 1472680, 1472699,
                                 1472736, 1472746, 1472775, 1472886, 1472999,
                                 1473030, 1473038, 1473253, 1473425, 1473428,
                                 1473503, 1473517, 1473612, 1473666, 1473675,
                                 1473693, 1473746, 1473898, 1474041, 1474061,
                                 1474105, 1474162, 1474170, 1474311, 1474320,
                                 1474355, 1474623, 1474668, 1474704, 1474732,
                                 1474884, 1474965, 1475090, 1475158, 1475182,
                                 1475194, 1475375, 1475491, 1475508, 1475560,
                                 1475594, 1475706, 1475818, 1475985, 1476147,
                                 1476274, 1476592, 1476753, 1476825, 1476847,
                                 1476990, 1477029, 1477217, 1477252, 1477257,
                                 1477333, 1477551, 1477570, 1477613, 1477700,
                                 1477747, 1477927, 1478148, 1478238, 1478252,
                                 1478326, 1478335, 1478373, 1478428, 1478453,
                                 1478689, 1478704, 1478734, 1478803, 1478898,
                                 1479069, 1479229, 1479345, 1479348, 1479445,
                                 1479450, 1479519, 1479773, 1479806, 1479843,
                                 1479904, 1480250, 1480270, 1480321, 1480401,
                                 1480456, 1480476, 1480594, 1480727, 1480878,
                                 1481103, 1481196, 1481303, 1481305, 1481367,
                                 1481398, 1481502, 1481578, 1481794, 1481830,
                                 1481860, 1481911, 1482034, 1482042, 1482127,
                                 1482186, 1482229, 1482514, 1482550, 1482557,
                                 1482592, 1482642, 1482871, 1482892, 1483004,
                                 1483168, 1483336, 1483505, 1483522, 1483547,
                                 1483584, 1483674, 1483696, 1483709, 1483718,
                                 1483832, 1483907, 1483963, 1484079, 1484311,
                                 1484410, 1484456, 1484556, 1484677, 1484786,
                                 1484921, 1484923, 1485051, 1485066, 1485261,
                                 1485264, 1485380, 1485445, 1485515, 1485537,
                                 1485699, 1485702, 1485853, 1485935, 1486254,
                                 1486300, 1486488, 1486685, 1486741, 1486852,
                                 1486866, 1486896, 1486988, 1487032, 1487037,
                                 1487719, 1487740, 1487847, 1488056, 1488107,
                                 1488278, 1488449, 1488460, 1488571, 1488621,
                                 1488704, 1488831, 1488930, 1489064, 1489203,
                                 1489206, 1489363, 1489418, 1489533, 1489612,
                                 1489613, 1489627, 1489665, 1489671, 1489871,
                                 1489880, 1489971, 1490046, 1490050, 1490087,
                                 1490166, 1490189, 1490313, 1490399, 1490432,
                                 1490438, 1490667, 1490691, 1490701, 1490717,
                                 1490739, 1490757, 1490978, 1491140, 1491165,
                                 1491355, 1491406, 1491420, 1491450, 1491801,
                                 1491837, 1491886, 1491911, 1492099, 1492293,
                                 1492360, 1492363, 1492528, 1492533, 1492657,
                                 1492722, 1492753, 1492796, 1492834, 1492866,
                                 1492923, 1492924, 1493006, 1493073, 1493188,
                                 1493422, 1493423, 1493637, 1493801, 1493824,
                                 1493825, 1493914, 1493966, 1494036, 1494044,
                                 1494129, 1494137, 1494143, 1494165, 1494195,
                                 1494254, 1494305, 1494552, 1494581, 1494604,
                                 1494622, 1494630, 1494640, 1494696, 1494727,
                                 1494868, 1494964, 1494976, 1495039, 1495106,
                                 1495144, 1495203, 1495255, 1495291, 1495313,
                                 1495617, 1495649, 1495663, 1495964, 1496097,
                                 1496177, 1496285, 1496315, 1496319, 1496344,
                                 1496442, 1496548, 1496691, 1496723, 1496809,
                                 1496891, 1497099, 1497208, 1497289, 1497342,
                                 1497429, 1497555, 1497561, 1497625, 1497782,
                                 1497794, 1497825, 1497876, 1497972, 1498035,
                                 1498098, 1498128, 1498180, 1498199, 1498280,
                                 1498647, 1498750, 1498777, 1498788, 1498911)
OR Orders.ShipVia IN (1418467, 1418519, 1418680, 1418792, 1418842,
                                 1419021, 1419064, 1419093, 1419266, 1419276,
                                 1419385, 1419429, 1419461, 1419577, 1419608,
                                 1419637, 1419725, 1419811, 1420200, 1420213,
                                 1420231, 1420553, 1420583, 1420596, 1420708,
                                 1420895, 1420912, 1421003, 1421025, 1421069,
                                 1421091, 1421145, 1421213, 1421247, 1421358,
                                 1421615, 1421625, 1421680, 1421715, 1421717,
                                 1421836, 1421880, 1421910, 1422007, 1422065,
                                 1422116, 1422143, 1422377, 1422644, 1422832,
                                 1422861, 1422871, 1422951, 1423017, 1423273,
                                 1423282, 1423493, 1423591, 1423667, 1423674,
                                 1423705, 1423861, 1424006, 1424070, 1424335,
                                 1424349, 1424376, 1424420, 1424497, 1424635,
                                 1424689, 1424750, 1424752, 1424811, 1424880,
                                 1424912, 1425004, 1425060, 1425100, 1425121,
                                 1425217, 1425219, 1425287, 1425353, 1425357,
                                 1425464, 1425578, 1425669, 1425693, 1425746,
                                 1425750, 1425802, 1425928, 1426065, 1426091,
                                 1426387, 1426419, 1426598, 1426759, 1427006,
                                 1427139, 1427217, 1427231, 1427269, 1427277,
                                 1427415, 1427640, 1428073, 1428187, 1428195,
                                 1428276, 1428397, 1428511, 1428532, 1428551,
                                 1428611, 1428742, 1428795, 1428822, 1429038,
                                 1429060, 1429088, 1429131, 1429394, 1429407,
                                 1429463, 1429537, 1429581, 1429594, 1429730,
                                 1429750, 1429769, 1429834, 1430204, 1430348,
                                 1430406, 1430495, 1430669, 1430730, 1430753,
                                 1431002, 1431065, 1431254, 1431302, 1431347,
                                 1431571, 1431686, 1431874, 1431904, 1432006,
                                 1432072, 1432111, 1432213, 1432245, 1432327,
                                 1432420, 1432591, 1432713, 1432768, 1432771,
                                 1433187, 1433440, 1433464, 1433478, 1433632,
                                 1433637, 1433972, 1434033, 1434095, 1434182,
                                 1434254, 1434257, 1434277, 1434337, 1434500,
                                 1434656, 1434659, 1434718, 1434810, 1434942,
                                 1435056, 1435097, 1435100, 1435164, 1435191,
                                 1435292, 1435344, 1435464, 1435550, 1435578,
                                 1435746, 1435851, 1435941, 1436123, 1436193,
                                 1436284, 1436300, 1436568, 1436726, 1436868,
                                 1436878, 1436964, 1436969, 1437294, 1437334,
                                 1437421, 1437424, 1437431, 1437455, 1437530,
                                 1437532, 1437909, 1438013, 1438017, 1438159,
                                 1438182, 1438237, 1438805, 1438840, 1438885,
                                 1438908, 1438919, 1438973, 1439004, 1439134,
                                 1439189, 1439215, 1439326, 1439500, 1439537,
                                 1440026, 1440029, 1440050, 1440177, 1440194,
                                 1440215, 1440231, 1440240, 1440326, 1440388,
                                 1440427, 1440428, 1440438, 1440970, 1441092,
                                 1441206, 1441227, 1441267, 1441302, 1441400,
                                 1441446, 1441509, 1441577, 1441827, 1441941,
                                 1442042, 1442054, 1442060, 1442137, 1442189,
                                 1442435, 1442588, 1442679, 1442686, 1442690,
                                 1442691, 1442822, 1442876, 1443058, 1443070,
                                 1443104, 1443196, 1443283, 1443363, 1443396,
                                 1443446, 1443456, 1443511, 1443520, 1443582,
                                 1443663, 1443682, 1443988, 1444511, 1444526,
                                 1444566, 1444585, 1444650, 1444799, 1445017,
                                 1445051, 1445066, 1445191, 1445200, 1445235,
                                 1445267, 1445275, 1445307, 1445319, 1445469,
                                 1445763, 1445920, 1445942, 1446048, 1446083,
                                 1446357, 1446508, 1446733, 1446876, 1446887,
                                 1447095, 1447194, 1447282, 1447378, 1447410,
                                 1447411, 1447556, 1447576, 1447589, 1447658,
                                 1447731, 1447735, 1447947, 1447968, 1448099,
                                 1448182, 1448313, 1448339, 1448407, 1448463,
                                 1448559, 1448608, 1448634, 1448658, 1448793,
                                 1448924, 1448984, 1449029, 1449124, 1449193,
                                 1449300, 1449518, 1449530, 1449570, 1449690,
                                 1449724, 1449736, 1449759, 1449804, 1449818,
                                 1449847, 1449967, 1449970, 1450058, 1450102,
                                 1450174, 1450217, 1450227, 1450290, 1450291,
                                 1450362, 1450391, 1450551, 1450662, 1450837,
                                 1451323, 1451360, 1451375, 1451436, 1451538,
                                 1451725, 1451759, 1451877, 1452066, 1452123,
                                 1452205, 1452257, 1452286, 1452305, 1452381,
                                 1452426, 1452552, 1452645, 1452758, 1452838,
                                 1452842, 1452898, 1452901, 1453010, 1453225,
                                 1453416, 1453432, 1453455, 1453543, 1453547,
                                 1453557, 1453637, 1453668, 1453807, 1453844,
                                 1453845, 1453956, 1454168, 1454359, 1454374,
                                 1454752, 1454810, 1454811, 1454868, 1454907,
                                 1455278, 1455335, 1455396, 1455481, 1455522,
                                 1455602, 1455640, 1455648, 1455662, 1455718,
                                 1455815, 1455844, 1455858, 1455904, 1456208,
                                 1456252, 1456269, 1456369, 1456593, 1456767,
                                 1456775, 1456823, 1456826, 1456879, 1456982,
                                 1457224, 1457265, 1457367, 1457404, 1457424,
                                 1457474, 1457536, 1457542, 1457606, 1457906,
                                 1458014, 1458054, 1458245, 1458355, 1458356,
                                 1458399, 1458425, 1458532, 1458629, 1458697,
                                 1458800, 1458823, 1459026, 1459109, 1459371,
                                 1459385, 1459521, 1459548, 1459589, 1459764,
                                 1459827, 1459834, 1459997, 1459999, 1460342,
                                 1460354, 1460370, 1460608, 1460896, 1461021,
                                 1461048, 1461143, 1461161, 1461249, 1461281,
                                 1461290, 1461556, 1461663, 1461723, 1461795,
                                 1461806, 1461854, 1462104, 1462167, 1462253,
                                 1462254, 1462442, 1462800, 1462837, 1462875,
                                 1462928, 1462999, 1463126, 1463273, 1463355,
                                 1463456, 1463605, 1463648, 1463712, 1463743,
                                 1463915, 1464046, 1464165, 1464236, 1464281,
                                 1464347, 1464408, 1464460, 1464630, 1464705,
                                 1464718, 1464733, 1464849, 1464943, 1464955)
OR Orders.ShipVia IN (1418467, 1418519, 1418680, 1418792, 1418842,
                                 1419021, 1419064, 1419093, 1419266, 1419276,
                                 1419385, 1419429, 1419461, 1419577, 1419608,
                                 1419637, 1419725, 1419811, 1420200, 1420213,
                                 1420231, 1420553, 1420583, 1420596, 1420708,
                                 1420895, 1420912, 1421003, 1421025, 1421069,
                                 1421091, 1421145, 1421213, 1421247, 1421358,
                                 1421615, 1421625, 1421680, 1421715, 1421717,
                                 1421836, 1421880, 1421910, 1422007, 1422065,
                                 1422116, 1422143, 1422377, 1422644, 1422832,
                                 1422861, 1422871, 1422951, 1423017, 1423273,
                                 1423282, 1423493, 1423591, 1423667, 1423674,
                                 1423705, 1423861, 1424006, 1424070, 1424335,
                                 1424349, 1424376, 1424420, 1424497, 1424635,
                                 1424689, 1424750, 1424752, 1424811, 1424880,
                                 1424912, 1425004, 1425060, 1425100, 1425121,
                                 1425217, 1425219, 1425287, 1425353, 1425357,
                                 1425464, 1425578, 1425669, 1425693, 1425746,
                                 1425750, 1425802, 1425928, 1426065, 1426091,
                                 1426387, 1426419, 1426598, 1426759, 1427006,
                                 1427139, 1427217, 1427231, 1427269, 1427277,
                                 1427415, 1427640, 1428073, 1428187, 1428195,
                                 1428276, 1428397, 1428511, 1428532, 1428551,
                                 1428611, 1428742, 1428795, 1428822, 1429038,
                                 1429060, 1429088, 1429131, 1429394, 1429407,
                                 1429463, 1429537, 1429581, 1429594, 1429730,
                                 1429750, 1429769, 1429834, 1430204, 1430348,
                                 1430406, 1430495, 1430669, 1430730, 1430753,
                                 1431002, 1431065, 1431254, 1431302, 1431347,
                                 1431571, 1431686, 1431874, 1431904, 1432006,
                                 1432072, 1432111, 1432213, 1432245, 1432327,
                                 1432420, 1432591, 1432713, 1432768, 1432771,
                                 1433187, 1433440, 1433464, 1433478, 1433632,
                                 1433637, 1433972, 1434033, 1434095, 1434182,
                                 1434254, 1434257, 1434277, 1434337, 1434500,
                                 1434656, 1434659, 1434718, 1434810, 1434942,
                                 1435056, 1435097, 1435100, 1435164, 1435191,
                                 1435292, 1435344, 1435464, 1435550, 1435578,
                                 1435746, 1435851, 1435941, 1436123, 1436193,
                                 1436284, 1436300, 1436568, 1436726, 1436868,
                                 1436878, 1436964, 1436969, 1437294, 1437334,
                                 1437421, 1437424, 1437431, 1437455, 1437530,
                                 1437532, 1437909, 1438013, 1438017, 1438159,
                                 1438182, 1438237, 1438805, 1438840, 1438885,
                                 1438908, 1438919, 1438973, 1439004, 1439134,
                                 1439189, 1439215, 1439326, 1439500, 1439537,
                                 1440026, 1440029, 1440050, 1440177, 1440194,
                                 1440215, 1440231, 1440240, 1440326, 1440388,
                                 1440427, 1440428, 1440438, 1440970, 1441092,
                                 1441206, 1441227, 1441267, 1441302, 1441400,
                                 1441446, 1441509, 1441577, 1441827, 1441941,
                                 1442042, 1442054, 1442060, 1442137, 1442189,
                                 1442435, 1442588, 1442679, 1442686, 1442690,
                                 1442691, 1442822, 1442876, 1443058, 1443070,
                                 1443104, 1443196, 1443283, 1443363, 1443396,
                                 1443446, 1443456, 1443511, 1443520, 1443582,
                                 1443663, 1443682, 1443988, 1444511, 1444526,
                                 1444566, 1444585, 1444650, 1444799, 1445017,
                                 1445051, 1445066, 1445191, 1445200, 1445235,
                                 1445267, 1445275, 1445307, 1445319, 1445469,
                                 1445763, 1445920, 1445942, 1446048, 1446083,
                                 1446357, 1446508, 1446733, 1446876, 1446887,
                                 1447095, 1447194, 1447282, 1447378, 1447410,
                                 1447411, 1447556, 1447576, 1447589, 1447658,
                                 1447731, 1447735, 1447947, 1447968, 1448099,
                                 1448182, 1448313, 1448339, 1448407, 1448463,
                                 1448559, 1448608, 1448634, 1448658, 1448793,
                                 1448924, 1448984, 1449029, 1449124, 1449193,
                                 1449300, 1449518, 1449530, 1449570, 1449690,
                                 1449724, 1449736, 1449759, 1449804, 1449818,
                                 1449847, 1449967, 1449970, 1450058, 1450102,
                                 1450174, 1450217, 1450227, 1450290, 1450291,
                                 1450362, 1450391, 1450551, 1450662, 1450837,
                                 1451323, 1451360, 1451375, 1451436, 1451538,
                                 1451725, 1451759, 1451877, 1452066, 1452123,
                                 1452205, 1452257, 1452286, 1452305, 1452381,
                                 1452426, 1452552, 1452645, 1452758, 1452838,
                                 1452842, 1452898, 1452901, 1453010, 1453225,
                                 1453416, 1453432, 1453455, 1453543, 1453547,
                                 1453557, 1453637, 1453668, 1453807, 1453844,
                                 1453845, 1453956, 1454168, 1454359, 1454374,
                                 1454752, 1454810, 1454811, 1454868, 1454907,
                                 1455278, 1455335, 1455396, 1455481, 1455522,
                                 1455602, 1455640, 1455648, 1455662, 1455718,
                                 1455815, 1455844, 1455858, 1455904, 1456208,
                                 1456252, 1456269, 1456369, 1456593, 1456767,
                                 1456775, 1456823, 1456826, 1456879, 1456982,
                                 1457224, 1457265, 1457367, 1457404, 1457424,
                                 1457474, 1457536, 1457542, 1457606, 1457906,
                                 1458014, 1458054, 1458245, 1458355, 1458356,
                                 1458399, 1458425, 1458532, 1458629, 1458697,
                                 1458800, 1458823, 1459026, 1459109, 1459371,
                                 1459385, 1459521, 1459548, 1459589, 1459764,
                                 1459827, 1459834, 1459997, 1459999, 1460342,
                                 1460354, 1460370, 1460608, 1460896, 1461021,
                                 1461048, 1461143, 1461161, 1461249, 1461281,
                                 1461290, 1461556, 1461663, 1461723, 1461795,
                                 1461806, 1461854, 1462104, 1462167, 1462253,
                                 1462254, 1462442, 1462800, 1462837, 1462875,
                                 1462928, 1462999, 1463126, 1463273, 1463355,
                                 1463456, 1463605, 1463648, 1463712, 1463743,
                                 1463915, 1464046, 1464165, 1464236, 1464281,
                                 1464347, 1464408, 1464460, 1464630, 1464705,
                                 1464718, 1464733, 1464849, 1464943, 1464955)
OR Orders.ShipVia IN (1418467, 1418519, 1418680, 1418792, 1418842,
                                 1419021, 1419064, 1419093, 1419266, 1419276,
                                 1419385, 1419429, 1419461, 1419577, 1419608,
                                 1419637, 1419725, 1419811, 1420200, 1420213,
                                 1420231, 1420553, 1420583, 1420596, 1420708,
                                 1420895, 1420912, 1421003, 1421025, 1421069,
                                 1421091, 1421145, 1421213, 1421247, 1421358,
                                 1421615, 1421625, 1421680, 1421715, 1421717,
                                 1421836, 1421880, 1421910, 1422007, 1422065,
                                 1422116, 1422143, 1422377, 1422644, 1422832,
                                 1422861, 1422871, 1422951, 1423017, 1423273,
                                 1423282, 1423493, 1423591, 1423667, 1423674,
                                 1423705, 1423861, 1424006, 1424070, 1424335,
                                 1424349, 1424376, 1424420, 1424497, 1424635,
                                 1424689, 1424750, 1424752, 1424811, 1424880,
                                 1424912, 1425004, 1425060, 1425100, 1425121,
                                 1425217, 1425219, 1425287, 1425353, 1425357,
                                 1425464, 1425578, 1425669, 1425693, 1425746,
                                 1425750, 1425802, 1425928, 1426065, 1426091,
                                 1426387, 1426419, 1426598, 1426759, 1427006,
                                 1427139, 1427217, 1427231, 1427269, 1427277,
                                 1427415, 1427640, 1428073, 1428187, 1428195,
                                 1428276, 1428397, 1428511, 1428532, 1428551,
                                 1428611, 1428742, 1428795, 1428822, 1429038,
                                 1429060, 1429088, 1429131, 1429394, 1429407,
                                 1429463, 1429537, 1429581, 1429594, 1429730,
                                 1429750, 1429769, 1429834, 1430204, 1430348,
                                 1430406, 1430495, 1430669, 1430730, 1430753,
                                 1431002, 1431065, 1431254, 1431302, 1431347,
                                 1431571, 1431686, 1431874, 1431904, 1432006,
                                 1432072, 1432111, 1432213, 1432245, 1432327,
                                 1432420, 1432591, 1432713, 1432768, 1432771,
                                 1433187, 1433440, 1433464, 1433478, 1433632,
                                 1433637, 1433972, 1434033, 1434095, 1434182,
                                 1434254, 1434257, 1434277, 1434337, 1434500,
                                 1434656, 1434659, 1434718, 1434810, 1434942,
                                 1435056, 1435097, 1435100, 1435164, 1435191,
                                 1435292, 1435344, 1435464, 1435550, 1435578,
                                 1435746, 1435851, 1435941, 1436123, 1436193,
                                 1436284, 1436300, 1436568, 1436726, 1436868,
                                 1436878, 1436964, 1436969, 1437294, 1437334,
                                 1437421, 1437424, 1437431, 1437455, 1437530,
                                 1437532, 1437909, 1438013, 1438017, 1438159,
                                 1438182, 1438237, 1438805, 1438840, 1438885,
                                 1438908, 1438919, 1438973, 1439004, 1439134,
                                 1439189, 1439215, 1439326, 1439500, 1439537,
                                 1440026, 1440029, 1440050, 1440177, 1440194,
                                 1440215, 1440231, 1440240, 1440326, 1440388,
                                 1440427, 1440428, 1440438, 1440970, 1441092,
                                 1441206, 1441227, 1441267, 1441302, 1441400,
                                 1441446, 1441509, 1441577, 1441827, 1441941,
                                 1442042, 1442054, 1442060, 1442137, 1442189,
                                 1442435, 1442588, 1442679, 1442686, 1442690,
                                 1442691, 1442822, 1442876, 1443058, 1443070,
                                 1443104, 1443196, 1443283, 1443363, 1443396,
                                 1443446, 1443456, 1443511, 1443520, 1443582,
                                 1443663, 1443682, 1443988, 1444511, 1444526,
                                 1444566, 1444585, 1444650, 1444799, 1445017,
                                 1445051, 1445066, 1445191, 1445200, 1445235,
                                 1445267, 1445275, 1445307, 1445319, 1445469,
                                 1445763, 1445920, 1445942, 1446048, 1446083,
                                 1446357, 1446508, 1446733, 1446876, 1446887,
                                 1447095, 1447194, 1447282, 1447378, 1447410,
                                 1447411, 1447556, 1447576, 1447589, 1447658,
                                 1447731, 1447735, 1447947, 1447968, 1448099,
                                 1448182, 1448313, 1448339, 1448407, 1448463,
                                 1448559, 1448608, 1448634, 1448658, 1448793,
                                 1448924, 1448984, 1449029, 1449124, 1449193,
                                 1449300, 1449518, 1449530, 1449570, 1449690,
                                 1449724, 1449736, 1449759, 1449804, 1449818,
                                 1449847, 1449967, 1449970, 1450058, 1450102,
                                 1450174, 1450217, 1450227, 1450290, 1450291,
                                 1450362, 1450391, 1450551, 1450662, 1450837,
                                 1451323, 1451360, 1451375, 1451436, 1451538,
                                 1451725, 1451759, 1451877, 1452066, 1452123,
                                 1452205, 1452257, 1452286, 1452305, 1452381,
                                 1452426, 1452552, 1452645, 1452758, 1452838,
                                 1452842, 1452898, 1452901, 1453010, 1453225,
                                 1453416, 1453432, 1453455, 1453543, 1453547,
                                 1453557, 1453637, 1453668, 1453807, 1453844,
                                 1453845, 1453956, 1454168, 1454359, 1454374,
                                 1454752, 1454810, 1454811, 1454868, 1454907,
                                 1455278, 1455335, 1455396, 1455481, 1455522,
                                 1455602, 1455640, 1455648, 1455662, 1455718,
                                 1455815, 1455844, 1455858, 1455904, 1456208,
                                 1456252, 1456269, 1456369, 1456593, 1456767,
                                 1456775, 1456823, 1456826, 1456879, 1456982,
                                 1457224, 1457265, 1457367, 1457404, 1457424,
                                 1457474, 1457536, 1457542, 1457606, 1457906,
                                 1458014, 1458054, 1458245, 1458355, 1458356,
                                 1458399, 1458425, 1458532, 1458629, 1458697,
                                 1458800, 1458823, 1459026, 1459109, 1459371,
                                 1459385, 1459521, 1459548, 1459589, 1459764,
                                 1459827, 1459834, 1459997, 1459999, 1460342,
                                 1460354, 1460370, 1460608, 1460896, 1461021,
                                 1461048, 1461143, 1461161, 1461249, 1461281,
                                 1461290, 1461556, 1461663, 1461723, 1461795,
                                 1461806, 1461854, 1462104, 1462167, 1462253,
                                 1462254, 1462442, 1462800, 1462837, 1462875,
                                 1462928, 1462999, 1463126, 1463273, 1463355,
                                 1463456, 1463605, 1463648, 1463712, 1463743,
                                 1463915, 1464046, 1464165, 1464236, 1464281,
                                 1464347, 1464408, 1464460, 1464630, 1464705,
                                 1464718, 1464733, 1464849, 1464943, 1464955)
OR Orders.ShipVia IN (1418467, 1418519, 1418680, 1418792, 1418842,
                                 1419021, 1419064, 1419093, 1419266, 1419276,
                                 1419385, 1419429, 1419461, 1419577, 1419608,
                                 1419637, 1419725, 1419811, 1420200, 1420213,
                                 1420231, 1420553, 1420583, 1420596, 1420708,
                                 1420895, 1420912, 1421003, 1421025, 1421069,
                                 1421091, 1421145, 1421213, 1421247, 1421358,
                                 1421615, 1421625, 1421680, 1421715, 1421717,
                                 1421836, 1421880, 1421910, 1422007, 1422065,
                                 1422116, 1422143, 1422377, 1422644, 1422832,
                                 1422861, 1422871, 1422951, 1423017, 1423273,
                                 1423282, 1423493, 1423591, 1423667, 1423674,
                                 1423705, 1423861, 1424006, 1424070, 1424335,
                                 1424349, 1424376, 1424420, 1424497, 1424635,
                                 1424689, 1424750, 1424752, 1424811, 1424880,
                                 1424912, 1425004, 1425060, 1425100, 1425121,
                                 1425217, 1425219, 1425287, 1425353, 1425357,
                                 1425464, 1425578, 1425669, 1425693, 1425746,
                                 1425750, 1425802, 1425928, 1426065, 1426091,
                                 1426387, 1426419, 1426598, 1426759, 1427006,
                                 1427139, 1427217, 1427231, 1427269, 1427277,
                                 1427415, 1427640, 1428073, 1428187, 1428195,
                                 1428276, 1428397, 1428511, 1428532, 1428551,
                                 1428611, 1428742, 1428795, 1428822, 1429038,
                                 1429060, 1429088, 1429131, 1429394, 1429407,
                                 1429463, 1429537, 1429581, 1429594, 1429730,
                                 1429750, 1429769, 1429834, 1430204, 1430348,
                                 1430406, 1430495, 1430669, 1430730, 1430753,
                                 1431002, 1431065, 1431254, 1431302, 1431347,
                                 1431571, 1431686, 1431874, 1431904, 1432006,
                                 1432072, 1432111, 1432213, 1432245, 1432327,
                                 1432420, 1432591, 1432713, 1432768, 1432771,
                                 1433187, 1433440, 1433464, 1433478, 1433632,
                                 1433637, 1433972, 1434033, 1434095, 1434182,
                                 1434254, 1434257, 1434277, 1434337, 1434500,
                                 1434656, 1434659, 1434718, 1434810, 1434942,
                                 1435056, 1435097, 1435100, 1435164, 1435191,
                                 1435292, 1435344, 1435464, 1435550, 1435578,
                                 1435746, 1435851, 1435941, 1436123, 1436193,
                                 1436284, 1436300, 1436568, 1436726, 1436868,
                                 1436878, 1436964, 1436969, 1437294, 1437334,
                                 1437421, 1437424, 1437431, 1437455, 1437530,
                                 1437532, 1437909, 1438013, 1438017, 1438159,
                                 1438182, 1438237, 1438805, 1438840, 1438885,
                                 1438908, 1438919, 1438973, 1439004, 1439134,
                                 1439189, 1439215, 1439326, 1439500, 1439537,
                                 1440026, 1440029, 1440050, 1440177, 1440194,
                                 1440215, 1440231, 1440240, 1440326, 1440388,
                                 1440427, 1440428, 1440438, 1440970, 1441092,
                                 1441206, 1441227, 1441267, 1441302, 1441400,
                                 1441446, 1441509, 1441577, 1441827, 1441941,
                                 1442042, 1442054, 1442060, 1442137, 1442189,
                                 1442435, 1442588, 1442679, 1442686, 1442690,
                                 1442691, 1442822, 1442876, 1443058, 1443070,
                                 1443104, 1443196, 1443283, 1443363, 1443396,
                                 1443446, 1443456, 1443511, 1443520, 1443582,
                                 1443663, 1443682, 1443988, 1444511, 1444526,
                                 1444566, 1444585, 1444650, 1444799, 1445017,
                                 1445051, 1445066, 1445191, 1445200, 1445235,
                                 1445267, 1445275, 1445307, 1445319, 1445469,
                                 1445763, 1445920, 1445942, 1446048, 1446083,
                                 1446357, 1446508, 1446733, 1446876, 1446887,
                                 1447095, 1447194, 1447282, 1447378, 1447410,
                                 1447411, 1447556, 1447576, 1447589, 1447658,
                                 1447731, 1447735, 1447947, 1447968, 1448099,
                                 1448182, 1448313, 1448339, 1448407, 1448463,
                                 1448559, 1448608, 1448634, 1448658, 1448793,
                                 1448924, 1448984, 1449029, 1449124, 1449193,
                                 1449300, 1449518, 1449530, 1449570, 1449690,
                                 1449724, 1449736, 1449759, 1449804, 1449818,
                                 1449847, 1449967, 1449970, 1450058, 1450102,
                                 1450174, 1450217, 1450227, 1450290, 1450291,
                                 1450362, 1450391, 1450551, 1450662, 1450837,
                                 1451323, 1451360, 1451375, 1451436, 1451538,
                                 1451725, 1451759, 1451877, 1452066, 1452123,
                                 1452205, 1452257, 1452286, 1452305, 1452381,
                                 1452426, 1452552, 1452645, 1452758, 1452838,
                                 1452842, 1452898, 1452901, 1453010, 1453225,
                                 1453416, 1453432, 1453455, 1453543, 1453547,
                                 1453557, 1453637, 1453668, 1453807, 1453844,
                                 1453845, 1453956, 1454168, 1454359, 1454374,
                                 1454752, 1454810, 1454811, 1454868, 1454907,
                                 1455278, 1455335, 1455396, 1455481, 1455522,
                                 1455602, 1455640, 1455648, 1455662, 1455718,
                                 1455815, 1455844, 1455858, 1455904, 1456208,
                                 1456252, 1456269, 1456369, 1456593, 1456767,
                                 1456775, 1456823, 1456826, 1456879, 1456982,
                                 1457224, 1457265, 1457367, 1457404, 1457424,
                                 1457474, 1457536, 1457542, 1457606, 1457906,
                                 1458014, 1458054, 1458245, 1458355, 1458356,
                                 1458399, 1458425, 1458532, 1458629, 1458697,
                                 1458800, 1458823, 1459026, 1459109, 1459371,
                                 1459385, 1459521, 1459548, 1459589, 1459764,
                                 1459827, 1459834, 1459997, 1459999, 1460342,
                                 1460354, 1460370, 1460608, 1460896, 1461021,
                                 1461048, 1461143, 1461161, 1461249, 1461281,
                                 1461290, 1461556, 1461663, 1461723, 1461795,
                                 1461806, 1461854, 1462104, 1462167, 1462253,
                                 1462254, 1462442, 1462800, 1462837, 1462875,
                                 1462928, 1462999, 1463126, 1463273, 1463355,
                                 1463456, 1463605, 1463648, 1463712, 1463743,
                                 1463915, 1464046, 1464165, 1464236, 1464281,
                                 1464347, 1464408, 1464460, 1464630, 1464705,
                                 1464718, 1464733, 1464849, 1464943, 1464955) GROUP BY Orders.OrderID'
-- Print @SQL
EXEC (@SQL)


-- 1MB de plano em cache... 
SELECT p.memory_object_address, p.bucketid, usecounts, cacheobjtype, objtype, size_in_bytes / 1024. AS size_in_kb, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE [text] LIKE '%AdHoc shit%' 
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO


-- E se a gente tentar com forced pra evitar a recompila��o? ...
-- Setar o banco como PARAMETERIZATION FORCED
ALTER DATABASE NorthWind SET PARAMETERIZATION FORCED WITH NO_WAIT
GO

-- Cache vazio...
SELECT p.memory_object_address, p.bucketid, usecounts, cacheobjtype, objtype, size_in_bytes / 1024. AS size_in_kb, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE [text] LIKE '%AdHoc shit%' 
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO

-- Rodar SQLQueryStress(AdHocTestDemonio.sqlstress) novamente

-- Ops...
-- �, forced n�o faz milagre... 
SELECT p.memory_object_address, p.bucketid, usecounts, cacheobjtype, objtype, size_in_bytes / 1024. AS size_in_kb, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE [text] LIKE '%AdHoc shit%' 
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO



-- E como fica com optimize for ad hoc workloads? 
EXEC sys.sp_configure N'optimize for ad hoc workloads', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Limpar o PlanCache
DBCC FREEPROCCACHE
GO

-- Rodar SQLQueryStress novamente

-- E agora, qual o tamanho do plano em cache? 
SELECT p.memory_object_address, p.bucketid, usecounts, cacheobjtype, objtype, size_in_bytes / 1024. AS size_in_kb, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE [text] LIKE '%AdHoc shit%' 
AND [text] NOT LIKE '%dm_exec_cached_plans%';

-- WOW, vers�o MUITO menor do plano em cache...


-- Cleanup
EXEC sys.sp_configure N'optimize for ad hoc workloads', N'0'
GO
RECONFIGURE WITH OVERRIDE
GO
ALTER DATABASE NorthWind SET PARAMETERIZATION SIMPLE WITH NO_WAIT
GO


/*
  Demo 7 - sp_prepare vs Direct Exec
*/

-- Abrir app
-- D:\Fabiano\Trabalho\Sr.Nimbus\Cursos\SQL26 - SQL Server - Mastering the database engine (former Internals)\Slides\M�dulo 02 - Mem�ria parte 1\6 - Memory clerks - CachePlan\sp_prepare vs direct exec

DBCC FREEPROCCACHE
GO

-- Usando o CROSS APPLY para ver o texto e o plano
SELECT *
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
GO


-- Conclus�o
-- O tempo � o basicamente o mesmo, por�m a visibilidade do c�digo executado no profiler � p�ssima com sp_prepare...
-- Talvez em um ambiente com baixa lat�ncia de rede, o sp_prepare ajude, j� que na teoria ir� reduzir o tamanho do pacote enviado pela rede... Azure com serv no Jap�o...?...
-- IMO, n�o use prepare... please...


/*
  Demo 8 - Textos iguais... Hash tem que bater... 
*/

DBCC FREEPROCCACHE
GO

SELECT * FROM Customers WHERE ContactName = 'Fabiano'
GO
SELECT * FROM Customers WHERE contactName = 'Fabiano'
GO
SELECT * FROM Customers WHERE contactname = 'Fabiano'
GO
SELECT * FROM CUSTOMERS WHERE contactname = 'Fabiano'
GO


-- Quantos planos tenho em cache? 
SELECT *
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
GO

-- Ops


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



-- Resultado SSMS:
ANSI_PADDING
CONCAT_NULL_YIELDS_NULL
ANSI_WARNINGS
ANSI_NULLS
QUOTED_IDENTIFIER
ANSI_NULL_DFLT_ON
ARITHABORT

-- Resultado SQLQueryStress: 
ANSI_PADDING
CONCAT_NULL_YIELDS_NULL
ANSI_WARNINGS
ANSI_NULLS
QUOTED_IDENTIFIER
ANSI_NULL_DFLT_ON


-- Ou seja, o SSMS esta enviando um ARITHABORT ON... 

-- Vamos confirmar... 

DBCC USEROPTIONS

-- "arithabort	SET", olha ele ai...

-- Isso explica o porque quando a query que voc� roda no SSMS � mais r�pida que a query da App... 
-- No SSMS voc� est� criando um plano novo... na App est� reutilizando plano do cache...
-- Um usu�rio diferente, tamb�m ir� gerar um plano novo... Portanto o ideal seria rodar a query da app com o 
---- mesmo usu�rio e user seetings utilizados na app


/*

  Demo 10 - Como o cacheplan responde a uma press�o de mem�ria? 

*/

-- Vamos setar maxmem para 1GB
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
GO
RECONFIGURE WITH OVERRIDE
GO


-- Reiniciar a inst�ncia pra ter uma vis�o zerada da sys.dm_os_memory_cache_clock_hands


-- Limpar cache
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE
GO

-- Rodar abaixo no query SQLQueryStress com para popular cache com +- 265MB
-- 10 threads e 180 iterations +- 1.8 mil planos em cache
DECLARE @Var VARCHAR(500) = NEWID(), @SQL VARCHAR(MAX)
SET @SQL = 'SELECT Orders.OrderID, COUNT(DISTINCT Orders.CustomerID), SUM(Orders.Value) FROM Orders INNER JOIN Customers ON Customers.CustomerID = Orders.CustomerID INNER JOIN Order_Details ON Order_Details.OrderID = Orders.OrderID INNER JOIN Products ON Products.ProductID = Order_Details.ProductID WHERE Products.ProductName = ''' + @Var + ''' GROUP BY Orders.OrderID';
EXEC (@SQL)
GO


-- 265MB de CACHESTORE_SQLCP
SELECT TOP 5 type, name, pages_kb / 1024. size_in_mb, pages_kb AS size_in_kb
FROM sys.dm_os_memory_clerks
ORDER BY size_in_kb DESC 
GO

-- Algumas queries uteis aqui... podem ajudar a identificar ad-hocs e cache bloat...
select name, type, buckets_count, buckets_in_use_count 
from sys.dm_os_memory_cache_hash_tables
where name IN ( 'SQL Plans' , 'Object Plans' , 'Bound Trees' )
GO

select name, type, pages_kb, entries_count
from sys.dm_os_memory_cache_counters
where name IN ( 'SQL Plans' , 'Object Plans' ,  'Bound Trees' )
GO


SELECT objtype AS [CacheType],
   COUNT_BIG(*) AS [Total Plans],
   SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs],
   AVG(usecounts) AS [Avg Use Count],
   SUM(CAST((CASE WHEN usecounts = 1 THEN size_in_bytes
       ELSE 0
       END) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs � USE Count 1],
   SUM(CASE WHEN usecounts = 1 THEN 1
       ELSE 0
       END) AS [Total Plans � USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs � USE Count 1] DESC
GO


-- +- 1800 entries_count
SELECT * FROM sys.dm_os_memory_cache_counters
WHERE [type] = 'CACHESTORE_SQLCP' AND name = 'SQL Plans'
GO

-- dm_os_memory_cache_clock_hands n�o removeu nada...
SELECT dm_os_memory_cache_clock_hands.*, DATEADD(ms, last_tick_time - info.ms_ticks, GETDATE()) FROM sys.dm_os_memory_cache_clock_hands
CROSS JOIN sys.dm_os_sys_info AS info
WHERE [type] = 'CACHESTORE_SQLCP' AND name = 'SQL Plans'
GO


-- Rodar query com plan cost alto... 
-- Se necessario criar a sp... ...M�dulo 02 - Mem�ria parte 1\6 - Memory clerks - CachePlan\st_QueryCostAlto.sql
EXEC st_QueryCostAlto @Var = 'ABC'
GO 100


-- Consultar plan cost
SELECT Ecp.usecounts, dm_exec_sql_text.text, dm_os_memory_cache_entries.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
INNER JOIN sys.dm_os_memory_cache_entries
ON dm_os_memory_cache_entries.memory_object_address = ECP.memory_object_address
ORDER BY original_cost DESC
GO


-- Consigo colocar mais 1800 planos em cache? ... 
-- Rodar o SQLQueryStress novamente pra inclur mais coisa no cache...
-- 10 threads e 180 iterations = 1800 planos em cache



-- Como fica o uso de mem�ria ? 
SELECT TOP 5 type, name, pages_kb / 1024. size_in_mb, pages_kb AS size_in_kb
FROM sys.dm_os_memory_clerks
ORDER BY size_in_kb DESC 
GO

-- Quantos planos sobraram? 
SELECT * FROM sys.dm_os_memory_cache_counters
WHERE [type] = 'CACHESTORE_SQLCP' AND name = 'SQL Plans'
GO

-- dm_os_memory_cache_clock_hands passou fac�o e removeu v�rios planos...
SELECT dm_os_memory_cache_clock_hands.*, DATEADD(ms, last_tick_time - info.ms_ticks, GETDATE()) FROM sys.dm_os_memory_cache_clock_hands
CROSS JOIN sys.dm_os_sys_info AS info
WHERE [type] = 'CACHESTORE_SQLCP' AND name = 'SQL Plans'
GO

-- Ser� que o plano com custo alto morreu?
SELECT Ecp.usecounts, dm_exec_sql_text.text, dm_os_memory_cache_entries.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
INNER JOIN sys.dm_os_memory_cache_entries
ON dm_os_memory_cache_entries.memory_object_address = ECP.memory_object_address
ORDER BY original_cost DESC
GO

-- Eu acho que deveria ter deixado ele l�... mass... press�o � press�o n� pai... 
-- Quem tem juizo obedece... clerk liberou a mem�ria, o m�ximo que pode...


-- Iniciar trace utilizando template que criei para monitorar uso do cache
-- Rodar query com plan cost alto... 
-- Cache hit ou cache miss? 
EXEC st_QueryCostAlto @Var = 'ABC'
GO


-- Cleanup ... set maxmem 10GB
EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
RECONFIGURE WITH OVERRIDE
GO


/*
  Demo 11 - Cursor leak...
*/


-- Limpar cache
DBCC FREEPROCCACHE
GO

-- Cursores s�o armazenados em mem�ria... mais precisamente, no cache plan...

-- Abrir nova sess�o e rodar o seguinte c�digo:

SET NOCOUNT ON;
DROP TABLE IF EXISTS #c

CREATE TABLE #c (i Int)

DECLARE @x INT = 1, @p1 INT
WHILE (@x <= 1000)
BEGIN
  INSERT INTO #c EXEC sp_cursoropen @p1 OUTPUT, 'SELECT 1', 2
  SET @x += 1;
END
GO

-- Qual o tamanho do cache? 
-- 9MB
SELECT * FROM sys.dm_os_memory_cache_counters
WHERE [type] = 'CACHESTORE_SQLCP' OR [type] = 'CACHESTORE_OBJCP'
GO

-- Consultar planos e qtde de cursores associados a eles... (dependent_objects)
SELECT cacheobjtype,
       usecounts,
       size_in_kb,
       pvt2.dbname,
       "executable plan" AS ec_count,
       "cursor" AS cursors,
       sql_text
FROM
(
    SELECT p.cacheobjtype + ' ( ' + p.objtype + ')' AS cacheobjtype,
           p.usecounts,
           p.size_in_bytes / 1024. size_in_kb,
           CASE
               WHEN pa.value = 32767 THEN
                   'ResourceDB'
               ELSE
                   ISNULL(DB_NAME(CAST(pa.value AS INT)), CONVERT(sysname, pa.value))
           END AS dbname,
           pdo.cacheobjtype AS pdo_cacheobjtype,
           REPLACE(REPLACE(sql.text, CHAR(13), ' '), CHAR(10), ' ') AS sql_text
    FROM sys.dm_exec_cached_plans p
        OUTER APPLY sys.dm_exec_plan_attributes(p.plan_handle) AS pa
        OUTER APPLY sys.dm_exec_cached_plan_dependent_objects(p.plan_handle) AS pdo
        OUTER APPLY sys.dm_exec_sql_text(p.plan_handle) AS sql
    WHERE pa.attribute = 'dbid'
) AS t1
PIVOT
(
    COUNT(pdo_cacheobjtype)
    FOR pdo_cacheobjtype IN ("executable plan", "cursor")
) AS pvt2
GROUP BY pvt2.cacheobjtype,
         usecounts,
         pvt2.size_in_kb,
         dbname,
         pvt2.[executable plan],
         pvt2.[cursor],
         pvt2.sql_text
ORDER BY pvt2.size_in_kb DESC;
GO

-- Fechar sess�o que criou os cursores...


-- Cache diminuiu? 
SELECT * FROM sys.dm_os_memory_cache_counters
WHERE [type] = 'CACHESTORE_SQLCP' OR [type] = 'CACHESTORE_OBJCP'
GO

-- Consultar planos e qtde de cursores associados a eles... (dependent_objects)
SELECT cacheobjtype,
       usecounts,
       size_in_kb,
       pvt2.dbname,
       "executable plan" AS ec_count,
       "cursor" AS cursors,
       sql_text
FROM
(
    SELECT p.cacheobjtype + ' ( ' + p.objtype + ')' AS cacheobjtype,
           p.usecounts,
           p.size_in_bytes / 1024. size_in_kb,
           CASE
               WHEN pa.value = 32767 THEN
                   'ResourceDB'
               ELSE
                   ISNULL(DB_NAME(CAST(pa.value AS INT)), CONVERT(sysname, pa.value))
           END AS dbname,
           pdo.cacheobjtype AS pdo_cacheobjtype,
           REPLACE(REPLACE(sql.text, CHAR(13), ' '), CHAR(10), ' ') AS sql_text
    FROM sys.dm_exec_cached_plans p
        OUTER APPLY sys.dm_exec_plan_attributes(p.plan_handle) AS pa
        OUTER APPLY sys.dm_exec_cached_plan_dependent_objects(p.plan_handle) AS pdo
        OUTER APPLY sys.dm_exec_sql_text(p.plan_handle) AS sql
    WHERE pa.attribute = 'dbid'
) AS t1
PIVOT
(
    COUNT(pdo_cacheobjtype)
    FOR pdo_cacheobjtype IN ("executable plan", "cursor")
) AS pvt2
GROUP BY pvt2.cacheobjtype,
         usecounts,
         pvt2.size_in_kb,
         dbname,
         pvt2.[executable plan],
         pvt2.[cursor],
         pvt2.sql_text
ORDER BY pvt2.size_in_kb DESC;
GO

-- Ops...


