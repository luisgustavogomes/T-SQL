/*
	SELECT 
	 [DBO].[FN_FORMATA_DOCUMENTO]('01683328094')
	,[DBO].[FN_FORMATA_DOCUMENTO]('89723977000140')
*/

CREATE or ALTER FUNCTION [DBO].[FN_FORMATA_DOCUMENTO](
    @Nr_Documento varchar(max)
)
RETURNS varchar(max)
WITH SCHEMABINDING
AS BEGIN

    SET @Nr_Documento = Replace(@Nr_Documento,'.','')
    SET @Nr_Documento = Replace(@Nr_Documento,'/','')
    SET @Nr_Documento = Replace(@Nr_Documento,'-','')

    DECLARE @Nr_Formatado varchar(max)
    
    
    IF (LEN(@Nr_Documento) = 14) BEGIN
        SET @Nr_Formatado = 
            substring(@Nr_Documento,1,2) + '.' + 
            substring(@Nr_Documento,3,3) + '.' + 
            substring(@Nr_Documento,6,3) + '/' + 
            substring(@Nr_Documento,9,4) + '-' + 
            substring(@Nr_Documento,13,2)
    END
    
    
    IF (LEN(@Nr_Documento) = 11) BEGIN	
        SET @Nr_Formatado = 
            substring(@Nr_Documento,1,3) + '.' + 
            substring(@Nr_Documento,4,3) + '.' + 
            substring(@Nr_Documento,7,3) + '-' + 
            substring(@Nr_Documento,10,2)
    END
    
    IF (@Nr_Formatado IS NULL) SET @Nr_Formatado = @Nr_Documento
    
    RETURN @Nr_Formatado
    
END