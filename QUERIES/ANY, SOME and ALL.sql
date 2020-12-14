USE MASTER
GO

IF OBJECT_ID('TEMPDB..#T') IS NOT NULL
	DROP TABLE #T

SELECT * INTO #T
FROM (VALUES(1,'C1'),(2,'C2'),(3,'C3')) AS T (ID, NM_CLIENT)

SELECT * FROM #T;
GO
DECLARE @VALOR int = 0
----É "Menor" que "Qualquer" dos números desta coluna
--SELECT IIF((@VALOR < ANY (SELECT ID_CLIENT FROM #T)), 'É', 'NÃO É')
----É "Menor" que "Algum" dos números desta coluna
--SELECT IIF((@VALOR < SOME (SELECT ID_CLIENT FROM #T)), 'É', 'NÃO É')
----É "Diferente" que "Qualquer" dos números desta coluna
--SELECT IIF((@VALOR <> ANY (SELECT ID_CLIENT FROM #T)), 'É diferente', 'É igual')
----É "Diferente" que "Algum" dos números desta coluna
--SELECT IIF((@VALOR <> SOME (SELECT ID_CLIENT FROM #T)), 'É diferente', 'É igual')
--É "Menor" que "Todos" os números desta coluna
SELECT IIF((@VALOR < ALL (SELECT ID_CLIENT FROM #T)), 'É', 'NÃO É')
--É "Diferente" que "Todos" os números desta coluna
SELECT IIF((@VALOR <> ALL (SELECT ID_CLIENT FROM #T)), 'Sim. É diferente', 'Não. É igual')
GO