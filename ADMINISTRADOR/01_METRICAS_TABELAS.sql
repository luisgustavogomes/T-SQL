CREATE TABLE #Resumo (
	Name NVARCHAR(128),
	Rows CHAR(11),
	Reserved VARCHAR(18),
	Data VARCHAR(18),
	Index_Size VARCHAR(18),
	Unused VARCHAR(18)
	)

-- Declara uma variável para armazenar o nome da tabela
DECLARE @Tabela NVARCHAR(128)

-- Declara um cursor para ler todas as tabelas
DECLARE Tabelas CURSOR FAST_FORWARD
FOR
SELECT TABLE_SCHEMA + '.' + TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

OPEN Tabelas

FETCH NEXT
FROM Tabelas
INTO @Tabela

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO #Resumo
	EXEC sp_spaceused @Tabela

	FETCH NEXT
	FROM Tabelas
	INTO @Tabela
END

CLOSE Tabelas

DEALLOCATE Tabelas

-- Retorna as métricas
SELECT Name,
	Rows,
	Reserved,
	Data,
	Index_Size,
	Unused
FROM #Resumo
where rows >0 
ORDER BY Name

DROP TABLE #Resumo
