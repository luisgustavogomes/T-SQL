/*

Identificar eventos de deadlock
Utilizando o Extended Events que já vem habilitado por padrão no SQL Server, o System_Health, podemos identificar eventos de Deadlock que ocorreram recentemente na instância. Para entender melhor o uso desse script, recomendo a leitura do artigo https://www.dirceuresende.com/blog/sql-server-como-gerar-um-monitoramento-de-historico-de-deadlocks-para-analise-de-falhas-em-rotinas/

*/

DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())

SELECT
    DATEADD(HOUR, @TimeZone, xed.value('@timestamp', 'datetime2(3)')) AS CreationDate,
    xed.query('.') AS XEvent
FROM
(
    SELECT 
        CAST(st.[target_data] AS XML) AS TargetData
    FROM 
        sys.dm_xe_session_targets AS st
        INNER JOIN sys.dm_xe_sessions AS s ON s.[address] = st.event_session_address
    WHERE 
        s.[name] = N'system_health'
        AND st.target_name = N'ring_buffer'
) AS [Data]
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData (xed)
ORDER BY 
    CreationDate DESC