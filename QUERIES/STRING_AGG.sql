USE MASTER
GO 


SELECT 
	 [is_auto_close_on]
	,STRING_AGG([NAME], ';') EMAIL_LIST
FROM SYS.databases
GROUP BY [is_auto_close_on]

SELECT 
	 [is_auto_close_on]
	,STRING_AGG([NAME], ';') 
	 WITHIN GROUP (ORDER BY NAME) EMAIL_LIST
FROM SYS.databases
GROUP BY [is_auto_close_on]

