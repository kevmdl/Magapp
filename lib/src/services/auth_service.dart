import 'package:dio/dio.dart' as dio;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maga_app/src/config/api_config.dart';
import 'dart:convert';

class AuthService {
  final dio.Dio _dio = dio.Dio();
  static const _storage = FlutterSecureStorage();

  AuthService() {
    _dio.options.baseUrl = ApiConfig.baseUrl; // Vai usar http://localhost:3000
    _dio.options.headers = ApiConfig.headers;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    
    _dio.interceptors.add(dio.LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
      responseHeader: true,
    ));
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
      print('Iniciando registro com IP: ${ApiConfig.baseUrl}');
      
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'email': email,
          'nome': nome,
          'telefone': telefone,
          'senha': senha,
        },
      );
      
      print('Resposta do servidor: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
      
    } on dio.DioException catch (e) {
      print('Erro de conexão: ${e.message}');
      print('Tipo de erro: ${e.type}');
      print('URL tentada: ${e.requestOptions.uri}');
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
        options: dio.Options(headers: {'Authorization': 'Bearer $token'})
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao verificar token: $e');
      return false;
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: 'user_id', value: userData['id'].toString());
    await _storage.write(key: 'token', value: userData['token']);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }
}
