import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maga_app/src/pages/tela_registrar.dart';
import '../mocks/auth_mock.dart';

void main() {
 
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

  group('TelaRegistrar widget tests', () {
    testWidgets('Deve encontrar todos os campos de registro', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1080, 1920);
      
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      expect(find.text('Digite seu email'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Número de contato'), findsOneWidget);
      expect(find.text('Digite sua senha'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(4));
      expect(find.widgetWithText(ElevatedButton, 'Registrar'), findsOneWidget);
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Deve mostrar erros quando campos estão vazios', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1080, 1920);
      
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      await tester.dragUntilVisible(
        find.widgetWithText(ElevatedButton, 'Registrar'),
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );
      
      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar'));
      await tester.pump();
      
      expect(find.text('E-mail obrigatório'), findsOneWidget);
      expect(find.text('Nome é obrigatório'), findsOneWidget);
      expect(find.text('Telefone é obrigatório'), findsOneWidget);
      expect(find.text('Senha obrigatória'), findsOneWidget);
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Deve validar formato de email', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1080, 1920);
      
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      await tester.enterText(find.byType(TextFormField).first, 'emailinvalido');
      
      await tester.dragUntilVisible(
        find.widgetWithText(ElevatedButton, 'Registrar'),
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );
      
      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar'));
      await tester.pump();
      
      expect(find.text('E-mail inválido'), findsOneWidget);
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Deve validar número de telefone', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1080, 1920);
      
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      await tester.enterText(find.byType(TextFormField).at(2), '12345');
      
      await tester.dragUntilVisible(
        find.widgetWithText(ElevatedButton, 'Registrar'),
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );
      
      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar'));
      await tester.pump();
      
      expect(find.text('Telefone inválido'), findsOneWidget);
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Deve navegar para confirmação quando registro bem sucedido', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1080, 1920);
      
      await tester.pumpWidget(const MaterialApp(home: TelaRegistrar()));
      
      await tester.enterText(find.byType(TextFormField).at(0), 'teste@exemplo.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Nome Teste');
      await tester.enterText(find.byType(TextFormField).at(2), '11987654321');
      await tester.enterText(find.byType(TextFormField).at(3), 'senha123');
      
      await tester.dragUntilVisible(
        find.widgetWithText(ElevatedButton, 'Registrar'),
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar'));
      await tester.pumpAndSettle();
      
      // Verifica se mostra mensagem de sucesso
      expect(find.text('Usuário registrado com sucesso!'), findsOneWidget);
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}