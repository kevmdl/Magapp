import 'package:flutter_test/flutter_test.dart';
import 'package:maga_app/src/services/mysql_service.dart';

// Este é um teste de integração para o serviço de MySQL
// Antes de executar, certifique-se de que:
// 1. O servidor MySQL esteja rodando
// 2. O banco de dados 'magapp_db' exista
// 3. A tabela 'usuarios' exista com os campos corretos

void main() {
  group('Testes de integração com MySQL', () {
    // Variável para armazenar o ID do usuário criado durante o teste
    int? testUserId;
    
    // Dados de teste
    final testUserName = 'Usuário de Teste';
    final testUserEmail = 'teste_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final testUserPassword = 'senha123';
    
    test('Deve conectar ao banco de dados MySQL', () async {
      var connection = await MySqlService.getConnection();
      expect(connection, isNotNull);
      await connection.close();
    });

    test('Deve inserir um novo usuário no banco de dados', () async {
      testUserId = await MySqlService.insertUser(
        testUserName, 
        testUserEmail, 
        testUserPassword
      );
      
      expect(testUserId, isNot(-1));
      print('Usuário de teste criado com ID: $testUserId');
    });

    test('Deve buscar usuários incluindo o recém criado', () async {
      var users = await MySqlService.getUsers();
      expect(users, isNotEmpty);
      
      // Verifica se o usuário que acabamos de criar está na lista
      bool foundTestUser = users.any((user) => 
        user['id'] == testUserId && 
        user['email'] == testUserEmail
      );
      
      expect(foundTestUser, isTrue);
    });

    test('Deve atualizar o usuário criado', () async {
      String novoNome = 'Nome Atualizado';
      
      var affectedRows = await MySqlService.updateUser(
        testUserId!, 
        novoNome, 
        testUserEmail
      );
      
      expect(affectedRows, 1);
      
      // Verifica se o nome foi atualizado
      var users = await MySqlService.getUsers();
      bool userUpdated = users.any((user) => 
        user['id'] == testUserId && 
        user['nome'] == novoNome
      );
      
      expect(userUpdated, isTrue);
    });

    test('Deve excluir o usuário de teste', () async {
      var affectedRows = await MySqlService.deleteUser(testUserId!);
      expect(affectedRows, 1);
      
      // Verifica se o usuário foi removido
      var users = await MySqlService.getUsers();
      bool userDeleted = !users.any((user) => user['id'] == testUserId);
      
      expect(userDeleted, isTrue);
    });
  });
}
