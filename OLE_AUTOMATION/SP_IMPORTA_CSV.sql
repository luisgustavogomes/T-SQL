USE Northwind
GO



SELECT @@LANGUAGE
/*
SELECT * FROM sys.syslanguages

EXEC DBO.[SP_IMPORTA_CSV]
	@Ds_Caminho_Arquivo = 'C:\Temporario\teste.csv' ,
	@Ds_Separador = ',' ,
	@Fl_Primeira_Linha_Cabecalho = 1  ,
	@Ds_Tabela_Destino = NULL
*/


CREATE OR ALTER PROCEDURE [dbo].[SP_IMPORTA_CSV] (
    @Ds_Caminho_Arquivo VARCHAR(MAX),
    @Ds_Separador VARCHAR(10) = ';',
    @Fl_Primeira_Linha_Cabecalho BIT = 1,
    @Ds_Tabela_Destino VARCHAR(MAX) = NULL
)
AS BEGIN

    DECLARE @tabela_bruta TABLE (
        Id INT IDENTITY(1,1),
        Ds_Linha VARCHAR(MAX)
    )

    -- Insere numa tabela temporária o conteúdo do CSV que será importado
    INSERT INTO @tabela_bruta(Ds_Linha)
    SELECT * FROM dbo.FN_LER_ARQUIVO_FSO(@Ds_Caminho_Arquivo)

    
    DECLARE 
        @contadorColunas INT = 1,
        @numeroColunas INT = (SELECT TOP 1 LEN(Ds_Linha) - LEN(REPLACE(Ds_Linha, @Ds_Separador, '')) + LEN(@Ds_Separador) FROM @tabela_bruta),
        @query VARCHAR(MAX)
        
    
    IF (OBJECT_ID('tempdb..#Tabela_Final') IS NOT NULL) DROP TABLE #Tabela_Final
    CREATE TABLE #Tabela_Final (
        Id INT IDENTITY(1,1)
    )
    
    -- Loop para inserir as colunas de acordo com a estrutura do CSV
    WHILE(@contadorColunas <= @numeroColunas)
    BEGIN
        
        SET @query = 'ALTER TABLE #Tabela_Final ADD Ds_Coluna_' + CAST(@contadorColunas AS VARCHAR(20)) + ' VARCHAR(MAX)'
        EXEC(@query)
        
        SET @contadorColunas = @contadorColunas + 1

    END


    
    DECLARE 
        @numeroLinhas INT = (SELECT COUNT(*) FROM @tabela_bruta),
        @linha VARCHAR(MAX),
        @contadorLinhas INT = 1

    
    -- Loop para renomear as colunas de acordo com o nome do cabeçalho (se usada a Flag @Fl_Primeira_Linha_Cabecalho = 1)
    IF (@Fl_Primeira_Linha_Cabecalho = 1)
    BEGIN
        
        SET @contadorColunas = 1
        
        DECLARE 
            @cabecalho VARCHAR(MAX) = (SELECT Ds_Linha FROM @tabela_bruta WHERE Id = 1),
            @Nm_Coluna_Anterior VARCHAR(MAX),
            @Nm_Coluna_Nova VARCHAR(MAX)
        
        WHILE(@contadorColunas <= @numeroColunas)
        BEGIN
            
            SET @Nm_Coluna_Anterior = '#tabela_final.Ds_Coluna_' + CAST(@contadorColunas AS VARCHAR(20))
            SET @Nm_Coluna_Nova = (SELECT dbo.FN_Split(@cabecalho, @Ds_Separador, @contadorColunas))
            
            -- Remove aspas (se houver)
            IF (LEFT(@Nm_Coluna_Nova, 1) = '"' AND RIGHT(@Nm_Coluna_Nova, 1) = '"')
                SET @Nm_Coluna_Nova = SUBSTRING(@Nm_Coluna_Nova, 2, LEN(@Nm_Coluna_Nova) - 2)
            
            EXEC tempdb..sp_RENAME @Nm_Coluna_Anterior, @Nm_Coluna_Nova, 'COLUMN'
            SET @contadorColunas = @contadorColunas + 1
            
        END
        
        DELETE FROM @tabela_bruta WHERE id = 1
        SET @contadorLinhas = 2
    
    END


    -- Loop para inserir os dados na tabela temporária final
    
    DECLARE
        @coluna VARCHAR(MAX)
    
    WHILE(@contadorLinhas <= @numeroLinhas)
    BEGIN
        
        SET @contadorColunas = 1
        SET @linha = (SELECT Ds_Linha FROM @tabela_bruta WHERE Id = @contadorLinhas)
        
        SET @query = 'INSERT INTO #tabela_final VALUES('
        
        WHILE(@contadorColunas <= @numeroColunas)
        BEGIN
            
            SET @coluna = ISNULL(dbo.FN_Split(@linha, @Ds_Separador, @contadorColunas), '')
            
            -- Remove aspas (se houver)
            IF (LEFT(@coluna, 1) = '"' AND RIGHT(@coluna, 1) = '"')
                SET @coluna = SUBSTRING(@coluna, 2, LEN(@coluna) - 2)
            
            SET @query = @query + CHAR(39) + @coluna + CHAR(39)
            
            IF (@contadorColunas + 1 <= @numeroColunas) SET @query = @query + ','
            
            SET @contadorColunas = @contadorColunas + 1
            
        END
        
        SET @query = @query + ')'
        EXEC(@query)
        
        SET @contadorLinhas = @contadorLinhas + 1

    END 
    
    
    IF (@Ds_Tabela_Destino IS NOT NULL)
    BEGIN
    
        SET @query = 'SELECT * INTO ' + @Ds_Tabela_Destino + ' FROM #Tabela_Final'
        EXEC(@query)
    
    END
    ELSE BEGIN
    
        -- Exibe o resultado final da SP
        SELECT * FROM #Tabela_Final
    
    END
    
    
END