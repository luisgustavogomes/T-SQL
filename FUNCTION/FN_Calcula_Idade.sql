CREATE OR ALTER FUNCTION [DBO].[FN_CALCULA_IDADE] (@DT_NASCIMENTO DATETIME, @DT_HOJE DATETIME)
RETURNS INT
WITH SCHEMABINDING
AS BEGIN
  RETURN DATEDIFF(YEAR, @DT_NASCIMENTO, @DT_HOJE) + CASE WHEN (MONTH(@DT_NASCIMENTO) > MONTH(@DT_HOJE) OR (MONTH(@DT_NASCIMENTO) = MONTH(@DT_HOJE) AND DAY(@DT_NASCIMENTO) > DAY(@DT_HOJE))) THEN -1 ELSE 0 END
END