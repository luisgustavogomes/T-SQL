EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'ProfileEnvioEmail',
    @recipients = 'destinatario@seudominio.com.br',
    @subject = 'Assunto do E-mail',
    @body = 'Ol�! <strong>Teste</strong>',
    @body_format = 'html',
    @from_address = 'remetente@seudominio.com.br',
    @query = 'SELECT TOP 10 * FROM sys.sysobjects'