--IF object_id('Contador') IS NOT NULL 
--   DROP TABLE Contador 
--GO 

--IF object_id('Comercial') IS NOT NULL 
--   DROP TABLE Comercial 
--GO 

--IF object_id('Chamada') IS NOT NULL 
--   DROP TABLE Chamada 
--GO 

--CREATE TABLE dbo.Contador
--  (Num INT NOT NULL PRIMARY KEY) 
--GO

--CREATE TABLE dbo.Comercial
-- (Inicio DATETIME NOT NULL CONSTRAINT PK_Comercial PRIMARY KEY, 
--  Final DATETIME NOT NULL, 
--  Nome VARCHAR(30) NOT NULL); 
--GO 

--CREATE TABLE dbo.Chamada
-- (IdtChamada INT  CONSTRAINT PK_Chamada NOT NULL PRIMARY KEY, 
--  Duracao DATETIME NOT NULL, 
--  Observacoes CHAR(300)); 
--GO 

--CREATE UNIQUE INDEX Chamada_Duracao ON dbo.Chamada(Duracao) INCLUDE(Observacoes); 
--GO 
 
--DECLARE @i INT = 1; 
--INSERT INTO dbo.Contador(Num) SELECT 1; 
--WHILE @i<1024000 BEGIN 
--  INSERT INTO dbo.Contador(Num) 
--  SELECT Num + @i FROM dbo.Contador; 
--  SET @i = @i * 2; 
--END; 
--GO 

--INSERT INTO dbo.Comercial(Inicio, Final, Nome) 
--SELECT DATEADD(minute, Num - 1, '20170101') 
--     , DATEADD(minute, Num, '20170101') 
--     , 'Exibir '+CAST(Num AS VARCHAR(6)) 
--  FROM dbo.Contador 
-- WHERE Num<=24*365*60; 
--GO 

--INSERT INTO dbo.Chamada(IdtChamada, Duracao, Observacoes) 
--SELECT Num  
--     , DATEADD(minute, Num - 1, '20170101') 
--     , 'Exibir durante o comercial '+CAST(Num AS VARCHAR(6)) 
--  FROM dbo.Contador 
--  WHERE Num<=24*365*60; 
--GO    

SELECT count(1) FROM Contador
SELECT count(1) FROM Comercial
SELECT count(1) FROM Chamada




SELECT s.Inicio, s.Final, c.Duracao 
  FROM dbo.Comercial s 
 INNER JOIN dbo.Chamada c ON c.Duracao >= s.Inicio AND c.Duracao < s.Final 
 WHERE c.Duracao BETWEEN '2017-07-01 00:00' AND '2017-07-01 03:00' 
GO  

SELECT COM.Inicio, COM.Final, CHA.Duracao 
  FROM dbo.Chamada AS CHA 
 CROSS APPLY(SELECT TOP 1 COM.Inicio, COM.Final 
               FROM dbo.Comercial AS COM
              WHERE CHA.Duracao >= COM.Inicio AND CHA.Duracao < COM.Final 
              ORDER BY COM.Inicio DESC) AS COM
 WHERE CHA.Duracao BETWEEN '20170701' AND '20170701 03:00'