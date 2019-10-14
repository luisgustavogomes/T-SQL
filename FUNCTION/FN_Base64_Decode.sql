CREATE OR ALTER FUNCTION [dbo].[fncBase64_Decode] (
    @string VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS BEGIN

    DECLARE @decoded VARCHAR(MAX)
    SET @decoded = CAST('' AS XML).value('xs:base64Binary(sql:variable("@string"))', 'varbinary(max)')

    RETURN convert(varchar(max), @decoded)
    
END