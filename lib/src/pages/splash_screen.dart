import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  
  const SplashScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late double _progressValue;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn)
    );
    
    _progressValue = 0.0;
    _fadeController.forward();
    
    // Progresso suave
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progressValue < 1.0) {
          _progressValue += 0.01; // Incremento menor para movimento mais suave
        } else {
          timer.cancel();
          // Aguardar um momento antes de navegar
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => widget.nextScreen)
            );
          });
        }
      });
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/img/logo_maga_app.png',
                width: 180,
                height: 180,
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  value: _progressValue,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
