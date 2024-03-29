USE tempdb
GO

CREATE TABLE ZDATA (
  [DATA] DATE,
  [DATAINICIO] DATETIME2,
  [DATAFIM] DATETIME2,
  [DATAPRIMEIRODIASEMANA] DATETIME2,
  [DATAULTIMODIASEMANA] DATETIME2,
  [SEMANA] INT,
  [SEMANANOME] VARCHAR(MAX),
  [ANO] INT,
  [MES] INT,
  [MESNOME] VARCHAR(MAX),
  [ANOMES] INT,
  [DIA] INT,
  [DIADOANO] INT 
  PRIMARY KEY ([DATA])
)

DECLARE @DINCR DATE = '2000-01-01'
DECLARE @DEND DATE = '2100-01-01'

WHILE ( @DINCR < @DEND )
BEGIN
  DECLARE @DTTIME DATETIME = @DINCR
  INSERT INTO ZDATA 
     ([DATA], 
      [DATAINICIO],
      [DATAFIM],
      [DATAPRIMEIRODIASEMANA],
      [DATAULTIMODIASEMANA],
      [SEMANA],
	  [SEMANANOME],
	  [ANO],
	  [MES],
	  [MESNOME],
	  [ANOMES],
	  [DIA],
	  [DIADOANO]
	  

      )
  VALUES
     (@DINCR, 
      @DTTIME,
      DATEADD(MS ,-3 ,DATEADD(DD, DATEDIFF(DD, 0, @DTTIME) + 1, 0)),
      DATEADD(WK, DATEDIFF(WK, 0, @DTTIME), 0),
	  DATEADD(MS ,-3 ,DATEADD(WK, DATEDIFF(WK, 0, @DTTIME) + 1, 0)),
      DATEPART(ISO_WEEK, @DTTIME),
      CASE DATEPART(DW, @DTTIME) 
           WHEN 1 THEN 'DOMINGO'
           WHEN 2 THEN 'SEGUNDA'
           WHEN 3 THEN 'TERCA'
           WHEN 4 THEN 'QUARTA'
           WHEN 5 THEN 'QUINTA' 
           WHEN 6 THEN 'SEXTA'
           WHEN 7 THEN 'SABADO'
      END,
	  DATEPART(YEAR, @DTTIME),
	  DATEPART(MONTH, @DTTIME),
	  --DATENAME(MONTH, @DTTIME),
	  CASE DATEPART(MONTH, @DTTIME) 
           WHEN 1 THEN 'JANEIRO'
           WHEN 2 THEN 'FEVEREIRO'
           WHEN 3 THEN 'MAR�O'
           WHEN 4 THEN 'ABRIL'
           WHEN 5 THEN 'MAIO'
           WHEN 6 THEN 'JUNHO'
           WHEN 7 THEN 'JULHO'
           WHEN 8 THEN 'AGOSTO'
           WHEN 9 THEN 'SETEMBRO'
           WHEN 10 THEN 'OUTUBRO'
           WHEN 11 THEN 'NOVEMBRO'
           WHEN 12 THEN 'DEZEMBRO'
      END,
	  DATEPART(YEAR, @DTTIME)*100+DATEPART(MONTH, @DTTIME),
	  DATEPART(DAY, @DTTIME),
	  DATEPART(DAYOFYEAR, @DTTIME)


      )
  SELECT @DINCR = DATEADD(DAY, 1, @DINCR )
END


--DROP TABLE ##DATES


