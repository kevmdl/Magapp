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
    email_cliente // Adicionar este campo
  } = req.body;

  try {
    const [result] = await db.execute(
      `INSERT INTO pedidos 
       (nome_cliente, cpf, placa, renavam, chassi, modelo, cor, email_cliente, concluido, data_conclusao) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, NULL)`,
      [nome_cliente, cpf, placa, renavam, chassi, modelo, cor, email_cliente]
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

router.put('/:id/status', async (req, res) => {
  const { id } = req.params;
  const { concluido, mensagem_rejeicao } = req.body; // Changed from rejectMessage
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

  try {
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
    );

    res.json({
      success: true,
      message: `Pedido ${concluido === 1 ? 'aprovado' : 'rejeitado'} com sucesso`
    });
  } catch (error) {
    console.error('Erro ao atualizar pedido:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao atualizar pedido'
    });
  }
});

// Adicione este endpoint
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

module.exports = router;