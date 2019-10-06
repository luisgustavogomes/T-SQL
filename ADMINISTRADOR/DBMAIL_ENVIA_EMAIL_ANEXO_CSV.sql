EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'ProfileEnvioEmail',
    @recipients = 'destinatario@seudominio.com.br',
    @subject = 'Assunto do E-mail',
    @body = 'Olá! <strong>Teste</strong>',
    @body_format = 'html',
    @from_address = 'remetente@seudominio.com.br',
    @query = 'SET NOCOUNT ON; SELECT TOP 10 * FROM sys.sysobjects',
    @query_attachment_filename = 'anexo.csv',
    @attach_query_result_as_file = 1,
    @query_result_header = 1,
    @query_result_width = 256,
    @query_result_separator = ';',
    @query_result_no_padding = 1