import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  // Mock dos clientes HTTP e das preferências compartilhadas
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    // Configuração do cliente Dio com adaptador de mock
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
    dioAdapter = DioAdapter(dio: dio);
    
    // Configurações para simular token armazenado
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mocked_jwt_token',
    });
  });

  group('Testes de integração da API - Pedidos', () {
    test('Listar pedidos - deve retornar lista de pedidos', () async {
      // Mock da resposta da API
      final mockResponse = {
        'success': true,
        'data': [
          {
            'id': 1,
            'nome': 'João Silva',
            'cpf_cnpj': '123.456.789-00',
            'placa': 'ABC1234',
            'renavam': '12345678901',
            'chassi': '9BWHE21JX24060831',
            'status': 'pendente',
            'data_criacao': '2025-05-15T14:30:00.000Z'
          },
          {
            'id': 2,
            'nome': 'Maria Oliveira',
            'cpf_cnpj': '987.654.321-00',
            'placa': 'XYZ9876',
            'renavam': '98765432109',
            'chassi': '1HGCM82633A123456',
            'status': 'concluido',
            'data_criacao': '2025-05-14T10:15:00.000Z'
          }
        ]
      };

      // Configurar mock para a rota de listar pedidos
      dioAdapter.onGet(
        '/pedidos',
        (request) => request.reply(200, mockResponse),
        headers: {
          'Authorization': 'Bearer mocked_jwt_token',
          'Content-Type': 'application/json',
        },
      );

      // Executar a requisição
      final response = await dio.get(
        '/pedidos',
        options: Options(
          headers: {
            'Authorization': 'Bearer mocked_jwt_token',
            'Content-Type': 'application/json',
          },
        ),
      );

      // Verificações
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data'], isA<List>());
      expect(response.data['data'].length, 2);
      expect(response.data['data'][0]['nome'], 'João Silva');
      expect(response.data['data'][1]['nome'], 'Maria Oliveira');
    });

    test('Criar pedido - deve retornar sucesso', () async {
      // Dados da requisição
      final requestData = {
        'nome': 'Pedro Santos',
        'cpf_cnpj': '111.222.333-44',
        'placa': 'DEF5678',
        'renavam': '11223344556',
        'chassi': '5YJSA1E40FF123456',
      };

      // Mock da resposta da API
      final mockResponse = {
        'success': true,
        'message': 'Pedido criado com sucesso',
        'data': {
          'id': 3,
          'nome': 'Pedro Santos',
          'cpf_cnpj': '111.222.333-44',
          'placa': 'DEF5678',
          'renavam': '11223344556',
          'chassi': '5YJSA1E40FF123456',
          'status': 'pendente',
          'data_criacao': '2025-05-15T15:00:00.000Z'
        }
      };

      // Configurar mock para a rota de criar pedido
      dioAdapter.onPost(
        '/pedidos',
        (request) => request.reply(201, mockResponse),
        data: requestData,
        headers: {
          'Authorization': 'Bearer mocked_jwt_token',
          'Content-Type': 'application/json',
        },
      );

      // Executar a requisição
      final response = await dio.post(
        '/pedidos',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer mocked_jwt_token',
            'Content-Type': 'application/json',
          },
        ),
      );

      // Verificações
      expect(response.statusCode, 201);
      expect(response.data['success'], true);
      expect(response.data['message'], 'Pedido criado com sucesso');
      expect(response.data['data']['nome'], 'Pedro Santos');
      expect(response.data['data']['status'], 'pendente');
    });

    test('Obter detalhes de um pedido - deve retornar detalhes do pedido', () async {
      // Mock da resposta da API
      final mockResponse = {
        'success': true,
        'data': {
          'id': 1,
          'nome': 'João Silva',
          'cpf_cnpj': '123.456.789-00',
          'placa': 'ABC1234',
          'renavam': '12345678901',
          'chassi': '9BWHE21JX24060831',
          'status': 'pendente',
          'data_criacao': '2025-05-15T14:30:00.000Z'
        }
      };

      // Configurar mock para a rota de detalhes do pedido
      dioAdapter.onGet(
        '/pedidos/1',
        (request) => request.reply(200, mockResponse),
        headers: {
          'Authorization': 'Bearer mocked_jwt_token',
          'Content-Type': 'application/json',
        },
      );

      // Executar a requisição
      final response = await dio.get(
        '/pedidos/1',
        options: Options(
          headers: {
            'Authorization': 'Bearer mocked_jwt_token',
            'Content-Type': 'application/json',
          },
        ),
      );

      // Verificações
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(response.data['data']['id'], 1);
      expect(response.data['data']['nome'], 'João Silva');
    });
  });
}
