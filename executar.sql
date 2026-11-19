-- Execute via SQLcl/SQL*Plus ou como script (F5) no SQL Developer.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON SIZE UNLIMITED
SET VERIFY OFF
SET SQLBLANKLINES ON
SET FEEDBACK ON
SET LINESIZE 140
SPOOL findme_database_execucao.log REPLACE

PROMPT === Find Me | Instalacao e demonstracao Oracle ===
@@sql/01_modelo.sql
@@sql/02_carga.sql
@@sql/03_procedimentos.sql

DECLARE
    v_erros PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_erros
      FROM user_errors
     WHERE type = 'PROCEDURE' AND attribute = 'ERROR'
       AND name IN ('FM_OPERAR_CASO', 'FM_LISTAR_ALERTAS_ATIVOS');
    IF v_erros > 0 THEN
        FOR item IN (SELECT name, line, text FROM user_errors
                      WHERE type = 'PROCEDURE' AND attribute = 'ERROR'
                        AND name IN ('FM_OPERAR_CASO', 'FM_LISTAR_ALERTAS_ATIVOS')
                      ORDER BY name, sequence) LOOP
            DBMS_OUTPUT.PUT_LINE(item.name || ', linha ' || item.line || ': ' || item.text);
        END LOOP;
        RAISE_APPLICATION_ERROR(-20900, 'Falha na compilacao de procedimento.');
    END IF;
END;
/

PROMPT === Quantidade de registros ===
COLUMN tabela FORMAT A25
SELECT 'FM_USUARIO' AS tabela, COUNT(*) AS linhas FROM fm_usuario
UNION ALL SELECT 'FM_CASO', COUNT(*) FROM fm_caso
UNION ALL SELECT 'FM_ALERTA', COUNT(*) FROM fm_alerta
UNION ALL SELECT 'FM_HISTORICO_STATUS', COUNT(*) FROM fm_historico_status;

@@sql/04_blocos.sql
SPOOL OFF
