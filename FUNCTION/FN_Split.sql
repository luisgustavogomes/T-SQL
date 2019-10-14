/*
	https://www.dirceuresende.com/blog/sql-server-comparacao-de-performance-entre-scalar-function-udf-e-clr-scalar-function/

*/



CREATE OR ALTER FUNCTION [dbo].[FN_Split] ( @String varchar(8000), @Separador varchar(8000), @PosBusca int )
RETURNS varchar(8000)
AS BEGIN
    
    DECLARE @Index int, @Max int, @Retorno varchar(8000)

    DECLARE @Partes as TABLE ( Id_Parte int identity(1,1), Texto varchar(8000) )

    SET @Index = charIndex(@Separador,@String)

    WHILE (@Index > 0) BEGIN	
        INSERT INTO @Partes SELECT SubString(@String,1,@Index-1)
        SET @String = Rtrim(Ltrim(SubString(@String,@Index+Len(@Separador),Len(@String))))
        SET @Index = charIndex(@Separador,@String)
    END

    IF (@String != '') INSERT INTO @Partes SELECT @String

    SELECT @Max = Count(*) FROM @Partes

    IF (@PosBusca = 0) SET @Retorno = Cast(@Max as varchar(5))
    IF (@PosBusca < 0) SET @PosBusca = @Max + 1 + @PosBusca
    IF (@PosBusca > 0) SELECT @Retorno = Texto FROM @Partes WHERE Id_Parte = @PosBusca

    RETURN Rtrim(Ltrim(@Retorno))

END