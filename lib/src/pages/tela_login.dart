import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/tela_principal.dart';
import 'package:maga_app/src/pages/tela_registrar.dart';
import 'package:maga_app/src/pages/tela_confirmacao.dart';
import 'package:maga_app/src/pages/tela_recuperacao.dart';
import 'package:validatorless/validatorless.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TelaLogin(),
  ));
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F59F7), Color(0xFF020e26)], // Azul gradiente
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/img/logo_maga.png',
                    height: 100,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Bem-vindo ao ",
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: "MAGAPP",
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0518A9)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TelaRegistrar()),
                                  );
                                },
                                child: const Text(
                                  "Não tem conta? Registre-se",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Login",
                            key: Key('loginTitleKey'), // Adicionando key para o título
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 10),
                          const Text("Digite seu email:"),
                          TextFormField(
                            key: const Key('emailFieldKey'), // Adicionando key para o campo de email
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: "Exemplo@....com",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: Validatorless.multiple([
                              Validatorless.required('E-mail obrigatório'),
                              Validatorless.email('E-mail inválido'),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          const Text("Digite sua senha:"),
                          TextFormField(
                            key: const Key('passwordFieldKey'), // Adicionando key para o campo de senha
                            controller: _senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: "Senha",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: Validatorless.multiple([
                              Validatorless.required('Senha obrigatória'),
                              Validatorless.min(6, 'Senha deve ter no mínimo 6 caracteres'),
                            ]),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TelaConfirmacao(
                                      proximaTela: TelaRecuperacao(),
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Esqueci minha senha",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            key: const Key('loginButtonKey'), // Adicionando key para o botão de login
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF063FBA), // Cor do botão alterada
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              final formValid = _formKey.currentState?.validate() ?? false;
                              if (formValid) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TelaPrincipal()),
                                );
                              }
                            },
                            child: const Center(
                              child: Text("Login"),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              "ou",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            onPressed: () {
                              // Lógica de login com Google
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/img/logo_google.png',
                                  height: 24,
                                ),
                                const SizedBox(width: 10),
                                const Text("Continue com Google"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
