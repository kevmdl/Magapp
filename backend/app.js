const jwt = require("jsonwebtoken");
const express = require("express");
const cors = require("cors");
const app = express();
require("dotenv").config();
const db = require("./config/db");
const authRoutes = require("./routes/auth"); // Add this line
const chatRoutes = require('./routes/chat');

// Teste de conexão com o banco
db.execute('SELECT 1')
  .then(() => {
    console.log('📦 Conexão com o banco de dados estabelecida com sucesso!');
    console.log('Credenciais:', {
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      database: process.env.DB_NAME
    });
  })
  .catch(err => {
    console.error('❌ Erro ao conectar ao banco de dados:', err);
    process.exit(1); // Encerra a aplicação se não conseguir conectar
  });

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/api/auth", authRoutes);
app.use('/api/chat', chatRoutes);

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

            const token = jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: "1h" });
            res.json({ token });
        }
    );
});

// Adicionar rota de login de demonstração
app.post("/login/demo", (req, res) => {
    console.log("Login de demonstração solicitado:", req.body);
    
    const { email, senha } = req.body;
    
    // Para fins de demonstração, aceitar qualquer email com senha "demo123"
    if (!email || senha !== "demo123") {
        return res.status(401).json({ 
            success: false,
            message: "Credenciais inválidas. Use qualquer email com a senha: demo123" 
        });
    }
    
    // Gerar um token de demonstração
    const userId = "demo_id";
    const token = jwt.sign({ userId }, process.env.JWT_SECRET || "demo_secret_key", { expiresIn: "1h" });
    
    // Retornar dados de usuário de demonstração
    res.json({
        success: true,
        message: "Login de demonstração bem-sucedido",
        token: token,
        usuario: {
            id: "demo_id",
            nome: "Usuário Demo",
            email: email,
            perfil: "demo"
        }
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});
