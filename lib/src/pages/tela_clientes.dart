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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
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
    );
  }

  void _editarCliente(BuildContext context, ClientModel client) {
    // Implement edit logic
  }
}
