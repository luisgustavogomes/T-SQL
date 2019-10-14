CREATE OR ALTER FUNCTION [dbo].[fncValida_CPF](@Nr_Documento [varchar](11))
RETURNS [bit]
AS 
BEGIN

    
    IF (ISNUMERIC(@Nr_Documento) = 0)
        RETURN 0


    DECLARE
        @Contador_1 INT,
        @Contador_2 INT,
        @Digito_1 INT,
        @Digito_2 INT,
        @Nr_Documento_Aux VARCHAR(11)

    SET @Nr_Documento_Aux = LTRIM(RTRIM(@Nr_Documento))
    SET @Digito_1 = 0

    IF LEN(@Nr_Documento_Aux) <> 11
        RETURN 0
    ELSE
    BEGIN

        -- Cálculo do segundo dígito
        SET @Nr_Documento_Aux = SUBSTRING(@Nr_Documento_Aux, 1, 9)

        SET @Contador_1 = 2

        WHILE @Contador_1 <= 10
        BEGIN 
            SET @Digito_1 = @Digito_1 + ( @Contador_1 * CAST(SUBSTRING(@Nr_Documento_Aux, 11 - @Contador_1, 1) AS INT) )
            SET @Contador_1 = @Contador_1 + 1
        END 

        SET @Digito_1 = @Digito_1 - ( @Digito_1 / 11 ) * 11

        IF @Digito_1 <= 1
            SET @Digito_1 = 0
        ELSE
            SET @Digito_1 = 11 - @Digito_1

        SET @Nr_Documento_Aux = @Nr_Documento_Aux + CAST(@Digito_1 AS VARCHAR(1))

        IF @Nr_Documento_Aux <> SUBSTRING(@Nr_Documento, 1, 10)
            RETURN 0
        ELSE 
        BEGIN 

            -- Cálculo do segundo dígito
            SET @Digito_2 = 0
            SET @Contador_2 = 2

            WHILE (@Contador_2 <= 11)
            BEGIN 
                SET @Digito_2 = @Digito_2 + ( @Contador_2 * CAST(SUBSTRING(@Nr_Documento_Aux, 12 - @Contador_2, 1) AS INT) )
                SET @Contador_2 = @Contador_2 + 1
            END 

            SET @Digito_2 = @Digito_2 - ( @Digito_2 / 11 ) * 11


            IF @Digito_2 < 2
                SET @Digito_2 = 0
            ELSE
                SET @Digito_2 = 11 - @Digito_2
    

            SET @Nr_Documento_Aux = @Nr_Documento_Aux + CAST(@Digito_2 AS VARCHAR(1))


            IF @Nr_Documento_Aux <> @Nr_Documento
                RETURN 0

        END
                    
    END

    RETURN 1

END