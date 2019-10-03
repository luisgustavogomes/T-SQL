USE	AdventureWorks2017	
GO 

--;WITH CTE_Numerico (Nivel, Numero) 
--AS
--(
--    --  ncora (nível 1)
--    SELECT 1 AS Nivel, 1 AS Numero
    
--    UNION ALL

--    -- Níveis recursivos (Níveis N)
--    SELECT Nivel + 1, Numero + Numero 
--    FROM CTE_Numerico
--    WHERE Numero < 2048
-- )
--SELECT *
--FROM CTE_Numerico

IF OBJECT_ID('TEMPDB..#D') IS NOT NULL
	DROP TABLE TEMPDB..#D 

CREATE TABLE #D ( DIA DATETIME2 ) 
INSERT INTO #D (DIA) VALUES ('1900-01-01')

;WITH TAB
AS
(
	SELECT DIA FROM #D

	UNION ALL 

	SELECT DATEADD(DD,+1,DIA)
	FROM TAB
	WHERE DIA < '2100-01-01'
)
--INSERT INTO #D
SELECT * 
FROM TAB 
OPTION (MAXRECURSION 0)



