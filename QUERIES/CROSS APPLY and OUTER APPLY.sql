--CREATE DATABASE Treinamento
--GO

--USE Treinamento
--GO

--IF object_id('Aluno') IS NOT NULL
--BEGIN
--   DROP TABLE Aluno
--END
--GO

--IF object_id('Aula') IS NOT NULL BEGIN
--   DROP TABLE Aula
--END

--CREATE TABLE Aula
--  (IdtAula [int] NOT NULL PRIMARY KEY,
--   NomeAula VARCHAR(250) NOT NULL)
--GO

--INSERT Aula (IdtAula, NomeAula) VALUES (1, N'Português')
--INSERT Aula (IdtAula, NomeAula) VALUES (2, N'Inglês')
--INSERT Aula (IdtAula, NomeAula) VALUES (3, N'Espanhol')
--INSERT Aula (IdtAula, NomeAula) VALUES (4, N'Italiano')
--INSERT Aula (IdtAula, NomeAula) VALUES (5, N'Alemão')
--INSERT Aula (IdtAula, NomeAula) VALUES (6, N'Japones')
--GO

--CREATE TABLE Aluno
--  (IdtAluno [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
--   NomeAluno VARCHAR(50) NOT NULL,
--   IdtAula [int] NOT NULL REFERENCES Aula(IdtAula))
--GO

--INSERT Aluno (NomeAluno, IdtAula) VALUES ('Ana Maria Figueiredo', 1)
--INSERT Aluno (NomeAluno, IdtAula) VALUES ('João de Carvalho', 2)
--INSERT Aluno (NomeAluno, IdtAula) VALUES ('Maria Luiza de Souza', 3)
--INSERT Aluno (NomeAluno, IdtAula) VALUES ('Paulo Cesar de Oliveira',3)
--GO

SELECT * FROM Aluno
SELECT * FROM Aula
GO

SELECT * 
  FROM Aula 
  OUTER APPLY (SELECT * 
                 FROM Aluno
                WHERE Aluno.IdtAula = Aula.IdtAula) AS AulasAluno 
GO


SELECT * 
  FROM Aula 
 LEFT JOIN Aluno ON Aluno.IdtAula = Aula.IdtAula 
GO

 SELECT * 
  FROM Aula 
 OUTER APPLY (SELECT IdtAula, COUNT(1) AS QtAlunos 
                 FROM Aluno 
                WHERE Aluno.IdtAula = Aula.IdtAula
                GROUP BY IdtAula
               HAVING COUNT(1) > 4) AS AulasAluno
GO

SELECT Aula.IdtAula, Aula.NomeAula, Aluno.IdtAula, count(1) AS QtAlunos 
  FROM Aula  
  LEFT JOIN Aluno  ON Aula.IdtAula = Aluno.IdtAula 
 GROUP BY Aula.IdtAula, Aula.NomeAula, Aluno.IdtAula
 HAVING COUNT(1) > 4
 GO


CREATE OR ALTER FUNCTION dbo.fnListarAlunosPorAula(@IdtAula AS INT)  
RETURNS TABLE 
AS 
RETURN (SELECT * 
          FROM Aluno  
         WHERE IdtAula= @IdtAula) 
GO 

SELECT * 
  FROM Aula
 CROSS APPLY dbo.fnListarAlunosPorAula(IdtAula) 
 ORDER BY NomeAula, NomeAluno
GO 

SELECT * 
  FROM Aula 
  OUTER APPLY dbo.fnListarAlunosPorAula(IdtAula) 
  ORDER BY NomeAula, NomeAluno
GO 
