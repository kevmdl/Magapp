import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/tela_clientes.dart';
import 'package:maga_app/src/pages/tela_pedido_adm.dart';
import 'package:maga_app/src/pages/ai_chatscreen.dart';
import 'package:maga_app/src/pages/tela_login.dart';
import 'package:maga_app/src/services/api_service.dart';

class TelaDashboardAdmin extends StatelessWidget {
  const TelaDashboardAdmin({super.key});
  
  // Método para realizar logout
  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TelaLogin()),
        (route) => false,
      );
    }
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
            // Barra superior branca com o botão de menu à esquerda
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
                        tooltip: '', // Removendo o texto "mostrar menu"
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
                                  child: Icon(Icons.logout, color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Text("Sair"),
                              ],
                            ),
                            onTap: () {
                              Future.delayed(
                                const Duration(seconds: 0),
                                () => _logout(context),
                              );
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                  const Text(
                    'Bem-vindo, Administrador',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
            // Conteúdo principal com cards
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      _buildAdminCard(
                        context,
                        Icons.people,
                        'Clientes',
                        'Gerenciar clientes cadastrados no sistema',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TelaClientes()),
                        ),
                      ),
                      _buildAdminCard(
                        context,
                        Icons.list_alt,
                        'Pedidos',
                        'Gerenciar pedidos recebidos dos clientes',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TelaPedidoAdmin()),
                        ),
                      ),
                      _buildAdminCard(
                        context,
                        Icons.chat_bubble,
                        'Chatbot IA',
                        'Configurar o chatbot de inteligência artificial',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatScreen()),
                        ),
                      ),
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

  Widget _buildAdminCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
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
                      Text(
                        title, 
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description, 
                        style: const TextStyle(
                          fontSize: 14, 
                          color: Colors.black87
                        )
                      ),
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
}
