/*

Utilizando consultas Transact SQL em views de catálogo
https://www.dirceuresende.com/blog/verificando-permissoes-privilegios-acessos-um-usuario-database-no-sql-server/
Uma forma muito interessante de se obter e trabalhar com essas informações que vimos na interface do SQL Server Managment Studio é utilizando queries SQL e views de catálogo do banco de dados SQL Server. Essas queries trazem mais informações que a sp de sistema sp_helprotect e assim como utilizando a SP, podemos trabalhar com os dados retornados.
*/

DECLARE
    @Ds_Usuario VARCHAR(100) = 'EMK'


-- Associação Usuário x Login
IF (OBJECT_ID('tempdb..#Users_Logins') IS NOT NULL) DROP TABLE #Users_Logins
SELECT
    C.name AS Ds_Login,
    B.name AS Ds_Usuario
INTO
    #Users_Logins
FROM 
    sys.database_principals				A	WITH(NOLOCK)
    JOIN sys.sysusers					B	WITH(NOLOCK)	ON	A.principal_id = B.uid
    LEFT JOIN sys.syslogins				C	WITH(NOLOCK)	ON	B.sid = C.sid
WHERE
    A.type_desc != 'DATABASE_ROLE'
    AND (C.name = @Ds_Usuario OR B.name = @Ds_Usuario OR @Ds_Usuario IS NULL)



-- Recupera o Login e o usuário
DECLARE
    @Ds_Usuario_Recuperado VARCHAR(MAX),
    @Ds_Login_Recuperado VARCHAR(MAX)


SELECT
    @Ds_Login_Recuperado = Ds_Login,
    @Ds_Usuario_Recuperado = Ds_Usuario
FROM
    #Users_Logins



-- Database Roles
IF (OBJECT_ID('tempdb..#Database_Roles') IS NOT NULL) DROP TABLE #Database_Roles
SELECT 
    C.name AS Ds_Usuario,
    B.name AS Ds_Database_Role
INTO
    #Database_Roles
FROM 
    sys.database_role_members		A	WITH(NOLOCK)
    JOIN sys.database_principals	B	WITH(NOLOCK)	ON	A.role_principal_id = B.principal_id
    JOIN sys.sysusers			C	WITH(NOLOCK)	ON	A.member_principal_id = C.uid
WHERE
    (C.name IN (@Ds_Usuario_Recuperado, @Ds_Login_Recuperado) OR @Ds_Usuario IS NULL)



-- Database Permissions
IF (OBJECT_ID('tempdb..#Database_Permissions') IS NOT NULL) DROP TABLE #Database_Permissions
SELECT
    A.class_desc AS Ds_Tipo_Permissao, 
    A.permission_name AS Ds_Permissao,
    A.state_desc AS Ds_Operacao,
    B.name AS Ds_Usuario_Permissao,
    C.name AS Ds_Login_Permissao,
    D.name AS Ds_Objeto
INTO
    #Database_Permissions
FROM 
    sys.database_permissions				A	WITH(NOLOCK)
    JOIN sys.sysusers					B	WITH(NOLOCK)	ON	A.grantee_principal_id = B.uid
    LEFT JOIN sys.syslogins				C	WITH(NOLOCK)	ON	B.sid = C.sid
    LEFT JOIN sys.objects				D	WITH(NOLOCK)	ON	A.major_id = D.object_id
WHERE
    A.major_id >= 0
    AND (C.name IN (@Ds_Usuario_Recuperado, @Ds_Login_Recuperado) OR B.name IN (@Ds_Usuario_Recuperado, @Ds_Login_Recuperado) OR @Ds_Usuario IS NULL)
    


-- Server roles
IF (OBJECT_ID('tempdb..#Server_Roles') IS NOT NULL) DROP TABLE #Server_Roles
SELECT 
    B.name AS Ds_Usuario,
    C.name AS Ds_Server_Role
INTO
    #Server_Roles
FROM 
    sys.server_role_members		A	WITH(NOLOCK)
    JOIN sys.server_principals		B	WITH(NOLOCK)	ON	A.member_principal_id = B.principal_id
    JOIN sys.server_principals		C	WITH(NOLOCK)	ON	A.role_principal_id = C.principal_id
WHERE
    (B.name IN (@Ds_Usuario_Recuperado, @Ds_Login_Recuperado) OR @Ds_Usuario IS NULL)
    


-- Server permissions
IF (OBJECT_ID('tempdb..#Server_Permissions') IS NOT NULL) DROP TABLE #Server_Permissions
SELECT
    A.class_desc AS Ds_Tipo_Permissao,
    A.state_desc AS Ds_Tipo_Operacao,
    A.permission_name AS Ds_Permissao,
    C.name AS Ds_Login,
    B.type_desc AS Ds_Tipo_Login
INTO
    #Server_Permissions
FROM 
    sys.server_permissions				A	WITH(NOLOCK)
    JOIN sys.server_principals				B	WITH(NOLOCK)	ON	A.grantee_principal_id = B.principal_id
    LEFT JOIN sys.syslogins				C	WITH(NOLOCK)	ON	B.sid = C.sid
WHERE
    (C.name IN (@Ds_Usuario_Recuperado, @Ds_Login_Recuperado) OR @Ds_Usuario IS NULL)


SELECT * FROM #Users_Logins
SELECT * FROM #Database_Roles
SELECT * FROM #Database_Permissions
SELECT * FROM #Server_Roles
SELECT * FROM #Server_Permissions