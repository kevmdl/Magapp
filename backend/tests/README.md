# Testes do Backend - MagApp

Esta pasta contém todos os testes automatizados para o backend do MagApp.

## Pré-requisitos

- Servidor backend rodando na porta 3000: `node app.js`
- Banco de dados MySQL conectado e configurado
- Node.js instalado

## Testes Disponíveis

### 1. Teste de Transição de Status (`test_status_transition.js`)
Testa a funcionalidade de transição de status dos pedidos (1 → 3 → 4).

```bash
node backend/tests/test_status_transition.js
```

### 2. Teste de Correção UTF-8 (`test_utf8_fix.js`)
Verifica se os caracteres especiais (acentos) estão sendo decodificados corretamente.

```bash
node backend/tests/test_utf8_fix.js
```

### 3. Teste de Novos Status (`test_new_status.js`)
Testa a implementação dos novos status de pedidos.

```bash
node backend/tests/test_new_status.js
```

### 4. Teste Completo de Status (`test_new_status_complete.js`)
Teste abrangente de todos os status de pedidos.

```bash
node backend/tests/test_new_status_complete.js
```

### 5. Testes de Integração

#### Banco de Dados (`db-integration.js`)
Testa a conexão e operações com o banco de dados.

```bash
node backend/tests/db-integration.js
```

#### Mock Database (`mock-db-integration.js`)
Testa com banco de dados mockado.

```bash
node backend/tests/mock-db-integration.js
```

#### Pedidos (`pedidos-integration.js`)
Testa operações CRUD de pedidos.

```bash
node backend/tests/pedidos-integration.js
```

#### WebSocket (`websocket-integration.js`)
Testa funcionalidades de WebSocket.

```bash
node backend/tests/websocket-integration.js
```

## Como Executar Todos os Testes

### Executar um teste específico:
```bash
cd c:\Users\Kevim\Magapp
node backend/tests/[nome-do-teste].js
```

### Executar testes com Jest (se disponível):
```bash
cd backend
npm test
```

## Status dos Testes

✅ **Funcionando:**
- Transição de status (1 → 3 → 4)
- Correção UTF-8
- Operações CRUD de pedidos
- Conexão com banco de dados

🔧 **Configuração:**
- Todos os testes configurados para porta 3000
- Headers UTF-8 configurados
- Banco de dados MySQL conectado

## Notas Importantes

- Certifique-se de que o servidor backend está rodando antes de executar os testes
- Os testes podem modificar dados no banco de dados
- Use um ambiente de teste separado quando possível
- Verifique as credenciais do banco de dados no arquivo `.env`

## Logs e Debug

Os testes incluem logs detalhados para facilitar o debug:
- Status das requisições HTTP
- Respostas da API
- Erros de conexão
- Dados retornados

## Estrutura dos Arquivos de Teste

```
backend/tests/
├── README.md                     # Este arquivo
├── test_status_transition.js     # Teste de transição de status
├── test_utf8_fix.js             # Teste de UTF-8
├── test_new_status.js           # Teste de novos status
├── test_new_status_complete.js  # Teste completo de status
├── db-integration.js            # Integração com banco
├── mock-db-integration.js       # Integração com mock
├── pedidos-integration.js       # Integração de pedidos
└── websocket-integration.js     # Integração WebSocket
```
