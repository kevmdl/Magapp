import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/ai_menupage.dart';
import 'package:maga_app/src/pages/tela_login.dart';
import 'package:maga_app/src/pages/sup_chatscreen.dart'; 
import 'package:maga_app/src/pages/tela_pedido.dart'; 
import 'package:maga_app/src/pages/tela_perfil.dart';
import 'package:maga_app/src/pages/tela_dashboard_admin.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TelaPrincipal(),
  ));
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _userPermission = 0;

  @override
  void initState() {
    super.initState();
    _loadUserPermission();
  }

  Future<void> _loadUserPermission() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPermission = prefs.getInt('user_permission') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F59F7), Color(0xFF020e26)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      PopupMenuButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(0xFF063FBA),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Text("Usuário"),
                              ],
                            ),
                            onTap: () {
                              Future.delayed(
                                const Duration(seconds: 0),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TelaPerfil()),
                                ),
                              );
                            },
                          ),
                          if (_userPermission == 1) // Only show if user has admin permission
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Color(0xFF063FBA),
                                    child: Icon(Icons.admin_panel_settings, color: Colors.white),
                                  ),
                                  SizedBox(width: 10),
                                  Text("Área Administrativa"),
                                ],
                              ),                              onTap: () {
                                Future.delayed(
                                  const Duration(seconds: 0),
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TelaDashboardAdmin()),
                                  ),
                                );
                              },
                            ),
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                Icon(Icons.exit_to_app, color: Color(0xFF063FBA)),
                                SizedBox(width: 10),
                                Text("Sair"),
                              ],
                            ),
                            onTap: () {
                              Future.delayed(
                                const Duration(seconds: 0),
                                () => Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TelaLogin()),
                                  (route) => false,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Image.asset(
                    'assets/img/logo_maga_app.png',
                    height: 80,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatScreen()),
                          );
                        },
                        child: _buildIconButton(Icons.person, "Contato"),
                      ),
                      GestureDetector(
                        onTap: () {                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _userPermission == 1 
                                ? const TelaDashboardAdmin() 
                                : const TelaPedido(),
                            ),
                          );
                        },
                        child: _buildIconButton(Icons.list, "Pedidos"),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MenuScreen()),
                          );
                        },
                        child: _buildIconButton(Icons.chat, "IA"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [                      _buildCard(Icons.person, "Contato", "No contato você vai poder falar diretamente com um funcionário, e fazer um pedido"),
                      _buildCardWithImage("IA", "Tire suas dúvidas de maneira mais rápida sem ter que esperar um de nossos atendentes"),                      _buildCard(Icons.list, "Pedidos", "Nesta opção você poderá olhar seus pedidos concluídos", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _userPermission == 1 
                              ? const TelaDashboardAdmin() 
                              : const TelaPedido(),
                          ),
                        );
                      }),                      _buildCard(Icons.description, "Documento", "Função desativada", null),
                      _buildCard(Icons.assignment, "Formulário", "No formulário você pode enviar um pedido para o estabelecimento", () {
                        if (_userPermission == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TelaDashboardAdmin()),
                          );
                        }
                        // Para usuários normais, adicionar navegação futura aqui
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildIconButton(IconData icon, String label) {
    if (label == "IA") {
      return Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF063FBA), Color(0xFF020e26)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
            ),
            padding: const EdgeInsets.all(15),
            child: Image.asset(
              'assets/img/logo_ia.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.black)),
        ],
      );
    }
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF063FBA), Color(0xFF020e26)], 
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          padding: const EdgeInsets.all(15),
          child: Icon(icon, color: Colors.white, size: 30), 
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.black)),
      ],
    );
  }


  Widget _buildCard(IconData icon, String title, String description, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F59F7), Color(0xFF020e26)], 
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCardWithImage(String title, String description) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0F59F7), Color(0xFF020e26)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/img/logo_ia.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
