-- Toda a massa é fictícia, com datas fixas para repetir a demonstração.
INSERT INTO fm_usuario (id, nome, email, tipo_usuario, data_cadastro)
SELECT LEVEL,
       CASE WHEN LEVEL <= 10 THEN 'Responsavel ' || LEVEL
            WHEN LEVEL <= 12 THEN 'Colaborador ' || LEVEL
            ELSE 'Moderador ' || LEVEL END,
       'teste' || LEVEL || '@findme.example',
       CASE WHEN LEVEL <= 10 THEN 'RESPONSAVEL'
            WHEN LEVEL <= 12 THEN 'COLABORADOR' ELSE 'MODERADOR' END,
       TIMESTAMP '2026-11-01 08:00:00'
FROM dual CONNECT BY LEVEL <= 14;

INSERT INTO fm_caso (id, responsavel_id, nome_desaparecido, idade, descricao,
                     ultima_localizacao_conhecida, data_desaparecimento, status)
SELECT LEVEL, MOD(LEVEL - 1, 10) + 1,
       'Pessoa ficticia ' || LPAD(LEVEL,2,'0'), 5 + MOD(LEVEL,13),
       'Registro privado para exercicio ' || LEVEL, 'Regiao ficticia ' || LEVEL,
       DATE '2026-11-18' - MOD(LEVEL,7),
       CASE
           WHEN LEVEL IN (1,2,3,4,5,6) THEN 'PUBLICADO'
           WHEN LEVEL IN (7,8) THEN 'EM_ACOMPANHAMENTO'
           WHEN LEVEL = 9 THEN 'LOCALIZADO'
           WHEN LEVEL = 10 THEN 'ENCERRADO'
           WHEN LEVEL = 11 THEN 'EM_ANALISE'
           ELSE 'VALIDADO'
       END
FROM dual CONNECT BY LEVEL <= 12;

INSERT INTO fm_alerta (id, caso_id, titulo, descricao_publica, data_publicacao, ativo)
SELECT id, id, 'Alerta demonstrativo ' || id,
       'Registro ficticio de divulgacao. Use o canal oficial em casos reais.',
       CAST(data_desaparecimento + 12/24 AS TIMESTAMP),
       CASE WHEN status IN ('PUBLICADO','EM_ACOMPANHAMENTO') THEN 1 ELSE 0 END
FROM fm_caso WHERE id <= 10;

INSERT INTO fm_historico_status (id, caso_id, autor_id, status_anterior, status_novo, data_alteracao)
SELECT id * 10 + 1, id, responsavel_id, NULL, 'EM_ANALISE',
       CAST(data_desaparecimento + 10/24 AS TIMESTAMP)
FROM fm_caso;

INSERT INTO fm_historico_status (id, caso_id, autor_id, status_anterior, status_novo, data_alteracao)
SELECT id * 10 + 2, id, 13, 'EM_ANALISE', 'VALIDADO',
       CAST(data_desaparecimento + 11/24 AS TIMESTAMP)
FROM fm_caso WHERE id <> 11;

INSERT INTO fm_historico_status (id, caso_id, autor_id, status_anterior, status_novo, data_alteracao)
SELECT c.id * 10 + 3, c.id, 13, 'VALIDADO', 'PUBLICADO', a.data_publicacao
FROM fm_caso c JOIN fm_alerta a ON a.caso_id = c.id;

INSERT INTO fm_historico_status (id, caso_id, autor_id, status_anterior, status_novo, data_alteracao)
SELECT id * 10 + 4, id, 14, 'PUBLICADO', status,
       CAST(data_desaparecimento + 14/24 AS TIMESTAMP)
FROM fm_caso WHERE id BETWEEN 7 AND 10;

COMMIT;
