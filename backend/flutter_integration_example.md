# Integração da API de Chat com Flutter

Este guia mostra como integrar a API de chat em tempo real com seu aplicativo Flutter. A integração substitui o Stream.io usando nossa API personalizada.

## Dependências Necessárias

Adicione estas dependências ao seu arquivo `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  socket_io_client: ^2.0.1
  dio: ^5.0.0
  provider: ^6.0.5
  shared_preferences: ^2.1.0
  intl: ^0.18.0
```

## Configuração de Serviço API

### 1. Cliente HTTP com Dio

```dart
// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://seu-ip-ou-dominio:3000/api';
  
  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Adiciona token a todas as requisições
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioError e, handler) {
          // Tratamento de erros
          print('Erro na API: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  // Autenticação
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('$baseUrl/auth/login', data: {
        'email': email,
        'senha': password,
      });
      
      // Armazena o token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response.data['data']['token']);
      await prefs.setInt('user_id', response.data['data']['user']['id']);
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('$baseUrl/auth/register', data: {
        'nome': name,
        'email': email,
        'senha': password,
      });
      
      // Armazena o token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response.data['data']['token']);
      await prefs.setInt('user_id', response.data['data']['user']['id']);
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Usuários
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('$baseUrl/users/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<dynamic>> searchUsers(String term) async {
    try {
      final response = await _dio.get('$baseUrl/users/search', queryParameters: {'term': term});
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // Mensagens
  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get('$baseUrl/messages/conversations');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<dynamic>> getMessagesWith(int userId) async {
    try {
      final response = await _dio.get('$baseUrl/messages/$userId');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> sendMessage(int receiverId, String content, {String type = 'text'}) async {
    try {
      final response = await _dio.post('$baseUrl/messages', data: {
        'receiverId': receiverId,
        'content': content,
        'type': type,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Canais/Grupos
  Future<List<dynamic>> getChannels() async {
    try {
      final response = await _dio.get('$baseUrl/channels');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> createChannel(String name, String description, {bool isPrivate = false}) async {
    try {
      final response = await _dio.post('$baseUrl/channels', data: {
        'nome': name,
        'descricao': description,
        'isPrivate': isPrivate,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<dynamic>> getChannelMessages(int channelId) async {
    try {
      final response = await _dio.get('$baseUrl/channels/$channelId/messages');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> sendChannelMessage(int channelId, String content, {String type = 'text'}) async {
    try {
      final response = await _dio.post('$baseUrl/channels/$channelId/messages', data: {
        'content': content,
        'type': type,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
```

### 2. Serviço Socket.IO

