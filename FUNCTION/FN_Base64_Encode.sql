CREATE OR ALTER FUNCTION [dbo].[FN_Base64_Encode] (
    @string VARCHAR(MAX)
) 
RETURNS VARCHAR(MAX)
WITH SCHEMABINDING
AS BEGIN

    DECLARE 
        @source VARBINARY(MAX), 
        @encoded VARCHAR(MAX)
        
    set @source = convert(varbinary(max), @string)
    SET @encoded = CAST('' AS XML).value('xs:base64Binary(sql:variable("@source"))', 'varchar(max)')

    RETURN @encoded

END