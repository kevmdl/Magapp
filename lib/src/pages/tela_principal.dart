import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/ai_menupage.dart';
import 'package:maga_app/src/pages/tela_login.dart';
import 'package:maga_app/src/pages/sup_chatscreen.dart'; // Adicionar este import
import 'package:maga_app/src/pages/tela_pedido.dart'; // Adicionar este import

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TelaPrincipal(),
  ));
}

class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F59F7), Color(0xFF020e26)], // Azul gradiente
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
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
                        icon: Icon(Icons.menu, color: Colors.black),
                        offset: Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(0xFF063FBA),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Text("Usuário"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            child: Row(
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
                                  MaterialPageRoute(builder: (context) => TelaLogin()),
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
                  SizedBox(height: 5), // Ajustado o espaçamento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen()),
                          );
                        },
                        child: _buildIconButton(Icons.person, "Contato"),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TelaPedido()),
                          );
                        },
                        child: _buildIconButton(Icons.list, "Pedidos"),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MenuScreen()),
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
                    children: [
                      _buildCard(Icons.person, "Contato", "No contato você vai poder falar diretamente com um funcionário, e fazer um pedido"),
                      _buildCardWithImage("IA", "Tire suas dúvidas de maneira mais rápida sem ter que esperar um de nossos atendentes"),
                      _buildCard(Icons.list, "Pedidos", "Nesta opção você poderá olhar seus pedidos concluídos"),
                      _buildCard(Icons.description, "Documento", "Essa função serve para enviar o arquivo para verificação."),
                      _buildCard(Icons.assignment, "Formulário", "No formulário você pode enviar um pedido para o estabelecimento"),
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

  // Função para construir os botões circulares
  Widget _buildIconButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF063FBA), Color(0xFF020e26)], // Azul gradiente
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          padding: EdgeInsets.all(15),
          child: Icon(icon, color: Colors.white, size: 30), // Ícone branco
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.black)),
      ],
    );
  }

  // Função para construir os cards brancos
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F59F7), Color(0xFF020e26)], // Azul gradiente
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: Colors.white, size: 30), // Ícone branco
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text(description, style: TextStyle(fontSize: 14, color: Colors.black87)),
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

  // Adicione este novo método para construir o card com imagem
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
              decoration: BoxDecoration(
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
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(description, style: TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
