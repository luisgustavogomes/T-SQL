-- @Fl_Tipo define como é o tipo de formatação
-- 1: Janeiro Fevereiro Marco Abril...
-- 2: JANEIRO FEVEVEIRO MARCO ABRIL
-- 3: Jan Fev Mar Abr
-- 4: JAN FEV MAR ABR
-- 5: January, February ... (cubo)

CREATE OR ALTER FUNCTION [dbo].[FN_Mes] (@Dt_Referencia DATETIME, @Fl_Tipo TINYINT, @Fl_Incluir_Ano BIT = 0, @Fl_Incluir_Dia BIT = 0)
RETURNS VARCHAR(30)
WITH SCHEMABINDING
AS BEGIN

    
    DECLARE @Mes TINYINT
    SET @Mes = DATEPART(MONTH, @Dt_Referencia)


    DECLARE @Ds_Mes as varchar(30)
    SET @Ds_Mes = CASE 
        WHEN @Mes =  1 THEN 'Janeiro'
        WHEN @Mes =  2 THEN 'Fevereiro'
        WHEN @Mes =  3 THEN 'Março'
        WHEN @Mes =  4 THEN 'Abril'
        WHEN @Mes =  5 THEN 'Maio'
        WHEN @Mes =  6 THEN 'Junho'
        WHEN @Mes =  7 THEN 'Julho'
        WHEN @Mes =  8 THEN 'Agosto'
        WHEN @Mes =  9 THEN 'Setembro'
        WHEN @Mes = 10 THEN 'Outubro'
        WHEN @Mes = 11 THEN 'Novembro'
        WHEN @Mes = 12 THEN 'Dezembro'	
        ELSE NULL
    END
    IF (@Fl_Tipo IN (3,4)) SET @Ds_Mes = SubString(@Ds_Mes,1,3)
    IF (@Fl_Tipo IN (2,4)) SET @Ds_Mes = Upper(@Ds_Mes)

    IF (@Fl_Tipo = 5) BEGIN
        DECLARE @Date datetime 
        SET @Date = '2001'+Right('0'+Cast(@Mes as varchar(2)),2)+'01' 
        SET @Ds_Mes = DateName(Month,@Date)
    END
    
    
    IF (@Fl_Incluir_Ano = 1)
        SET @Ds_Mes = @Ds_Mes + ' ' + CAST(DATEPART(YEAR, @Dt_Referencia) AS VARCHAR(4))
    
    
    IF (@Fl_Incluir_Dia = 1)
        SET @Ds_Mes =   CAST(DATEPART(DAY, @Dt_Referencia) AS VARCHAR(4)) + '/' + @Ds_Mes
    

    RETURN @Ds_Mes
    
END