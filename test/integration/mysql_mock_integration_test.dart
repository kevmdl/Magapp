import 'package:flutter_test/flutter_test.dart';

// Importação direta usando caminho relativo à raiz do projeto
import '../mocks/mock_mysql_service.dart';

// Este é um teste de integração simulado usando mocks
// Não é necessário um servidor MySQL real para executar este teste

void main() {
  group('Testes de integração com MySQL (Mock)', () {
    // Variável para armazenar o ID do usuário criado durante o teste
    int? testUserId;
    
    // Dados de teste
    const testUserName = 'Usuário de Teste';
    final testUserEmail = 'teste_${DateTime.now().millisecondsSinceEpoch}@example.com';
    const testUserPassword = 'senha123';
    
    test('Deve simular conexão ao banco de dados MySQL', () async {
      var connection = await MockMySqlService.getConnection();
      expect(connection, isTrue);
    });

    test('Deve inserir um novo usuário no banco de dados simulado', () async {
      testUserId = await MockMySqlService.insertUser(
        testUserName, 
        testUserEmail, 
        testUserPassword
      );
      
      expect(testUserId, isNotNull);
      expect(testUserId, greaterThan(0));
      print('Usuário de teste criado com ID simulado: $testUserId');
    });

    test('Deve buscar usuários incluindo o recém criado', () async {
      var users = await MockMySqlService.getUsers();
      expect(users, isNotEmpty);
      
      // Verifica se o usuário que acabamos de criar está na lista
      bool foundTestUser = users.any((user) => 
        user['email'] == testUserEmail
      );
      
      expect(foundTestUser, isTrue);
    });

    test('Deve atualizar o usuário criado', () async {
      String novoNome = 'Nome Atualizado';
      
      var affectedRows = await MockMySqlService.updateUser(
        testUserId!, 
        novoNome, 
        testUserEmail
      );
      
      expect(affectedRows, 1);
      
      // Verifica se o nome foi atualizado
      var users = await MockMySqlService.getUsers();
      var updatedUser = users.firstWhere((user) => user['id'] == testUserId);
      
      expect(updatedUser['nome'], equals(novoNome));
    });

    test('Deve excluir o usuário de teste', () async {
      var affectedRows = await MockMySqlService.deleteUser(testUserId!);
      expect(affectedRows, 1);
      
      // Verifica se o usuário foi removido
      var users = await MockMySqlService.getUsers();
      bool userDeleted = !users.any((user) => user['id'] == testUserId);
      
      expect(userDeleted, isTrue);
    });
    
    test('Deve retornar erro ao tentar inserir email duplicado', () async {
      // Primeiro insere um usuário
      const email = 'duplicado@example.com';
      await MockMySqlService.insertUser('Usuário 1', email, 'senha123');
      
      // Tenta inserir outro usuário com o mesmo email
      expect(
        () => MockMySqlService.insertUser('Usuário 2', email, 'outrasenha'),
        throwsException
      );
    });
  });
}
