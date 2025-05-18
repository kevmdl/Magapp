import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:validatorless/validatorless.dart';

import '../services/api_service.dart';

class TelaFormulario extends StatefulWidget {
  const TelaFormulario({super.key});

  @override
  State<TelaFormulario> createState() => _TelaFormularioState();
}

class _TelaFormularioState extends State<TelaFormulario> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _placaController = TextEditingController();
  final _renavamController = TextEditingController();
  final _chassiController = TextEditingController();
  final _modeloController = TextEditingController();
  final _corController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _placaController.dispose();
    _renavamController.dispose();
    _chassiController.dispose();
    _modeloController.dispose();
    _corController.dispose();
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
                              const Center(
                                child: Text(
                                  "Formulário do Pedido",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const SizedBox(height: 10),
                              const Text("Nome/Razão Social"),
                              TextFormField(
                                controller: _nomeController,
                                validator: Validatorless.required('Nome é obrigatório'),
                                decoration: InputDecoration(
                                  hintText: "Digite o nome ou razão social",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("CPF/CNPJ"),
                              TextFormField(
                                controller: _cpfController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: Validatorless.multiple([
                                  Validatorless.required('CPF é obrigatório'),
                                  Validatorless.cpf('CPF inválido'),
                                  Validatorless.number('Apenas números são permitidos'),
                                ]),
                                decoration: InputDecoration(
                                  hintText: "Digite o CPF (apenas números)",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Placa"),
                              TextFormField(
                                controller: _placaController,
                                textCapitalization: TextCapitalization.characters,
                                validator: Validatorless.multiple([
                                  Validatorless.required('Placa é obrigatória'),
                                  Validatorless.regex(
                                    RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$'),
                                    'Formato inválido. Use o padrão ABC1D23'
                                  ),
                                ]),
                                decoration: InputDecoration(
                                  hintText: "Digite a placa (ABC1D23)",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Renavam"),
                              TextFormField(
                                controller: _renavamController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: Validatorless.multiple([
                                  Validatorless.required('Renavam é obrigatório'),
                                  Validatorless.number('Apenas números são permitidos'),
                                  Validatorless.min(9, 'Renavam deve ter no mínimo 9 dígitos'),
                                  Validatorless.max(11, 'Renavam deve ter no máximo 11 dígitos'),
                                ]),
                                decoration: InputDecoration(
                                  hintText: "Digite o Renavam (9 a 11 dígitos)",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Chassi"),
                              TextFormField(
                                controller: _chassiController,
                                textCapitalization: TextCapitalization.characters,
                                validator: Validatorless.multiple([
                                  Validatorless.required('Chassi é obrigatório'),
                                  Validatorless.regex(
                                    RegExp(r'^[A-HJ-NPR-Z0-9]{17}$'),
                                    'Chassi deve ter 17 caracteres válidos'
                                  ),
                                ]),
                                decoration: InputDecoration(
                                  hintText: "Digite o Chassi (17 caracteres)",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Modelo"),
                              TextFormField(
                                controller: _modeloController,
                                textCapitalization: TextCapitalization.words,
                                validator: Validatorless.required('Modelo é obrigatório'),
                                decoration: InputDecoration(
                                  hintText: "Digite o modelo do veículo",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Cor"),
                              TextFormField(
                                controller: _corController,
                                textCapitalization: TextCapitalization.words,
                                validator: Validatorless.required('Cor é obrigatória'),
                                decoration: InputDecoration(
                                  hintText: "Digite a cor do veículo",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
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
                                onPressed: () async {
                                  final formValid = _formKey.currentState?.validate() ?? false;
                                  if (formValid) {
                                    try {
                                      final pedidoData = {
                                        'nome_cliente': _nomeController.text,
                                        'cpf': _cpfController.text,
                                        'placa': _placaController.text,
                                        'renavam': _renavamController.text,
                                        'chassi': _chassiController.text,
                                        'modelo': _modeloController.text,
                                        'cor': _corController.text,
                                        'concluido': 0, // Estado inicial: não concluído
                                      };

                                      final success = await ApiService.createPedido(pedidoData);

                                      if (!mounted) return;

                                      if (success) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              title: const Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Color(0xFF063FBA)),
                                                  SizedBox(width: 10),
                                                  Text("Sucesso!"),
                                                ],
                                              ),
                                              content: const Text("Pedido feito com sucesso!"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop(); // Fechar diálogo
                                                    Navigator.of(context).pop(); // Voltar para a tela anterior
                                                  },
                                                  child: const Text(
                                                    "OK",
                                                    style: TextStyle(color: Color(0xFF063FBA)),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Erro ao criar pedido. Tente novamente.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Center(
                                  child: Text("Fazer Pedido"),
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
}
