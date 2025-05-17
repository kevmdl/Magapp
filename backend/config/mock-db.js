const { createPool } = require('mysql2/promise');

// Configuração para o banco de testes
const mockConfig = {
  host: process.env.TEST_DB_HOST || 'localhost',
  user: process.env.TEST_DB_USER || 'test_user',
  password: process.env.TEST_DB_PASSWORD || 'test_password',
  database: process.env.TEST_DB_NAME || 'magapp_test',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

// Criando um pool de conexões para os testes
const pool = createPool(mockConfig);

// Função para inicializar o banco de testes
async function initTestDatabase() {
  try {
    // Criando tabelas de teste
    await pool.query(`
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
    
    // Tabela de pedidos para testes
    await pool.query(`
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
    
    console.log('Banco de dados de teste inicializado com sucesso!');
    return true;
  } catch (error) {
    console.error('Erro ao inicializar banco de teste:', error);
    return false;
  }
}

// Função para limpar o banco de testes
async function clearTestDatabase() {
  try {
    // Remover dados das tabelas
    await pool.query('DELETE FROM pedidos');
    await pool.query('DELETE FROM usuario');
    console.log('Banco de dados de teste limpo com sucesso!');
    return true;
  } catch (error) {
    console.error('Erro ao limpar banco de teste:', error);
    return false;
  }
}

// Função para fechar conexões após os testes
async function closeDatabase() {
  try {
    await pool.end();
    console.log('Conexões de teste encerradas com sucesso!');
    return true;
  } catch (error) {
    console.error('Erro ao fechar conexões de teste:', error);
    return false;
  }
}

// Função para executar query no banco de testes
async function query(sql, params) {
  try {
    const [results] = await pool.query(sql, params);
    return results;
  } catch (error) {
    console.error('Erro na query:', error);
    throw error;
  }
}

module.exports = {
  pool,
  query,
  initTestDatabase,
  clearTestDatabase,
  closeDatabase
};