DECLARE @getdate DATETIME;
declare @d varchar(max) = '201902'

SET @getdate = SUBSTRING(@d,5,2)+'-'+SUBSTRING(@d,1,4)+'-01'
select @getdate

SELECT CAST('1  ) Data Processada'         AS VARCHAR(50)), @getdate
UNION
SELECT CAST('2  ) Primeiro dia do m�s'     AS VARCHAR(50)), DATEADD(mm, DATEDIFF(mm, 0, @getdate), 0)
UNION
SELECT CAST('2.1) Primeiro dia do m�s ANTERIOR'     AS VARCHAR(50)), DATEADD(MM, -1, DATEADD(mm, DATEDIFF(mm, 0, @getdate), 0))
UNION
SELECT CAST('3  ) Primeiro dia da semana'  AS VARCHAR(50)), DATEADD(wk, DATEDIFF(wk, 0, @getdate), 0)
UNION
SELECT CAST('4  ) Inicio do dia'           AS VARCHAR(50)), DATEADD(dd, DATEDIFF(dd, 0, @getdate), 0) 
UNION
SELECT CAST('5  ) Fim do dia'              AS VARCHAR(50)), DATEADD(ms ,-3 ,DATEADD(dd, DATEDIFF(dd, 0, @getdate) + 1, 0))
UNION
SELECT CAST('6  ) �ltimo dia da semana'    AS VARCHAR(50)), DATEADD(ms ,-3 ,DATEADD(wk, DATEDIFF(wk, 0, @getdate) + 1, 0))
UNION
SELECT CAST('7  ) �ltimo dia do m�s'       AS VARCHAR(50)), DATEADD(ms ,-3 ,DATEADD(mm, DATEDIFF(mm, 0, @getdate) + 1, 0))


