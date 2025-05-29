const express = require('express');
const router = express.Router();
const db = require('../config/db');

router.post('/', async (req, res) => {
  const {
    nome_cliente,
    cpf,
    placa,
    renavam,
    chassi,
    modelo,
    cor,
    usuario_id  // Adicionar usuario_id
  } = req.body;

  try {
    const [result] = await db.execute(
      `INSERT INTO pedidos 
       (nome_cliente, cpf, placa, renavam, chassi, modelo, cor, usuario_id, concluido, data_conclusao) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, NULL)`,
      [nome_cliente, cpf, placa, renavam, chassi, modelo, cor, usuario_id]
    );

    res.status(201).json({
      success: true,
      message: 'Pedido criado com sucesso',
      pedidoId: result.insertId
    });
  } catch (error) {
    console.error('Erro ao criar pedido:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao criar pedido'
    });
  }
});

router.get('/', async (req, res) => {
  try {
    console.log('Fetching all pedidos...');
    
    // Definir charset UTF-8 na resposta
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    
    const [pedidos] = await db.execute(`
      SELECT * FROM pedidos 
      ORDER BY idpedidos DESC`
    );
    
    console.log(`Found ${pedidos.length} pedidos`);

    res.json({
      success: true,
      data: pedidos
    });
  } catch (error) {
    console.error('Error fetching pedidos:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching pedidos'
    });
  }
});

// Novo endpoint para buscar pedidos por usuário
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`Fetching pedidos for user ${userId}...`);
    
    // Definir charset UTF-8 na resposta
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    
    const [pedidos] = await db.execute(`
      SELECT * FROM pedidos 
      WHERE usuario_id = ?
      ORDER BY idpedidos DESC`,
      [userId]
    );
    
    console.log(`Found ${pedidos.length} pedidos for user ${userId}`);

    res.json({
      success: true,
      data: pedidos
    });
  } catch (error) {
    console.error('Error fetching user pedidos:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user pedidos'
    });
  }
});

router.put('/:id/status', async (req, res) => {
  const { id } = req.params;
  const { concluido, mensagem_rejeicao } = req.body; // Changed from rejectMessage
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

  try {
    // Definir charset UTF-8 na resposta
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    
    // Log para debug
    console.log('Updating pedido:', { id, concluido, mensagem_rejeicao, now });

    // Ensure mensagem_rejeicao is null if not provided
    const rejectMessage = concluido === 2 ? (mensagem_rejeicao || null) : null;

    await db.execute(
      `UPDATE pedidos 
       SET concluido = ?, 
           data_conclusao = ?,
           mensagem_rejeicao = ?
       WHERE idpedidos = ?`,
      [concluido, now, rejectMessage, id]
    );    let message;
    switch (concluido) {
      case 1:
        message = 'Pedido aprovado com sucesso';
        break;
      case 2:
        message = 'Pedido rejeitado com sucesso';
        break;
      case 3:
        message = 'Pedido marcado como pronto para retirada';
        break;
      case 4:
        message = 'Pedido marcado como retirado';
        break;
      default:
        message = 'Status do pedido atualizado com sucesso';
    }

    res.json({
      success: true,
      message: message
    });
  } catch (error) {
    console.error('Erro ao atualizar pedido:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao atualizar pedido'
    });
  }
});

// Endpoint removido - não há mais email_cliente na tabela
// Se precisar buscar pedidos por usuário, use outro campo como CPF
/*
router.get('/user/:email', async (req, res) => {
  const { email } = req.params;
  
  try {
    console.log(`Buscando pedidos para o email: ${email}`);
    
    const [pedidos] = await db.execute(`
      SELECT * FROM pedidos 
      WHERE email_cliente = ?
      ORDER BY idpedidos DESC
    `, [email]);
    
    console.log(`Encontrados ${pedidos.length} pedidos para ${email}`);
    
    res.json({
      success: true,
      data: pedidos
    });
  } catch (error) {
    console.error('Error fetching user pedidos:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user pedidos'
    });
  }
});
*/

module.exports = router;