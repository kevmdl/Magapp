// Modelo para gerenciar canais (chats em grupo)
const db = require('../config/db');

class ChannelModel {
  /**
   * Cria um novo canal
   * @param {Object} channelData - Dados do canal
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async createChannel(channelData) {
    const { nome, descricao, imagem, criadorId, isPrivate } = channelData;

    return new Promise((resolve, reject) => {
      db.query(
        'INSERT INTO canais (nome, descricao, imagem, criador_id, is_private) VALUES (?, ?, ?, ?, ?)',
        [nome, descricao || null, imagem || null, criadorId, isPrivate ? 1 : 0],
        async (err, result) => {
          if (err) {
            console.error('Erro ao criar canal:', err);
            return reject(err);
          }

          const channelId = result.insertId;
          
          // Adiciona o criador como membro admin do canal
          try {
            await this.addMemberToChannel({
              channelId,
              userId: criadorId,
              role: 'admin'
            });
            
            // Busca o canal criado
            db.query(
              'SELECT * FROM canais WHERE id = ?',
              [channelId],
              (err, results) => {
                if (err) {
                  console.error('Erro ao buscar canal criado:', err);
                  return reject(err);
                }
                
                resolve(results[0]);
              }
            );
          } catch (error) {
            reject(error);
          }
        }
      );
    });
  }

  /**
   * Adiciona um membro a um canal
   * @param {Object} memberData - Dados do membro
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async addMemberToChannel(memberData) {
    const { channelId, userId, role = 'membro' } = memberData;

    return new Promise((resolve, reject) => {
      db.query(
        'INSERT INTO membros_canal (canal_id, usuario_id, role) VALUES (?, ?, ?)',
        [channelId, userId, role],
        (err, result) => {
          if (err) {
            console.error('Erro ao adicionar membro ao canal:', err);
            return reject(err);
          }
          resolve(result);
        }
      );
    });
  }

  /**
   * Remove um membro de um canal
   * @param {number} channelId - ID do canal
   * @param {number} userId - ID do usuário
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async removeMemberFromChannel(channelId, userId) {
    return new Promise((resolve, reject) => {
      db.query(
        'DELETE FROM membros_canal WHERE canal_id = ? AND usuario_id = ?',
        [channelId, userId],
        (err, result) => {
          if (err) {
            console.error('Erro ao remover membro do canal:', err);
            return reject(err);
          }
          resolve(result);
        }
      );
    });
  }

  /**
   * Envia uma mensagem para um canal
   * @param {Object} messageData - Dados da mensagem
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async sendChannelMessage(messageData) {
    const { channelId, userId, content, type = 'text' } = messageData;

    return new Promise((resolve, reject) => {
      // Verifica se o usuário é membro do canal
      db.query(
        'SELECT * FROM membros_canal WHERE canal_id = ? AND usuario_id = ?',
        [channelId, userId],
        (err, results) => {
          if (err) {
            console.error('Erro ao verificar membro do canal:', err);
            return reject(err);
          }
          
          if (results.length === 0) {
            return reject(new Error('Usuário não é membro deste canal'));
          }
          
          // Insere a mensagem
          db.query(
            'INSERT INTO mensagens_canal (canal_id, usuario_id, content, type) VALUES (?, ?, ?, ?)',
            [channelId, userId, content, type],
            (err, result) => {
              if (err) {
                console.error('Erro ao enviar mensagem para o canal:', err);
                return reject(err);
              }
              
              // Busca a mensagem com informações do usuário
              db.query(
                `SELECT mc.*, u.nome as sender_name, u.avatar as sender_avatar 
                FROM mensagens_canal mc
                JOIN usuario u ON mc.usuario_id = u.id
                WHERE mc.id = ?`,
                [result.insertId],
                (err, messageResults) => {
                  if (err) {
                    console.error('Erro ao buscar mensagem enviada:', err);
                    return reject(err);
                  }
                  
                  resolve(messageResults[0]);
                }
              );
            }
          );
        }
      );
    });
  }

  /**
   * Obtém mensagens de um canal
   * @param {number} channelId - ID do canal
   * @param {number} limit - Limite de mensagens
   * @param {number} offset - Deslocamento para paginação
   * @returns {Promise} - Promise com as mensagens do canal
   */
  static async getChannelMessages(channelId, limit = 50, offset = 0) {
    return new Promise((resolve, reject) => {
      db.query(
        `SELECT mc.*, u.nome as sender_name, u.avatar as sender_avatar 
         FROM mensagens_canal mc
         JOIN usuario u ON mc.usuario_id = u.id
         WHERE mc.canal_id = ?
         ORDER BY mc.created_at DESC
         LIMIT ? OFFSET ?`,
        [channelId, limit, offset],
        (err, results) => {
          if (err) {
            console.error('Erro ao buscar mensagens do canal:', err);
            return reject(err);
          }
          resolve(results);
        }
      );
    });
  }

  /**
   * Obtém todos os canais que um usuário participa
   * @param {number} userId - ID do usuário
   * @returns {Promise} - Promise com os canais do usuário
   */
  static async getUserChannels(userId) {
    return new Promise((resolve, reject) => {
      db.query(
        `SELECT c.*, mc.role,
         (SELECT COUNT(*) FROM mensagens_canal mc 
          LEFT JOIN leitura_mensagens_canal lmc ON mc.id = lmc.mensagem_id AND lmc.usuario_id = ?
          WHERE mc.canal_id = c.id AND lmc.id IS NULL AND mc.usuario_id != ?) as unread_count
         FROM canais c
         JOIN membros_canal mc ON c.id = mc.canal_id
         WHERE mc.usuario_id = ?
         ORDER BY c.created_at DESC`,
        [userId, userId, userId],
        (err, results) => {
          if (err) {
            console.error('Erro ao buscar canais do usuário:', err);
            return reject(err);
          }
          resolve(results);
        }
      );
    });
  }

  /**
   * Marca as mensagens de um canal como lidas para um usuário
   * @param {number} channelId - ID do canal
   * @param {number} userId - ID do usuário
   * @returns {Promise} - Promise com o resultado da operação
   */
  static async markChannelMessagesAsRead(channelId, userId) {
    return new Promise((resolve, reject) => {
      // Busca mensagens não lidas
      db.query(
        `SELECT mc.id FROM mensagens_canal mc 
         LEFT JOIN leitura_mensagens_canal lmc 
           ON mc.id = lmc.mensagem_id AND lmc.usuario_id = ?
         WHERE mc.canal_id = ? AND lmc.id IS NULL AND mc.usuario_id != ?`,
        [userId, channelId, userId],
        (err, unreadMessages) => {
          if (err) {
            console.error('Erro ao buscar mensagens não lidas:', err);
            return reject(err);
          }
          
          if (unreadMessages.length === 0) {
            return resolve({ affectedRows: 0 });
          }
          
          // Para cada mensagem não lida, insere registro de leitura
          const values = unreadMessages.map(msg => [msg.id, userId]);
          
          db.query(
            'INSERT INTO leitura_mensagens_canal (mensagem_id, usuario_id) VALUES ?',
            [values],
            (err, result) => {
              if (err) {
                console.error('Erro ao marcar mensagens como lidas:', err);
                return reject(err);
              }
              resolve(result);
            }
          );
        }
      );
    });
  }
}

module.exports = ChannelModel;
