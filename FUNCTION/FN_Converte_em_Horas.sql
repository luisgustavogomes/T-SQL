/*
	SELECT DBO.FN_CONVERTE_EM_HORAS(61,'second')
*/


CREATE OR ALTER FUNCTION [DBO].[FN_CONVERTE_EM_HORAS] (@QT_TEMPO BIGINT, @TP_TEMPO VARCHAR(10))
RETURNS VARCHAR(MAX)
WITH SCHEMABINDING
BEGIN 

    DECLARE @ResultadoNegativo TINYINT = 0

    IF (@Qt_Tempo < 0)
    BEGIN
        SET @ResultadoNegativo = 1
        SET @Qt_Tempo = @Qt_Tempo * (-1)
    END 
    

    DECLARE @Diferenca BIGINT = @Qt_Tempo, 
            @Segundos BIGINT = 0, 
            @Minutos BIGINT = 0, 
            @Horas BIGINT = 0

    
    IF(@Tp_Tempo IN('ss','second'))
    BEGIN
        
        SET @Horas = @Diferenca / 3600 
        SET @Diferenca = @Diferenca - (@Horas * 3600) 

        SET @Minutos = @Diferenca / 60 
        SET @Diferenca = @Diferenca - (@Minutos * 60) 

        SET @Segundos = @Diferenca 
    
    END
    
    IF(@Tp_Tempo IN('mm','minute'))
    BEGIN
        
        SET @Horas = @Diferenca / 60
        SET @Diferenca = @Diferenca - (@Horas * 60)

        SET @Minutos = @Diferenca

        SET @Segundos = 0 
    
    END
    
    IF(@Tp_Tempo IN('hh','hour'))
    BEGIN
        
        SET @Horas = @Diferenca 

        SET @Minutos = 0

        SET @Segundos = 0
    
    END
    
        
    RETURN 
        (CASE WHEN @ResultadoNegativo = 1 THEN '-' ELSE '' END) + 
        (CASE WHEN @Horas <= 9 THEN RIGHT('00' + CAST(@Horas AS VARCHAR(1)), 2) ELSE CAST(@Horas AS VARCHAR(MAX)) END + ':' + 
         RIGHT('00' + CAST(@Minutos AS VARCHAR(2)), 2) + ':' + 
         RIGHT('00' + CAST(@Segundos AS VARCHAR(2)), 2)) 
        
END