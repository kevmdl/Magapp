import 'package:mockito/mockito.dart';
import 'package:maga_app/src/services/mysql_service.dart';

class MockMySqlService extends Mock implements MySqlService {
  // Lista simulada de usuários
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 1,
      'nome': 'Usuário Mock 1',
      'email': 'mock1@example.com',
      'created_at': DateTime.now().toString(),
    },
    {
      'id': 2,
      'nome': 'Usuário Mock 2',
      'email': 'mock2@example.com',
      'created_at': DateTime.now().toString(),
    }
  ];

  // ID para novos usuários
  static int _nextId = 3;

  // Simula conexão com o banco de dados
  static Future<bool> getConnection() async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simula atraso de rede
    return true;
  }

  // Simula busca de usuários
  static Future<List<Map<String, dynamic>>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simula atraso de rede
    return List.from(_mockUsers); // Retorna uma cópia para evitar modificações externas
  }

  // Simula inserção de usuário
  static Future<int> insertUser(String nome, String email, String senha) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simula atraso de rede
    
    // Verifica se o email já existe
    if (_mockUsers.any((user) => user['email'] == email)) {
      throw Exception('Email já cadastrado');
    }
    
    int newId = _nextId++;
    _mockUsers.add({
      'id': newId,
      'nome': nome,
      'email': email,
      'created_at': DateTime.now().toString(),
    });
    
    return newId;
  }

  // Simula atualização de usuário
  static Future<int> updateUser(int id, String nome, String email) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simula atraso de rede
    
    int index = _mockUsers.indexWhere((user) => user['id'] == id);
    if (index == -1) {
      return 0; // Nenhum usuário encontrado
    }
    
    // Verifica se o novo email já existe em outro usuário
    bool emailExists = _mockUsers.any((user) => 
      user['email'] == email && user['id'] != id
    );
    
    if (emailExists) {
      throw Exception('Email já cadastrado para outro usuário');
    }
    
    _mockUsers[index] = {
      'id': id,
      'nome': nome,
      'email': email,
      'created_at': _mockUsers[index]['created_at'],
    };
    
    return 1; // Um usuário atualizado
  }

  // Simula exclusão de usuário
  static Future<int> deleteUser(int id) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simula atraso de rede
    
    int initialLength = _mockUsers.length;
    _mockUsers.removeWhere((user) => user['id'] == id);
    
    return initialLength - _mockUsers.length; // Retorna número de usuários removidos
  }
}
