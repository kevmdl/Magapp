# Guia de Testes de Integração com Banco de Dados - Magapp

Este documento explica como configurar e executar os testes de integração que verificam a comunicação entre o aplicativo Magapp e o banco de dados.

## Pré-requisitos

Antes de executar os testes, você precisa ter:

1. **Node.js** (versão 14 ou superior)
2. **MySQL** (versão 5.7 ou superior)
3. **Jest** (instalado como dependência de desenvolvimento)

## Configuração do Ambiente de Teste

### Configuração Automática

Para configurar automaticamente o ambiente de testes, execute um dos scripts abaixo:

**No Windows (PowerShell)**:
```powershell
.\run_db_integration_tests.ps1
```

**No Windows (Command Prompt)**:
```cmd
run_db_integration_tests.bat
```

Estes scripts irão:
1. Verificar se o MySQL está instalado e acessível
2. Criar o banco de dados de testes (`magapp_test`)
3. Criar o usuário de teste (`test_user` com senha `test_password`)
4. Configurar as tabelas necessárias para os testes
5. Executar os testes de integração

### Configuração Manual

Se a configuração automática falhar, você pode configurar o ambiente manualmente:

1. Acesse o MySQL como administrador:
   ```sql
   mysql -u root -p
   ```

2. Crie o banco de dados de teste:
   ```sql
   CREATE DATABASE IF NOT EXISTS magapp_test;
   ```

3. Crie o usuário para testes:
   ```sql
   CREATE USER IF NOT EXISTS 'test_user'@'localhost' IDENTIFIED BY 'test_password';
   ```

4. Conceda privilégios ao usuário:
   ```sql
   GRANT ALL PRIVILEGES ON magapp_test.* TO 'test_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

5. Crie as tabelas necessárias executando o script:
   ```bash
   cd backend
   npm run setup:test-db
   ```

## Executando os Testes de Integração

### Testes com Mock de Banco de Dados

Os testes com mock não precisam de um banco de dados real e são mais rápidos:

```bash
cd backend
npm run test:mock-db
```

### Testes com Banco de Dados Real

Estes testes verificam a integração completa com o MySQL:

```bash
cd backend
npm run test:db
```

### Executando Todos os Testes

Para executar todos os testes de integração com banco de dados:

```bash
cd backend
npm test
```

## Estrutura dos Testes

### Mock DB Integration (`mock-db-integration.js`)

Este arquivo contém:
- Repositório simulado para operações CRUD
- Testes para criar, ler, atualizar e excluir registros
- Testes para buscar registros por filtros
- Tratamento de erros

### DB Integration (`db-integration.js`)

Este arquivo contém:
- Testes diretos com o banco de dados
- Verificação de operações CRUD completas
- Testes de transações
- Testes de consultas complexas

## Resolução de Problemas

### Erro de Conexão

Se você encontrar erros de conexão com o banco de dados, verifique:

1. Se o MySQL está em execução
2. Se o usuário e senha estão corretos no arquivo `.env.test`
3. Se o banco de dados `magapp_test` existe

### Falhas nos Testes

Se os testes falharem, verifique:

1. Os logs de erro para identificar o problema específico
2. Se as tabelas foram criadas corretamente
3. Se o usuário tem permissões suficientes

## Integração Contínua

Para usar estes testes em um pipeline de CI/CD, configure as variáveis de ambiente necessárias:

- `TEST_DB_HOST`
- `TEST_DB_USER`
- `TEST_DB_PASSWORD`
- `TEST_DB_NAME`

E execute o comando:

```bash
npm run test:db
```
