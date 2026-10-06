-- =====================================================================
-- banco.sql
-- Script de criação do banco de dados do Projeto Integrador
-- (sistema de controle de ferramentas, funcionários e empréstimos).
-- Como usar: abra o MySQL Workbench / phpMyAdmin e execute este arquivo.
-- =====================================================================

-- Cria o banco (se ainda não existir) usando UTF-8 completo (acentos, emojis)
CREATE DATABASE IF NOT EXISTS projeto_ferramentas
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Seleciona o banco para os próximos comandos
USE projeto_ferramentas;

-- ---------------------------------------------------------------------
-- Tabela FERRAMENTAS: é a tabela usada na demonstração do POST e do PUT
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ferramentas (
  id            INT AUTO_INCREMENT PRIMARY KEY,          -- identificador gerado pelo MySQL
  nome          VARCHAR(100) NOT NULL,                   -- ex: "Furadeira de Impacto"
  patrimonio    VARCHAR(30)  NOT NULL UNIQUE,            -- código único da ferramenta
  status        ENUM('disponivel','emprestada','em_manutencao')
                NOT NULL DEFAULT 'disponivel',           -- só aceita esses 3 valores
  localizacao   VARCHAR(100) NULL,                       -- ex: "Almoxarifado A - Prateleira 3"
  criado_em     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- data do cadastro (POST)
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ON UPDATE CURRENT_TIMESTAMP              -- muda sozinho a cada UPDATE (PUT)
);

-- ---------------------------------------------------------------------
-- Tabela FUNCIONARIOS: cadastro de quem pode pegar ferramentas
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS funcionarios (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  nome      VARCHAR(100) NOT NULL,
  matricula VARCHAR(20)  NOT NULL UNIQUE,
  setor     VARCHAR(60)  NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- Tabela EMPRESTIMOS: liga um funcionário a uma ferramenta
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS emprestimos (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  ferramenta_id   INT NOT NULL,
  funcionario_id  INT NOT NULL,
  data_retirada   DATETIME DEFAULT CURRENT_TIMESTAMP,
  data_devolucao  DATETIME NULL,                        -- NULL = ainda não devolvida
  FOREIGN KEY (ferramenta_id)  REFERENCES ferramentas(id),
  FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id)
);

-- ---------------------------------------------------------------------
-- Consulta usada NA DEMONSTRAÇÃO para mostrar o dado no MySQL
-- (rode depois do POST e de novo depois do PUT)
-- ---------------------------------------------------------------------
-- SELECT * FROM ferramentas ORDER BY id DESC;
