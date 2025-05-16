-- Script para configurar o banco de dados de teste

-- Criar banco de dados (se não existir)
CREATE DATABASE IF NOT EXISTS magapp_db;

-- Usar o banco de dados
USE magapp_db;

-- Criar tabela de usuários (se não existir)
CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  senha VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Inserir alguns dados de exemplo (opcional)
-- INSERT INTO usuarios (nome, email, senha) VALUES
-- ('Admin', 'admin@magapp.com', 'adminpass'),
-- ('Usuário Teste', 'usuario@magapp.com', 'userpass');

-- Comando para visualizar a estrutura da tabela
-- DESCRIBE usuarios;

-- Comando para verificar os registros
-- SELECT * FROM usuarios;
