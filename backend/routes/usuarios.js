const express = require('express');
const router = express.Router();
const db = require('../config/db');

router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const updateData = req.body;

  try {
    const updateFields = [];
    const updateValues = [];

    // Build dynamic update query
    Object.entries(updateData).forEach(([key, value]) => {
      updateFields.push(`${key} = ?`);
      updateValues.push(value);
    });

    // Add id to values array
    updateValues.push(id);

    const query = `
      UPDATE usuarios 
      SET ${updateFields.join(', ')} 
      WHERE idusuarios = ?
    `;

    await db.execute(query, updateValues);

    res.json({
      success: true,
      message: 'Usuário atualizado com sucesso'
    });
  } catch (error) {
    console.error('Erro ao atualizar usuário:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao atualizar usuário'
    });
  }
});

module.exports = router;