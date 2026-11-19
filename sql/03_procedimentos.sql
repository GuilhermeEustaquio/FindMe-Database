CREATE OR REPLACE PROCEDURE fm_operar_caso (
    p_caso_id IN fm_caso.id%TYPE,
    p_autor_id IN fm_usuario.id%TYPE,
    p_acao IN VARCHAR2,
    p_titulo IN fm_alerta.titulo%TYPE DEFAULT NULL,
    p_descricao_publica IN fm_alerta.descricao_publica%TYPE DEFAULT NULL
)
AS
    v_tipo fm_usuario.tipo_usuario%TYPE;
    v_status fm_caso.status%TYPE;
    v_novo_status fm_caso.status%TYPE;
    v_agora TIMESTAMP;
BEGIN
    SAVEPOINT fm_antes_operacao;

    BEGIN
        SELECT tipo_usuario INTO v_tipo FROM fm_usuario WHERE id = p_autor_id FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Autor inexistente.');
    END;
    IF v_tipo <> 'MODERADOR' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Somente um moderador pode realizar esta operacao.');
    END IF;

    BEGIN
        SELECT status INTO v_status FROM fm_caso WHERE id = p_caso_id FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Caso inexistente.');
    END;

    v_agora := LOCALTIMESTAMP;
    IF p_acao = 'PUBLICAR' THEN
        IF v_status <> 'VALIDADO' THEN
            RAISE_APPLICATION_ERROR(-20004, 'A publicacao exige um caso VALIDADO.');
        END IF;
        IF TRIM(p_titulo) IS NULL OR TRIM(p_descricao_publica) IS NULL
            OR LENGTH(TRIM(p_titulo)) > 150 OR LENGTH(TRIM(p_descricao_publica)) > 1000 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Informe titulo e descricao publica dentro dos limites.');
        END IF;

        UPDATE fm_alerta
           SET titulo = TRIM(p_titulo),
               descricao_publica = TRIM(p_descricao_publica),
               data_publicacao = v_agora,
               ativo = 1
         WHERE caso_id = p_caso_id;
        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO fm_alerta (caso_id, titulo, descricao_publica, data_publicacao, ativo)
            VALUES (p_caso_id, TRIM(p_titulo), TRIM(p_descricao_publica), v_agora, 1);
        END IF;
        v_novo_status := 'PUBLICADO';
    ELSIF p_acao = 'LOCALIZAR' THEN
        IF v_status NOT IN ('PUBLICADO','EM_ACOMPANHAMENTO') THEN
            RAISE_APPLICATION_ERROR(-20006, 'A localizacao exige um caso publicado ou em acompanhamento.');
        END IF;
        UPDATE fm_alerta SET ativo = 0 WHERE caso_id = p_caso_id AND ativo = 1;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'O caso precisa de um alerta ativo.');
        END IF;
        v_novo_status := 'LOCALIZADO';
    ELSE
        RAISE_APPLICATION_ERROR(-20008, 'Acao invalida. Use PUBLICAR ou LOCALIZAR.');
    END IF;

    UPDATE fm_caso SET status = v_novo_status WHERE id = p_caso_id;

    INSERT INTO fm_historico_status (caso_id, autor_id, status_anterior, status_novo, data_alteracao)
    VALUES (p_caso_id, p_autor_id, v_status, v_novo_status, v_agora);

    DBMS_OUTPUT.PUT_LINE('Caso ' || p_caso_id || ': ' || v_status || ' -> '
                         || v_novo_status || ' (moderador ' || p_autor_id || ')');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO fm_antes_operacao;
        RAISE;
END fm_operar_caso;
/

CREATE OR REPLACE PROCEDURE fm_listar_alertas_ativos
AS
    CURSOR c_alertas IS
        SELECT a.id AS alerta_id, a.titulo, a.data_publicacao, c.status
          FROM fm_alerta a JOIN fm_caso c ON c.id = a.caso_id
         WHERE a.ativo = 1 AND c.status IN ('PUBLICADO', 'EM_ACOMPANHAMENTO')
         ORDER BY a.data_publicacao DESC, a.id;
    v_alerta c_alertas%ROWTYPE;
    v_total PLS_INTEGER := 0;
BEGIN
    OPEN c_alertas;
    LOOP
        FETCH c_alertas INTO v_alerta;
        EXIT WHEN c_alertas%NOTFOUND;
        v_total := v_total + 1;
        DBMS_OUTPUT.PUT_LINE('Alerta ' || v_alerta.alerta_id || ' | ' || v_alerta.status
            || ' | ' || TO_CHAR(v_alerta.data_publicacao, 'YYYY-MM-DD HH24:MI')
            || ' | ' || v_alerta.titulo);
    END LOOP;
    CLOSE c_alertas;

    DBMS_OUTPUT.PUT_LINE('Alertas ativos listados: ' || v_total);
END fm_listar_alertas_ativos;
/
