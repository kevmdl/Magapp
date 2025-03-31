import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';

class TelaConfirmacao extends StatefulWidget {
  final Widget proximaTela;

  const TelaConfirmacao({
    super.key, 
    required this.proximaTela,
  });

  @override
  State<TelaConfirmacao> createState() => _TelaConfirmacaoState();
}

class _TelaConfirmacaoState extends State<TelaConfirmacao> {
  final _formKey = GlobalKey<FormState>();
  final _telefoneController = TextEditingController();
  final _codigoController = TextEditingController();

  @override
  void dispose() {
    _telefoneController.dispose();
    _codigoController.dispose();
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
                  child: Form(
                    key: _formKey,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  "Confirmação",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text("Número do celular"),
                              TextFormField(
                                controller: _telefoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: "Digite o número",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: Validatorless.multiple([
                                  Validatorless.required('Telefone obrigatório'),
                                  Validatorless.number('Apenas números'),
                                  Validatorless.min(11, 'Telefone inválido'),
                                ]),
                              ),
                              const SizedBox(height: 5),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Lógica para enviar código
                                  },
                                  child: const Text(
                                    "Enviar código",
                                    style: TextStyle(color: Color(0xFF0F59F7)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Código"),
                              TextFormField(
                                controller: _codigoController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Digite o código",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: Validatorless.multiple([
                                  Validatorless.required('Código obrigatório'),
                                  Validatorless.number('Apenas números'),
                                  Validatorless.min(6, 'Código deve ter 6 dígitos'),
                                  Validatorless.max(6, 'Código deve ter 6 dígitos'),
                                ]),
                              ),
                              const SizedBox(height: 20),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => widget.proximaTela),
                                    );
                                  }
                                },
                                child: const Center(child: Text("Validar")),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
