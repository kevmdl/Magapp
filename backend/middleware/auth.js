const jwt = require('jsonwebtoken');
require('dotenv').config();

/**
 * Middleware para verificar token JWT
 */
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
  
  if (!token) {
    return res.status(401).json({ 
      success: false,
      message: 'Token de autenticação não fornecido' 
    });
  }
  
  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ 
        success: false,
        message: 'Token inválido ou expirado' 
      });
    }
    
    // Salva o ID do usuário no objeto req para uso nas rotas
    req.userId = decoded.userId;
    next();
  });
};

module.exports = {
  authenticateToken
};