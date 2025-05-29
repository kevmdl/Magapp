const express = require('express');
const router = express.Router();
const db = require('../config/db');
const fs = require('fs');
const path = require('path');

// Endpoint temporário para executar a migração
router.post('/migrate-add-usuario-id', async (req, res) => {
  try {
    console.log('Iniciando migração: adicionando usuario_id à tabela pedidos...');
    
    // Verificar se a coluna já existe
    const [columns] = await db.execute(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = 'magapp' 
      AND TABLE_NAME = 'pedidos' 
      AND COLUMN_NAME = 'usuario_id'
    `);
    
    if (columns.length > 0) {
      return res.json({
        success: true,
        message: 'Coluna usuario_id já existe na tabela pedidos'
      });
    }
    
    // Adicionar a coluna usuario_id
    await db.execute(`ALTER TABLE pedidos ADD COLUMN usuario_id INT`);
    console.log('Coluna usuario_id adicionada com sucesso');
    
    // Adicionar chave estrangeira
    await db.execute(`
      ALTER TABLE pedidos 
      ADD CONSTRAINT fk_pedidos_usuario 
      FOREIGN KEY (usuario_id) REFERENCES usuarios(idusuarios)
    `);
    console.log('Chave estrangeira adicionada com sucesso');
    
    // Verificar a estrutura da tabela
    const [structure] = await db.execute(`DESCRIBE pedidos`);
    
    res.json({
      success: true,
      message: 'Migração concluída com sucesso',
      tableStructure: structure
    });
    
  } catch (error) {
    console.error('Erro na migração:', error);
    res.status(500).json({
      success: false,
      message: 'Erro na migração: ' + error.message
    });
  }
});

module.exports = router;
