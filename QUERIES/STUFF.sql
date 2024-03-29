SELECT O.NAME, 
       STUFF((SELECT (', ' + OD.NAME)
              FROM SYS.COLUMNS OD
              WHERE OD.OBJECT_ID = O.OBJECT_ID
              ORDER BY OD.COLUMN_ID
              FOR XML PATH('')), 1, 2, '') COLS
FROM SYS.OBJECTS O
WHERE O.TYPE = 'U'
ORDER BY O.NAME
