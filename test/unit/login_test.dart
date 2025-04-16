import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maga_app/src/pages/tela_login.dart';
import 'package:maga_app/src/pages/tela_principal.dart';
import '../mocks/auth_mock.dart';

void main() {
  // Testes unitários do serviço de autenticação
  group('AuthMock login tests', () {
    test('Login bem-sucedido', () {
      final auth = AuthMock();
      final result = auth.login('test', 'password');
      expect(result, true);
    });

    test('Login com credenciais inválidas', () {
      final auth = AuthMock();
      final result = auth.login('usuario_invalido', 'senha_incorreta');
      expect(result, false);
    });

    test('Login com email', () {
      final auth = AuthMock();
      final result = auth.loginWithEmail('test@example.com', 'password123');
      expect(result, true);
    });
  });

  // Testes de widget para a tela de login
  group('TelaLogin widget tests', () {
    testWidgets('Deve encontrar campos de email e senha', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      expect(find.text('Digite seu email:'), findsOneWidget);
      expect(find.text('Digite sua senha:'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(2));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Deve mostrar erros quando campos estão vazios', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      await tester.tap(find.text('Login'));
      await tester.pump();
      
      expect(find.text('E-mail obrigatório'), findsOneWidget);
      expect(find.text('Senha obrigatória'), findsOneWidget);
    });

    testWidgets('Deve validar formato de email', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      await tester.enterText(find.byType(TextFormField).first, 'emailinvalido');
      await tester.tap(find.text('Login'));
      await tester.pump();
      
      expect(find.text('E-mail inválido'), findsOneWidget);
    });

    testWidgets('Deve validar comprimento da senha', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Login'));
      await tester.pump();
      
      expect(find.text('Senha deve ter no mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('Deve navegar para tela principal quando login bem sucedido', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      expect(find.byType(TelaPrincipal), findsOneWidget);
    });
  });
}