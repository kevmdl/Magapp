import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Serviço central de guard rails para proteção da IA
class AiGuardRailsService {
  // Configurações de limites
  static const int _maxMessageLength = 10000;
  static const int _maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int _maxImageSize = 20 * 1024 * 1024; // 20MB
  static const int _maxRequestsPerMinute = 30;
  static const int _maxConcurrentRequests = 5;
  static const Duration _timeoutDuration = Duration(minutes: 2);
  
  // Cache para rate limiting
  static final Map<String, List<DateTime>> _requestHistory = {};
  static int _currentConcurrentRequests = 0;
  
  // Padrões maliciosos para detectar
  static final List<RegExp> _maliciousPatterns = [
    // SQL Injection
    RegExp(r"(\bUNION\b|\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bDROP\b|\bCREATE\b)", caseSensitive: false),
    RegExp(r"('|\"|;|--|\s+OR\s+|\s+AND\s+)", caseSensitive: false),
    
    // XSS
    RegExp(r"<script|javascript:|vbscript:|onload=|onerror=|onclick=", caseSensitive: false),
    RegExp(r"<iframe|<object|<embed|<form", caseSensitive: false),
    
    // Path Traversal
    RegExp(r"\.\./|\.\.\[\\|/]|~[/\\]|%2e%2e", caseSensitive: false),
    
    // Command Injection
    RegExp(r"(\||&|;|`|\$\(|\${)", caseSensitive: false),
    RegExp(r"(curl|wget|nc|netcat|ping|nslookup)", caseSensitive: false),
    
    // LDAP/JNDI Injection
    RegExp(r"\$\{jndi:|ldap://|rmi://", caseSensitive: false),
    
    // Template Injection
    RegExp(r"\{\{.*\}\}|\$\{.*\}|<%.*%>", caseSensitive: false),
  ];
  
  // Tipos de arquivo perigosos
  static final List<String> _dangerousFileTypes = [
    'application/x-executable',
    'application/x-msdownload',
    'application/x-msdos-program',
    'application/x-dosexec',
    'application/octet-stream',
    'text/x-shellscript',
    'application/x-sh',
    'application/x-bat',
    'application/x-perl',
    'application/x-python',
  ];

  /// Valida entrada de texto do usuário
  static ValidationResult validateTextInput(String input, {String? context}) {
    try {
      // 1. Verificação de tamanho
      if (input.isEmpty) {
        return ValidationResult.invalid('Entrada vazia não é permitida');
      }
      
      if (input.length > _maxMessageLength) {
        return ValidationResult.invalid('Mensagem muito longa. Máximo: $_maxMessageLength caracteres');
      }
      
      // 2. Sanitização básica
      final sanitized = _sanitizeInput(input);
      
      // 3. Detecção de padrões maliciosos
      final maliciousCheck = _checkMaliciousPatterns(sanitized);
      if (!maliciousCheck.isValid) {
        return maliciousCheck;
      }
      
      // 4. Verificação de encoding
      if (!_isValidEncoding(input)) {
        return ValidationResult.invalid('Encoding inválido detectado');
      }
      
      // 5. Verificação de contexto específico
      if (context != null) {
        final contextCheck = _validateByContext(sanitized, context);
        if (!contextCheck.isValid) {
          return contextCheck;
        }
      }
      
      return ValidationResult.valid(sanitized);
      
    } catch (e) {
      return ValidationResult.invalid('Erro na validação: $e');
    }
  }

