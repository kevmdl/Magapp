const express = require('express');
const router = express.Router();
const db = require('../config/db');

// Armazenamento de mensagens em memória (simulado)
// Em um ambiente de produção, isso seria armazenado em um banco de dados
const mensagens = [];
let proximoId = 1;

// Rota para enviar uma mensagem
router.post('/enviar', (req, res) => {
  const { remetente_id, destinatario_id, conteudo } = req.body;

  if (!remetente_id || !conteudo) {
    return res.status(400).json({ 
      success: false, 
      message: 'Dados incompletos. Informe remetente_id e conteudo.' 
    });
  }

  // Criar uma nova mensagem
  const novaMensagem = {
    id: proximoId++,
    remetente_id,
    destinatario_id,
    conteudo,
    timestamp: new Date().toISOString(),
    lido: false
  };

  // Adicionar ao "banco de dados" em memória
  mensagens.push(novaMensagem);

  res.status(201).json({
    success: true,
    message: 'Mensagem enviada com sucesso',
    data: novaMensagem
  });
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
router.get('/mensagens/:usuario1_id/:usuario2_id', (req, res) => {
  const { usuario1_id, usuario2_id } = req.params;
  
  // Filtrar mensagens entre os dois usuários
  const mensagensEntreUsuarios = mensagens.filter(msg => 
    (msg.remetente_id == usuario1_id && msg.destinatario_id == usuario2_id) ||
    (msg.remetente_id == usuario2_id && msg.destinatario_id == usuario1_id)
  );
  
  // Ordenar por timestamp (mais antigas primeiro)
  mensagensEntreUsuarios.sort((a, b) => 
    new Date(a.timestamp) - new Date(b.timestamp)
  );
  
  // Marcar mensagens como lidas
  mensagensEntreUsuarios.forEach(msg => {
    if (msg.destinatario_id == usuario1_id && !msg.lido) {
      msg.lido = true;
    }
  });
  
  res.json({
    success: true,
    data: mensagensEntreUsuarios
  });
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

module.exports = router;