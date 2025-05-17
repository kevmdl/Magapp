const express = require('express');
const router = express.Router();
const db = require('../config/db');

// Armazenamento de mensagens em memória (simulado)
// Em um ambiente de produção, isso seria armazenado em um banco de dados
const mensagens = [];
let proximoId = 1;

// Add body-parser middleware
router.use(express.json());

// Rota para enviar uma mensagem
router.post('/enviar', async (req, res) => {
  console.log('Raw request body:', req.body);
  
  const { chat_id, sender_id, content } = req.body;
  console.log('Parsed values:', { chat_id, sender_id, content });
  
  // Validate all required fields
  if (!chat_id || !sender_id || !content) {
    return res.status(400).json({
      success: false,
      message: 'Dados incompletos',
      missing: {
        chat_id: !chat_id,
        sender_id: !sender_id,
        content: !content
      },
      received: req.body
    });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO mensagens (chat_id, sender_id, content) VALUES (?, ?, ?)',
      [chat_id, sender_id, content]
    );

    console.log('Message inserted successfully:', result.insertId);

    res.status(201).json({
      success: true,
      data: {
        id: result.insertId,
        chat_id,
        sender_id,
        content,
        created_at: new Date()
      }
    });
  } catch (error) {
    console.error('Database error:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao enviar mensagem',
      error: error.message
    });
  }
});

// Rota para buscar conversas de um usuário
router.get('/conversas/:usuario_id', (req, res) => {
  const { usuario_id } = req.params;
  
  // Filtrar mensagens em que o usuário está envolvido
  const mensagensDoUsuario = mensagens.filter(msg => 
    msg.remetente_id == usuario_id || msg.destinatario_id == usuario_id
  );
  
  // Agrupar por conversas (por usuário)
  const conversas = {};
  
  mensagensDoUsuario.forEach(msg => {
    // Determinar o ID do outro usuário na conversa
    const outroUsuarioId = msg.remetente_id == usuario_id 
      ? msg.destinatario_id 
      : msg.remetente_id;
    
    if (!conversas[outroUsuarioId]) {
      conversas[outroUsuarioId] = {
        usuario_id: outroUsuarioId,
        mensagens: [],
        ultima_mensagem: null,
        nao_lidas: 0
      };
    }
    
    conversas[outroUsuarioId].mensagens.push(msg);
    
    // Atualiza última mensagem
    if (!conversas[outroUsuarioId].ultima_mensagem || 
        new Date(msg.timestamp) > new Date(conversas[outroUsuarioId].ultima_mensagem.timestamp)) {
      conversas[outroUsuarioId].ultima_mensagem = msg;
    }
    
    // Conta mensagens não lidas
    if (msg.destinatario_id == usuario_id && !msg.lido) {
      conversas[outroUsuarioId].nao_lidas++;
    }
  });
  
  // Converter o objeto em array
  const resultadoConversas = Object.values(conversas);
  
  // Ordenar por timestamp da última mensagem (mais recentes primeiro)
  resultadoConversas.sort((a, b) => {
    if (!a.ultima_mensagem) return 1;
    if (!b.ultima_mensagem) return -1;
    return new Date(b.ultima_mensagem.timestamp) - new Date(a.ultima_mensagem.timestamp);
  });
  
  res.json({
    success: true,
    data: resultadoConversas
  });
});

// Rota para buscar mensagens entre dois usuários
router.get('/mensagens/:chatId', async (req, res) => {
  const { chatId } = req.params;
  
  try {
    console.log(`Buscando mensagens do chat ${chatId}`);
    
    const [messages] = await db.execute(
      `SELECT m.*, u.nome as nome_usuario 
       FROM mensagens m
       LEFT JOIN usuarios u ON m.sender_id = u.idusuarios
       WHERE m.chat_id = ?
       ORDER BY m.created_at ASC`,
      [chatId]
    );

    console.log(`${messages.length} mensagens encontradas para chat ${chatId}`);
    
    res.json({
      success: true,
      data: messages
    });
  } catch (error) {
    console.error('Erro ao buscar mensagens:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erro ao buscar mensagens'
    });
  }
});

// Dados de usuários fictícios para teste
const usuariosDemo = [
  { id: 1, nome: 'Ana Silva', foto: null },
  { id: 2, nome: 'Carlos Mendes', foto: null },
  { id: 3, nome: 'Paulo Souza', foto: null },
  { id: 'demo_id', nome: 'Usuário Demo', foto: null }
];

// Rota para listar usuários (para fins de demo)
router.get('/usuarios', (req, res) => {
  res.json({
    success: true,
    data: usuariosDemo
  });
});

// Rota para criar um novo chat
router.post('/criar', async (req, res) => {
  const { usuario_id, admin_id } = req.body;
  
  try {
    console.log('Verificando chat existente para usuário:', usuario_id);

    // Modified query to be more specific
    const [existingChats] = await db.execute(
      `SELECT DISTINCT c.* 
       FROM chat c
       INNER JOIN participantes p ON c.idchat = p.chat_idchat
       WHERE p.chat_idchat IN (
         SELECT p1.chat_idchat 
         FROM participantes p1
         INNER JOIN participantes p2 ON p1.chat_idchat = p2.chat_idchat
         WHERE p1.Usuario_idusuario = ? 
         AND p2.Usuario_idusuario = ?
       )`,
      [usuario_id, admin_id]
    );

    if (existingChats.length > 0) {
      console.log('Chat existente encontrado para usuário:', usuario_id);
      return res.status(200).json({
        success: true,
        data: existingChats[0]
      });
    }

    // Create new chat if none exists
    console.log('Criando novo chat para usuário:', usuario_id);
    const [result] = await db.execute(
      'INSERT INTO chat (nome, data_criacao) VALUES (?, NOW())',
      [`Suporte - Usuário ${usuario_id}`]
    );

    const chatId = result.insertId;

    // Add participants
    await db.execute(
      'INSERT INTO participantes (Usuario_idusuario, chat_idchat) VALUES (?, ?), (?, ?)',
      [usuario_id, chatId, admin_id, chatId]
    );

    console.log('Novo chat criado:', { chatId, usuario_id });

    res.status(201).json({
      success: true,
      data: {
        idchat: chatId,
        nome: `Suporte - Usuário ${usuario_id}`,
        data_criacao: new Date()
      }
    });

  } catch (error) {
    console.error('Erro ao criar chat:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

module.exports = router;