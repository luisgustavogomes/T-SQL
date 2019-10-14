CREATE OR ALTER PROCEDURE [DBO].[SP_RECRIA_FK_TABELA_REFERENTE]
    @Database [sysname],
    @Objeto [sysname] = NULL,
    @Schema [sysname] = NULL
WITH EXECUTE AS CALLER
AS
BEGIN
    
    --
    -- DROP CONSTRAINTS 
    --

    DECLARE @Db_Id sysname = (SELECT database_id FROM sys.databases WHERE name = @Database)
    DECLARE @query VARCHAR(MAX), @cmd VARCHAR(MAX)

    SET @query = '
    SELECT 
        ''ALTER TABLE [' + @Database + '].['' + schema_ori.name + ''].['' + objeto.name + ''] DROP CONSTRAINT ['' + FK.name  + '']'' AS Dropar_FKs
    FROM 
        ' + @Database + '.sys.foreign_keys				AS FK
        JOIN ' + @Database + '.sys.foreign_key_columns	AS FK_Coluna ON FK.object_id = FK_Coluna.constraint_object_id
        JOIN ' + @Database + '.sys.objects				AS objeto ON FK.parent_object_id = objeto.object_id
        JOIN ' + @Database + '.sys.schemas				AS schema_ori ON objeto.schema_id = schema_ori.schema_id'


    IF (@Objeto IS NOT NULL)
    BEGIN

        SET @query = @query + '
    WHERE
        objeto.name = ''' + @Objeto + ''''

    END


    IF (@Schema IS NOT NULL)
    BEGIN

        IF (@Objeto IS NULL) 
            SET @query = @query + ' 
    WHERE 1=1'

        SET @query = @query + '
        AND schema_ori.name = ''' + @Schema + ''''

    END


    EXEC(@query)



    -- 
    -- RECREATE CONSTRAINTS
    --

    SET @query = '
    SELECT 
        ''ALTER TABLE [' + @Database + '].['' + schema_ori.name + ''].['' + objeto.name + ''] '' + 
        ''ADD CONSTRAINT ['' + fk.name + ''] FOREIGN KEY ('' + colunas.name + '') '' + 
        ''REFERENCES ['' + schema_ref.name + ''].['' + objeto_ref.name + ''] ('' + colunas_ref.name + '')'' as Recriar_FKs
    FROM 
        ' + @Database + '.sys.foreign_keys AS fk
        JOIN ' + @Database + '.sys.foreign_key_columns AS fc ON fk.object_id = fc.constraint_object_id

        JOIN ' + @Database + '.sys.objects objeto ON fk.parent_object_id = objeto.object_id
        JOIN ' + @Database + '.sys.columns colunas ON fc.parent_column_id = colunas.column_id AND fk.parent_object_id = colunas.object_id
        JOIN ' + @Database + '.sys.schemas schema_ori ON objeto.schema_id = schema_ori.schema_id

        JOIN ' + @Database + '.sys.objects objeto_ref ON fc.referenced_object_id = objeto_ref.object_id
        JOIN ' + @Database + '.sys.columns colunas_ref ON fc.referenced_column_id = colunas_ref.column_id AND fk.referenced_object_id = colunas_ref.object_id
        JOIN ' + @Database + '.sys.schemas schema_ref ON objeto_ref.schema_id = schema_ref.schema_id'
    

    IF (@Objeto IS NOT NULL)
    BEGIN

        SET @query = @query + '
    WHERE
        objeto.name = ''' + @Objeto + ''''

    END


    IF (@Schema IS NOT NULL)
    BEGIN

        IF (@Objeto IS NULL) 
            SET @query = @query + ' 
    WHERE 1=1'

        SET @query = @query + '
        AND schema_ori.name = ''' + @Schema + ''''

    END


    EXEC(@query)


END