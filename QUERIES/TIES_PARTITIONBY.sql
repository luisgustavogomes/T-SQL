USE TEMPDB
GO 

;WITH TAB
AS
(
	SELECT ProductName, Price
	FROM 
	(
		VALUES 
			 ('Bicycle 1' , 258.2)
			,('Bicycle 2' , 265.3)
			,('Bicycle 3' , 267.8)
			,('Bicycle 4' , 268.9)
			,('Bicycle 5' , 267.9)
			,('Bicycle 6' , 267.9)
	) T (ProductName, Price)
)
SELECT TOP 4 ProductName, Price
FROM TAB 
ORDER BY PRICE 


;WITH TAB
AS
(
	SELECT ProductName, Price
	FROM 
	(
		VALUES 
			 ('Bicycle 1' , 258.2)
			,('Bicycle 2' , 265.3)
			,('Bicycle 3' , 267.8)
			,('Bicycle 4' , 268.9)
			,('Bicycle 5' , 267.9)
			,('Bicycle 6' , 267.9)
	) T (ProductName, Price)
)
SELECT TOP 4  WITH TIES ProductName, Price
FROM TAB 
ORDER BY Price



;WITH TAB
AS
(
	SELECT Company, ProductName, Price
	FROM 
	(
		VALUES 
			 (1,'Bicycle 1.1' , 258.2)
			,(1,'Bicycle 1.2' , 265.3)
			,(1,'Bicycle 1.3' , 267.8)
			,(1,'Bicycle 1.4' , 268.9)
			,(1,'Bicycle 1.5' , 267.9)
			,(1,'Bicycle 1.6' , 267.9)
			,(2,'Bicycle 2.2' , 265.3)
			,(2,'Bicycle 2.3' , 267.8)
			,(2,'Bicycle 2.4' , 250.9)
			,(2,'Bicycle 2.5' , 267.9)
			,(2,'Bicycle 2.6' , 267.9)
	) T (Company, ProductName, Price)
)
SELECT TOP 2  WITH TIES 
	Company, ProductName, Price
FROM TAB 
ORDER BY ROW_NUMBER() OVER ( PARTITION BY COMPANY ORDER BY PRICE   )