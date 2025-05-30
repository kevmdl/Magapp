import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maga_app/src/pages/tela_login.dart';
import '../mocks/auth_mock.dart';

void main() {

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


  group('TelaLogin widget tests', () {    testWidgets('Deve encontrar campos de email e senha', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      expect(find.byKey(const Key('welcomeTitleKey')), findsOneWidget);  // Use a key do título de boas-vindas
      expect(find.byKey(const Key('emailFieldKey')), findsOneWidget);  // Use a key do campo de email
      expect(find.byKey(const Key('passwordFieldKey')), findsOneWidget);  // Use a key do campo de senha
      expect(find.byKey(const Key('loginButtonKey')), findsOneWidget);  // Use a key do botão
    });

    testWidgets('Deve mostrar erros quando campos estão vazios', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      await tester.tap(find.byKey(const Key('loginButtonKey')));  // Use a key do botão
      await tester.pump();
      
      expect(find.text('E-mail obrigatório'), findsOneWidget);
      expect(find.text('Senha obrigatória'), findsOneWidget);
    });

    testWidgets('Deve validar formato de email', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      await tester.enterText(find.byType(TextFormField).first, 'emailinvalido');
      await tester.tap(find.byKey(const Key('loginButtonKey')));  // Use a key do botão
      await tester.pump();
      
      expect(find.text('E-mail inválido'), findsOneWidget);
    });

    testWidgets('Deve validar comprimento da senha', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
      
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.byKey(const Key('loginButtonKey')));  // Use a key do botão
      await tester.pump();
      
      expect(find.text('Senha deve ter no mínimo 6 caracteres'), findsOneWidget);
    });    // Teste removido porque faz requisição HTTP real
    // testWidgets('Deve navegar para tela principal quando login bem sucedido', (WidgetTester tester) async {
    //   await tester.pumpWidget(const MaterialApp(home: TelaLogin()));
    //   
    //   await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    //   await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    //   await tester.tap(find.byKey(const Key('loginButtonKey')));  // Use a key do botão
    //   await tester.pumpAndSettle();
    //   
    //   expect(find.byType(TelaPrincipal), findsOneWidget);
    // });
  });
}