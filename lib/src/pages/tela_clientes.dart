import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../widgets/client_card.dart';
import '../services/api_service.dart';

class TelaClientes extends StatefulWidget {
  const TelaClientes({super.key});

  @override
  State<TelaClientes> createState() => _TelaClientesState();
}

class _TelaClientesState extends State<TelaClientes> {
  List<ClientModel> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await ApiService.getClientsWithChats();
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading clients: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(      body: Stack(
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
                    ),                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              // Lista de clientes
                              Expanded(
                                child: _clients.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Nenhum cliente encontrado',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                  itemCount: _clients.length,
                                  itemBuilder: (context, index) {
                                    final client = _clients[index];
                                    return ClientCard(
                                      client: client,
                                      onEdit: () => _editarCliente(context, client),
                                    );
                                  },
                                ),
                              ),
                            ],
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
        onPressed: _loadClients,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
  void _editarCliente(BuildContext context, ClientModel client) {
    // Controladores para os campos do formulário
    final nameController = TextEditingController(text: client.name);
    final emailController = TextEditingController(text: client.email);
    final phoneController = TextEditingController(text: client.phone ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Validar os campos
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos obrigatórios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Montar o objeto de atualização
              final updateData = {
                'nome': nameController.text,
                'email': emailController.text,
                'telefone': phoneController.text,
              };
              
              // Fechar o diálogo
              Navigator.pop(context);
              
              try {
                // Chamar a API para atualizar o cliente
                final success = await ApiService.updateClient(client.id, updateData);
                
                if (success) {
                  // Recarregar a lista
                  _loadClients();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente atualizado com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception('Falha ao atualizar cliente');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao atualizar cliente: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
