USE CORPORERM
GO 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

DECLARE @PCODCOLIGADA INT = 1;
DECLARE @PSTATUS VARCHAR(100) = '10' 
DECLARE @PANOCOMP INT = 2025 
DECLARE @PMESCOMP INT = 1

;WITH XMLNAMESPACES (
	DEFAULT 'http://www.esocial.gov.br/schema/evt/evtRemun/v_S_01_03_00'		
)
,TAB_FILTRO_STATUS 
AS
(
	SELECT REPLACE([value], ' ', '') AS 'STATUS'
	FROM STRING_SPLIT (@PSTATUS,',')
)
, TAB_DADOS_XML 
AS
(
	SELECT 
		 PE.CODCOLIGADA
		,PE.ID		
		,PE.ANOCOMP
		,PE.MESCOMP
		,PE.[STATUS]
		,CONVERT(VARCHAR(MAX), PE.MENSAGEM) COLLATE Latin1_General_100_CI_AI_SC_UTF8  AS 'XMLDATA' 
	FROM DBO.PESOCIALEVENTOS PE
	JOIN TAB_FILTRO_STATUS SS ON (PE.[STATUS] = SS.[STATUS])
	WHERE PE.CODCOLIGADA = IIF(@PCODCOLIGADA = 0, PE.CODCOLIGADA, @PCODCOLIGADA )
	AND PE.TIPOEVENTO = 'S-1200' 
	AND PE.ANOCOMP = @PANOCOMP 
	AND PE.MESCOMP = @PMESCOMP	
)
, TAB_DADOS_XMLDATA
AS
(
	SELECT 
		 CODCOLIGADA
		,ID
		,[STATUS]
		,ANOCOMP
		,MESCOMP
		,CONVERT(XML,XMLDATA,2) AS 'XMLDATA'
	FROM TAB_DADOS_XML
)
SELECT
	 T.CODCOLIGADA
	,T.ID
	,T.[STATUS]
	,T.ANOCOMP
	,T.MESCOMP
	,dmDev.rows.value('(ideDmDev)[1]','varchar(max)') as 'ideDmDev'
	,dmDev.rows.value('(codCateg)[1]','varchar(max)') as 'codCateg'
	,ideEstabLot.rows.value('(tpInsc)[1]','varchar(max)') as 'tpInsc'
	,ideEstabLot.rows.value('(nrInsc)[1]','varchar(max)') as 'nrInsc'
	,ideEstabLot.rows.value('(codLotacao)[1]','varchar(max)') as 'codLotacao'	
	,remunPerApur.rows.value('(matricula)[1]','varchar(max)') as 'matricula'
	,ideTrabalhador.rows.value('(cpfTrab)[1]','varchar(max)') as 'cpfTrab'
	,itensRemun.rows.value('(codRubr)[1]','varchar(max)') as 'codRubr'
	,itensRemun.rows.value('(ideTabRubr)[1]','int') as 'ideTabRubr'
	,itensRemun.rows.value('(qtdRubr)[1]','decimal(15,4)') as 'qtdRubr'
	,itensRemun.rows.value('(vrRubr)[1]','decimal(15,4)') as 'vrRubr'
	,infoAgNocivo.rows.value('(grauExp)[1]','int') as 'grauExp'
FROM TAB_DADOS_XMLDATA T 
CROSS APPLY T.[XMLDATA].nodes(N'eSocial/evtRemun') AS evtRemun(rows)
CROSS APPLY evtRemun.rows.nodes(N'ideEvento') as ideEvento(rows)
CROSS APPLY evtRemun.rows.nodes(N'dmDev') as dmDev(rows)
CROSS APPLY evtRemun.rows.nodes(N'ideTrabalhador') as ideTrabalhador(rows)
CROSS APPLY dmDev.rows.nodes(N'infoPerApur/ideEstabLot') as ideEstabLot(rows)
CROSS APPLY ideEstabLot.rows.nodes(N'remunPerApur') as remunPerApur(rows)
CROSS APPLY remunPerApur.rows.nodes(N'itensRemun') as itensRemun(rows)
CROSS APPLY remunPerApur.rows.nodes(N'infoAgNocivo') as infoAgNocivo(rows)


