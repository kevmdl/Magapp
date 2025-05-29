GRUPO 10 MAGAPP
Jorge Luis Santiciolli Filho
Kevilyn Marinho de Lima

# 🚗 MagApp - Sistema Inteligente para Pedidos de Placas Mercosul

[![Flutter](https://img.shields.io/badge/Flutter-v3.6.0-blue.svg)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-Backend-green.svg)](https://nodejs.org/)
[![MySQL](https://img.shields.io/badge/MySQL-Database-orange.svg)](https://mysql.com/)
[![AI](https://img.shields.io/badge/AI-Visão%20Computacional-purple.svg)](https://ai.google.dev/)
[![AI](https://img.shields.io/badge/AI-Processamento%20de%20Linguagem%20Natural-purple.svg)](https://ai.google.dev/)

**Desenvolvido por GRUPO 10:**
- Jorge Luis Santiciolli Filho
- Kevilyn Marinho de Lima

## 📋 Sobre o Projeto

O MagApp é um sistema inteligente que **revoluciona o processo de pedidos de placas Mercosul**, utilizando tecnologias de Inteligência Artificial para aumentar a eficiência e reduzir significativamente o tempo de processamento. O aplicativo combina Visão Computacional e Processamento de Linguagem Natural para automatizar a validação de documentos e oferecer atendimento ao cliente 24/7.

### 🎯 Principais Funcionalidades

- **🔍 Validação de Documentos com IA**: Análise automática de documentos veiculares usando Visão Computacional
- **🤖 Chat Inteligente 24/7**: Atendimento automatizado com Processamento de Linguagem Natural
- **📋 Gestão de Pedidos**: Sistema completo para pedidos de placas Mercosul
- **📊 Dashboard Administrativo**: Relatórios e métricas em tempo real
- **🔒 Segurança**: Autenticação JWT e armazenamento seguro de dados

## 🛠️ Tecnologias Utilizadas

### Frontend (Mobile)
- **Flutter 3.6.0** - Framework para desenvolvimento mobile
- **Dart** - Linguagem de programação
- **Material Design** - Design system
- **Google Fonts** - Tipografia personalizada
- **Table Calendar** - Componente de calendário
- **Flutter Secure Storage** - Armazenamento seguro
- **HTTP** - Requisições para API
- **Shared Preferences** - Persistência de dados locais
- **Page Transition** - Animações de navegação
- **Google Generative AI** - Integração com IA

### Backend (API)
- **Node.js** - Runtime JavaScript
- **Express.js** - Framework web
- **MySQL2** - Driver para banco de dados
- **JWT (jsonwebtoken)** - Autenticação
- **Bcrypt** - Criptografia de senhas
- **CORS** - Cross-Origin Resource Sharing
- **Dotenv** - Gerenciamento de variáveis de ambiente

### Banco de Dados
- **MySQL** - Sistema de gerenciamento de banco de dados relacional

### Ferramentas de Desenvolvimento
- **Flutter Lints** - Análise de código
- **Mockito** - Testes unitários
- **Nodemon** - Auto-reload do servidor
- **Build Runner** - Geração de código

## 📁 Estrutura do Projeto

```
MagApp/
├── lib/                          # Código fonte Flutter
│   ├── main.dart                 # Ponto de entrada do app
│   ├── views/                    # Telas do aplicativo
│   │   ├── home_view.dart        # Tela principal/dashboard
│   │   ├── login_view.dart       # Tela de login
│   │   ├── profile_view.dart     # Perfil do usuário
│   │   ├── document_view.dart    # Validação de documentos
│   │   ├── chat_view.dart        # Chat inteligente
│   │   ├── orders_view.dart      # Gestão de pedidos
│   │   └── register_view.dart    # Cadastro de usuário
│   ├── models/                   # Modelos de dados
│   ├── services/                 # Serviços e APIs
│   ├── widgets/                  # Componentes reutilizáveis
│   ├── src/                      # Código fonte otimizado
│   │   ├── mixins/               # Mixins de performance
│   │   ├── widgets/              # Widgets otimizados
│   │   └── utils/                # Utilitários e monitores
├── backend/                      # Servidor Node.js
│   ├── app.js                    # Aplicação principal
│   ├── config/                   # Configurações
│   │   └── database.sql          # Scripts do banco
│   ├── routes/                   # Rotas da API
│   └── middleware/               # Middlewares
├── assets/                       # Recursos estáticos
└── test/                         # Testes automatizados
```

## 🚀 Como Executar o Projeto

### Pré-requisitos

Certifique-se de ter instalado:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (≥ 3.6.0)
- [Node.js](https://nodejs.org/) (≥ 14.0.0)
- [MySQL](https://mysql.com/) (≥ 8.0)
- [Git](https://git-scm.com/)

### 1. Clone o Repositório

```bash
git clone <url-do-repositorio>
cd Magapp
```

### 2. Configuração do Banco de Dados

1. Crie um banco de dados MySQL:
```sql
CREATE DATABASE magapp;
```

2. Execute os scripts SQL localizados em `backend/config/database.sql`

3. Configure as variáveis de ambiente no backend:
```bash
cd backend
cp .env.example .env
```

Edite o arquivo `.env` com suas credenciais:
```env
DB_HOST=localhost
DB_USER=seu_usuario
DB_PASSWORD=sua_senha
DB_NAME=magapp
JWT_SECRET=sua_chave_secreta
PORT=3000
```

### 3. Configuração do Backend

```bash
cd backend
npm install
npm start
```

O servidor estará rodando em `http://localhost:3000`

### 4. Configuração do Frontend

```bash
# Volte para o diretório raiz
cd ..
flutter pub get
flutter run
```

### 5. Desenvolvimento

Para desenvolvimento com hot-reload:

**Backend:**
```bash
cd backend
npm run dev
```

**Frontend:**
```bash
flutter run --hot
```

## 🧪 Testes

### Testes do Frontend
```bash
flutter test
```

### Testes do Backend
```bash
cd backend
npm test
```

## 📱 Funcionalidades Detalhadas

### Sistema de Autenticação
- Registro de novos usuários
- Login seguro com JWT
- Recuperação de senha
- Perfil de usuário editável

### 🔍 Validação de Documentos com IA
- Análise automática de documentos veiculares usando Visão Computacional
- Validação de CRLV
- Detecção de inconsistências e erros em documentos
- Verificação de autenticidade através de IA

### 🤖 Chat Inteligente com IA
- Atendimento ao cliente 24/7 com Processamento de Linguagem Natural
- Suporte automatizado para dúvidas sobre emplacamento
- Orientações sobre documentação necessária
- Esclarecimentos sobre o processo Mercosul

### 📋 Gestão de Pedidos de Placas
- Criação e acompanhamento de pedidos de placas Mercosul
- Status em tempo real do processo de emplacamento
- Histórico completo de pedidos
- Notificações sobre andamento dos processos

### 📊 Dashboard Administrativo
- Relatórios de pedidos processados
- Estatísticas de validação de documentos
- Métricas de atendimento do chatbot
- Controle de usuários e permissões

### Interface do Usuário
- Design Material Design 3
- Navegação fluida com animações
- Responsividade para diferentes tamanhos de tela
- Tema claro/escuro (se implementado)

## 🔧 Configurações Avançadas

### Configuração de Rede
Por padrão, o app se conecta ao backend em `localhost:3000`. Para usar em dispositivos físicos, edite a URL base nos serviços do Flutter.

### Banco de Dados
O projeto inclui scripts SQL completos para criação das tabelas e dados de exemplo. Verifique o arquivo `backend/config/database.sql` para mais detalhes.

## 🐛 Solução de Problemas

### Problemas Comuns

1. **Erro de conexão com banco**: Verifique as credenciais no arquivo `.env`
2. **Falha ao instalar dependências**: Execute `flutter clean` e `flutter pub get`
3. **Erro de CORS**: Certifique-se de que o backend está configurado corretamente
4. **Problemas de build**: Verifique se todas as versões do SDK estão corretas

### Logs e Debug
- Backend: Os logs aparecem no console do Node.js
- Frontend: Use `flutter logs` para debug em tempo real

## 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos. Todos os direitos reservados aos desenvolvedores.

## 🤝 Contribuição

Este é um projeto acadêmico desenvolvido por Jorge Luis Santiciolli Filho e Kevilyn Marinho de Lima.

---

**Versão:** 1.0.0  
**Última atualização:** 2024

