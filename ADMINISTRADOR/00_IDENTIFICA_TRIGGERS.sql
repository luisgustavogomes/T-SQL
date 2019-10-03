SELECT sysobjects.name AS trigger_name,
	USER_NAME(sysobjects.uid) AS trigger_owner,
	s.name AS table_schema,
	OBJECT_NAME(parent_obj) AS table_name,
	OBJECTPROPERTY(id, 'ExecIsUpdateTrigger') AS isUpdate,
	OBJECTPROPERTY(id, 'ExecIsDeleteTrigger') AS isDelete,
	OBJECTPROPERTY(id, 'ExecIsInsertTrigger') AS isInsert,
	OBJECTPROPERTY(id, 'ExecIsAfterTrigger') AS isAfter,
	OBJECTPROPERTY(id, 'ExecIsInsteadOfTrigger') AS isInsteadof,
	OBJECTPROPERTY(id, 'ExecIsTriggerDisabled') AS [disabled]
FROM sysobjects
INNER JOIN sys.tables t ON sysobjects.parent_obj = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE sysobjects.type = 'TR'
ORDER BY trigger_name
