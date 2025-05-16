const jwt = require("jsonwebtoken");
const express = require("express");
const cors = require("cors"); // Adicionar CORS para permitir requisições do Flutter
const app = express();
require("dotenv").config();
const db = require("./config/db");
const chatRoutes = require("./routes/chat"); // Importar rotas de chat

// Middleware para permitir CORS
app.use(cors());
app.use(express.json());

// Usar rotas de chat
app.use("/chat", chatRoutes);

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

app.listen(3000, () => console.log("Servidor rodando na porta 3000"));
