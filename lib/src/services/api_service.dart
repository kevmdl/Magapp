import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Determina a URL base baseada na plataforma em que o app está sendo executado
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // URL para web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // URL para emuladores Android
    } else {
      return 'http://localhost:3000'; // URL para iOS/macOS
    }
    // Se estiver testando em um dispositivo físico, substitua por seu IP local:
    // return 'http://192.168.1.x:3000';
  }

  // Token armazenado em memória
  static String? _authToken;

  // Getter para o token
  static String? get token => _authToken;

  // Método para fazer login de demonstração
  static Future<Map<String, dynamic>> loginDemo(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token if provided
        if (responseData['token'] != null) {
          _authToken = responseData['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _authToken!);
        }
        
        // Save user data
        if (responseData['usuario'] != null) {
          final userData = responseData['usuario'];
          await saveUserData(userData);
          print('Login successful for user ID: ${userData['idusuarios']}');
        }
        
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Credenciais inválidas',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
  
  // Método para verificar se já existe um token salvo
  static Future<bool> verificarToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        _authToken = token;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Obter dados do usuário atual
  static Future<Map<String, dynamic>?> getUsuarioAtual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioString = prefs.getString('usuario_dados');
      
      if (usuarioString != null) {
        return jsonDecode(usuarioString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erro ao obter dados do usuário: $e');
      return null;
    }
  }

  // Método para fazer logout
  static Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('usuario_dados');
  }

  // MÉTODOS DE CHAT

  // Obter lista de usuários para chat
  static Future<List<Map<String, dynamic>>> getUsuarios() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      return [];
    } catch (e) {
      print('Erro ao obter usuários: $e');
      return [];
    }
  }

  // Obter conversas do usuário atual
  static Future<List<Map<String, dynamic>>> getConversas(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversas/$usuarioId'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      return [];
    } catch (e) {
      print('Erro ao obter conversas: $e');
      return [];
    }
  }

  // Obter mensagens entre dois usuários
  static Future<List<Map<String, dynamic>>> getMensagens(String usuario1Id, String usuario2Id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/mensagens/$usuario1Id/$usuario2Id'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      return [];
    } catch (e) {
      print('Erro ao obter mensagens: $e');
      return [];
    }
  }

  // Enviar uma mensagem
  static Future<bool> enviarMensagemParaUsuario({
    required String remetenteId, 
    required String destinatarioId, 
    required String conteudo, required String chatId
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/enviar'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'remetente_id': remetenteId,
          'destinatario_id': destinatarioId,
          'conteudo': conteudo,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> buscarChatComAdmin({
    required String userId,
    required String adminId
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/buscar/$userId/$adminId'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Erro ao buscar chat: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> criarChat({
    required String userId,
    required String adminId,
    required String nome,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/criar'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'usuario_id': userId,
          'admin_id': adminId,
          'nome': nome,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body)['data'];
      }
      throw Exception('Erro ao criar chat');
    } catch (e) {
      print('Erro ao criar chat: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getMensagensPorChat(String chatId) async {
    try {
      print('Buscando mensagens do chat $chatId'); // Debug log
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/mensagens/$chatId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Status da resposta: ${response.statusCode}'); // Debug log
    
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Mensagens recebidas: ${data['data'].length}'); // Debug log
        return List<Map<String, dynamic>>.from(data['data']);
      }
    
      print('Erro ao buscar mensagens: ${response.body}'); // Debug log
      return [];
    } catch (e) {
      print('Erro na requisição: $e'); // Debug log
      return [];
    }
  }

  static Future<bool> enviarMensagem({
    required String chatId,
    required String senderId,
    required String conteudo,
  }) async {
    try {
      print('Enviando mensagem: chatId=$chatId, senderId=$senderId');
    
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat/enviar'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'sender_id': senderId,
          'content': conteudo,
        }),
      );

      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> criarOuBuscarChat({
    required String userId,
    required String adminId,
  }) async {
    try {
      print('Criando/buscando chat para usuário $userId com admin $adminId');
    
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat/criar'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuario_id': userId,
          'admin_id': adminId,
        }),
      );

      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          print('Chat criado/encontrado com sucesso: $responseData');
          return responseData['data']; // Return only the data portion
        }
      }
    
      throw Exception('Erro na criação do chat: ${response.statusCode}');
    } catch (e) {
      print('Erro ao criar/buscar chat: $e');
      return null;
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userData['idusuarios'].toString());
    await prefs.setString('usuario_dados', jsonEncode(userData));
    print('Dados do usuário salvos: ${userData['idusuarios']}');
  }
}