/*
	https://www.dirceuresende.com/blog/como-identificar-apagar-e-recriar-foreign-keys-fk-de-uma-tabela-no-sql-server/

	om o código abaixo, você poderá criar a SP citada no tópico, que permite a fácil visualização das FK’s que referenciam uma determinada tabela, e já informa o script para a remoção e criação dessa FK:

	EXEC [DBO].[SP_RECRIA_FK] @DATABASE = 'NORTHWIND' ,  @OBJETO = 'Order_Details'
	EXEC [DBO].[SP_RECRIA_FK_COMPOSTA] @DATABASE = 'NORTHWIND' ,  @OBJETO = 'Order_Details'
	EXEC [DBO].[SP_RECRIA_FK_TABELA_REFERENTE] @DATABASE = 'NORTHWIND',  @OBJETO = 'Order_Details'

*/
CREATE OR ALTER PROCEDURE [DBO].[SP_RECRIA_FK]
    @DATABASE [SYSNAME],
    @OBJETO [SYSNAME] = NULL,
    @SCHEMA [SYSNAME] = 'DBO'
WITH EXECUTE AS CALLER
AS
BEGIN
    
    
    DECLARE @Db_Id sysname = (SELECT database_id FROM sys.databases WHERE name = @Database)
    DECLARE @query VARCHAR(MAX)

    
    SET @query = '
    SELECT
        FK.name AS Ds_Nome_FK,
        schema_ori.name + ''.'' + objeto_ori.name AS Ds_Objeto,
        coluna_ori.name AS Ds_Coluna,
        schema_dest.name + ''.'' + objeto_dest.name AS Ds_Objeto_Referencia,
        coluna_dest.name AS Ds_Coluna_Referencia,
        ''ALTER TABLE [' + @Database + '].['' + schema_ori.name + ''].['' + objeto_ori.name + ''] DROP CONSTRAINT ['' + FK.name  + '']'' AS Dropar_FK,
        ''ALTER TABLE [' + @Database + '].['' + schema_ori.name + ''].['' + objeto_ori.name + ''] ADD CONSTRAINT ['' + FK.name + ''] FOREIGN KEY ('' + coluna_ori.name + '') REFERENCES [' + @Database + '].['' + schema_dest.name + ''].['' + objeto_dest.name + ''] ('' + coluna_dest.name + '')'' AS Criar_FK
    FROM 
        [' + @Database + '].sys.foreign_keys				    AS FK			WITH(NOLOCK)
        JOIN [' + @Database + '].sys.foreign_key_columns	    AS FK_Coluna	WITH(NOLOCK)	ON FK.object_id = FK_Coluna.constraint_object_id
    
        JOIN [' + @Database + '].sys.objects				    AS objeto_ori	WITH(NOLOCK)	ON FK.parent_object_id = objeto_ori.object_id
        JOIN [' + @Database + '].sys.objects				    AS objeto_dest	WITH(NOLOCK)	ON FK.referenced_object_id = objeto_dest.object_id

        JOIN [' + @Database + '].sys.schemas				    AS schema_ori	WITH(NOLOCK)	ON objeto_ori.schema_id = schema_ori.schema_id
        JOIN [' + @Database + '].sys.schemas				    AS schema_dest	WITH(NOLOCK)	ON FK.schema_id = schema_dest.schema_id
    
        JOIN [' + @Database + '].sys.columns				    AS coluna_ori	WITH(NOLOCK)	ON FK_Coluna.parent_object_id = coluna_ori.object_id AND FK_Coluna.parent_column_id = coluna_ori.column_id
        JOIN [' + @Database + '].sys.columns				    AS coluna_dest	WITH(NOLOCK)	ON FK_Coluna.referenced_object_id = coluna_dest.object_id AND FK_Coluna.referenced_column_id = coluna_dest.column_id'


    IF (NULLIF(LTRIM(RTRIM(@Objeto)), '') IS NOT NULL)
    BEGIN

        SET @query = @query + '
    WHERE
        objeto_dest.name = ''' + @Objeto + ''''

    END
    

    IF (NULLIF(LTRIM(RTRIM(@Schema)), '') IS NOT NULL)
    BEGIN

        IF (@Objeto IS NULL) 
            SET @query = @query + ' 
    WHERE 1=1'

        SET @query = @query + '
        AND schema_ori.name = ''' + @Schema + ''''

    END


    
    SET @query = @query + '
    ORDER BY
        schema_ori.name, objeto_dest.name'

    
    EXEC(@query)


END