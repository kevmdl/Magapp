import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:maga_app/src/pages/tela_formulario.dart';
import '../services/gemini_service.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isMenuOpen = false;
  
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<Content> _chatHistory = [];
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
    
    // Mensagem inicial especializada em emplacamento
    _addMessage(_getWelcomeMessage(), false);
    
    // Verificar se há um resumo de pedido para exibir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarResumoPedido();
    });
  }

  String _getWelcomeMessage() {
    return '''🚗 **Olá! Sou a Mag IA, sua assistente especializada em emplacamento de veículos!**

Estou aqui para ajudar você 24/7 com:

📋 **Processo de Emplacamento**
• Orientações sobre documentação necessária
• Verificação de documentos (CRV/CRLV-e)
• Esclarecimento de dúvidas sobre taxas e prazos

🤖 **Como posso ajudar:**
• Responder suas perguntas sobre emplacamento
• Analisar documentos enviados
• Guiar você através do processo completo
• Criar pedidos de emplacamento

Como posso ajudar você hoje?''';
  }

  void _verificarResumoPedido() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['resumoPedido'] != null) {
      final resumoPedido = args['resumoPedido'] as String;
      Future.delayed(const Duration(milliseconds: 500), () {
        _addMessage(resumoPedido, false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    
    // Adiciona ao histórico do chat para contexto
    _chatHistory.add(Content.text(text));
    
    // Scroll automático para a última mensagem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Adiciona mensagem do usuário
    _addMessage(message, true);
    _messageController.clear();

    // Mostra indicador de carregamento
    setState(() {
      _isLoading = true;
    });

    try {
      // Envia mensagem para a Mag IA
      final response = await GeminiService.sendMessageWithHistory(message, _chatHistory);
      
      // Adiciona resposta da IA
      _addMessage(response, false);
    } catch (e) {
      _addMessage('Desculpe, ocorreu um erro. Tente novamente.', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            flexibleSpace: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      'assets/img/logo_ia.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Mag IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ChatBubble(
                      isUser: message.isUser,
                      text: message.text,
                      timestamp: message.timestamp,
                    );
                  },
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),                      Text(
                        'Mag IA está digitando...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.send, 
                        color: _isLoading ? Colors.grey : const Color(0xFF063FBA),
                      ),
                      onPressed: _isLoading ? null : _sendMessage,
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
                    children: [                      InkWell(
                        onTap: () {
                          _toggleMenu();
                          _messageController.text = 'Como posso anexar um documento?';
                          _sendMessage();
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
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _toggleMenu();
                          _messageController.text = 'Quais documentos preciso para emplacar meu veículo?';
                          _sendMessage();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.help_outline, color: Color(0xFF063FBA)),
                              SizedBox(width: 12),
                              Text("Documentos necessários", 
                                style: TextStyle(
                                  color: Color(0xFF063FBA),
                                  fontSize: 16,
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _toggleMenu();
                          _messageController.text = 'Quanto custa o emplacamento e quais são as taxas?';
                          _sendMessage();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_money, color: Color(0xFF063FBA)),
                              SizedBox(width: 12),
                              Text("Taxas e custos", 
                                style: TextStyle(
                                  color: Color(0xFF063FBA),
                                  fontSize: 16,
                                )
                              ),
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
                                )
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
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;
  final DateTime timestamp;

  const ChatBubble({
    super.key, 
    required this.isUser, 
    required this.text, 
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF011640) : const Color(0xFFDFECF6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: isUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
