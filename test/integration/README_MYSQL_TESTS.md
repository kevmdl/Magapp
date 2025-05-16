# Testes de Integração com MySQL no Flutter

Este documento descreve como configurar e executar os testes de integração com MySQL para o aplicativo Magapp.

## Requisitos

1. MySQL Server instalado e em execução
2. Banco de dados configurado conforme o script SQL fornecido
3. Dependências do Flutter instaladas através do comando `flutter pub get`

## Configuração do Banco de Dados

1. Abra o MySQL Workbench ou qualquer outro cliente MySQL
2. Execute o script SQL localizado em: `test/integration/setup_test_db.sql`
3. Verifique se o banco de dados `magapp_db` foi criado com sucesso
4. Confirme se a tabela `usuarios` foi criada corretamente

## Configuração da Conexão

Se necessário, ajuste as configurações de conexão no arquivo `lib/src/services/mysql_service.dart`:

```dart
static final ConnectionSettings _settings = ConnectionSettings(
  host: 'localhost',
  port: 3306,
  user: 'seu_usuario',  // Altere para o seu usuário MySQL
  password: 'sua_senha', // Altere para sua senha MySQL
  db: 'magapp_db',
);
```

## Executando os Testes de Integração

Para executar os testes de integração com o MySQL, utilize o seguinte comando:

```bash
flutter test test/integration/mysql_integration_test.dart
```

### Observações Importantes

- Os testes de integração devem ser executados em um ambiente controlado, não em produção
- Certifique-se de que o servidor MySQL esteja em execução antes de iniciar os testes
- Os testes criam, atualizam e excluem registros no banco de dados, então use um banco de testes separado

## Troubleshooting

### Problemas de Conexão

Se ocorrerem erros de conexão, verifique:
- Se o servidor MySQL está em execução
- Se as configurações de host, porta, usuário e senha estão corretas
- Se o banco de dados `magapp_db` existe
- Se o usuário tem permissões suficientes para o banco de dados

### Erros na Tabela

Se ocorrerem erros relacionados à tabela, verifique:
- Se a tabela `usuarios` foi criada corretamente
- Se os campos na tabela correspondem aos esperados pelo teste
