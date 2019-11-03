/*
	IF OBJECT_ID('TEMPDB..#T') IS NOT NULL
		DROP TABLE #T

	SELECT * INTO #T
	FROM [DBO].[FN_LER_ARQUIVO_FSO]('C:\TEMPORARIO\TESTE.TXT')

	SELECT * FROM #T

*/

CREATE OR ALTER FUNCTION [DBO].[FN_LER_ARQUIVO_FSO] (
    @Ds_Arquivo VARCHAR(256)
)
RETURNS @Tabela_Final TABLE (
    Ds_Linha VARCHAR(8000)
)
AS
BEGIN

    DECLARE @OLEResult INT
    DECLARE @FileSystemObject INT
    DECLARE @FileID INT
    DECLARE @Message VARCHAR (8000)

    DECLARE @Tabela TABLE ( Ds_Linha varchar(8000) )

    EXECUTE @OLEResult = sp_OACreate 'Scripting.FileSystemObject', @FileSystemObject OUT
    IF @OLEResult <> 0
    BEGIN
        SET @Message = 'Scripting.FileSystemObject - Error code: ' + CONVERT (VARCHAR, @OLEResult)
        INSERT INTO @Tabela_Final SELECT @Message
        RETURN
    END

    EXEC @OLEResult = sp_OAMethod @FileSystemObject, 'OpenTextFile', @FileID OUT, @Ds_Arquivo, 1, 1
    IF @OLEResult <> 0
    BEGIN
        SET @Message = 'OpenTextFile - Error code: ' + CONVERT (VARCHAR, @OLEResult)
        INSERT INTO @Tabela_Final SELECT @Message
        RETURN
    END

    EXECUTE @OLEResult = sp_OAMethod @FileID, 'ReadLine', @Message OUT

    WHILE (@OLEResult >= 0)
    BEGIN

        INSERT INTO @Tabela(Ds_Linha) VALUES( @Message )
        EXECUTE @OLEResult = sp_OAMethod @FileID, 'ReadLine', @Message OUT

    END

    EXECUTE @OLEResult = sp_OADestroy @FileID
    EXECUTE @OLEResult = sp_OADestroy @FileSystemObject
    
    
    INSERT INTO @Tabela_Final
    SELECT Ds_Linha FROM @Tabela
    
    
    RETURN
    
END