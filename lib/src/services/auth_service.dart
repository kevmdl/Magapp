import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maga_app/src/config/api_config.dart';
import 'dart:convert';

class AuthService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  AuthService() {
    // Configuração inicial do Dio
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.headers = ApiConfig.headers;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  Future<bool> login(String email, String senha) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: {
        'email': email,
        'senha': senha,
      });
      
      if (response.statusCode == 200 && response.data['token'] != null) {
        // Salva o token e dados do usuário
        await _storage.write(key: 'token', value: response.data['token']);
        
        // Se houver dados do usuário, salve-os também
        if (response.data['user'] != null) {
          await _storage.write(key: 'user', value: jsonEncode(response.data['user']));
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('Erro no login: $e');
      return false;
    }
  }

  Future<bool> register(String email, String nome, String telefone, String senha) async {
    try {
      final response = await _dio.post(ApiConfig.register, data: {
        'email': email,
        'nome': nome,
        'telefone': telefone,
        'senha': senha,
      });
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Erro no registro: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final userJson = await _storage.read(key: 'user');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }
  
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      final response = await _dio.get(
        ApiConfig.verifyToken,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao verificar token: $e');
      return false;
    }
  }
}
