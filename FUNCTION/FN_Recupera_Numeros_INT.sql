CREATE OR ALTER  FUNCTION [DBO].[FN_RECUPERA_NUMEROS](@STR VARCHAR(500))  
RETURNS BIGINT 
WITH SCHEMABINDING
BEGIN  

    DECLARE @STARTINGINDEX INT  
    SET @STARTINGINDEX=0  
    WHILE 1=1  
    BEGIN  
        SET @STARTINGINDEX= PATINDEX('%[^0-9]%',@STR)  
        IF @STARTINGINDEX <> 0  
        BEGIN  
            SET @STR = REPLACE(@STR,SUBSTRING(@STR,@STARTINGINDEX,1),'')  
        END  
        ELSE    BREAK;   
    END 
	

	DECLARE @RETURN BIGINT
	
	IF @RETURN = ''
		SET @RETURN = TRY_CAST(@STR AS BIGINT)
	ELSE 
		SET @RETURN = 0 	

    RETURN @RETURN

END