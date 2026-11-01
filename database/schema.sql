-- =====================================================================
-- Sistema de Gestão para Pequeno Negócio
-- Schema do banco de dados (SQLite)
-- Baseado no modelo lógico: usuarios, clientes, produtos, vendas, itens_venda
-- =====================================================================

-- No SQLite as chaves estrangeiras vêm DESLIGADAS por padrão.
-- Esta linha vale só para a conexão atual: no Flask, rode-a em toda conexão.
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- usuarios: quem acessa o sistema (admin ou funcionário)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nome        VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    senha_hash  VARCHAR(255) NOT NULL,           -- nunca guardar senha em texto puro (RNF01)
    nivel       TEXT NOT NULL CHECK (nivel IN ('admin', 'funcionario')),
    ativo       INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
    criado_em   DATETIME NOT NULL DEFAULT (datetime('now', 'localtime'))
);

-- ---------------------------------------------------------------------
-- clientes
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nome        VARCHAR(100) NOT NULL,
    telefone    VARCHAR(20),
    email       VARCHAR(120),
    ativo       INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
    criado_em   DATETIME NOT NULL DEFAULT (datetime('now', 'localtime'))
);

-- ---------------------------------------------------------------------
-- produtos
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS produtos (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nome            VARCHAR(100) NOT NULL,
    categoria       VARCHAR(50),
    preco           DECIMAL(10,2) NOT NULL CHECK (preco > 0),
    estoque         INTEGER NOT NULL CHECK (estoque >= 0),     -- RN01: nunca fica negativo
    estoque_minimo  INTEGER NOT NULL DEFAULT 5,                -- RF05: alerta de estoque baixo
    ativo           INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1))
);

-- ---------------------------------------------------------------------
-- vendas
-- cliente_id pode ser NULL (venda sem cadastro de cliente)
-- ON DELETE RESTRICT: não deixa apagar cliente/usuário que tenha vendas (RN04)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vendas (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id       INTEGER,
    usuario_id       INTEGER NOT NULL,
    data_venda       DATETIME NOT NULL DEFAULT (datetime('now', 'localtime')),
    forma_pagamento  VARCHAR(30),
    total            DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- itens_venda: resolve a relação N:N entre vendas e produtos
-- preco_unitario guarda o preço da época da venda (RN02)
-- Se a venda for apagada, seus itens vão junto (CASCADE).
-- Produto com vendas não pode ser apagado (RESTRICT, RN04).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS itens_venda (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    venda_id        INTEGER NOT NULL,
    produto_id      INTEGER NOT NULL,
    quantidade      INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario  DECIMAL(10,2) NOT NULL CHECK (preco_unitario > 0),
    FOREIGN KEY (venda_id)   REFERENCES vendas (id)   ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- Índices: deixam as buscas e filtros mais rápidos (RF10, dashboard, relatórios)
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_produtos_nome       ON produtos (nome);
CREATE INDEX IF NOT EXISTS idx_clientes_nome       ON clientes (nome);
CREATE INDEX IF NOT EXISTS idx_vendas_data         ON vendas (data_venda);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente      ON vendas (cliente_id);
CREATE INDEX IF NOT EXISTS idx_vendas_usuario      ON vendas (usuario_id);
CREATE INDEX IF NOT EXISTS idx_itens_venda         ON itens_venda (venda_id);
CREATE INDEX IF NOT EXISTS idx_itens_produto       ON itens_venda (produto_id);
