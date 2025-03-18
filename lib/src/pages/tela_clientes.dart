import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ClientesScreen(),
    );
  }
}

class ClientesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clientes'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Ação do botão voltar
          },
        ),
      ),
      body: ListView(
        children: [
          ChatItem(
            username: 'Usuario teste 1',
            message: 'Oi Boa tarde',
            time: '13:43',
          ),
          ChatItem(
            username: 'Usuario teste 2',
            message: 'Opa, tudo bom?',
            time: '09:30',
          ),
        ],
      ),
    );
  }
}

class ChatItem extends StatelessWidget {
  final String username;
  final String message;
  final String time;

  ChatItem({required this.username, required this.message, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(Icons.person),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(message),
                ],
              ),
            ),
            Text(time),
          ],
        ),
     ),
    );
}
}
