USE MASTER
GO

IF OBJECT_ID('TEMPDB..#T') IS NOT NULL
	DROP TABLE #T

SELECT * INTO #T
FROM (VALUES(1,'C1'),(2,'C2'),(3,'C3')) AS T (ID, NM_CLIENT)

SELECT * FROM #T;
GO
DECLARE @VALOR int = 0
----� "Menor" que "Qualquer" dos n�meros desta coluna
--SELECT IIF((@VALOR < ANY (SELECT ID_CLIENT FROM #T)), '�', 'N�O �')
----� "Menor" que "Algum" dos n�meros desta coluna
--SELECT IIF((@VALOR < SOME (SELECT ID_CLIENT FROM #T)), '�', 'N�O �')
----� "Diferente" que "Qualquer" dos n�meros desta coluna
--SELECT IIF((@VALOR <> ANY (SELECT ID_CLIENT FROM #T)), '� diferente', '� igual')
----� "Diferente" que "Algum" dos n�meros desta coluna
--SELECT IIF((@VALOR <> SOME (SELECT ID_CLIENT FROM #T)), '� diferente', '� igual')
--� "Menor" que "Todos" os n�meros desta coluna
SELECT IIF((@VALOR < ALL (SELECT ID_CLIENT FROM #T)), '�', 'N�O �')
--� "Diferente" que "Todos" os n�meros desta coluna
SELECT IIF((@VALOR <> ALL (SELECT ID_CLIENT FROM #T)), 'Sim. � diferente', 'N�o. � igual')
GO