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
        Uri.parse('$_baseUrl/login/demo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Armazenar o token
        _authToken = responseData['token'];
        
        // Salvar o token para persistência
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _authToken!);
        
        // Salvar dados do usuário, se disponíveis
        if (responseData['usuario'] != null) {
          await prefs.setString('usuario_dados', jsonEncode(responseData['usuario']));
        }
        
        return {
          'success': true,
          'message': responseData['message'],
          'usuario': responseData['usuario'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erro ao fazer login',
        };
      }
    } catch (e) {
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
  static Future<bool> enviarMensagem({
    required String remetenteId, 
    required String destinatarioId, 
    required String conteudo
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
}