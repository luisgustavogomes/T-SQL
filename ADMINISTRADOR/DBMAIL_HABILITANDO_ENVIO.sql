/*
	Não se esqueçam que para o usuário conseguir enviar e-mails pelo SQL Server, ele precisará estar na database role DatabaseMailUserRole do banco msdb (ou permissões elevadas, como owner da msdb, sysadmin, etc)

	https://www.dirceuresende.com/blog/como-habilitar-enviar-monitorar-emails-pelo-sql-server-sp_send_dbmail/

*/

-----------------------------------------------------------------------------------------
-- Habilita o envio de e-mail no servidor
-----------------------------------------------------------------------------------------

sp_configure 'show advanced options', 1;
GO

RECONFIGURE
GO

sp_configure 'Database Mail XPs', 1;
GO

RECONFIGURE
GO


-----------------------------------------------------------------------------------------
-- Cria uma conta de envio de e-mail no banco de dados
-----------------------------------------------------------------------------------------

DECLARE
    @Account_Name SYSNAME = 'ContaEnvioEmail',
    @Profile_Name SYSNAME = 'ProfileEnvioEmail'
    

IF ((SELECT COUNT(*) FROM msdb.dbo.sysmail_account WHERE name = @Account_Name) > 0)
    EXEC msdb.dbo.sysmail_delete_account_sp @account_name = @Account_Name


EXEC msdb.dbo.sysmail_add_account_sp
    @account_name = @Account_Name,
    @description = 'Conta de e-mail para ser utilizada por todos os usuários do banco',
    @email_address = 'usuario@seudominio.com.br',
    @replyto_address = 'naoresponder@seudominio.com.br',
    @display_name = 'Sua Empresa',
    @mailserver_name = 'smtp.seudominio.com.br',
    @mailserver_type = 'SMTP',
    @port = '587',
    @username = 'usuario@seudominio.com.br',
    @password = 'senha',
    @enable_ssl = 1,
    @use_default_credentials = 0



-----------------------------------------------------------------------------------------
-- Cria o profile de e-mail
-----------------------------------------------------------------------------------------

IF ((SELECT COUNT(*) FROM msdb.dbo.sysmail_profile WHERE name = @Profile_Name) > 0)
    EXEC msdb.dbo.sysmail_delete_profile_sp @profile_name = @Profile_Name



EXEC msdb.dbo.sysmail_add_profile_sp
    @profile_name = @Profile_Name,
    @description = 'Profile Público para Envio de E-mail' ;


-----------------------------------------------------------------------------------------
-- Adiciona a conta ao perfil criado
-----------------------------------------------------------------------------------------

DECLARE 
    @profile_id INT = (SELECT profile_id FROM msdb.dbo.sysmail_profile WHERE name = @Profile_Name), 
    @account_id INT = (SELECT account_id FROM msdb.dbo.sysmail_account WHERE name = @Account_Name)
    

IF ((SELECT COUNT(*) FROM msdb.dbo.sysmail_profileaccount WHERE account_id = @account_id AND profile_id = @profile_id) > 0)
    EXEC msdb.dbo.sysmail_delete_profileaccount_sp @profile_name = @Profile_Name, @account_name = @Account_Name


EXEC msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = @Profile_Name,
    @account_name = @Account_Name,
    @sequence_number = 1;


-----------------------------------------------------------------------------------------
-- Libera acesso no perfil criado para todos os usuários
-----------------------------------------------------------------------------------------

IF ((SELECT COUNT(*) FROM msdb.dbo.sysmail_principalprofile WHERE profile_id = @profile_id) > 0)
    EXEC msdb.dbo.sysmail_delete_principalprofile_sp @profile_name = @Profile_Name


EXEC msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = @Profile_Name,
    @principal_name = 'public', -- Aqui você pode dar acesso para um usuário específico, se quiser
    @is_default = 1;


-----------------------------------------------------------------------------------------
-- Define o tamanho máximo por anexo para 5 MB (O Padrão é 1 MB por arquivo)
-----------------------------------------------------------------------------------------

EXEC msdb.dbo.sysmail_configure_sp 'MaxFileSize', '5242880'; -- 1024 x 1024 x 5