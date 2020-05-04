SELECT
    FORMAT(123456.99, 'C'), -- Formato de moeda padr�o
    FORMAT(-123456.987654321, 'C4'), -- Formato de moeda com 4 casas decimais
    FORMAT(123456.987654321, 'C2', 'pt-br') -- Formato de moeda for�ando a localidade pra Brasil e 2 casas decimais
,
    FORMAT(123456.99, 'D'), -- Formato de n�mero inteiro com valores numeric (NULL)
    FORMAT(123456, 'D'), -- Formato de n�mero inteiro
    FORMAT(-123456, 'D4'), -- Formato de n�mero inteiro com valores negativos
    FORMAT(123456, 'D10', 'pt-br'), -- formato de n�mero inteiro com tamanho fixo em 10 caracteres
    FORMAT(-123456, 'D10', 'pt-br') -- formato de n�mero inteiro com tamanho fixo em 10 caracteres
,
    FORMAT(123456.99, 'E'), -- Formato de nota��o cient�fica
    FORMAT(123456.99, 'E4') -- Formato de nota��o cient�fica e 4 casas decimais de precis�o
,
    FORMAT(1, 'P'), -- Formato de porcentagem
    FORMAT(1, 'P2'), -- Formato de porcentagem com 2 casas decimais
    FORMAT(0.91, 'P'), -- Formato de porcentagem
    FORMAT(0.005, 'P4') -- Formato de porcentagem com 4 casas decimais
,
    FORMAT(255, 'X'), -- Formato hexadecimal
    FORMAT(512, 'X8') -- Formato hexadecimal fixando o retorno em 8 caracteres


SELECT
    -- Formato de moeda brasileira (manualmente)
    FORMAT(123456789.9, 'R$ ###,###,###,###.00'),
    -- Utilizando sess�o (;) para formatar valores positivos e negativos
    FORMAT(123456789.9, 'R$ ###,###,###,###.00;-R$ ###,###,###,###.00'), 
    
    -- Utilizando sess�o (;) para formatar valores positivos e negativos
    FORMAT(-123456789.9, 'R$ ###,###,###,###.00;-R$ ###,###,###,###.00'), 
    -- Utilizando sess�o (;) para formatar valores positivos e negativos
    FORMAT(-123456789.9, 'R$ ###,###,###,###.00;(R$ ###,###,###,###.00)'),
    
    -- Formatando porcentagem com 2 casas decimais
    FORMAT(0.9975, '#.00%'), 
    -- Formatando porcentagem com 4 casas decimais
    FORMAT(0.997521654, '#.0000%'),
    -- Formatando porcentagem com 4 casas decimais
    FORMAT(123456789.997521654, '#.0000%'),
    
    -- Formatando porcentagem com 2 casas decimais e utilizando sess�o (;)
    FORMAT(0.123456789, '#.00%;-#.00%'),
    -- Formatando porcentagem com 2 casas decimais e utilizando sess�o (;)
    FORMAT(-0.123456789, '#.00%;-#.00%'),
    -- Formatando porcentagem com 2 casas decimais e utilizando sess�o (;)
    FORMAT(-0.123456789, '#.00%;(#.00%)')

--------------------------------------------------------------

SELECT
    -- Formato de data t�pico do Brasil
    FORMAT(GETDATE(), 'dd/MM/yyyy'),

    -- Formato de data/hora t�pico dos EUA
    FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),

    -- Exibindo a data por extenso
    FORMAT(GETDATE(), 'dddd, dd \d\e MMMM \d\e yyyy'),

    -- Exibindo a data por extenso (for�ando o idioma pra PT-BR)
    FORMAT(GETDATE(), 'dddd, dd \d\e MMMM \d\e yyyy', 'pt-br'),

    -- Exibindo a data/hora, mas zerando os minutos e segundos
    FORMAT(GETDATE(), 'dd/MM/yyyy HH:00:00', 'pt-br')

SET LANGUAGE 'English'

SELECT
    FORMAT(GETDATE(), 'd'), -- Padr�o de data abreviada.
    FORMAT(GETDATE(), 'D'), -- Padr�o de data completa.

    FORMAT(GETDATE(), 'R'), -- Padr�o RFC1123

    FORMAT(GETDATE(), 't'), -- Padr�o de hora abreviada.
    FORMAT(GETDATE(), 'T') -- Padr�o de hora completa.
    

SET LANGUAGE 'Brazilian'

SELECT
    FORMAT(GETDATE(), 'd'), -- Padr�o de data abreviada.
    FORMAT(GETDATE(), 'D'), -- Padr�o de data completa.

    FORMAT(GETDATE(), 'R'), -- Padr�o RFC1123

    FORMAT(GETDATE(), 't'), -- Padr�o de hora abreviada.
    FORMAT(GETDATE(), 'T') -- Padr�o de hora completa.