const express = require("express");
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const jwt = require("jsonwebtoken");
require("dotenv").config();

// Configuração do banco de dados
const db = require("./config/db");

// Importação do gerenciador de Socket.IO
const SocketManager = require('./socket/socketManager');

// Importação das rotas
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const messageRoutes = require('./routes/messages');
const channelRoutes = require('./routes/channels');

// Inicialização do app Express
const app = express();
const server = http.createServer(app);

// Configuração do Socket.IO
const io = new Server(server, {
  cors: {
    origin: '*', // Em produção, defina as origens permitidas
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Middleware
app.use(cors({
  origin: '*', // Em produção, defina as origens permitidas
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  credentials: true
}));
app.use(express.json());

// Configuração das rotas
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/channels', channelRoutes);

// Rota de status da API
app.get('/api/status', (req, res) => {
  res.json({
    status: 'online',
    serverTime: new Date(),
    message: 'API de chat funcionando corretamente'
  });
});

// Mantendo rota de login legada para compatibilidade
app.post("/login", (req, res) => {
    console.log(req.body);

    const { userId } = req.body;

    if (!userId) {
        return res.status(400).json({ message: "Usuário inválido" });
    }

    db.query(
        "SELECT * FROM usuario WHERE id = ?",
        [userId],
        (err, results) => {
            if (err) {
                console.error(err);
                return res.status(500).json({ message: "Erro no servidor" });
            }

            if (results.length === 0) {
                return res.status(401).json({ message: "Usuário não encontrado" });
            }

            const token = jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: "24h" });
            res.json({ token });
        }
    );
});

// Inicialização do gerenciador de sockets
const socketManager = new SocketManager(io);

// Inicialização do servidor
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
  console.log(`Acesse http://localhost:${PORT}/api/status para verificar o status da API`);
});
