import 'package:mysql1/mysql1.dart';

class MySqlService {
  // Configurações de conexão
  static final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'senha',
    db: 'magapp_db',
  );

  // Método para obter uma conexão com o banco de dados
  static Future<MySqlConnection> getConnection() async {
    try {
      return await MySqlConnection.connect(_settings);
    } catch (e) {
      throw Exception('Falha ao conectar com o banco de dados MySQL: $e');
    }
  }

  // Método para buscar usuários como exemplo
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final conn = await getConnection();
    try {
      var results = await conn.query('SELECT * FROM usuarios');
      List<Map<String, dynamic>> users = [];
      for (var row in results) {
        users.add({
          'id': row['id'],
          'nome': row['nome'],
          'email': row['email'],
          'created_at': row['created_at'],
        });
      }
      return users;
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    } finally {
      await conn.close();
    }
  }

  // Método para inserir um usuário
  static Future<int> insertUser(String nome, String email, String senha) async {
    final conn = await getConnection();
    try {
      var result = await conn.query(
        'INSERT INTO usuarios (nome, email, senha) VALUES (?, ?, ?)',
        [nome, email, senha],
      );
      return result.insertId ?? -1;
    } catch (e) {
      throw Exception('Erro ao inserir usuário: $e');
    } finally {
      await conn.close();
    }
  }

  // Método para atualizar um usuário
  static Future<int> updateUser(int id, String nome, String email) async {
    final conn = await getConnection();
    try {
      var result = await conn.query(
        'UPDATE usuarios SET nome = ?, email = ? WHERE id = ?',
        [nome, email, id],
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    } finally {
      await conn.close();
    }
  }

  // Método para excluir um usuário
  static Future<int> deleteUser(int id) async {
    final conn = await getConnection();
    try {
      var result = await conn.query(
        'DELETE FROM usuarios WHERE id = ?',
        [id],
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      throw Exception('Erro ao excluir usuário: $e');
    } finally {
      await conn.close();
    }
  }
}
