import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/tela_login.dart';
import 'package:maga_app/src/pages/tela_recuperacao.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final Map<String, bool> _editingMap = {};
  final Map<String, TextEditingController> _controllers = {};
  String displayName = 'Nome Usuário';
  String displayEmail = 'nomeusuario@example.com';

  @override
  void initState() {
    super.initState();
    _controllers['Nome:'] = TextEditingController(text: displayName);
    _controllers['Email:'] = TextEditingController(text: displayEmail);
    _controllers['Celular:'] = TextEditingController(text: '** *****-1234');
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        
          Container(
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
                    
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/img/perfil.png'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        displayEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfo("Nome:", "Nome Usuário"),
                            _buildInfo("Email:", "nomeusuario@example.com"),
                            _buildInfo("Celular:", "** *****-1234"),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                backgroundColor: const Color(0xFF063FBA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TelaRecuperacao(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Alterar senha",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                backgroundColor: const Color(0xFF063FBA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TelaLogin()),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                "Sair",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Botão de voltar
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para exibir informações
  Widget _buildInfo(String label, String value) {
    _editingMap[label] ??= false;
    _controllers[label] ??= TextEditingController(text: value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _editingMap[label]!
                    ? TextField(
                        controller: _controllers[label],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.black54),
                      )
                    : Text(
                        _controllers[label]!.text,
                        style: const TextStyle(color: Colors.black54),
                      ),
              ),
              IconButton(
                icon: Icon(
                  _editingMap[label]! ? Icons.check : Icons.edit,
                  size: 20,
                  color: const Color(0xFF063FBA),
                ),
                onPressed: () {
                  setState(() {
                    _editingMap[label] = !_editingMap[label]!;
                    if (!_editingMap[label]!) {
                      if (label == 'Nome:') {
                        displayName = _controllers[label]!.text;
                      } else if (label == 'Email:') {
                        displayEmail = _controllers[label]!.text;
                      }
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
