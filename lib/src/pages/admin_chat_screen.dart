import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/api_service.dart';

class AdminChatScreen extends StatefulWidget {
  final ClientModel client;

  const AdminChatScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ApiService.getMensagensPorChat(widget.client.chatId.toString());
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.client.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _messages.length,                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    final isAdmin = message['sender_id'].toString() == '1';
                                    
                                    return Align(
                                      alignment: isAdmin 
                                          ? Alignment.centerRight 
                                          : Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAdmin 
                                              ? const Color(0xFF0F59F7)
                                              : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          message['content'] ?? '',
                                          style: TextStyle(
                                            color: isAdmin ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Digite sua mensagem...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                color: const Color(0xFF0F59F7),
                                onPressed: _sendMessage,
                              ),
                            ],
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
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await ApiService.enviarMensagem(
        chatId: widget.client.chatId.toString(),
        senderId: '1', // Admin ID
        conteudo: text,
      );
      
      _loadMessages(); // Reload messages after sending
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
