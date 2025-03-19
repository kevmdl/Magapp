import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/admin_chat_screen.dart';

class TelaClientes extends StatelessWidget {
  const TelaClientes({super.key});

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
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Gerenciamento de Clientes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: 2,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF063FBA),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              index == 0 ? 'João Silva' : 'Maria Santos',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: #${1000 + index}'),
                                Text(index == 0 ? 'joao@email.com' : 'maria@email.com'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat),
                                  color: const Color(0xFF063FBA),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminChatScreen(
                                          clientName: index == 0 ? 'João Silva' : 'Maria Santos',
                                          clientEmail: index == 0 ? 'joao@email.com' : 'maria@email.com',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: const Color(0xFF063FBA),
                                  onPressed: () => _editarCliente(context, index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye),
                                  color: const Color(0xFF063FBA),
                                  onPressed: () => _mostrarDetalhes(context, index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF063FBA),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _adicionarCliente(context),
      ),
    );
  }

  void _mostrarDetalhes(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF063FBA)),
            const SizedBox(width: 10),
            Text('Cliente ${index + 1}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalheItem('ID:', '#${1000 + index}'),
            _buildDetalheItem('Email:', index == 0 ? 'joao@email.com' : 'maria@email.com'),
            _buildDetalheItem('Telefone:', index == 0 ? '(11) 99999-1234' : '(11) 99999-5678'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF063FBA)),
            ),
          ),
        ],
      ),
    );
  }

  void _editarCliente(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Editar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nome'),
              controller: TextEditingController(text: index == 0 ? 'João Silva' : 'Maria Santos'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              controller: TextEditingController(text: index == 0 ? 'joao@email.com' : 'maria@email.com'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Implementar lógica de salvar
              Navigator.pop(context);
            },
            child: const Text(
              'Salvar',
              style: TextStyle(color: Color(0xFF063FBA)),
            ),
          ),
        ],
      ),
    );
  }

  void _adicionarCliente(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Novo Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Implementar lógica de adicionar
              Navigator.pop(context);
            },
            child: const Text(
              'Adicionar',
              style: TextStyle(color: Color(0xFF063FBA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}
