const express = require('express');
const router = express.Router();
const db = require('../config/db');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const SALT_ROUNDS = 12;

router.post('/register', async (req, res) => {
    const { email, nome, telefone, senha } = req.body;

    try {
        // Verificar se usuário já existe
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

        // Criptografar a senha
        console.log('🔐 Criptografando senha...');
        const hashedPassword = await bcrypt.hash(senha, SALT_ROUNDS);
        console.log('✅ Senha criptografada');

        // Inserir usuário com senha criptografada
        const [result] = await db.execute(
            'INSERT INTO usuarios (email, nome, telefone, senha, permissao) VALUES (?, ?, ?, ?, 0)',
            [email, nome, telefone, hashedPassword]
        );

        console.log('✅ Usuário criado com ID:', result.insertId);

        res.status(201).json({
            success: true,
            message: 'Usuário registrado com sucesso',
            userId: result.insertId
        });
    } catch (error) {
        console.error('❌ Erro ao registrar usuário:', error);
        res.status(500).json({
            success: false,
            message: 'Erro ao registrar usuário'
        });
    }
});

router.post('/login', async (req, res) => {
    const { email, senha } = req.body;

    try {
        console.log('🔍 Tentativa de login:', email);

        const [users] = await db.execute(
            'SELECT * FROM usuarios WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Email ou senha incorretos'
            });
        }

        const user = users[0];

        // Comparar senha criptografada
        console.log('🔐 Verificando senha...');
        const passwordMatch = await bcrypt.compare(senha, user.senha);

        if (passwordMatch) {
            console.log('✅ Login bem-sucedido para:', email);
            
            // Remover senha da resposta
            const userResponse = { ...user };
            delete userResponse.senha;

            return res.json({
                success: true,
                message: 'Login realizado com sucesso',
                usuario: userResponse
            });
        } else {
            console.log('❌ Senha incorreta para:', email);
            return res.status(401).json({
                success: false,
                message: 'Email ou senha incorretos'
            });
        }

    } catch (error) {
        console.error('❌ Erro no login:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

module.exports = router;
