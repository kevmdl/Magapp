# API de Chat em Tempo Real

Esta é uma API completa de chat em tempo real desenvolvida como alternativa ao Stream.io para aplicativos Flutter. A API oferece funcionalidades de mensagens diretas e canais de chat em grupo, usando Node.js, Express, Socket.io e MySQL.

## Características

- **Mensagens em tempo real**: Comunicação instantânea usando Socket.io
- **Mensagens diretas**: Chat privado entre dois usuários
- **Canais/Grupos**: Conversas em grupo com múltiplos participantes
- **Notificações de digitação**: Indicação de quando alguém está digitando
- **Status online/offline**: Rastreamento da presença dos usuários
- **Histórico de mensagens**: Armazenamento persistente no MySQL
- **Indicador de mensagens lidas**: Saiba quando suas mensagens foram lidas
- **Autenticação segura**: Sistema de JWT para proteção das rotas

## Pré-requisitos

- Node.js (v14 ou superior)
- MySQL (v5.7 ou superior)
- npm ou yarn

## Configuração

1. Clone o repositório e instale as dependências:

```bash
git clone seu-repositorio
cd Back_Magapp-main
npm install
```

2. Crie o banco de dados MySQL:

```sql
CREATE DATABASE meu_app;
```

3. Execute o script SQL de criação de tabelas:

```bash
mysql -u seu_usuario -p meu_app < config/database.sql
```

4. Configure as variáveis de ambiente:

```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas configurações:

```
DB_HOST=localhost
DB_USER=seu_usuario
DB_PASS=sua_senha
DB_NAME=meu_app
JWT_SECRET=sua_chave_secreta
PORT=3000
```

5. Inicie o servidor:

```bash
npm start
```

Para desenvolvimento:

```bash
npm run dev
```

## Endpoints da API

### Autenticação

- `POST /api/auth/register` - Registrar novo usuário
- `POST /api/auth/login` - Login de usuário

### Usuários

- `GET /api/users/search?term=nome` - Buscar usuários
- `GET /api/users/me` - Obter usuário atual
- `GET /api/users/:userId` - Obter usuário específico

### Mensagens Diretas

- `GET /api/messages/conversations` - Listar conversas
- `GET /api/messages/:userId` - Obter mensagens com usuário específico
- `POST /api/messages` - Enviar mensagem direta
- `PATCH /api/messages/:messageId/read` - Marcar mensagem como lida

### Canais/Grupos

- `GET /api/channels` - Listar canais do usuário
- `POST /api/channels` - Criar novo canal
- `GET /api/channels/:channelId/messages` - Listar mensagens do canal
- `POST /api/channels/:channelId/messages` - Enviar mensagem ao canal
- `POST /api/channels/:channelId/members` - Adicionar membro ao canal
- `DELETE /api/channels/:channelId/members/:userId` - Remover membro do canal

## Eventos do Socket.io

### Autenticação

- Conecte-se ao socket enviando o token JWT: `{ auth: { token: 'seu-jwt-token' } }`

### Mensagens Diretas

- `message:send` - Enviar mensagem direta
- `message:received` - Receber mensagem direta
- `message:sent` - Confirmação de mensagem enviada
- `message:read` - Notificação de leitura de mensagem
- `typing:start` - Notificar que usuário começou a digitar
- `typing:stop` - Notificar que usuário parou de digitar

### Canais/Grupos

- `channel:message` - Enviar/receber mensagem em canal
- `channel:read` - Notificação de leitura de mensagens em canal
- `channel:typing:start` - Notificar digitação em canal
- `channel:typing:stop` - Notificar parada de digitação em canal

### Presença

- `user:status` - Atualizações de status online/offline

## Integração com Flutter

Consulte o arquivo `flutter_integration_example.md` para exemplos de como integrar esta API com seu aplicativo Flutter.

## Testes

O projeto inclui uma suíte abrangente de testes automatizados para garantir a qualidade e funcionamento correto de todas as funcionalidades.

### Executar Testes

Execute todos os testes principais:
```bash
node tests/run_all_tests.js
```

Execute um teste específico:
```bash
node tests/test_status_transition.js
node tests/test_utf8_fix.js
node tests/pedidos-integration.js
```

### Tipos de Teste

- **Testes de Status**: Verificam transições de status dos pedidos (1 → 3 → 4)
- **Testes UTF-8**: Validam decodificação correta de caracteres especiais
- **Testes de Integração**: Testam operações CRUD e conexão com banco
- **Testes de WebSocket**: Verificam funcionalidades de chat em tempo real

### Documentação dos Testes

Consulte `tests/README.md` para documentação detalhada dos testes disponíveis.

## Segurança

Esta API usa JWT (JSON Web Tokens) para autenticação. Todas as rotas da API, exceto login e registro, são protegidas e requerem um token JWT válido.

## Licença

MIT