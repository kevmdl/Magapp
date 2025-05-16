import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/tela_formulario.dart';
import 'package:maga_app/src/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isMenuOpen = false;

  // Controlador para o campo de texto da mensagem
  final TextEditingController _messageController = TextEditingController();

  // ID do usuário atual (obtido do login)
  String _currentUserId = 'demo_id'; // Valor padrão para demonstração

  // Lista de mensagens
  List<Map<String, dynamic>> _messages = [];

  // ID do assistente (destinatário fixo para este exemplo)
  final String _assistantId = '1'; // ID do assistente no backend

  // Flag para indicar carregamento
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Carregar o ID do usuário atual e as mensagens quando a tela for iniciada
    _loadCurrentUser();
    _loadMessages();
  }

  // Carregar informações do usuário atual
  Future<void> _loadCurrentUser() async {
    final userData = await ApiService.getUsuarioAtual();
    if (userData != null && userData['id'] != null) {
      setState(() {
        _currentUserId = userData['id'].toString();
      });
    }
  }

  // Carregar as mensagens do chat
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await ApiService.getMensagens(_currentUserId, _assistantId);
      setState(() {
        _messages = messages;
      });
    } catch (e) {
      // Em caso de erro, mostrar algumas mensagens de teste
      setState(() {
        _messages = [
          {
            'id': 1,
            'remetente_id': _currentUserId,
            'destinatario_id': _assistantId,
            'conteudo': 'Olá, pode me tirar uma dúvida?',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          },
          {
            'id': 2,
            'remetente_id': _assistantId,
            'destinatario_id': _currentUserId,
            'conteudo': 'Claro, estou à disposição!',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
          },
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Enviar uma nova mensagem
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Limpar o campo de texto
    _messageController.clear();

    // Criar uma mensagem temporária para exibição imediata
    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'remetente_id': _currentUserId,
      'destinatario_id': _assistantId,
      'conteudo': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Adicionar a mensagem à lista
    setState(() {
      _messages.add(tempMessage);
    });

    // Enviar a mensagem para o backend
    try {
      final success = await ApiService.enviarMensagem(
        remetenteId: _currentUserId,
        destinatarioId: _assistantId,
        conteudo: text,
      );

      if (success) {
        // Recarregar as mensagens para obter a versão correta do backend
        // Em um ambiente de produção, você poderia implementar WebSockets para
        // atualização em tempo real em vez de recarregar
        _loadMessages();
        
        // Removida a notificação de sucesso conforme solicitado
      }
    } catch (e) {
      // Exibir erro (opcional)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F59F7), Color(0xFF020e26)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            flexibleSpace: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 15,
                    child: Icon(Icons.support_agent, color: Color(0xFF063FBA)),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Assistente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message['remetente_id'] == _currentUserId;

                          return ChatBubble(
                            isUser: isUser,
                            text: message['conteudo'] ?? '',
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Color(0xFF063FBA)),
                      onPressed: _toggleMenu,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFF063FBA)),
                          ),
                          labelText: 'Digite sua mensagem...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF063FBA)),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 70,
            left: 10,
            child: ScaleTransition(
              scale: _animation,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          // Ação do documento
                          _toggleMenu();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.description, color: Color(0xFF063FBA)),
                              SizedBox(width: 12),
                              Text("Anexar documento",
                                  style: TextStyle(
                                    color: Color(0xFF063FBA),
                                    fontSize: 16,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _toggleMenu();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TelaFormulario()),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment, color: Color(0xFF063FBA)),
                              SizedBox(width: 12),
                              Text("Fazer Pedido",
                                  style: TextStyle(
                                    color: Color(0xFF063FBA),
                                    fontSize: 16,
                                  )),
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
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;

  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF011640) : const Color(0xFFDFECF6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}