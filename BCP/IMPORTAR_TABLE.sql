IF OBJECT_ID ('northwind.dbo.teste') IS NOT NULL
	DROP TABLE northwind.dbo.teste

CREATE TABLE northwind.dbo.teste (DS_LINHA VARCHAR(MAX))

EXEC MASTER.DBO.XP_CMDSHELL 'bcp northwind.dbo.teste in "c:\temporario\CLR_Texto.txt" -T -c'


select * from northwind.dbo.teste