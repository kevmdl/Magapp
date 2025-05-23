import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/tela_principal.dart';
import 'package:maga_app/src/pages/tela_confirmacao.dart';
import 'package:validatorless/validatorless.dart';
import 'package:maga_app/src/services/auth_service.dart';

class TelaRegistrar extends StatefulWidget {
  const TelaRegistrar({super.key});

  @override
  State<TelaRegistrar> createState() => _TelaRegistrarState();
}

class _TelaRegistrarState extends State<TelaRegistrar> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    setState(() => _isLoading = true);

    try {
      // Limpa os dados antes de enviar
      final email = _emailController.text.trim();
      final nome = _nomeController.text.trim();
      final telefone = _telefoneController.text.trim();
      final senha = _senhaController.text;

      final sucesso = await _authService.register(
        email,
        nome,
        telefone,
        senha,
      );

      if (sucesso) {
        // Se o registro foi bem sucedido
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TelaConfirmacao(
                proximaTela: TelaPrincipal(),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao registrar usuário. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F59F7), Color(0xFF020e26)],
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
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Já tem conta? Login",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Registrar",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text("Digite seu email"),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: "Ex: email23@gmail.com",
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
                          const Text("Nome completo"),
                          TextFormField(
                            controller: _nomeController,
                            decoration: InputDecoration(
                              hintText: "Digite seu nome completo",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: Validatorless.required('Nome é obrigatório'),
                          ),
                          const SizedBox(height: 10),
                          const Text("Número de contato"),
                          TextFormField(
                            controller: _telefoneController,
                            decoration: InputDecoration(
                              hintText: "Digite seu número de contato",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: Validatorless.multiple([
                              Validatorless.required('Telefone é obrigatório'),
                              Validatorless.number('Apenas números'),
                              Validatorless.min(11, 'Telefone inválido'),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          const Text("Digite sua senha"),
                          TextFormField(
                            controller: _senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: "Senha...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: Validatorless.multiple([
                              Validatorless.required('Senha obrigatória'),
                              Validatorless.min(6, 'Senha deve ter no mínimo 6 caracteres'),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF063FBA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading ? null : _registrarUsuario,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Center(child: Text("Registrar")),
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
                                side: const BorderSide(color: Colors.grey),
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
