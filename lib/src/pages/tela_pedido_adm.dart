import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'tela_pedido.dart';

class TelaPedidoAdmin extends StatefulWidget {
  const TelaPedidoAdmin({super.key});

  @override
  State<TelaPedidoAdmin> createState() => _TelaPedidoAdminState();
}

class _TelaPedidoAdminState extends State<TelaPedidoAdmin> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPedidos();
  }

  Future<void> _loadPedidos() async {
    setState(() => _isLoading = true);
    try {
      final pedidos = await ApiService.getAllPedidos();
      if (mounted) {
        setState(() {
          _pedidos = pedidos;
          _isLoading = false;
        });
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
                    'Gerenciamento de Pedidos',
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
                        : _pedidos.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum pedido encontrado',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _pedidos.length,
                                itemBuilder: (context, index) {
                                  final pedido = _pedidos[index];
                                  return _buildPedidoCard(pedido);
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
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF0F59F7),
              onPressed: _loadPedidos,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(Map<String, dynamic> pedido) {
    final idPedido = pedido['idpedidos']?.toString() ?? 'N/A';
    // Adicionando debug print para ver o valor bruto
    print('Valor bruto de concluido: ${pedido['concluido']}');
    
    // Convertendo concluido para int de forma segura
    final concluido = pedido['concluido'] is int 
        ? pedido['concluido'] 
        : int.tryParse(pedido['concluido']?.toString() ?? '0') ?? 0;
    
    // Debug print para verificar o valor convertido
    print('Valor convertido de concluido: $concluido');

    final dataConclusao = pedido['data_conclusao'] != null
        ? DateTime.parse(pedido['data_conclusao'])
        : null;

    String getStatusText() {
      switch (concluido) {
        case 1:
          return 'Aprovado';
        case 2:
          return 'Rejeitado';
        default:
          return 'Pendente';
      }
    }

    Color getStatusColor() {
      switch (concluido) {
        case 1:
          return Colors.green;
        case 2:
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: getStatusColor(),
                shape: BoxShape.circle,
              ),
              margin: const EdgeInsets.only(right: 8),
            ),
            Expanded(
              child: Text(
                'Pedido #$idPedido',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${pedido['nome_cliente'] ?? 'Não informado'}'),
            Text('Status: ${getStatusText()}'),
            if (dataConclusao != null)
              Text(
                  'Concluído em: ${DateFormat('dd/MM/yyyy HH:mm').format(dataConclusao)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Placa', pedido['placa']),
                _buildInfoRow('Renavam', pedido['renavam']),
                _buildInfoRow('Chassi', pedido['chassi']),
                _buildInfoRow('Modelo', pedido['modelo']),
                _buildInfoRow('Cor', pedido['cor']),
                const Divider(),
                // Updated condition to check if pedido is not concluded
                if (concluido != 1 && concluido != 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        'Aprovar',
                        Icons.check_circle,
                        Colors.green,
                        () => _updatePedidoStatus(pedido['idpedidos'], 1),
                      ),
                      _buildActionButton(
                        'Rejeitar',
                        Icons.cancel,
                        Colors.red,
                        () => _updatePedidoStatus(pedido['idpedidos'], 2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Não informado'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _updatePedidoStatus(dynamic pedidoId, int concluido) async {
    if (pedidoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID do pedido inválido')),
      );
      return;
    }

    try {
      final success = await ApiService.updatePedidoStatus(
        pedidoId.toString(),
        concluido,
      );

      if (!success) {
        throw Exception('Falha ao atualizar status');
      }

      await _loadPedidos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido ${concluido == 1 ? 'aprovado' : 'rejeitado'} com sucesso'),
            backgroundColor: concluido == 1 ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Exemplo de uso correto do contexto para navegação dentro de um método:
// Chame este método passando o contexto correto, por exemplo, em um botão ou evento.

void navigateBasedOnPermission(BuildContext context, int userPermission) {
  if (userPermission == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaPedidoAdmin()),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaPedido()),
    );
  }
}