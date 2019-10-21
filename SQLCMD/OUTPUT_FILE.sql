sqlcmd 
	-S hostname 
	-d teste 
	-U sa 
	-P sa
	-i "c:\sql\myquery.sql" 
	-o "c:\sql\myoutput.csv" -s";"