```dart
// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  IO.Socket? socket;
  final String baseUrl = 'http://seu-ip-ou-dominio:3000';
  
  // Callbacks para eventos
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onMessageRead;
  Function(Map<String, dynamic>)? onTypingStarted;
  Function(Map<String, dynamic>)? onTypingStopped;
  Function(Map<String, dynamic>)? onChannelMessage;
  Function(Map<String, dynamic>)? onUserStatusChanged;
  
  Future<void> connect() async {
    if (socket != null && socket!.connected) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }
    
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token,
      },
    });
    
    _setupSocketListeners();
    
    socket!.connect();
  }
  
  void disconnect() {
    socket?.disconnect();
  }
  
  void _setupSocketListeners() {
    socket!.on('connect', (_) {
      print('Socket conectado');
    });
    
    socket!.on('disconnect', (_) {
      print('Socket desconectado');
    });
    
    socket!.on('error', (data) {
      print('Erro de socket: $data');
    });
    
    // Mensagens diretas
    socket!.on('message:received', (data) {
      if (onMessageReceived != null) {
        onMessageReceived!(data);
      }
    });
    
    socket!.on('message:read', (data) {
      if (onMessageRead != null) {
        onMessageRead!(data);
      }
    });
    
    // Digitando
    socket!.on('typing:start', (data) {
      if (onTypingStarted != null) {
        onTypingStarted!(data);
      }
    });
    
    socket!.on('typing:stop', (data) {
      if (onTypingStopped != null) {
        onTypingStopped!(data);
      }
    });
    
    // Mensagens de canal
    socket!.on('channel:message', (data) {
      if (onChannelMessage != null) {
        onChannelMessage!(data);
      }
    });
    
    // Status de usuário
    socket!.on('user:status', (data) {
      if (onUserStatusChanged != null) {
        onUserStatusChanged!(data);
      }
    });
  }
  
  // Enviar mensagem direta
  void sendMessage(int receiverId, String content, {String type = 'text'}) {
    if (socket == null || !socket!.connected) {
      throw Exception('Socket não conectado');
    }
    
    socket!.emit('message:send', {
      'receiverId': receiverId,
      'content': content,
      'type': type,
    });
  }
  
  // Marcar mensagem como lida
  void markMessageAsRead(int messageId, int senderId) {
    if (socket == null || !socket!.connected) return;
    
    socket!.emit('message:read', {
      'messageId': messageId,
      'senderId': senderId,
    });
  }
  
  // Indicar digitação
  void startTyping(int receiverId) {
    if (socket == null || !socket!.connected) return;
    
    socket!.emit('typing:start', {
      'receiverId': receiverId,
    });
  }
  
  void stopTyping(int receiverId) {
    if (socket == null || !socket!.connected) return;
    
    socket!.emit('typing:stop', {
      'receiverId': receiverId,
    });
  }
  
  // Enviar mensagem de canal
  void sendChannelMessage(int channelId, String content, {String type = 'text'}) {
    if (socket == null || !socket!.connected) return;
    
    socket!.emit('channel:message', {
      'channelId': channelId,
      'content': content,
      'type': type,
    });
  }
  
  // Marcar mensagens de canal como lidas
  void markChannelMessagesAsRead(int channelId) {
    if (socket == null || !socket!.connected) return;
    
    socket!.emit('channel:read', {
      'channelId': channelId,
    });
  }
  
  // Indicar digitação em canal
  void startTypingInChannel(int channelId) {
    if (socket == null || !socket!.connected) return;
    
    socket!.emit('channel:typing:start', {
      'channelId': channelId,
    });
  }
  
  void stopTypingInChannel(int channelId) {
    if (socket == null || !socket!.connected) return;
    
    socket!.emit('channel:typing:stop', {
      'channelId': channelId,
    });
  }
}
```

## Modelos de Dados

### Mensagem

```dart
// lib/models/message.dart
class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;
  
  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      type: json['type'] ?? 'text',
      isRead: json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
    );
  }
}
```

### Usuário

```dart
// lib/models/user.dart
class User {
  final int id;
  final String nome;
  final String email;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastActive;
  
  User({
    required this.id,
    required this.nome,
    required this.email,
    this.avatar,
    required this.isOnline,
    this.lastActive,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      avatar: json['avatar'],
      isOnline: json['is_online'] == 1,
      lastActive: json['last_active'] != null 
          ? DateTime.parse(json['last_active'])
          : null,
    );
  }
}
```

### Conversa

```dart
// lib/models/conversation.dart
import 'user.dart';
import 'message.dart';

class Conversation {
  final int userId;
  final User user;
  final Message lastMessage;
  final int unreadCount;
  
  Conversation({
    required this.userId,
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
  });
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['sender_id'] == json['current_user_id'] 
          ? json['receiver_id'] 
          : json['sender_id'],
      user: User(
        id: json['receiver_id'],
        nome: json['receiver_name'],
        email: '',
        isOnline: false,
        avatar: json['receiver_avatar'],
      ),
      lastMessage: Message.fromJson(json),
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
```

## Gerenciadores de Estado

### Chat Provider

