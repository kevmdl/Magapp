import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../pages/admin_chat_screen.dart';

class ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onEdit;

  const ClientCard({
    super.key,
    required this.client,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
            client.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: #${client.id}'),
            Text(client.email),
            if (client.phone != null && client.phone!.isNotEmpty)
              Text(client.phone!),
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
                      key: ValueKey(client.id),
                      client: client,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              color: const Color(0xFF063FBA),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}