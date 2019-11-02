USE Northwind
GO


EXEC MASTER.DBO.XP_CMDSHELL 'bcp "select * from Northwind.sys.tables" queryout "c:\temporario\teste.csv" -c -t; -T -SLUIS'

EXEC MASTER.DBO.XP_CMDSHELL 'bcp Northwind.sys.tables out "c:\temporario\teste2.csv" -c -t; -T -SLUIS'

