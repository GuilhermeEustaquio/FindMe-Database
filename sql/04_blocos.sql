PROMPT === Bloco 1: SELECT INTO, IF/ELSIF/ELSE e FOR ===
DECLARE
    CURSOR c_em_teste IS SELECT id FROM fm_caso WHERE id IN (5,11,12) ORDER BY id;
    v_status fm_caso.status%TYPE;
    v_prioridade VARCHAR2(30);
    v_processados PLS_INTEGER := 0;
BEGIN
    FOR item IN c_em_teste LOOP
        SELECT status INTO v_status FROM fm_caso WHERE id = item.id;

        IF v_status = 'EM_ANALISE' THEN
            v_prioridade := 'REVISAR_CADASTRO';
        ELSIF v_status = 'VALIDADO' THEN
            v_prioridade := 'PREPARAR_DIVULGACAO';
        ELSE
            v_prioridade := 'FORA_DA_FILA_DE_PUBLICACAO';
        END IF;

        v_processados := v_processados + 1;
        DBMS_OUTPUT.PUT_LINE('Caso ' || item.id || ' | ' || v_status || ' | ' || v_prioridade);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Casos processados: ' || v_processados);
END;
/

PROMPT === Bloco 2: publicacao, localizacao e auditoria ===
DECLARE
    v_ativos NUMBER;
    v_status fm_caso.status%TYPE;
    v_historico NUMBER;
    e_perfil EXCEPTION;
    e_validacao EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_perfil, -20002);
    PRAGMA EXCEPTION_INIT(e_validacao, -20004);
BEGIN
    SAVEPOINT fm_inicio_demo;

    BEGIN
        fm_operar_caso(12, 11, 'PUBLICAR', 'Alerta 12', 'Informacao ficticia.');
        RAISE_APPLICATION_ERROR(-20901, 'Era esperado bloqueio por papel.');
    EXCEPTION WHEN e_perfil THEN
        DBMS_OUTPUT.PUT_LINE('Bloqueio por papel confirmado: ' || SQLERRM);
    END;

    BEGIN
        fm_operar_caso(11, 13, 'PUBLICAR', 'Alerta 11', 'Informacao ficticia.');
        RAISE_APPLICATION_ERROR(-20902, 'Era esperado bloqueio por status.');
    EXCEPTION WHEN e_validacao THEN
        DBMS_OUTPUT.PUT_LINE('Bloqueio por status confirmado: ' || SQLERRM);
    END;

    fm_operar_caso(12, 13, 'PUBLICAR', 'Alerta demonstrativo 12', 'Informacao ficticia.');
    SELECT COUNT(*) INTO v_ativos FROM fm_alerta WHERE caso_id = 12 AND ativo = 1;
    IF v_ativos <> 1 THEN
        RAISE_APPLICATION_ERROR(-20903, 'Esperado exatamente um alerta ativo para o caso 12.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Alertas ativos do caso 12: ' || v_ativos);
    fm_listar_alertas_ativos;

    fm_operar_caso(12, 14, 'LOCALIZAR');
    SELECT COUNT(*) INTO v_ativos FROM fm_alerta WHERE caso_id = 12 AND ativo = 1;
    SELECT status INTO v_status FROM fm_caso WHERE id = 12;
    SELECT COUNT(*) INTO v_historico FROM fm_historico_status WHERE caso_id = 12;
    IF v_status <> 'LOCALIZADO' OR v_ativos <> 0 OR v_historico <> 4 THEN
        RAISE_APPLICATION_ERROR(-20904, 'O estado final ou o historico diverge do esperado.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Apos localizar: status=' || v_status
                       || ', alertas ativos=' || v_ativos || ', eventos=' || v_historico);
    DBMS_OUTPUT.PUT_LINE('Historico do caso 12:');
    FOR evento IN (
        SELECT status_anterior, status_novo, autor_id
          FROM fm_historico_status WHERE caso_id = 12 ORDER BY data_alteracao, id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(NVL(evento.status_anterior,'(criacao)') || ' -> '
                         || evento.status_novo || ' | autor ' || evento.autor_id);
    END LOOP;
    fm_listar_alertas_ativos;
    ROLLBACK TO fm_inicio_demo;
    DBMS_OUTPUT.PUT_LINE('Demonstracao aprovada. Alteracoes desfeitas para repetir os blocos.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO fm_inicio_demo;
        RAISE;
END;
/
