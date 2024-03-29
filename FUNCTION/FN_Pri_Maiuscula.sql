/*
	SELECT [DBO].[FN_PRI_MAIUSCULA] ('LUIS GUSTAVO BAUER PEDROSO GOMES')
*/

CREATE OR ALTER FUNCTION [DBO].[FN_PRI_MAIUSCULA]
(
	@NOME VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
WITH SCHEMABINDING
AS
BEGIN
	    SET @NOME = LTRIM(RTRIM(@NOME))
	DECLARE @RETORNO AS VARCHAR(MAX)
	DECLARE @TAMANHO INT = LEN(@NOME)
	DECLARE @CONTROLADOR INT = 1
	DECLARE @CONTROLADORESPACO INT = 0
	DECLARE @INTASCII INT = 0
	DECLARE @CHARSUB VARCHAR(MAX)	
	SET @RETORNO = UPPER(SUBSTRING(@NOME,@CONTROLADOR,1))	
	SET @CONTROLADOR = 2
		WHILE (	@CONTROLADOR <= @TAMANHO )
			BEGIN				
				SET @CHARSUB = SUBSTRING(@NOME,@CONTROLADOR,1)
				SET @INTASCII = ASCII (SUBSTRING(@NOME,@CONTROLADOR,1))
				
				IF(@CONTROLADORESPACO = 1)
					SET @RETORNO = @RETORNO + UPPER(SUBSTRING(@NOME,@CONTROLADOR,1))
				ELSE 
					SET @RETORNO = @RETORNO + LOWER(SUBSTRING(@NOME,@CONTROLADOR,1))

				IF(@CONTROLADORESPACO = 1) 
				   SET @CONTROLADORESPACO =0 

				IF(@INTASCII = 32)
					SET @CONTROLADORESPACO = 1 
				
			SET @CONTROLADOR = @CONTROLADOR + 1
			END		
	RETURN @RETORNO
END