const express = require('express');
const router = express.Router();
const UserModel = require('../models/userModel');
const { authenticateToken } = require('../middleware/auth');

// Protege todas as rotas com autenticação
router.use(authenticateToken);

/**
 * Rota para buscar usuários por termo de pesquisa
 * GET /api/users/search?term=nome
 */
router.get('/search', async (req, res) => {
  try {
    const searchTerm = req.query.term || '';
    const limit = parseInt(req.query.limit) || 20;
    
    if (searchTerm.length < 2) {
      return res.status(400).json({
        success: false,
        message: 'O termo de busca deve ter pelo menos 2 caracteres'
      });
    }
    
    const users = await UserModel.searchUsers(searchTerm, limit);
    
    res.json({
      success: true,
      data: users
    });
  } catch (error) {
    console.error('Erro ao buscar usuários:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar usuários',
      error: error.message
    });
  }
});

/**
 * Rota para obter usuário atual
 * GET /api/users/me
 */
router.get('/me', async (req, res) => {
  try {
    const userId = req.userId;
    const user = await UserModel.getUserById(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Usuário não encontrado'
      });
    }
    
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Erro ao buscar usuário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar usuário',
      error: error.message
    });
  }
});

/**
 * Rota para obter um usuário específico
 * GET /api/users/:userId
 */
router.get('/:userId', async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    
    if (isNaN(userId)) {
      return res.status(400).json({
        success: false,
        message: 'ID de usuário inválido'
      });
    }
    
    const user = await UserModel.getUserById(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Usuário não encontrado'
      });
    }
    
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Erro ao buscar usuário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar usuário',
      error: error.message
    });
  }
});

module.exports = router;