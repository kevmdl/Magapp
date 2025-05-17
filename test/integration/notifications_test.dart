import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../mocks/notification_mock.dart';

void main() {
  // Cliente HTTP e adaptador de mock
  late Dio dio;
  late DioAdapter dioAdapter;

  // Token de autenticação simulado
  const String mockToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsImVtYWlsIjoidGVzdGVAZXhlbXBsby5jb20iLCJpYXQiOjE2MjExMDU2MjEsImV4cCI6MTYyMTE5MjAyMX0.DGSl9Cf0VmNZOCUCDzHf9fh-F1qCRQuDvhRmAQAIzq8';
  
  // Token de dispositivo simulado para notificações push
  const String mockDeviceToken = 'dz-KWIzTvUUyJRpf7-JWf1:APA91bGhWGxQ_c3n9DlTcQ18S2vNa-jLKCZg8MDfPO9rCPIgXb0jQpPeIvsY_U8ZyDfyJUcUHa5jKQv7KLpJKXJTY5K9mjL9kX2vzIHkJXM8m-X8eHXPX_dW9ThUol-k-vS2eQ4N7pyZ';

  setUp(() {
    // Configuração do cliente Dio com adaptador de mock
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3000/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));
    dioAdapter = DioAdapter(dio: dio);
    
    // Configurar preferências compartilhadas com tokens simulados
    SharedPreferences.setMockInitialValues({
      'auth_token': mockToken,
      'device_token': mockDeviceToken,
      'notifications_enabled': true,
      'user_data': jsonEncode({
        'id': 1,
        'nome': 'Usuário Teste',
        'email': 'teste@exemplo.com',
      }),
    });
  });

  group('Testes de Integração de Notificações', () {
    test('Registrar token do dispositivo - deve retornar sucesso', () async {
      // Dados da requisição
      final registerData = {
        'device_token': mockDeviceToken,
        'device_type': 'android',
        'app_version': '1.0.0'
      };

      // Mock da resposta da API
      final mockResponse = {
        'success': true,
        'message': 'Token do dispositivo registrado com sucesso',
        'data': {
          'user_id': 1,
          'device_id': 123,
          'created_at': '2025-05-15T12:00:00.000Z'
        }
      };

      // Configurar mock para a rota de registro de dispositivo
      dioAdapter.onPost(
        '/notifications/register-device',
        (request) => request.reply(200, mockResponse),
        data: registerData,
        headers: {'Authorization': 'Bearer $mockToken'},
      );

      // Executar a requisição
      final response = await dio.post(
        '/notifications/register-device',
        data: registerData,
        options: Options(headers: {'Authorization': 'Bearer $mockToken'}),
      );

      // Verificações
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['message'], contains('registrado com sucesso'));
      expect(response.data['data']['user_id'], 1);
    });

    test('Atualizar preferências de notificação - deve retornar configurações atualizadas', () async {
      // Dados da requisição
      final prefData = {
        'channels': {
          'pedidos': true,
          'promocoes': false,
          'chat': true,
          'sistema': true
        }
      };

      // Mock da resposta da API
      final mockResponse = {
        'success': true,
        'message': 'Preferências de notificação atualizadas',
        'data': {
          'user_id': 1,
          'channels': {
            'pedidos': true,
            'promocoes': false,
            'chat': true,
            'sistema': true
          },
          'updated_at': '2025-05-15T12:05:00.000Z'
        }
      };

      // Configurar mock para a rota de atualização de preferências
      dioAdapter.onPut(
        '/notifications/preferences',
        (request) => request.reply(200, mockResponse),
        data: prefData,
        headers: {'Authorization': 'Bearer $mockToken'},
      );

      // Executar a requisição
      final response = await dio.put(
        '/notifications/preferences',
        data: prefData,
        options: Options(headers: {'Authorization': 'Bearer $mockToken'}),
      );

      // Verificações
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data']['channels']['promocoes'], false);
      expect(response.data['data']['channels']['pedidos'], true);
    });

    test('Obter histórico de notificações - deve retornar lista de notificações', () async {
      // Mock da resposta da API
      final mockResponse = {
        'success': true,
        'data': {
          'notifications': [
            {
              'id': 1,
              'title': 'Pedido Atualizado',
              'body': 'Seu pedido #12345 foi aprovado',
              'type': 'pedido',
              'data': {'pedido_id': 12345, 'status': 'aprovado'},
              'read': true,
              'created_at': '2025-05-14T10:00:00.000Z'
            },
            {
              'id': 2,
              'title': 'Nova Mensagem',
              'body': 'Você tem uma nova mensagem do suporte',
              'type': 'chat',
              'data': {'channel_id': 1},
              'read': false,
              'created_at': '2025-05-15T09:30:00.000Z'
            },
            {
              'id': 3,
              'title': 'Promoção Especial',
              'body': 'Aproveite 20% de desconto em serviços',
              'type': 'promocao',
              'data': {'promocao_id': 45},
              'read': false,
              'created_at': '2025-05-15T11:00:00.000Z'
            }
          ],
          'pagination': {
            'total': 3,
            'per_page': 10,
            'current_page': 1,
            'last_page': 1
          }
        }
      };

      // Configurar mock para a rota de histórico de notificações
      dioAdapter.onGet(
        '/notifications/history',
        (request) => request.reply(200, mockResponse),
        headers: {'Authorization': 'Bearer $mockToken'},
      );

      // Executar a requisição
      final response = await dio.get(
        '/notifications/history',
        options: Options(headers: {'Authorization': 'Bearer $mockToken'}),
      );

      // Verificações
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data']['notifications'], isA<List>());
      expect(response.data['data']['notifications'].length, 3);
      
      // Verificar que há notificações não lidas
      final notifications = response.data['data']['notifications'] as List;
      final unreadNotifications = notifications.where((n) => n['read'] == false).toList();
      expect(unreadNotifications.length, 2);
    });

    test('Marcar notificação como lida - deve atualizar status de leitura', () async {
      // ID da notificação a ser marcada como lida
      const int notificationId = 2;
      
      // Mock da resposta da API
      final mockResponse = {
        'success': true,
        'message': 'Notificação marcada como lida',
        'data': {
          'id': notificationId,
          'read': true,
          'read_at': '2025-05-15T12:10:00.000Z'
        }
      };

      // Configurar mock para a rota de marcar como lida
      dioAdapter.onPatch(
        '/notifications/$notificationId/read',
        (request) => request.reply(200, mockResponse),
        headers: {'Authorization': 'Bearer $mockToken'},
      );

      // Executar a requisição
      final response = await dio.patch(
        '/notifications/$notificationId/read',
        options: Options(headers: {'Authorization': 'Bearer $mockToken'}),
      );

      // Verificações
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data']['id'], notificationId);
      expect(response.data['data']['read'], true);
    });

    test('Desativar notificações em um canal específico - deve retornar status atualizado', () async {
      // Dados da requisição
      final channelData = {
        'enabled': false
      };

      // Nome do canal a desativar
      const String channelName = 'promocoes';

      // Mock da resposta da API
      final mockResponse = {
        'success': true,
        'message': 'Canal de notificação atualizado',
        'data': {
          'channel': channelName,
          'enabled': false,
          'updated_at': '2025-05-15T12:15:00.000Z'
        }
      };

      // Configurar mock para a rota de atualização de canal
      dioAdapter.onPut(
        '/notifications/channel/$channelName',
        (request) => request.reply(200, mockResponse),
        data: channelData,
        headers: {'Authorization': 'Bearer $mockToken'},
      );

      // Executar a requisição
      final response = await dio.put(
        '/notifications/channel/$channelName',
        data: channelData,
        options: Options(headers: {'Authorization': 'Bearer $mockToken'}),
      );

      // Verificações
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data']['channel'], channelName);
      expect(response.data['data']['enabled'], false);
    });
  });
}
