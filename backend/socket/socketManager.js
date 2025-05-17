const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');
const MessageModel = require('../models/messageModel');
const ChannelModel = require('../models/channelModel');

/**
 * Gerenciador de sockets para comunicação em tempo real
 */
class SocketManager {
  constructor(io) {
    this.io = io;
    this.userSockets = new Map(); // userId -> socketId
    this.init();
  }

  /**
   * Inicializa o gerenciador de sockets
   */
  init() {
    this.io.use(this.authenticateSocket);
    this.io.on('connection', this.handleConnection.bind(this));
  }

  /**
   * Middleware para autenticar socket com JWT
   */
  authenticateSocket(socket, next) {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization;
    
    if (!token) {
      return next(new Error('Autenticação necessária'));
    }
    
    // Remove o prefixo "Bearer " se existir
    const tokenString = token.startsWith('Bearer ') ? token.slice(7) : token;
    
    try {
      const decoded = jwt.verify(tokenString, process.env.JWT_SECRET);
      socket.userId = decoded.userId;
      next();
    } catch (error) {
      return next(new Error('Token inválido'));
    }
  }

  /**
   * Trata nova conexão de socket
   */
  async handleConnection(socket) {
    const userId = socket.userId;
    
    console.log(`Usuário ${userId} conectado (socketId: ${socket.id})`);
    
    // Armazena socket do usuário
    this.userSockets.set(userId, socket.id);
    
    try {
      // Atualiza status online
      await UserModel.updateOnlineStatus(userId, true);
      
      // Notifica outros usuários sobre status online
      socket.broadcast.emit('user:status', { userId, isOnline: true });
      
      // Configura os event listeners
      this.setupMessageHandlers(socket);
      this.setupChannelHandlers(socket);
      this.setupPresenceHandlers(socket);
      
      // Adiciona o usuário em salas para suas conversas e canais
      this.joinUserRooms(socket);
      
    } catch (error) {
      console.error('Erro ao processar conexão de socket:', error);
    }
  }

  /**
   * Configura os manipuladores de eventos para mensagens diretas
   */
  setupMessageHandlers(socket) {
    const userId = socket.userId;
    
    // Ouvir por novas mensagens diretas
    socket.on('message:send', async (data) => {
      try {
        const { receiverId, content, type } = data;
        
        if (!receiverId || !content) {
          return socket.emit('error', { message: 'Dados incompletos' });
        }
        
        // Salva a mensagem no banco de dados
        const message = await MessageModel.saveDirectMessage({
          senderId: userId,
          receiverId,
          content,
          type: type || 'text'
        });
        
        // Emite para o remetente confirmação
        socket.emit('message:sent', { message });
        
        // Emite para o destinatário se online
        const receiverSocketId = this.userSockets.get(receiverId);
        if (receiverSocketId) {
          this.io.to(receiverSocketId).emit('message:received', { message });
        }
        
      } catch (error) {
        console.error('Erro ao processar nova mensagem:', error);
        socket.emit('error', { message: 'Erro ao enviar mensagem' });
      }
    });
    
    // Ouvir por marcação de leitura de mensagens
    socket.on('message:read', async (data) => {
      try {
        const { messageId, senderId } = data;
        
        if (messageId) {
          await MessageModel.markMessageAsRead(messageId);
        } else if (senderId) {
          await MessageModel.markAllMessagesAsRead(senderId, userId);
        }
        
        // Notifica o remetente original que as mensagens foram lidas
        const senderSocketId = this.userSockets.get(senderId);
        if (senderSocketId) {
          this.io.to(senderSocketId).emit('message:read', { 
            by: userId, 
            messageId: messageId || null,
            timestamp: new Date()
          });
        }
        
      } catch (error) {
        console.error('Erro ao marcar mensagem como lida:', error);
        socket.emit('error', { message: 'Erro ao marcar mensagem como lida' });
      }
    });
    
    // Notificação de digitando
    socket.on('typing:start', (data) => {
      const receiverSocketId = this.userSockets.get(data.receiverId);
      if (receiverSocketId) {
        this.io.to(receiverSocketId).emit('typing:start', { userId });
      }
    });
    
    socket.on('typing:stop', (data) => {
      const receiverSocketId = this.userSockets.get(data.receiverId);
      if (receiverSocketId) {
        this.io.to(receiverSocketId).emit('typing:stop', { userId });
      }
    });
  }

  /**
   * Configura os manipuladores de eventos para canais
   */
  setupChannelHandlers(socket) {
    const userId = socket.userId;
    
    // Ouvir por novas mensagens em canais
    socket.on('channel:message', async (data) => {
      try {
        const { channelId, content, type } = data;
        
        if (!channelId || !content) {
          return socket.emit('error', { message: 'Dados incompletos' });
        }
        
        // Salva a mensagem no banco de dados
        const message = await ChannelModel.sendChannelMessage({
          channelId,
          userId,
          content,
          type: type || 'text'
        });
        
        // Emite para todos os membros do canal
        this.io.to(`channel:${channelId}`).emit('channel:message', { message });
        
      } catch (error) {
        console.error('Erro ao processar mensagem de canal:', error);
        socket.emit('error', { message: 'Erro ao enviar mensagem para o canal' });
      }
    });
    
    // Ouvir por leitura de mensagens em canais
    socket.on('channel:read', async (data) => {
      try {
        const { channelId } = data;
        
        if (!channelId) {
          return socket.emit('error', { message: 'ID do canal é obrigatório' });
        }
        
        await ChannelModel.markChannelMessagesAsRead(channelId, userId);
        
        // Notifica outros membros do canal
        socket.to(`channel:${channelId}`).emit('channel:read', {
          channelId,
          userId,
          timestamp: new Date()
        });
        
      } catch (error) {
        console.error('Erro ao marcar mensagens de canal como lidas:', error);
        socket.emit('error', { message: 'Erro ao marcar mensagens como lidas' });
      }
    });
    
    // Notificação de digitando em canal
    socket.on('channel:typing:start', (data) => {
      socket.to(`channel:${data.channelId}`).emit('channel:typing:start', { 
        userId,
        channelId: data.channelId 
      });
    });
    
    socket.on('channel:typing:stop', (data) => {
      socket.to(`channel:${data.channelId}`).emit('channel:typing:stop', { 
        userId,
        channelId: data.channelId 
      });
    });
  }

  /**
   * Configura os manipuladores de presença/status
   */
  setupPresenceHandlers(socket) {
    const userId = socket.userId;
    
    // Desconexão
    socket.on('disconnect', async () => {
      console.log(`Usuário ${userId} desconectado`);
      
      this.userSockets.delete(userId);
      
      try {
        // Atualiza status offline
        await UserModel.updateOnlineStatus(userId, false);
        
        // Notifica outros usuários
        socket.broadcast.emit('user:status', { userId, isOnline: false });
      } catch (error) {
        console.error('Erro ao processar desconexão:', error);
      }
    });
  }

  /**
   * Adiciona o usuário nas salas apropriadas
   */
  async joinUserRooms(socket) {
    try {
      const userId = socket.userId;
      
      // Busca os canais do usuário
      const channels = await ChannelModel.getUserChannels(userId);
      
      // Adiciona o usuário nas salas dos canais
      channels.forEach(channel => {
        socket.join(`channel:${channel.id}`);
      });
      
    } catch (error) {
      console.error('Erro ao adicionar usuário às salas:', error);
    }
  }
}

module.exports = SocketManager;