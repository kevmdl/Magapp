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
    cor
  } = req.body;

  try {
    const [result] = await db.execute(
      `INSERT INTO pedidos 
       (nome_cliente, cpf, placa, renavam, chassi, modelo, cor, concluido, data_conclusao) 
       VALUES (?, ?, ?, ?, ?, ?, ?, 0, NULL)`,
      [nome_cliente, cpf, placa, renavam, chassi, modelo, cor]
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
  const { concluido } = req.body;
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

  try {
    await db.execute(
      `UPDATE pedidos 
       SET concluido = ?, 
           data_conclusao = ? 
       WHERE idpedidos = ?`,
      [concluido, now, id]
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

module.exports = router;