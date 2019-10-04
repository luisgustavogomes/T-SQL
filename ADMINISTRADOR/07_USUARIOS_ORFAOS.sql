/*

https://www.dirceuresende.com/blog/sql-server-consultas-uteis-do-dia-a-dia-do-dba-que-voce-sempre-tem-que-ficar-procurando-na-internet/

*/


SELECT
    A.[name],
    A.[sid],
    (CASE 
        WHEN C.principal_id IS NULL THEN NULL -- Não tem o que fazer.. Login correspondente não existe
        ELSE 'ALTER USER [' + A.[name] + '] WITH LOGIN = [' + C.[name] + ']' -- Tenta corrigir o usuário órfão
    END) AS command
FROM
    sys.database_principals A WITH(NOLOCK)
    LEFT JOIN sys.sql_logins B WITH(NOLOCK) ON A.[sid] = B.[sid]
    LEFT JOIN sys.server_principals C WITH(NOLOCK) ON (A.[name] COLLATE SQL_Latin1_General_CP1_CI_AI = C.[name] COLLATE SQL_Latin1_General_CP1_CI_AI OR A.[sid] = C.[sid]) AND C.is_fixed_role = 0 AND C.[type_desc] = 'SQL_LOGIN'
WHERE
    A.principal_id > 4
    AND B.[sid] IS NULL
    AND A.is_fixed_role = 0
    AND A.[type_desc] = 'SQL_USER'
    AND A.authentication_type <> 0 -- NONE
ORDER BY
    A.[name]