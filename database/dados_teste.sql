-- =====================================================================
-- Dados de teste (SQLite) — rode DEPOIS do schema.sql
-- Serve só para desenvolvimento: não use em produção.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- Usuários
-- ATENÇÃO: os valores de senha_hash abaixo são apenas marcadores.
-- Quando fizer o login (Fase 5), gere hashes de verdade com o werkzeug
-- (generate_password_hash) e atualize estes registros.
INSERT INTO usuarios (nome, email, senha_hash, nivel) VALUES
    ('Administrador', 'admin@exemplo.com',       'TROCAR_POR_HASH_REAL', 'admin'),
    ('Funcionário',   'funcionario@exemplo.com', 'TROCAR_POR_HASH_REAL', 'funcionario');

-- Clientes
INSERT INTO clientes (nome, telefone, email) VALUES
    ('Maria Souza',  '(31) 91234-5678', 'maria@exemplo.com'),
    ('João Pereira', '(31) 98765-4321', 'joao@exemplo.com'),
    ('Ana Lima',     '(31) 99999-0000', NULL);

-- Produtos (o Boné está abaixo do mínimo e o Cinto zerado, para testar o alerta RF05)
INSERT INTO produtos (nome, categoria, preco, estoque, estoque_minimo) VALUES
    ('Camiseta Básica', 'Roupas',     39.90, 20,  5),
    ('Calça Jeans',     'Roupas',    119.90, 12,  5),
    ('Boné',            'Acessórios', 29.90,  3,  5),
    ('Meia Esportiva',  'Acessórios', 14.90, 40, 10),
    ('Tênis Casual',    'Calçados',  199.90,  8,  3),
    ('Cinto de Couro',  'Acessórios', 49.90,  0,  5);

-- Venda 1 (hoje): Maria, atendida pelo funcionário
--   2 x Camiseta (39,90) + 1 x Boné (29,90) = 109,70
INSERT INTO vendas (cliente_id, usuario_id, data_venda, forma_pagamento, total)
    VALUES (1, 2, datetime('now', 'localtime'), 'Pix', 109.70);
INSERT INTO itens_venda (venda_id, produto_id, quantidade, preco_unitario) VALUES
    (1, 1, 2, 39.90),
    (1, 3, 1, 29.90);

-- Venda 2 (ontem): sem cliente cadastrado, feita pelo admin
--   1 x Calça (119,90) + 2 x Meia (14,90) = 149,70
INSERT INTO vendas (cliente_id, usuario_id, data_venda, forma_pagamento, total)
    VALUES (NULL, 1, datetime('now', 'localtime', '-1 day'), 'Cartão', 149.70);
INSERT INTO itens_venda (venda_id, produto_id, quantidade, preco_unitario) VALUES
    (2, 2, 1, 119.90),
    (2, 4, 2, 14.90);

-- Venda 3 (há 10 dias): João, funcionário
--   1 x Tênis (199,90) = 199,90
INSERT INTO vendas (cliente_id, usuario_id, data_venda, forma_pagamento, total)
    VALUES (2, 2, datetime('now', 'localtime', '-10 days'), 'Dinheiro', 199.90);
INSERT INTO itens_venda (venda_id, produto_id, quantidade, preco_unitario) VALUES
    (3, 5, 1, 199.90);
