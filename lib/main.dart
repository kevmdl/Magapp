import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maga_app/src/pages/tela_login.dart';
import 'package:maga_app/src/pages/tela_principal.dart';
import 'package:maga_app/src/pages/splash_screen.dart';
import 'package:maga_app/src/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authService = AuthService();
  bool _loading = true;
  bool _isAuthenticated = false;
  
  @override
  void initState() {
    super.initState();
    _verificarAutenticacao();
  }
  
  Future<void> _verificarAutenticacao() async {
    final isAuth = await _authService.isAuthenticated();
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget initialScreen;
    
    if (_loading) {
      initialScreen = const SplashScreen(nextScreen: TelaLogin());
    } else if (_isAuthenticated) {
      initialScreen = const TelaPrincipal();
    } else {
      initialScreen = const TelaLogin();
    }
    
    return MaterialApp(
      title: 'Maga App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0F59F7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F59F7)),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: initialScreen,
    );
  }
}
