/* Database Roles */

SELECT
	db_name() as db_name,
    C.[name] AS Ds_Usuario,
    B.[name] AS Ds_Database_Role
FROM 
    sys.database_role_members A
    JOIN sys.database_principals B ON A.role_principal_id = B.principal_id
    JOIN sys.database_principals C ON A.member_principal_id = C.principal_id

/* Permissões a nível de database */

SELECT
	db_name() as db_name,
    A.class_desc AS Ds_Tipo_Permissao, 
    A.[permission_name] AS Ds_Permissao,
    A.state_desc AS Ds_Operacao,
    B.[name] AS Ds_Usuario_Permissao,
    C.[name] AS Ds_Login_Permissao,
    D.[name] AS Ds_Objeto
FROM 
    sys.database_permissions A
    JOIN sys.database_principals B ON A.grantee_principal_id = B.principal_id
    LEFT JOIN sys.server_principals C ON B.[sid] = C.[sid]
    LEFT JOIN sys.objects D ON A.major_id = D.[object_id]
WHERE
    A.major_id >= 0

/* Server roles */

SELECT 
    B.[name] AS Ds_Usuario,
    C.[name] AS Ds_Server_Role
FROM 
    sys.server_role_members A
    JOIN sys.server_principals B ON A.member_principal_id = B.principal_id
    JOIN sys.server_principals C ON A.role_principal_id = C.principal_id

/* Permissões a nível de instância */

SELECT
    A.class_desc AS Ds_Tipo_Permissao,
    A.state_desc AS Ds_Tipo_Operacao,
    A.[permission_name] AS Ds_Permissao,
    B.[name] AS Ds_Login,
    B.[type_desc] AS Ds_Tipo_Login
FROM 
    sys.server_permissions A
    JOIN sys.server_principals B ON A.grantee_principal_id = B.principal_id
WHERE
    B.[name] NOT LIKE '##%'
ORDER BY
    B.[name],
    A.[permission_name]

