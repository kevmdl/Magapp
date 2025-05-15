const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');
const db = require("../config/db");

/**
 * Rota para login de usuário
 * POST /api/auth/login
 */
router.post('/login', async (req, res) => {
  try {
    const { email, senha, userId } = req.body;
    
    // Se fornecido userId diretamente (para manter compatibilidade com código existente)
    if (userId) {
      try {
        const user = await UserModel.getUserById(userId);
        
        if (!user) {
          return res.status(401).json({
            success: false,
            message: 'Usuário não encontrado'
          });
        }
        
        // Gera o token JWT
        const token = jwt.sign(
          { userId: user.id }, 
          process.env.JWT_SECRET, 
          { expiresIn: '7d' }
        );
        
        // Atualiza status online
        await UserModel.updateOnlineStatus(user.id, true);
        
        return res.json({
          success: true,
          data: { user, token }
        });
      } catch (error) {
        console.error('Erro ao autenticar por userId:', error);
        return res.status(500).json({
          success: false,
          message: 'Erro no servidor',
          error: error.message
        });
      }
    }
    
    // Autenticação por email e senha
    if (!email || !senha) {
      return res.status(400).json({
        success: false,
        message: 'Email e senha são obrigatórios'
      });
    }
    
    const user = await UserModel.authenticateUser(email, senha);
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Credenciais inválidas'
      });
    }
    
    // Gera o token JWT
    const token = jwt.sign(
      { userId: user.id }, 
      process.env.JWT_SECRET, 
      { expiresIn: '7d' }
    );
    
    // Atualiza status online
    await UserModel.updateOnlineStatus(user.id, true);
    
    res.json({
      success: true,
      data: { user, token }
    });
    
  } catch (error) {
    console.error('Erro ao fazer login:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao fazer login',
      error: error.message
    });
  }
});

/**
 * Rota para registro de novo usuário
 * POST /api/auth/register
 */
router.post('/register', async (req, res) => {
  try {
    const { nome, email, senha, avatar } = req.body;
    
    if (!nome || !email || !senha) {
      return res.status(400).json({
        success: false,
        message: 'Nome, email e senha são obrigatórios'
      });
    }
    
    const userData = {
      nome,
      email,
      senha,
      avatar
    };
    
    const user = await UserModel.registerUser(userData);
    
    // Gera o token JWT
    const token = jwt.sign(
      { userId: user.id }, 
      process.env.JWT_SECRET, 
      { expiresIn: '7d' }
    );
    
    res.status(201).json({
      success: true,
      data: { user, token },
      message: 'Usuário registrado com sucesso'
    });
    
  } catch (error) {
    console.error('Erro ao registrar usuário:', error);
    
    if (error.message === 'Email já está em uso') {
      return res.status(409).json({
        success: false,
        message: 'Email já está em uso'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Erro ao registrar usuário',
      error: error.message
    });
  }
});

module.exports = router;
