IF OBJECT_ID ('master.dbo.teste') IS NOT NULL
	DROP TABLE master.dbo.teste

CREATE TABLE master.dbo.teste (DS_LINHA VARCHAR(MAX))

EXEC MASTER.DBO.XP_CMDSHELL 'bcp master.dbo.teste in "c:\temporario\Teste.csv" -T -c'


select * from master.dbo.teste