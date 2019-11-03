/*

	SELECT [DBO].[FN_LER_ARQUIVO_STRING_FSO]('C:\TEMPORARIO\TESTE.TXT')

*/


CREATE OR ALTER FUNCTION [DBO].[FN_LER_ARQUIVO_STRING_FSO] (
    @Ds_Arquivo VARCHAR(256)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

    DECLARE @OLEResult INT
    DECLARE @FileSystemObject INT
    DECLARE @FileID INT
    DECLARE @Message VARCHAR (8000)
    DECLARE @Retorno VARCHAR(MAX)

    EXECUTE @OLEResult = sp_OACreate 'Scripting.FileSystemObject', @FileSystemObject OUT
    IF @OLEResult <> 0
    BEGIN
        SET @Message = 'Scripting.FileSystemObject - Error code: ' + CONVERT (VARCHAR, @OLEResult)
        RETURN @Message
    END

    EXEC @OLEResult = sp_OAMethod @FileSystemObject, 'OpenTextFile', @FileID OUT, @Ds_Arquivo, 1, 1
    IF @OLEResult <> 0
    BEGIN
        SET @Message = 'OpenTextFile - Error code: ' + CONVERT (VARCHAR, @OLEResult)
        RETURN @Message
    END

    EXECUTE @OLEResult = sp_OAMethod @FileID, 'ReadLine', @Message OUT
    SET @Retorno = ISNULL(@Retorno, '') + ISNULL(@Message, '') + CHAR(13)

    WHILE (@OLEResult >= 0)
    BEGIN
        
        SET @Message = NULL
        EXECUTE @OLEResult = sp_OAMethod @FileID, 'ReadLine', @Message OUT
        SET @Retorno = ISNULL(@Retorno, '') + ISNULL(@Message, '') + CHAR(13)

    END

    EXECUTE @OLEResult = sp_OADestroy @FileID
    EXECUTE @OLEResult = sp_OADestroy @FileSystemObject
    
    
    RETURN @Retorno

    
END