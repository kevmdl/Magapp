import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Adicione este import
import '../services/api_service.dart';

class TelaPedido extends StatefulWidget {
  const TelaPedido({super.key});

  @override
  State<TelaPedido> createState() => _TelaPedidoState();
}

class _TelaPedidoState extends State<TelaPedido> {
  List<Map<String, dynamic>> _meusPedidos = [];
  bool _isLoading = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserPedidos();
  }

  Future<void> _loadUserPedidos() async {
    setState(() => _isLoading = true);
    try {
      // Pegar o email do usuário logado
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('usuario_dados');
      
      if (userData != null) {
        final user = jsonDecode(userData);
        _userEmail = user['email'];
        print('User email: $_userEmail'); // Debug
        
        // Buscar apenas os pedidos do usuário logado
        if (_userEmail != null) {
          final meusPedidos = await ApiService.getUserPedidos(_userEmail!);
          print('Pedidos do usuário encontrados: ${meusPedidos.length}'); // Debug
          
          if (mounted) {
            setState(() {
              _meusPedidos = meusPedidos;
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Email do usuário não encontrado');
        }
      } else {
        throw Exception('Dados do usuário não encontrados');
      }
    } catch (e) {
      print('Erro ao carregar pedidos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
        backgroundColor: const Color(0xFF0F59F7),
        foregroundColor: Colors.white,
      ),
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
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _meusPedidos.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum pedido encontrado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _meusPedidos.length,
                            itemBuilder: (context, index) {
                              final pedido = _meusPedidos[index];
                              return _buildPedidoCard(pedido);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F59F7),
        onPressed: _loadUserPedidos,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildPedidoCard(Map<String, dynamic> pedido) {
    final idPedido = pedido['idpedidos']?.toString() ?? 'N/A';
    final concluido = int.tryParse(pedido['concluido']?.toString() ?? '0') ?? 0;
    final dataConclusao = pedido['data_conclusao'] != null
        ? DateTime.parse(pedido['data_conclusao'])
        : null;
    final mensagemRejeicao = pedido['mensagem_rejeicao'];

    String getStatusText() {
      switch (concluido) {
        case 1:
          return 'Aprovado';
        case 2:
          return 'Rejeitado';
        default:
          return 'Em Análise';
      }
    }

    Color getStatusColor() {
      switch (concluido) {
        case 1:
          return Colors.green;
        case 2:
          return Colors.red;
        default:
          return Colors.orange;
      }
    }

    IconData getStatusIcon() {
      switch (concluido) {
        case 1:
          return Icons.check_circle;
        case 2:
          return Icons.cancel;
        default:
          return Icons.hourglass_empty;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: getStatusColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getStatusIcon(),
                color: getStatusColor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #$idPedido',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Status: ${getStatusText()}',
                    style: TextStyle(
                      color: getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Veículo: ${pedido['modelo'] ?? 'N/A'} - ${pedido['cor'] ?? 'N/A'}'),
            Text('Placa: ${pedido['placa'] ?? 'N/A'}'),
            if (dataConclusao != null)
              Text(
                'Processado em: ${DateFormat('dd/MM/yyyy HH:mm').format(dataConclusao)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  'Detalhes do Veículo:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Placa', pedido['placa']),
                _buildDetailRow('Renavam', pedido['renavam']),
                _buildDetailRow('Chassi', pedido['chassi']),
                _buildDetailRow('Modelo', pedido['modelo']),
                _buildDetailRow('Cor', pedido['cor']),
                
                // Mostrar mensagem de rejeição se houver
                if (concluido == 2 && mensagemRejeicao != null && mensagemRejeicao.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Motivo da Rejeição:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mensagemRejeicao,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Não informado',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
