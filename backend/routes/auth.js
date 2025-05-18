const express = require('express');
const router = express.Router();
const db = require('../config/db');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const SALT_ROUNDS = 10;

router.post('/register', async (req, res) => {
    const { email, nome, telefone, senha } = req.body;

    try {
        // Check if user already exists
        const [existingUsers] = await db.execute(
            'SELECT * FROM usuarios WHERE email = ?',
            [email]
        );

        if (existingUsers.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Email já cadastrado'
            });
        }

        // Insert new user with plain password
        const [result] = await db.execute(
            'INSERT INTO usuarios (email, nome, telefone, senha, permissao) VALUES (?, ?, ?, ?, 0)',
            [email, nome, telefone, senha]
        );

        res.status(201).json({
            success: true,
            message: 'Usuário registrado com sucesso',
            userId: result.insertId
        });
    } catch (error) {
        console.error('Erro ao registrar usuário:', error);
        res.status(500).json({
            success: false,
            message: 'Erro ao registrar usuário'
        });
    }
});

router.post('/login', async (req, res) => {
    const { email, senha } = req.body;

    try {
        console.log('Login attempt:', { email });

        const [users] = await db.execute(
            'SELECT * FROM usuarios WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Email não encontrado'
            });
        }

        const user = users[0];
        console.log('Comparing passwords:', { 
            provided: senha,
            stored: user.senha 
        });

        // Simple string comparison
        if (senha === user.senha) {
            const userResponse = { ...user };
            delete userResponse.senha;

            return res.json({
                success: true,
                message: 'Login realizado com sucesso',
                usuario: userResponse
            });
        }

        return res.status(401).json({
            success: false,
            message: 'Senha incorreta'
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});



module.exports = router;
