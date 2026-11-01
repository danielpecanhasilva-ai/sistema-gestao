-- =====================================================================
-- Sistema de Gestão para Pequeno Negócio
-- Schema do banco de dados (MySQL 8.0.16 ou superior)
-- Mesmo modelo do schema.sql (SQLite), com a sintaxe do MySQL
-- =====================================================================

CREATE DATABASE IF NOT EXISTS sistema_gestao
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sistema_gestao;

-- ---------------------------------------------------------------------
-- usuarios
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    senha_hash  VARCHAR(255) NOT NULL,
    nivel       ENUM('admin', 'funcionario') NOT NULL,
    ativo       BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- clientes
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    telefone    VARCHAR(20),
    email       VARCHAR(120),
    ativo       BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- produtos
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS produtos (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    categoria       VARCHAR(50),
    preco           DECIMAL(10,2) NOT NULL,
    estoque         INT NOT NULL,
    estoque_minimo  INT NOT NULL DEFAULT 5,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_produtos_preco   CHECK (preco > 0),
    CONSTRAINT chk_produtos_estoque CHECK (estoque >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- vendas (cliente_id pode ser NULL: venda sem cadastro)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vendas (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id       INT NULL,
    usuario_id       INT NOT NULL,
    data_venda       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    forma_pagamento  VARCHAR(30),
    total            DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_vendas_total CHECK (total >= 0),
    CONSTRAINT fk_vendas_cliente FOREIGN KEY (cliente_id)
        REFERENCES clientes (id) ON DELETE RESTRICT,
    CONSTRAINT fk_vendas_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- itens_venda (tabela associativa entre vendas e produtos)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS itens_venda (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    venda_id        INT NOT NULL,
    produto_id      INT NOT NULL,
    quantidade      INT NOT NULL,
    preco_unitario  DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_itens_quantidade CHECK (quantidade > 0),
    CONSTRAINT chk_itens_preco      CHECK (preco_unitario > 0),
    CONSTRAINT fk_itens_venda   FOREIGN KEY (venda_id)
        REFERENCES vendas (id) ON DELETE CASCADE,
    CONSTRAINT fk_itens_produto FOREIGN KEY (produto_id)
        REFERENCES produtos (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Índices (as chaves estrangeiras já criam índice automaticamente no MySQL)
-- ---------------------------------------------------------------------
CREATE INDEX idx_produtos_nome ON produtos (nome);
CREATE INDEX idx_clientes_nome ON clientes (nome);
CREATE INDEX idx_vendas_data   ON vendas (data_venda);
