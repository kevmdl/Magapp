// Modelo para gerenciar mensagens no banco de dados
const db = require('../config/db');

/**
 * Classe para manipulação de mensagens diretas (1 a 1)
 */
class MessageModel {
  /**
   * Salva uma nova mensagem direta no banco de dados
   * @param {Object} messageData - Dados da mensagem
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async saveDirectMessage(messageData) {
    const { senderId, receiverId, content, type = 'text' } = messageData;

    return new Promise((resolve, reject) => {
      db.query(
        'INSERT INTO mensagens (sender_id, receiver_id, content, type) VALUES (?, ?, ?, ?)',
        [senderId, receiverId, content, type],
        (err, result) => {
          if (err) {
            console.error('Erro ao salvar mensagem:', err);
            return reject(err);
          }
          
          // Busca a mensagem com timestamp
          db.query(
            'SELECT * FROM mensagens WHERE id = ?',
            [result.insertId],
            (err, results) => {
              if (err) {
                console.error('Erro ao buscar mensagem salva:', err);
                return reject(err);
              }
              
              resolve(results[0]);
            }
          );
        }
      );
    });
  }

  /**
   * Obtém mensagens entre dois usuários
   * @param {number} user1Id - ID do primeiro usuário
   * @param {number} user2Id - ID do segundo usuário
   * @param {number} limit - Limite de mensagens a retornar
   * @param {number} offset - Deslocamento para paginação
   * @returns {Promise} - Promise com as mensagens encontradas
   */
  static async getMessagesBetweenUsers(user1Id, user2Id, limit = 50, offset = 0) {
    return new Promise((resolve, reject) => {
      db.query(
        `SELECT * FROM mensagens 
         WHERE (sender_id = ? AND receiver_id = ?)
         OR (sender_id = ? AND receiver_id = ?)
         ORDER BY created_at DESC
         LIMIT ? OFFSET ?`,
        [user1Id, user2Id, user2Id, user1Id, limit, offset],
        (err, results) => {
          if (err) {
            console.error('Erro ao buscar mensagens:', err);
            return reject(err);
          }
          resolve(results);
        }
      );
    });
  }

  /**
   * Marca uma mensagem como lida
   * @param {number} messageId - ID da mensagem
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async markMessageAsRead(messageId) {
    return new Promise((resolve, reject) => {
      db.query(
        'UPDATE mensagens SET is_read = TRUE WHERE id = ?',
        [messageId],
        (err, result) => {
          if (err) {
            console.error('Erro ao marcar mensagem como lida:', err);
            return reject(err);
          }
          resolve(result);
        }
      );
    });
  }

  /**
   * Marca várias mensagens como lidas
   * @param {number} senderId - ID do remetente
   * @param {number} receiverId - ID do destinatário
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async markAllMessagesAsRead(senderId, receiverId) {
    return new Promise((resolve, reject) => {
      db.query(
        'UPDATE mensagens SET is_read = TRUE WHERE sender_id = ? AND receiver_id = ? AND is_read = FALSE',
        [senderId, receiverId],
        (err, result) => {
          if (err) {
            console.error('Erro ao marcar mensagens como lidas:', err);
            return reject(err);
          }
          resolve(result);
        }
      );
    });
  }

  /**
   * Obtém todas as conversas de um usuário
   * @param {number} userId - ID do usuário
   * @returns {Promise} - Promise com as conversas encontradas
   */
  static async getUserConversations(userId) {
    return new Promise((resolve, reject) => {
      db.query(
        `SELECT 
          m.*, u.nome as receiver_name, u.avatar as receiver_avatar, 
          (SELECT COUNT(*) FROM mensagens WHERE is_read = FALSE AND sender_id = u.id AND receiver_id = ?) as unread_count
        FROM 
          mensagens m
        JOIN 
          usuario u ON (
            CASE 
              WHEN m.sender_id = ? THEN m.receiver_id = u.id
              ELSE m.sender_id = u.id
            END
          )
        WHERE 
          m.id IN (
            SELECT MAX(id)
            FROM mensagens
            WHERE sender_id = ? OR receiver_id = ?
            GROUP BY 
              CASE 
                WHEN sender_id = ? THEN receiver_id
                ELSE sender_id
              END
          )
        ORDER BY 
          m.created_at DESC`,
        [userId, userId, userId, userId, userId],
        (err, results) => {
          if (err) {
            console.error('Erro ao buscar conversas:', err);
            return reject(err);
          }
          resolve(results);
        }
      );
    });
  }
}

module.exports = MessageModel;