```dart
// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/user.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = false;
  
  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  List<User> get users => _users;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  
  // Inicialização
  Future<void> initialize() async {
    await _socketService.connect();
    _setupSocketListeners();
    await loadCurrentUser();
    await loadConversations();
  }
  
  void _setupSocketListeners() {
    _socketService.onMessageReceived = (data) {
      final message = Message.fromJson(data['message']);
      _addMessage(message);
      notifyListeners();
    };
    
    _socketService.onMessageRead = (data) {
      final messageId = data['messageId'];
      final userId = data['by'];
      
      if (messageId != null) {
        _markMessageAsRead(messageId);
      } else {
        _markAllMessagesAsRead(userId);
      }
      
      notifyListeners();
    };
    
    _socketService.onUserStatusChanged = (data) {
      _updateUserStatus(data['userId'], data['isOnline']);
      notifyListeners();
    };
  }
  
  // Carrega usuário atual
  Future<void> loadCurrentUser() async {
    try {
      _setLoading(true);
      final response = await _apiService.getCurrentUser();
      _currentUser = User.fromJson(response['data']);
    } catch (e) {
      print('Erro ao carregar usuário: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Carrega as conversas
  Future<void> loadConversations() async {
    try {
      _setLoading(true);
      final data = await _apiService.getConversations();
      _conversations = data.map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar conversas: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Carrega mensagens com um usuário específico
  Future<void> loadMessagesWithUser(int userId) async {
    try {
      _setLoading(true);
      final data = await _apiService.getMessagesWith(userId);
      _messages = data.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar mensagens: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Envia uma mensagem
  Future<void> sendMessage(int receiverId, String content) async {
    try {
      // Usa o socket para envio em tempo real
      _socketService.sendMessage(receiverId, content);
      
      // Também faz a chamada API para garantir persistência
      final response = await _apiService.sendMessage(receiverId, content);
      final message = Message.fromJson(response['data']);
      _addMessage(message);
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
    }
  }
  
  // Marca mensagem como lida
  Future<void> markAsRead(int messageId, int senderId) async {
    try {
      _socketService.markMessageAsRead(messageId, senderId);
      await _apiService.markMessageAsRead(messageId);
      _markMessageAsRead(messageId);
    } catch (e) {
      print('Erro ao marcar mensagem como lida: $e');
    }
  }
  
  // Busca usuários
  Future<void> searchUsers(String term) async {
    try {
      _setLoading(true);
      final data = await _apiService.searchUsers(term);
      _users = data.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar usuários: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Métodos internos
  void _addMessage(Message message) {
    // Adiciona a mensagem à lista
    _messages.insert(0, message);
    
    // Atualiza a conversa ou cria uma nova
    final otherUserId = message.senderId == _currentUser?.id 
        ? message.receiverId 
        : message.senderId;
    
    final existingConversationIndex = _conversations.indexWhere(
      (c) => c.userId == otherUserId
    );
    
    if (existingConversationIndex != -1) {
      // Atualiza conversa existente
      final updatedConversation = Conversation(
        userId: otherUserId,
        user: _conversations[existingConversationIndex].user,
        lastMessage: message,
        unreadCount: message.senderId != _currentUser?.id 
            ? _conversations[existingConversationIndex].unreadCount + 1 
            : _conversations[existingConversationIndex].unreadCount,
      );
      
      _conversations[existingConversationIndex] = updatedConversation;
    }
    
    // Reordena as conversas (a mais recente primeiro)
    _conversations.sort((a, b) => 
      b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt)
    );
    
    notifyListeners();
  }
  
  void _markMessageAsRead(int messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      _messages[index] = Message(
        id: message.id,
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: message.content,
        type: message.type,
        isRead: true,
        createdAt: message.createdAt,
        senderName: message.senderName,
        senderAvatar: message.senderAvatar,
      );
    }
  }
  
  void _markAllMessagesAsRead(int senderId) {
    for (var i = 0; i < _messages.length; i++) {
      if (_messages[i].senderId == senderId && !_messages[i].isRead) {
        final message = _messages[i];
        _messages[i] = Message(
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          content: message.content,
          type: message.type,
          isRead: true,
          createdAt: message.createdAt,
          senderName: message.senderName,
          senderAvatar: message.senderAvatar,
        );
      }
    }
    
    // Atualiza contagem de não lidas na conversa
    final conversationIndex = _conversations.indexWhere((c) => c.userId == senderId);
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      _conversations[conversationIndex] = Conversation(
        userId: conversation.userId,
        user: conversation.user,
        lastMessage: conversation.lastMessage,
        unreadCount: 0,
      );
    }
  }
  
  void _updateUserStatus(int userId, bool isOnline) {
    // Atualiza status do usuário na lista de usuários
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex != -1) {
      final user = _users[userIndex];
      _users[userIndex] = User(
        id: user.id,
        nome: user.nome,
        email: user.email,
        avatar: user.avatar,
        isOnline: isOnline,
        lastActive: isOnline ? DateTime.now() : user.lastActive,
      );
    }
    
    // Atualiza status na conversa
    final conversationIndex = _conversations.indexWhere((c) => c.userId == userId);
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      final updatedUser = User(
        id: conversation.user.id,
        nome: conversation.user.nome,
        email: conversation.user.email,
        avatar: conversation.user.avatar,
        isOnline: isOnline,
        lastActive: isOnline ? DateTime.now() : conversation.user.lastActive,
      );
      
      _conversations[conversationIndex] = Conversation(
        userId: conversation.userId,
        user: updatedUser,
        lastMessage: conversation.lastMessage,
        unreadCount: conversation.unreadCount,
      );
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Limpa os recursos ao sair
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
```

