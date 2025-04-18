import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';

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

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _placaController.dispose();
    _renavamController.dispose();
    _chassiController.dispose();
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
                                validator: Validatorless.multiple([
                                  Validatorless.required('CPF/CNPJ é obrigatório'),
                                  Validatorless.cpf('CPF inválido'),
                                ]),
                                decoration: InputDecoration(
                                  hintText: "Digite o CPF ou CNPJ",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Placa"),
                              TextFormField(
                                controller: _placaController,
                                validator: Validatorless.required('Placa é obrigatória'),
                                decoration: InputDecoration(
                                  hintText: "Digite a placa",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Renavam"),
                              TextFormField(
                                controller: _renavamController,
                                decoration: InputDecoration(
                                  hintText: "Digite o Renavam",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: Validatorless.required('Renavam é obrigatório'),
                              ),
                              const SizedBox(height: 10),
                              const Text("Chassi"),
                              TextFormField(
                                controller: _chassiController,
                                decoration: InputDecoration(
                                  hintText: "Digite o Chassi",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: Validatorless.required('Chassi é obrigatório'),
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
                                onPressed: () {
                                  final formValid = _formKey.currentState?.validate() ?? false;
                                  if (formValid) {
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
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
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
