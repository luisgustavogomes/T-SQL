USE MASTER
GO
select @@SERVERNAME


EXEC MASTER.DBO.XP_CMDSHELL 'bcp "select * from master.sys.tables" queryout "c:\temporario\teste2.csv" -c -t; -T -SLUIS'

EXEC MASTER.DBO.XP_CMDSHELL 'bcp Northwind.sys.tables out "c:\temporario\teste3.csv" -c -t; -T -SLUIS'