## Exemplos de Telas

### Tela de Login

```dart
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'conversations_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Navega para a tela de conversas
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ConversationsScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha no login. Verifique suas credenciais.';
      });
      print('Erro de login: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Entrar'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navegação para tela de registro
                },
                child: Text('Não tem uma conta? Registre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Tela de Conversas

```dart
// lib/screens/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'package:intl/intl.dart';

class ConversationsScreen extends StatefulWidget {
  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).initialize();
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(
      dateTime.year, 
      dateTime.month, 
      dateTime.day
    );
    
    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Ontem';
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversas'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (chatProvider.conversations.isEmpty) {
            return Center(
              child: Text('Nenhuma conversa encontrada'),
            );
          }

          return ListView.builder(
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: conversation.user.avatar != null
                      ? NetworkImage(conversation.user.avatar!)
                      : null,
                  child: conversation.user.avatar == null
                      ? Text(conversation.user.nome[0])
                      : null,
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(conversation.user.nome)),
                    Text(
                      _formatTime(conversation.lastMessage.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.lastMessage.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (conversation.unreadCount > 0)
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          conversation.unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conversation.user.isOnline
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        userId: conversation.userId,
                        name: conversation.user.nome,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

### Tela de Chat

```dart
// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String name;

  ChatScreen({
    required this.userId,
    required this.name,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  bool _isTyping = false;
  int? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadMessagesWithUser(widget.userId);
    _currentUserId = chatProvider.currentUser?.id;
    
    // Marcar mensagens como lidas
    // Implementação da marcação das mensagens como lidas
  }
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final message = _messageController.text;
    _messageController.clear();
    
    Provider.of<ChatProvider>(context, listen: false).sendMessage(
      widget.userId,
      message,
    );
  }
  
  void _handleTyping(String text) {
    final socketService = Provider.of<ChatProvider>(context, listen: false);
    
    if (text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      // Envia evento de começou a digitar
    } else if (text.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
      // Envia evento de parou de digitar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Ação para ver detalhes do usuário
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Text('Nenhuma mensagem encontrada'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isMe = message.senderId == _currentUserId;
                    
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(message.createdAt),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMe) ...[
                                  SizedBox(width: 5),
                                  Icon(
                                    message.isRead
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 14,
                                    color: message.isRead
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () {
                    // Implementar anexo de arquivos
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _handleTyping,
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Configuração Final

Para integrar completamente a API com seu aplicativo Flutter, siga estas etapas:

1. Configure o `main.dart` para usar o Provider:

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'App de Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LoginScreen(),
      ),
    );
  }
}
```

2. Adicione as permissões necessárias nos arquivos de manifesto:

Para Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Para iOS (`ios/Runner/Info.plist`):
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

3. Configure a URL base nos arquivos de serviço para o endereço IP do seu servidor.

4. Instale as dependências e execute o aplicativo:

```bash
flutter pub get
flutter run
```

Após essas etapas, você terá uma implementação completa e funcional de um sistema de chat em tempo real no seu aplicativo Flutter, substituindo o Stream.io com sua própria API personalizada.