  /// Valida arquivo enviado
  static ValidationResult validateFile(File file, {String? expectedMimeType}) {
    try {
      // 1. Verificação de existência
      if (!file.existsSync()) {
        return ValidationResult.invalid('Arquivo não encontrado');
      }
      
      // 2. Verificação de tamanho
      final fileSize = file.lengthSync();
      if (fileSize == 0) {
        return ValidationResult.invalid('Arquivo está vazio');
      }
      
      if (fileSize > _maxFileSize) {
        return ValidationResult.invalid('Arquivo muito grande. Máximo: ${_maxFileSize ~/ (1024 * 1024)}MB');
      }
      
      // 3. Verificação do tipo MIME
      final mimeType = _getMimeType(file.path);
      if (_dangerousFileTypes.contains(mimeType)) {
        return ValidationResult.invalid('Tipo de arquivo não permitido: $mimeType');
      }
      
      // 4. Verificação do cabeçalho do arquivo
      if (!_isValidFileHeader(file, mimeType)) {
        return ValidationResult.invalid('Cabeçalho de arquivo inválido ou suspeito');
      }
      
      // 5. Verificação específica para imagens
      if (mimeType?.startsWith('image/') == true && fileSize > _maxImageSize) {
        return ValidationResult.invalid('Imagem muito grande. Máximo: ${_maxImageSize ~/ (1024 * 1024)}MB');
      }
      
      return ValidationResult.valid(file.path);
      
    } catch (e) {
      return ValidationResult.invalid('Erro na validação do arquivo: $e');
    }
  }

  /// Valida dados de bytes (para web)
  static ValidationResult validateBytes(Uint8List bytes, {String? mimeType}) {
    try {
      // 1. Verificação de tamanho
      if (bytes.isEmpty) {
        return ValidationResult.invalid('Dados vazios');
      }
      
      if (bytes.length > _maxFileSize) {
        return ValidationResult.invalid('Dados muito grandes. Máximo: ${_maxFileSize ~/ (1024 * 1024)}MB');
      }
      
      // 2. Verificação do tipo MIME
      if (mimeType != null && _dangerousFileTypes.contains(mimeType)) {
        return ValidationResult.invalid('Tipo de arquivo não permitido: $mimeType');
      }
      
      // 3. Verificação de cabeçalho de bytes
      if (!_isValidBytesHeader(bytes, mimeType)) {
        return ValidationResult.invalid('Cabeçalho de dados inválido');
      }
      
      // 4. Verificação específica para imagens
      if (mimeType?.startsWith('image/') == true && bytes.length > _maxImageSize) {
        return ValidationResult.invalid('Imagem muito grande. Máximo: ${_maxImageSize ~/ (1024 * 1024)}MB');
      }
      
      return ValidationResult.valid('Dados válidos');
      
    } catch (e) {
      return ValidationResult.invalid('Erro na validação dos dados: $e');
    }
  }

  /// Implementa rate limiting por usuário/IP
  static ValidationResult checkRateLimit(String identifier) {
    try {
      final now = DateTime.now();
      
      // Remove requests antigos (mais de 1 minuto)
      _requestHistory[identifier]?.removeWhere(
        (timestamp) => now.difference(timestamp).inMinutes >= 1
      );
      
      final userRequests = _requestHistory[identifier] ?? [];
      
      // Verifica limite de requests por minuto
      if (userRequests.length >= _maxRequestsPerMinute) {
        return ValidationResult.invalid(
          'Muitas solicitações. Limite: $_maxRequestsPerMinute por minuto'
        );
      }
      
      // Verifica requests concorrentes
      if (_currentConcurrentRequests >= _maxConcurrentRequests) {
        return ValidationResult.invalid(
          'Muitas solicitações simultâneas. Tente novamente em alguns segundos.'
        );
      }
      
      // Adiciona nova request
      _requestHistory[identifier] = [...userRequests, now];
      _currentConcurrentRequests++;
      
      return ValidationResult.valid('Rate limit OK');
      
    } catch (e) {
      return ValidationResult.invalid('Erro no controle de rate limit: $e');
    }
  }

  /// Marca fim da request (para controle de concorrência)
  static void endRequest() {
    if (_currentConcurrentRequests > 0) {
      _currentConcurrentRequests--;
    }
  }

  /// Sanitiza resposta da IA antes de enviar ao usuário
  static String sanitizeAiResponse(String response) {
    try {
      // Remove possíveis scripts maliciosos
      String sanitized = response
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
          .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
          .replaceAll(RegExp(r'vbscript:', caseSensitive: false), '')
          .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
      
      // Remove referências a arquivos do sistema
      sanitized = sanitized
          .replaceAll(RegExp(r'/etc/passwd|/etc/shadow|C:\\Windows', caseSensitive: false), '[REDACTED]')
          .replaceAll(RegExp(r'file://|ftp://'), '[PROTOCOLO_REMOVIDO]');
      
      // Limita tamanho da resposta
      if (sanitized.length > _maxMessageLength * 2) {
        sanitized = sanitized.substring(0, _maxMessageLength * 2) + '\n\n[Resposta truncada devido ao tamanho]';
      }
      
      return sanitized;
      
    } catch (e) {
      return 'Erro ao processar resposta da IA. Tente novamente.';
    }
  }

