

-- TAREFAS DO USU�RIO QUE EST�O ESPERANDO PARA SEREM EXECUTADAS
SELECT * 
FROM SYS.DM_OS_WAITING_TASKS WT
JOIN SYS.DM_EXEC_SESSIONS ES ON (WT.SESSION_ID= ES.SESSION_ID)
WHERE ES.is_user_process = 1 


