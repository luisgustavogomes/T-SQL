

 
-- Exportando query para arquivo texto (CSV)
EXEC CLR.dbo.SP_EXPORTA_QUERY_TXT 
    @query = N'SELECT * FROM northwind.dbo.OrdersBig', -- nvarchar(max)
    @separador = N';', -- nvarchar(max)
    @caminho = N'C:\temporario\CLR_Teste.csv', -- nvarchar(max)
    @Fl_Coluna = 1 -- int