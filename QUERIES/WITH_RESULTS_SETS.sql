USE AdventureWorks2017
GO 

CREATE OR ALTER PROCEDURE spGetSalesAmout
AS
SELECT ProductID, [Name]
FROM Production.Product AS P

CREATE OR ALTER PROCEDURE spGetSalesAmout2
AS
SELECT ProductID, [Name], P.ProductNumber
FROM Production.Product AS P
WHERE P.ProductID < 30

SELECT ProductID, [Name]
FROM Production.Product AS P
WHERE P.ProductID > 800


EXEC spGetSalesAmout
WITH RESULT SETS 
(
	(ProductID INT
	,[Name] NAME)
);
GO

EXEC spGetSalesAmout2
WITH RESULT SETS 
(
	(
		 ProductID INT
		,[Name] NAME
		,ProductNumber NVARCHAR(50)
	) 
	,
	(
		 ProductID INT
		,[Name] NAME
	) 
);
GO

IF OBJECT_ID ('TEMPDB.DBO.#TABELA ') IS NOT NULL
	DROP TABLE #TABELA
CREATE TABLE #TABELA 
(
	 ProductID INT
	,[Name] NVARCHAR(50)
)

INSERT INTO #TABELA
EXEC spGetSalesAmout

SELECT * FROM #TABELA



--------------------------------------------
sp_configure 'Show Advanced Options', 1
GO
RECONFIGURE
GO
sp_configure 'Ad Hoc Distributed Queries', 1
GO
RECONFIGURE
GO


SELECT
  *
INTO
  #tmpSortedBooks
FROM
  OPENROWSET(
    'SQLNCLI11',
    'Server=(local);Trusted_Connection=yes;',
    'EXEC AdventureWorks2017.dbo.spGetSalesAmout'
)


