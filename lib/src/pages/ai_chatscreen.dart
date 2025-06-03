import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:maga_app/src/pages/tela_formulario.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/gemini_service.dart';
import '../services/image_vision_service.dart';
import '../services/document_analysis_service.dart';
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
    // Variáveis para análise de imagens e documentos
  final ImagePicker _imagePicker = ImagePicker();
  bool _isAnalyzingImage = false;
  bool _isAnalyzingDocument = false;
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
  }  String _getWelcomeMessage() {
    return '''🚗 **Olá! Sou a Mag IA, sua assistente especializada em emplacamento de veículos!**

Estou aqui para ajudar você 24/7 com:

📋 **Processo de Emplacamento**
• Orientações sobre documentação necessária
• Verificação de documentos (CRV/CRLV-e)
• Esclarecimento de dúvidas sobre taxas e prazos

🔍 **Extração Inteligente de Dados**
• **CHASSI** - Identificação automática de 17 caracteres
• **PLACA** - Detecção de modelo antigo vs. Mercosul
• **RENAVAM** - Extração precisa de 11 dígitos
• **Análise de necessidade** - Determino se precisa emplacar

📷 **Análise Completa de Documentos**
• **Imagens**: JPG, PNG, WEBP, GIF
• **PDFs**: Documentos digitalizados
• **Textos**: DOC, TXT, contratos
• **Planilhas**: CSV, XLS
• **Todos os tipos** de arquivo

🎯 **Orientação Automática por Tipo de Placa:**
• **Placa Antiga (ABC-1234)** → Não precisa emplacar ✅
• **Placa Mercosul (ABC1D23)** → Pode fazer novo pedido 🔄
• **Sem Placa** → Emplacamento obrigatório ⚠️

🤖 **Como posso ajudar:**
• Responder suas perguntas sobre emplacamento
• Analisar qualquer documento (use o botão 📎)
• Extrair chassi, placa e Renavam automaticamente
• Guiar você através do processo completo
• Criar pedidos de emplacamento

**💡 Dica:** Clique no botão 📎 para enviar fotos, PDFs ou qualquer arquivo!

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
  }  // Métodos para análise de imagens
  Future<void> _requestPermissions() async {
    // Para web não precisamos de permissões específicas
    try {
      await [
        Permission.camera,
        Permission.photos,
        Permission.storage,
      ].request();
    } catch (e) {
      print('Permissões não aplicáveis na plataforma atual: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      await _requestPermissions();
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        await _analyzePickedImage(image);
      } else {
        _addMessage('❌ Nenhuma foto foi tirada.', false);
      }
    } catch (e) {
      print('Erro ao acessar câmera: $e');
      _addMessage('❌ Erro ao acessar a câmera. Erro: ${e.toString()}', false);
    }
    _toggleMenu();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      await _requestPermissions();
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        await _analyzePickedImage(image);
      } else {
        _addMessage('❌ Nenhuma imagem foi selecionada.', false);
      }
    } catch (e) {
      print('Erro ao acessar galeria: $e');
      _addMessage('❌ Erro ao acessar a galeria. Erro: ${e.toString()}', false);
    }
    _toggleMenu();
  }  Future<void> _analyzePickedImage(XFile image) async {
    setState(() {
      _isAnalyzingImage = true;
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;
      
      if (kIsWeb) {
        // Para web, usa bytes diretamente
        final Uint8List imageBytes = await image.readAsBytes();
        if (imageBytes.isEmpty) {
          throw Exception('Dados de imagem estão vazios');
        }

        // Adiciona mensagem do usuário indicando envio de imagem
        _addMessage('📷 Imagem enviada para análise (${(imageBytes.length / 1024).toStringAsFixed(1)} KB)', true);

        print('Analisando imagem (web): ${image.name}, Tamanho: ${imageBytes.length} bytes');

        // Analisa a imagem usando bytes para web
        result = await ImageVisionService.analyzeVehicleDocumentFromBytes(imageBytes);
      } else {
        // Para mobile/desktop, usa arquivo
        final file = File(image.path);
        if (!await file.exists()) {
          throw Exception('Arquivo de imagem não encontrado');
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('Arquivo de imagem está vazio');
        }

        // Adiciona mensagem do usuário indicando envio de imagem
        _addMessage('📷 Imagem enviada para análise (${(fileSize / 1024).toStringAsFixed(1)} KB)', true);

        print('Analisando imagem: ${image.path}, Tamanho: $fileSize bytes');

        // Analisa a imagem usando arquivo para mobile/desktop
        result = await ImageVisionService.analyzeVehicleDocument(file);
      }
      
      print('Resultado da análise: $result');
      
      // Verifica se a análise foi bem-sucedida
      if (result['success'] == true) {
        // Adiciona resposta da análise
        _addMessage(result['analysis'], false);
        
        // Se houver dados veiculares extraídos, adiciona informações especiais
        if (result['vehicleData'] != null && result['vehicleData']['success'] == true) {
          final vehicleData = result['vehicleData'];
          
          // Se a placa for modelo antigo, adiciona orientação específica
          if (vehicleData['modelo_placa'] == 'antigo') {
            _addMessage('''💡 **INFORMAÇÃO ADICIONAL**

Como sua placa está no modelo antigo, você tem algumas opções:

1️⃣ **Manter a placa atual** - Não há obrigatoriedade de trocar
2️⃣ **Solicitar placa Mercosul** - Se desejar, pode fazer o pedido pelo app

Para fazer pedido de nova placa, use o botão "Fazer Pedido" no menu (📎).''', false);
          }
          
          // Se a placa for Mercosul, adiciona orientação específica
          if (vehicleData['modelo_placa'] == 'mercosul') {
            _addMessage('''🎯 **PRÓXIMOS PASSOS DISPONÍVEIS**

Sua placa já está no padrão Mercosul! Você pode:

1️⃣ **Solicitar segunda via** - Em caso de dano ou perda
2️⃣ **Personalizar placa** - Solicitar placa com desenho especial
3️⃣ **Atualizar dados** - Se houver mudança de endereço

Use o botão "Fazer Pedido" no menu (📎) para qualquer solicitação!''', false);
          }
          
          // Se precisa emplacar
          if (vehicleData['precisa_emplacar'] == true) {
            _addMessage('''🚨 **AÇÃO OBRIGATÓRIA IDENTIFICADA**

Seu veículo precisa de emplacamento! 

➡️ **Faça agora mesmo:**
1. Clique no botão "Fazer Pedido" no menu (📎)
2. Selecione "Primeiro emplacamento"
3. Preencha todos os dados identificados automaticamente
4. Anexe os documentos restantes

⏰ **Importante:** Dirija apenas com autorização até concluir o processo!''', false);
          }
        }
      } else {
        // Adiciona mensagem de erro
        _addMessage('❌ ${result['message'] ?? 'Erro desconhecido na análise.'}', false);
      }
      
    } catch (e) {
      print('Erro na análise de imagem: $e');
      _addMessage('❌ Erro ao analisar a imagem: ${e.toString()}', false);
    } finally {
      setState(() {
        _isAnalyzingImage = false;
        _isLoading = false;
      });
    }
  }
  // Métodos para análise de documentos
  Future<void> _pickAndAnalyzeDocument() async {
    try {
      await _requestPermissions();
      setState(() {
        _isAnalyzingDocument = true;
        _isLoading = true;
      });

      // Adiciona mensagem do usuário indicando envio de documento
      _addMessage('📄 Selecionando documento para análise...', true);

      print('Iniciando seleção de documento...');

      // Seleciona e analisa o documento usando o serviço
      final result = await DocumentAnalysisService.pickAndAnalyzeDocument();
      
      print('Resultado da análise de documento: $result');
      
      // Verifica se a análise foi bem-sucedida
      if (result['success'] == true) {
        // Formata a resposta com informações do arquivo
        final fileName = result['fileName'] ?? 'Documento';
        final fileSize = result['fileSize'] ?? '';
        final mimeType = result['mimeType'] ?? '';
        
        final response = '''📄 **Análise do documento: $fileName**
📊 **Informações do arquivo:**
• Tamanho: $fileSize
• Tipo: $mimeType

${result['analysis']}''';
        
        _addMessage(response, false);
      } else {
        _addMessage('❌ ${result['message'] ?? 'Erro desconhecido na análise.'}', false);
      }
      
    } catch (e) {
      print('Erro na análise de documento: $e');
      _addMessage('❌ Erro ao analisar o documento: ${e.toString()}', false);
    } finally {
      setState(() {
        _isAnalyzingDocument = false;
        _isLoading = false;
      });
    }
    _toggleMenu();
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
              ),              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isAnalyzingImage 
                            ? 'Mag IA está analisando o documento...' 
                            : _isAnalyzingDocument
                                ? 'Mag IA está processando o arquivo...'
                                : 'Mag IA está digitando...',
                        style: const TextStyle(
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
                  padding: const EdgeInsets.all(8.0),                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão para tirar foto
                      InkWell(
                        onTap: _pickImageFromCamera,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, color: Color(0xFF063FBA)),
                              SizedBox(width: 12),
                              Text("Tirar foto do documento", 
                                style: TextStyle(
                                  color: Color(0xFF063FBA),
                                  fontSize: 16,
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Botão para galeria
                      InkWell(
                        onTap: _pickImageFromGallery,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library, color: Color(0xFF063FBA)),
                              SizedBox(width: 12),
                              Text("Escolher da galeria", 
                                style: TextStyle(
                                  color: Color(0xFF063FBA),
                                  fontSize: 16,
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Botão para selecionar qualquer documento
                      InkWell(
                        onTap: _pickAndAnalyzeDocument,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insert_drive_file, color: Color(0xFF063FBA)),
                              SizedBox(width: 12),
                              Text("Selecionar arquivo/documento", 
                                style: TextStyle(
                                  color: Color(0xFF063FBA),
                                  fontSize: 16,
                                )
                              ),
                            ],
                          ),
                        ),
                      ),                      const Divider(height: 1),
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
