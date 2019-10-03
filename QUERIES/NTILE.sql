USE Treinamento
GO


;WITH CTE_Numerico (Nivel, Numero) 
AS
(
    --  ncora (n�vel 1)
    SELECT 1 AS Nivel, 1 AS Numero
    
    UNION ALL

    -- N�veis recursivos (N�veis N)
    SELECT Nivel + 1, Numero + Numero 
    FROM CTE_Numerico
    WHERE Numero < 2048
 )
SELECT * , NTILE(5) OVER (ORDER BY CTE_Numerico.Nivel)
FROM CTE_Numerico
