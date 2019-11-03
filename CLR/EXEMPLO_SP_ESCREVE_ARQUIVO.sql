DECLARE @Texto VARCHAR(MAX) = 'Testando
Arquivo texto
 
com
quebra
de
linhas'
 
EXEC CLR.dbo.SP_ESCREVE_ARQUIVO 
    @Ds_Texto = @Texto, -- nvarchar(max)
    @Ds_Caminho = N'C:\temporario\CLR_Texto.txt', -- nvarchar(max)
    @Ds_Codificacao = N'ISO-8859-1', -- nvarchar(max)
    @Ds_Formato_Quebra_Linha = N'windows', -- nvarchar(max)
    @Fl_Append = 0 -- bit
 