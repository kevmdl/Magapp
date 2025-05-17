const express = require('express');
const router = express.Router();
const MessageModel = require('../models/messageModel');
const { authenticateToken } = require('../middleware/auth');

// Protege todas as rotas com autenticação
router.use(authenticateToken);

/**
 * Rota para obter todas as conversas do usuário
 * GET /api/messages/conversations
 */
router.get('/conversations', async (req, res) => {
  try {
    const userId = req.userId;
    const conversations = await MessageModel.getUserConversations(userId);
    
    res.json({
      success: true,
      data: conversations
    });
  } catch (error) {
    console.error('Erro ao buscar conversas:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar conversas',
      error: error.message
    });
  }
});

/**
 * Rota para obter mensagens entre o usuário atual e outro usuário
 * GET /api/messages/:userId
 */
router.get('/:userId', async (req, res) => {
  try {
    const currentUserId = req.userId;
    const otherUserId = parseInt(req.params.userId);
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    
    if (isNaN(otherUserId)) {
      return res.status(400).json({
        success: false,
        message: 'ID de usuário inválido'
      });
    }
    
    const messages = await MessageModel.getMessagesBetweenUsers(
      currentUserId,
      otherUserId,
      limit,
      offset
    );
    
    res.json({
      success: true,
      data: messages
    });
    
    // Marca mensagens como lidas
    await MessageModel.markAllMessagesAsRead(otherUserId, currentUserId);
    
  } catch (error) {
    console.error('Erro ao buscar mensagens:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar mensagens',
      error: error.message
    });
  }
});

/**
 * Rota para enviar uma mensagem
 * POST /api/messages
 */
router.post('/', async (req, res) => {
  try {
    const { receiverId, content, type } = req.body;
    const senderId = req.userId;
    
    if (!receiverId || !content) {
      return res.status(400).json({
        success: false,
        message: 'O ID do destinatário e o conteúdo da mensagem são obrigatórios'
      });
    }
    
    const messageData = {
      senderId,
      receiverId,
      content,
      type: type || 'text'
    };
    
    const savedMessage = await MessageModel.saveDirectMessage(messageData);
    
    res.status(201).json({
      success: true,
      data: savedMessage,
      message: 'Mensagem enviada com sucesso'
    });
  } catch (error) {
    console.error('Erro ao enviar mensagem:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao enviar mensagem',
      error: error.message
    });
  }
});

/**
 * Rota para marcar uma mensagem como lida
 * PATCH /api/messages/:messageId/read
 */
router.patch('/:messageId/read', async (req, res) => {
  try {
    const messageId = parseInt(req.params.messageId);
    
    if (isNaN(messageId)) {
      return res.status(400).json({
        success: false,
        message: 'ID de mensagem inválido'
      });
    }
    
    await MessageModel.markMessageAsRead(messageId);
    
    res.json({
      success: true,
      message: 'Mensagem marcada como lida'
    });
  } catch (error) {
    console.error('Erro ao marcar mensagem como lida:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao marcar mensagem como lida',
      error: error.message
    });
  }
});

module.exports = router;