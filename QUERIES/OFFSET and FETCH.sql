USE Northwind
GO 

IF OBJECT_ID ('tblPaginacao') IS NOT NULL
	DROP TABLE tblPaginacao
CREATE TABLE tblPaginacao
(
id INT IDENTITY ,
nome VARCHAR(100)
)
GO
INSERT INTO tblPaginacao
VALUES ( 'Registro 1'  ),( 'Registro 2'  ),
       ( 'Registro 3'  ),( 'Registro 4'  ),
       ( 'Registro 5'  ),( 'Registro 6'  ),
       ( 'Registro 7'  ),( 'Registro 8'  ),
       ( 'Registro 9'  ),( 'Registro 10' ),
       ( 'Registro 11' ),( 'Registro 12' ),
       ( 'Registro 13' ),( 'Registro 14' ),
       ( 'Registro 15' ),( 'Registro 16' ),
       ( 'Registro 17' ),( 'Registro 18' ),
       ( 'Registro 19' ),( 'Registro 20' )


SELECT * 
FROM tblPaginacao




SELECT *
FROM tblPaginacao
ORDER BY id
OFFSET 5 ROWS


SELECT *
FROM tblPaginacao
ORDER BY id
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY

DECLARE @PageNumber INT = 1 
DECLARE @RowsPerPage INT = 5

SELECT *
  FROM ProductsBig
 ORDER BY Col2
OFFSET ((@PageNumber - 1) * @RowsPerPage) ROWS
 FETCH NEXT @RowsPerPage ROWS ONLY
OPTION (RECOMPILE, MAXDOP 1)
GO