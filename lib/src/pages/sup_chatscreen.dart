import 'package:flutter/material.dart';
import 'package:maga_app/src/pages/tela_formulario.dart';
import 'package:maga_app/src/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ID do admin
  String? _chatId; // ID do chat atual
  String? _currentUserId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

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
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _messages = [];
    });
    
    try {
      // Get current user ID from shared preferences or auth service
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');
      
      if (_currentUserId == null) {
        throw Exception('Usuário não está logado');
      }

      print('Inicializando chat para usuário: $_currentUserId');
      
      final chatResponse = await ApiService.criarOuBuscarChat(
        userId: _currentUserId!,
        adminId: '1',
      );
      
      if (chatResponse != null) {
        _chatId = chatResponse['idchat'].toString();
        print('Chat inicializado - chatId: $_chatId, userId: $_currentUserId');
        await _loadMessages();
      } else {
        throw Exception('Não foi possível inicializar o chat');
      }
    } catch (e) {
      print('Erro na inicialização do chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao inicializar chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      if (_chatId == null) return;

      print('Carregando mensagens do chat $_chatId...'); // Debug log
      final messages = await ApiService.getMensagensPorChat(_chatId!);
      print('Mensagens carregadas: ${messages.length}'); // Debug log

      if (mounted) {
        setState(() {
          _messages = messages;
          print('Estado atualizado com ${_messages.length} mensagens'); // Debug log
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      print('Erro ao carregar mensagens: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar mensagens: $e')),
        );
      }
    }
  }

  // Enviar uma nova mensagem
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null || _currentUserId == null) {
      print('Validação falhou: texto=${text.isEmpty}, chatId=$_chatId, userId=$_currentUserId');
      return;
    }

    _messageController.clear();

    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'chat_id': _chatId,
      'sender_id': _currentUserId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      print('Enviando mensagem para chat $_chatId');
      final success = await ApiService.enviarMensagem(
        chatId: _chatId!,
        senderId: _currentUserId!,
        conteudo: text,
      );
      
      if (!success && mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['id'] == tempMessage['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar mensagem. Tente novamente.')),
        );
      } else {
        await _loadMessages(); // Reload messages after successful send
      }
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['id'] == tempMessage['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
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
  void dispose() {
    _scrollController.dispose();
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
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          // Use sender_id instead of Usuario_idusuario
                          final isUser = message['sender_id'].toString() == _currentUserId;
                          
                          return ChatBubble(
                            key: ValueKey(message['id']),
                            isUser: isUser,
                            // Use content instead of conteudo
                            text: message['content'] ?? '',
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