require("dotenv").config();

// Simulação de banco de dados em memória para demonstração
const mockDB = {
  users: [
    { id: 1, email: 'demo@example.com', nome: 'Usuário Demo', password: 'demo123' }
  ],
  messages: []
};

// Função simulada para consultas
const mockConnection = {
  query: (sql, params, callback) => {
    console.log('Simulando consulta SQL:', sql);
    
    // Simular consulta de usuário para login
    if (sql.includes('SELECT * FROM usuario WHERE id = ?')) {
      const userId = params[0];
      const user = mockDB.users.find(u => u.id == userId);
      
      if (callback) {
        if (user) {
          callback(null, [user]);
        } else {
          callback(null, []);
        }
      }
    } else {
      // Para outras consultas, retornar um array vazio
      if (callback) {
        callback(null, []);
      }
    }
  }
};

console.log('Usando banco de dados simulado para demonstração');

module.exports = mockConnection;
