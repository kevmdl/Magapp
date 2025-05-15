const express = require('express');
const router = express.Router();
const ChannelModel = require('../models/channelModel');
const { authenticateToken } = require('../middleware/auth');

// Protege todas as rotas com autenticação
router.use(authenticateToken);

/**
 * Rota para obter todos os canais do usuário
 * GET /api/channels
 */
router.get('/', async (req, res) => {
  try {
    const userId = req.userId;
    const channels = await ChannelModel.getUserChannels(userId);
    
    res.json({
      success: true,
      data: channels
    });
  } catch (error) {
    console.error('Erro ao buscar canais:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar canais',
      error: error.message
    });
  }
});

/**
 * Rota para criar um novo canal
 * POST /api/channels
 */
router.post('/', async (req, res) => {
  try {
    const { nome, descricao, imagem, isPrivate } = req.body;
    const criadorId = req.userId;
    
    if (!nome) {
      return res.status(400).json({
        success: false,
        message: 'O nome do canal é obrigatório'
      });
    }
    
    const channelData = {
      nome,
      descricao,
      imagem,
      criadorId,
      isPrivate: isPrivate || false
    };
    
    const newChannel = await ChannelModel.createChannel(channelData);
    
    res.status(201).json({
      success: true,
      data: newChannel,
      message: 'Canal criado com sucesso'
    });
  } catch (error) {
    console.error('Erro ao criar canal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao criar canal',
      error: error.message
    });
  }
});

/**
 * Rota para obter as mensagens de um canal
 * GET /api/channels/:channelId/messages
 */
router.get('/:channelId/messages', async (req, res) => {
  try {
    const channelId = parseInt(req.params.channelId);
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    
    if (isNaN(channelId)) {
      return res.status(400).json({
        success: false,
        message: 'ID de canal inválido'
      });
    }
    
    const messages = await ChannelModel.getChannelMessages(channelId, limit, offset);
    
    res.json({
      success: true,
      data: messages
    });
    
    // Marca mensagens como lidas em background
    ChannelModel.markChannelMessagesAsRead(channelId, req.userId).catch(err => {
      console.error('Erro ao marcar mensagens como lidas:', err);
    });
  } catch (error) {
    console.error('Erro ao buscar mensagens do canal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar mensagens do canal',
      error: error.message
    });
  }
});

/**
 * Rota para enviar uma mensagem para um canal
 * POST /api/channels/:channelId/messages
 */
router.post('/:channelId/messages', async (req, res) => {
  try {
    const channelId = parseInt(req.params.channelId);
    const { content, type } = req.body;
    const userId = req.userId;
    
    if (isNaN(channelId)) {
      return res.status(400).json({
        success: false,
        message: 'ID de canal inválido'
      });
    }
    
    if (!content) {
      return res.status(400).json({
        success: false,
        message: 'O conteúdo da mensagem é obrigatório'
      });
    }
    
    const messageData = {
      channelId,
      userId,
      content,
      type: type || 'text'
    };
    
    const message = await ChannelModel.sendChannelMessage(messageData);
    
    res.status(201).json({
      success: true,
      data: message,
      message: 'Mensagem enviada com sucesso'
    });
  } catch (error) {
    console.error('Erro ao enviar mensagem para o canal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao enviar mensagem para o canal',
      error: error.message
    });
  }
});

/**
 * Rota para adicionar um membro a um canal
 * POST /api/channels/:channelId/members
 */
router.post('/:channelId/members', async (req, res) => {
  try {
    const channelId = parseInt(req.params.channelId);
    const { userId, role } = req.body;
    
    if (isNaN(channelId) || !userId) {
      return res.status(400).json({
        success: false,
        message: 'ID de canal e usuário são obrigatórios'
      });
    }
    
    await ChannelModel.addMemberToChannel({
      channelId,
      userId,
      role: role || 'membro'
    });
    
    res.status(201).json({
      success: true,
      message: 'Membro adicionado ao canal com sucesso'
    });
  } catch (error) {
    console.error('Erro ao adicionar membro ao canal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao adicionar membro ao canal',
      error: error.message
    });
  }
});

/**
 * Rota para remover um membro de um canal
 * DELETE /api/channels/:channelId/members/:userId
 */
router.delete('/:channelId/members/:userId', async (req, res) => {
  try {
    const channelId = parseInt(req.params.channelId);
    const userId = parseInt(req.params.userId);
    
    if (isNaN(channelId) || isNaN(userId)) {
      return res.status(400).json({
        success: false,
        message: 'IDs de canal e usuário inválidos'
      });
    }
    
    await ChannelModel.removeMemberFromChannel(channelId, userId);
    
    res.json({
      success: true,
      message: 'Membro removido do canal com sucesso'
    });
  } catch (error) {
    console.error('Erro ao remover membro do canal:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao remover membro do canal',
      error: error.message
    });
  }
});

module.exports = router;
