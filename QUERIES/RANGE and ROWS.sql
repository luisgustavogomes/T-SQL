USE MASTER
GO

-- Syntax for SQL Server, Azure SQL Database, and Azure Synapse Analytics  
  
--OVER (   
--       [ <PARTITION BY clause> ]  
--       [ <ORDER BY clause> ]   
--       [ <ROW or RANGE clause> ]  
--      )  
  
--<PARTITION BY clause> ::=  
--PARTITION BY value_expression , ... [ n ]  
  
--<ORDER BY clause> ::=  
--ORDER BY order_by_expression  
--    [ COLLATE collation_name ]   
--    [ ASC | DESC ]   
--    [ ,...n ]  
  
--<ROW or RANGE clause> ::=  
--{ ROWS | RANGE } <window frame extent>  
  
--<window frame extent> ::=   
--{   <window frame preceding>  
--  | <window frame between>  
--}  
--<window frame between> ::=   
--  BETWEEN <window frame bound> AND <window frame bound>  
  
--<window frame bound> ::=   
--{   <window frame preceding>  
--  | <window frame following>  
--}  
  
--<window frame preceding> ::=   
--{  
--    UNBOUNDED PRECEDING  
--  | <unsigned_value_specification> PRECEDING  
--  | CURRENT ROW  
--}  
  
--<window frame following> ::=   
--{  
--    UNBOUNDED FOLLOWING  
--  | <unsigned_value_specification> FOLLOWING  
--  | CURRENT ROW  
--}  
  
--<unsigned value specification> ::=   
--{  <unsigned integer literal> }


--SELECT ID,ANO,VLR
--	,SUM(VLR) OVER(ORDER BY ANO RANGE UNBOUNDED PRECEDING) AS 'RANGE'
--	,SUM(VLR) OVER(ORDER BY ANO ROWS UNBOUNDED PRECEDING)  AS 'ROWS'
--FROM @TAB T	


-- EXEMPLO 1 
;WITH T
AS
(

SELECT 
	 ID
	,ANO
	,VLR
	,SUM(VLR) OVER(PARTITION BY ANO ORDER BY ANO) AS 'VLR_ANO'
	,SUM(VLR) OVER(ORDER BY ANO) AS 'VLR_TOTAL'
	,SUM(VLR) OVER(ORDER BY ANO RANGE UNBOUNDED PRECEDING) AS 'RANGE'
	,SUM(VLR) OVER(ORDER BY ANO ROWS UNBOUNDED PRECEDING)  AS 'ROWS'
FROM @TAB T	
)
SELECT 
	 *
	,ROUND(VLR / VLR_ANO,4) * 100 '% RANGE'
	,ROUND([ROWS] / (SELECT SUM(VLR) FROM T), 4 ) * 100 '%ROWS'
FROM T 


USE tempdb;

DROP TABLE IF EXISTS #T;
CREATE TABLE #T (ID INT NOT NULL IDENTITY(1,1), VALOR DECIMAL(15,4) NOT NULL, ANO INT NOT NULL);
INSERT INTO #T (VALOR,ANO) VALUES (5,2019),(10,2019),(15,2020),(20,2020),(25,2021),(30,2021);

/*
ORDER BY - Em que ordem será efetuada a soma
ROWS BETWEEN - Quais registros participarão da soma sendo que:
UNBOUNDED PRECEDING - Primeiro registro
PRECEDING 1 - Registro anterior
CURRENT ROW - Registro atual
UNBOUNDED FOLLOWING - Último registro
FOLLOWING 1 - Próximo registro
*/


SELECT 
	 *
	,' <|> ' AS '____'
	,SUM(VALOR) OVER() AS 'ROWS_T'
	,SUM(VALOR) OVER(ORDER BY ID,ANO ROWS UNBOUNDED PRECEDING) AS 'ROWS_TA'
	,SUM(VALOR) OVER(ORDER BY ID,ANO ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS 'ROWS_TA_2'
	,SUM(VALOR) OVER(ORDER BY ID,ANO ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS 'ROWS_TA_DESC'
	,SUM(VALOR) OVER(ORDER BY ID,ANO ROWS BETWEEN 1 PRECEDING AND CURRENT ROW ) AS 'ROWS_TA_1_ANTERIOR'
	,SUM(VALOR) OVER(ORDER BY ID,ANO ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING ) AS 'ROWS_TA_1_POSTERIOR'
	,SUM(VALOR) OVER(ORDER BY ID,ANO ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING ) AS 'ROWS_TA_1_1'
	,' <|> ' AS '____'
	,SUM(VALOR) OVER() AS 'RANGE_T'
	,SUM(VALOR) OVER(ORDER BY ANO RANGE UNBOUNDED PRECEDING) AS 'RANGE_TA'
	,SUM(VALOR) OVER(ORDER BY ANO RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS 'RANGE_TA_2'
	,SUM(VALOR) OVER(ORDER BY ANO RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS 'RANGE_TA_DESC'
FROM #T
ORDER BY ID;


