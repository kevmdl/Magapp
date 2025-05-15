// Modelo para gerenciar usuários
const db = require('../config/db');

class UserModel {
  /**
   * Obtém um usuário pelo ID
   * @param {number} userId - ID do usuário
   * @returns {Promise} - Promise com o usuário encontrado
   */
  static async getUserById(userId) {
    return new Promise((resolve, reject) => {
      db.query(
        'SELECT id, nome, email, avatar, is_online, last_active FROM usuario WHERE id = ?',
        [userId],
        (err, results) => {
          if (err) {
            console.error('Erro ao buscar usuário:', err);
            return reject(err);
          }
          
          if (results.length === 0) {
            return resolve(null);
          }
          
          resolve(results[0]);
        }
      );
    });
  }

  /**
   * Busca usuários pelo nome ou email
   * @param {string} searchTerm - Termo de busca
   * @param {number} limit - Limite de resultados
   * @returns {Promise} - Promise com os usuários encontrados
   */
  static async searchUsers(searchTerm, limit = 20) {
    return new Promise((resolve, reject) => {
      db.query(
        `SELECT id, nome, email, avatar, is_online 
         FROM usuario 
         WHERE nome LIKE ? OR email LIKE ?
         LIMIT ?`,
        [`%${searchTerm}%`, `%${searchTerm}%`, limit],
        (err, results) => {
          if (err) {
            console.error('Erro ao buscar usuários:', err);
            return reject(err);
          }
          resolve(results);
        }
      );
    });
  }

  /**
   * Atualiza o status online de um usuário
   * @param {number} userId - ID do usuário
   * @param {boolean} isOnline - Status online
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async updateOnlineStatus(userId, isOnline) {
    return new Promise((resolve, reject) => {
      db.query(
        'UPDATE usuario SET is_online = ?, last_active = NOW() WHERE id = ?',
        [isOnline ? 1 : 0, userId],
        (err, result) => {
          if (err) {
            console.error('Erro ao atualizar status online:', err);
            return reject(err);
          }
          resolve(result);
        }
      );
    });
  }

  /**
   * Registra um novo usuário
   * @param {Object} userData - Dados do usuário
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async registerUser(userData) {
    const { nome, email, senha, avatar } = userData;

    return new Promise((resolve, reject) => {
      // Verifica se o email já existe
      db.query(
        'SELECT id FROM usuario WHERE email = ?',
        [email],
        (err, results) => {
          if (err) {
            console.error('Erro ao verificar email:', err);
            return reject(err);
          }
          
          if (results.length > 0) {
            return reject(new Error('Email já está em uso'));
          }
          
          // Insere o novo usuário
          db.query(
            'INSERT INTO usuario (nome, email, senha, avatar) VALUES (?, ?, ?, ?)',
            [nome, email, senha, avatar || null],
            (err, result) => {
              if (err) {
                console.error('Erro ao registrar usuário:', err);
                return reject(err);
              }
              
              // Retorna o usuário registrado
              this.getUserById(result.insertId)
                .then(resolve)
                .catch(reject);
            }
          );
        }
      );
    });
  }

  /**
   * Autentica um usuário pelo email e senha
   * @param {string} email - Email do usuário
   * @param {string} senha - Senha do usuário
   * @returns {Promise} - Promise com o usuário autenticado
   */
  static async authenticateUser(email, senha) {
    return new Promise((resolve, reject) => {
      db.query(
        'SELECT id, nome, email, avatar FROM usuario WHERE email = ? AND senha = ?',
        [email, senha],
        (err, results) => {
          if (err) {
            console.error('Erro ao autenticar usuário:', err);
            return reject(err);
          }
          
          if (results.length === 0) {
            return resolve(null);
          }
          
          resolve(results[0]);
        }
      );
    });
  }
}

module.exports = UserModel;