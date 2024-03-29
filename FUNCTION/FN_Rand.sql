

CREATE OR ALTER FUNCTION DBO.FN_RAND(@NUMERO BIGINT)
RETURNS BIGINT
WITH SCHEMABINDING
AS
BEGIN
    RETURN (ABS(CHECKSUM(PWDENCRYPT(N''))) / 2147483647.0) * @NUMERO
END
GO