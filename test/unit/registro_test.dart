import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maga_app/src/pages/tela_registrar.dart';
import 'package:maga_app/src/pages/tela_confirmacao.dart';
import '../mocks/auth_mock.dart';

void main() {
  // Testes unitários do serviço de autenticação para registro
  group('AuthMock registro tests', () {
    test('Registro com dados válidos', () {
      final auth = AuthMock();
      expect(auth.register('novousuario', 'senha123'), isTrue);
    });

    test('Registro com senha curta', () {
      final auth = AuthMock();
      expect(auth.register('usuario', '12345'), isFalse);
    });

    test('Registro com nome de usuário vazio', () {
      final auth = AuthMock();
      expect(auth.register('', 'senha123'), isFalse);
    });

    test('Registro com todos os campos', () {
      final auth = AuthMock();
      final result = auth.registerWithEmail(
        'novo@exemplo.com',
        'Nome Completo',
        '11987654321',
        'senha123'
      );
      expect(result, true);
    });
  });

  // Testes de widget para a tela de registro
  group('TelaRegistrar widget tests', () {
    testWidgets('Deve encontrar todos os campos de registro', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      expect(find.text('Digite seu email'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Número de contato'), findsOneWidget);
      expect(find.text('Digite sua senha'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(4));
      expect(find.text('Registrar'), findsAtLeast(1));
    });

    testWidgets('Deve mostrar erros quando campos estão vazios', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      await tester.tap(find.text('Registrar').last);
      await tester.pump();
      
      expect(find.text('E-mail obrigatório'), findsOneWidget);
      expect(find.text('Nome é obrigatório'), findsOneWidget);
      expect(find.text('Telefone é obrigatório'), findsOneWidget);
      expect(find.text('Senha obrigatória'), findsOneWidget);
    });

    testWidgets('Deve validar formato de email', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      await tester.enterText(find.byType(TextFormField).first, 'emailinvalido');
      await tester.tap(find.text('Registrar').last);
      await tester.pump();
      
      expect(find.text('E-mail inválido'), findsOneWidget);
    });

    testWidgets('Deve validar número de telefone', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      await tester.enterText(find.byType(TextFormField).at(2), '12345');
      await tester.tap(find.text('Registrar').last);
      await tester.pump();
      
      expect(find.text('Telefone inválido'), findsOneWidget);
    });

    testWidgets('Deve navegar para confirmação quando registro bem sucedido', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      await tester.enterText(find.byType(TextFormField).at(0), 'teste@exemplo.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Nome Teste');
      await tester.enterText(find.byType(TextFormField).at(2), '11987654321');
      await tester.enterText(find.byType(TextFormField).at(3), 'senha123');
      
      await tester.tap(find.text('Registrar').last);
      await tester.pumpAndSettle();
      
      expect(find.byType(TelaConfirmacao), findsOneWidget);
    });
  });
}