  /// Gera hash único para cache/logging seguro
  static String generateSecureHash(String input) {
    final bytes = utf8.encode(input + DateTime.now().millisecondsSinceEpoch.toString());
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Monitora uso da IA e detecta padrões suspeitos
  static void logAiUsage(String userId, String operation, {Map<String, dynamic>? metadata}) {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'userId': _hashUserId(userId),
        'operation': operation,
        'metadata': metadata,
      };
      
      // Em produção, enviar para sistema de monitoramento
      print('AI_USAGE_LOG: ${jsonEncode(logEntry)}');
      
    } catch (e) {
      print('Erro ao registrar uso da IA: $e');
    }
  }

  // Métodos privados de utilidade

  static String _sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'), '') // Remove caracteres de controle
        .trim();
  }

  static ValidationResult _checkMaliciousPatterns(String input) {
    for (final pattern in _maliciousPatterns) {
      if (pattern.hasMatch(input)) {
        return ValidationResult.invalid('Padrão suspeito detectado');
      }
    }
    return ValidationResult.valid(input);
  }

  static bool _isValidEncoding(String input) {
    try {
      // Verifica se pode ser encodado/decodado corretamente
      final bytes = utf8.encode(input);
      final decoded = utf8.decode(bytes);
      return decoded == input;
    } catch (e) {
      return false;
    }
  }

  static ValidationResult _validateByContext(String input, String context) {
    switch (context.toLowerCase()) {
      case 'chassi':
        if (input.length != 17) {
          return ValidationResult.invalid('Chassi deve ter 17 caracteres');
        }
        if (RegExp(r'[IOQ]', caseSensitive: false).hasMatch(input)) {
          return ValidationResult.invalid('Chassi não pode conter I, O ou Q');
        }
        break;
        
      case 'placa':
        if (!RegExp(r'^[A-Z]{3}-?\d{4}$|^[A-Z]{3}\d[A-Z]\d{2}$', caseSensitive: false).hasMatch(input)) {
          return ValidationResult.invalid('Formato de placa inválido');
        }
        break;
        
      case 'renavam':
        if (!RegExp(r'^\d{11}$').hasMatch(input)) {
          return ValidationResult.invalid('Renavam deve ter 11 dígitos');
        }
        break;
    }
    
    return ValidationResult.valid(input);
  }

  static String? _getMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  static bool _isValidFileHeader(File file, String? mimeType) {
    try {
      final bytes = file.readAsBytesSync().take(20).toList();
      return _isValidBytesHeader(Uint8List.fromList(bytes), mimeType);
    } catch (e) {
      return false;
    }
  }

  static bool _isValidBytesHeader(Uint8List bytes, String? mimeType) {
    if (bytes.length < 4) return false;
    
    // Verifica assinaturas de arquivo conhecidas
    final header = bytes.take(20).toList();
    
    switch (mimeType) {
      case 'image/jpeg':
        return header[0] == 0xFF && header[1] == 0xD8;
      case 'image/png':
        return header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47;
      case 'application/pdf':
        return header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44 && header[3] == 0x46;
      default:
        // Para outros tipos, verifica se não são executáveis
        return !(header[0] == 0x4D && header[1] == 0x5A) && // PE executável
               !(header[0] == 0x7F && header[1] == 0x45 && header[2] == 0x4C && header[3] == 0x46); // ELF
    }
  }

  static String _hashUserId(String userId) {
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }
}

/// Resultado de validação
class ValidationResult {
  final bool isValid;
  final String message;
  final dynamic data;

  ValidationResult._(this.isValid, this.message, [this.data]);

  factory ValidationResult.valid(dynamic data) => ValidationResult._(true, 'Válido', data);
  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);

  @override
  String toString() => isValid ? 'Válido: $message' : 'Inválido: $message';
}
