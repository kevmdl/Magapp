/**
 * Script para configurar o banco de dados de testes.
 * Este script cria o banco de dados de teste e o usuário para testes.
 */

const mysql = require('mysql2/promise');
const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

// Carregar configurações de teste
dotenv.config({ path: path.join(__dirname, '../.env.test') });

async function setupTestDatabase() {
  console.log('Iniciando configuração do banco de dados de testes...');
  
  // Conexão com o servidor MySQL (sem especificar banco de dados)
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: 'root', // Precisa ser um usuário com privilégios para criar bancos/usuários
    password: process.env.ROOT_PASSWORD || 'unifeob@123',
  });

  try {
    const testDbName = process.env.DB_NAME || 'magapp_test';
    const testUser = process.env.DB_USER || 'test_user';
    const testPassword = process.env.DB_PASSWORD || 'test_password';

    // Criar banco de dados de teste se não existir
    console.log(`Criando banco de dados ${testDbName}...`);
    await connection.query(`CREATE DATABASE IF NOT EXISTS ${testDbName}`);

    // Criar usuário de teste se não existir
    console.log(`Criando usuário ${testUser}...`);
    try {
      await connection.query(`CREATE USER IF NOT EXISTS '${testUser}'@'localhost' IDENTIFIED BY '${testPassword}'`);
    } catch (error) {
      // Usuário já pode existir em versões mais antigas do MySQL
      console.log('Nota: Usuário já pode existir, tentando definir senha...');
      await connection.query(`SET PASSWORD FOR '${testUser}'@'localhost' = PASSWORD('${testPassword}')`);
    }

    // Conceder privilégios ao usuário de teste
    console.log('Concedendo privilégios ao usuário de testes...');
    await connection.query(`GRANT ALL PRIVILEGES ON ${testDbName}.* TO '${testUser}'@'localhost'`);
    await connection.query('FLUSH PRIVILEGES');

    console.log('Criando estrutura das tabelas...');
    // Mudar para o banco de dados de teste
    await connection.query(`USE ${testDbName}`);

    // Criar tabelas necessárias para os testes
    await connection.query(`
      CREATE TABLE IF NOT EXISTS usuario (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nome VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        senha VARCHAR(255),
        avatar VARCHAR(255),
        is_online BOOLEAN DEFAULT FALSE,
        last_active TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    await connection.query(`
      CREATE TABLE IF NOT EXISTS pedidos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nome VARCHAR(100) NOT NULL,
        cpf_cnpj VARCHAR(20) NOT NULL,
        placa VARCHAR(10),
        renavam VARCHAR(20),
        chassi VARCHAR(30),
        status VARCHAR(20) DEFAULT 'pendente',
        criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    console.log('Configuração do banco de dados de testes concluída com sucesso!');
  } catch (error) {
    console.error('Erro ao configurar banco de dados de testes:', error);
    process.exit(1);
  } finally {
    await connection.end();
  }
}

// Executar a configuração
setupTestDatabase();
