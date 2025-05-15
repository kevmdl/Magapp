-- Arquivo SQL para criar as tabelas necessárias no MySQL Workbench

-- Comando para criar o banco de dados (execute isso primeiro)
-- CREATE DATABASE IF NOT EXISTS meu_app;
-- USE meu_app;

-- Tabela de usuários (caso não exista)
CREATE TABLE IF NOT EXISTS usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(255),
    avatar VARCHAR(255),
    is_online BOOLEAN DEFAULT FALSE,
    last_active TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de mensagens diretas (1 a 1)
CREATE TABLE IF NOT EXISTS mensagens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'text',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES usuario(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES usuario(id) ON DELETE CASCADE,
    INDEX (sender_id, receiver_id),
    INDEX (created_at)
);

-- Tabela de canais (chats em grupo)
CREATE TABLE IF NOT EXISTS canais (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    imagem VARCHAR(255),
    criador_id INT NOT NULL,
    is_private BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (criador_id) REFERENCES usuario(id) ON DELETE CASCADE
);

-- Tabela de membros dos canais
CREATE TABLE IF NOT EXISTS membros_canal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    canal_id INT NOT NULL,
    usuario_id INT NOT NULL,
    role ENUM('admin', 'moderador', 'membro') DEFAULT 'membro',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (canal_id) REFERENCES canais(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    UNIQUE INDEX unico_membro (canal_id, usuario_id)
);

-- Tabela de mensagens em canais
CREATE TABLE IF NOT EXISTS mensagens_canal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    canal_id INT NOT NULL,
    usuario_id INT NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'text',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (canal_id) REFERENCES canais(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    INDEX (canal_id, created_at)
);

-- Tabela para gerenciar status de leitura de mensagens em canal
CREATE TABLE IF NOT EXISTS leitura_mensagens_canal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mensagem_id INT NOT NULL,
    usuario_id INT NOT NULL,
    read_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mensagem_id) REFERENCES mensagens_canal(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    UNIQUE INDEX unico_leitura (mensagem_id, usuario_id)
);