import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'vehicle_data_extraction_service.dart';
import 'ai_guard_rails_service.dart';

class ImageVisionService {
  static GenerativeModel? _visionModel;

  static GenerativeModel get visionModel {
    _visionModel ??= GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: ApiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Mais precisão para análise de documentos
        topK: 32,
        topP: 0.8,
        maxOutputTokens: 4096,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
      systemInstruction: Content.text(_getVisionSystemPrompt()),
    );
    return _visionModel!;
  }

  static String _getVisionSystemPrompt() {
    return '''
Você é a Mag IA, especialista em análise de documentos de emplacamento veicular brasileiro.

FUNÇÃO PRINCIPAL: Analisar imagens de documentos relacionados ao emplacamento de veículos.

DOCUMENTOS QUE VOCÊ ANALISA:
1. CRV (Certificado de Registro de Veículo)
2. CRLV-e (Certificado de Registro e Licenciamento de Veículo eletrônico)
3. CNH (Carteira Nacional de Habilitação)
4. Comprovantes de residência
5. Notas fiscais de veículos
6. Documentos de transferência
7. Fotos do veículo (chassi, placa, etc.)

ANÁLISE DETALHADA:
• Verificar legibilidade dos dados
• Identificar informações obrigatórias presentes/ausentes
• Validar formato dos documentos
• Detectar possíveis problemas ou irregularidades
• Orientar sobre correções necessárias

DIRETRIZES DE ANÁLISE:
• Seja preciso e detalhista
• Aponte problemas específicos encontrados
• Sugira soluções práticas
• Explique a importância de cada campo
• Use linguagem clara e acessível
• Mantenha foco em emplacamento brasileiro

FORMATO DE RESPOSTA:
1. Tipo de documento identificado
2. Qualidade da imagem (legível/ilegível)
3. Informações principais extraídas
4. Problemas identificados (se houver)
5. Recomendações e próximos passos

Sempre mantenha o contexto de emplacamento veicular e seja prestativo!
''';
  }

  /// Seleciona e analisa uma imagem
  static Future<Map<String, dynamic>> pickAndAnalyzeImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return {
          'success': false,
          'message': 'Nenhuma imagem selecionada',
        };
      }

      return await analyzeImage(File(image.path));
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao selecionar imagem: $e',
      };
    }
  }  /// Analisa uma imagem específica
  static Future<Map<String, dynamic>> analyzeImage(File imageFile, {String? userId}) async {
    // Guard Rails: Validação do arquivo
    final fileValidation = AiGuardRailsService.validateFile(imageFile, expectedMimeType: 'image/');
    if (!fileValidation.isValid) {
      AiGuardRailsService.logAiUsage(userId ?? 'anonymous', 'image_blocked', 
        metadata: {'reason': fileValidation.message, 'file': imageFile.path});
      return {
        'success': false,
        'message': 'Arquivo inválido: ${fileValidation.message}',
      };
    }

    // Guard Rails: Rate limiting
    final rateLimitCheck = AiGuardRailsService.checkRateLimit(userId ?? 'anonymous');
    if (!rateLimitCheck.isValid) {
      return {
        'success': false,
        'message': rateLimitCheck.message,
      };
    }

    try {
      print('ImageVisionService: Iniciando análise de ${imageFile.path}');
      
      AiGuardRailsService.logAiUsage(userId ?? 'anonymous', 'analyze_image', 
        metadata: {'file_size': await imageFile.length(), 'file_path': imageFile.path});
      
      // Verifica se o arquivo existe
      if (!await imageFile.exists()) {
        throw Exception('Arquivo de imagem não encontrado');
      }

      // Lê os bytes da imagem
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      if (imageBytes.isEmpty) {
        throw Exception('Arquivo de imagem está vazio');
      }
      
      print('ImageVisionService: Imagem carregada, ${imageBytes.length} bytes');
      
      // Determina o tipo MIME da imagem
      String mimeType = 'image/jpeg';
      final extension = imageFile.path.toLowerCase().split('.').last;
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
      }
      
      // Cria o conteúdo com imagem para análise
      final prompt = '''
Analise este documento relacionado ao emplacamento veicular.

Por favor, forneça:
1. **Tipo de documento**: Identifique qual documento é este
2. **Qualidade**: Avalie se a imagem está legível
3. **Dados extraídos**: Liste as informações visíveis e importantes
4. **Problemas identificados**: Aponte qualquer irregularidade
5. **Recomendações**: Sugira os próximos passos

Seja detalhista e prático em suas orientações.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      print('ImageVisionService: Enviando para análise...');
      
      // Envia para análise
      final response = await visionModel.generateContent(content);
      
      print('ImageVisionService: Análise concluída');
      
      return {
        'success': true,
        'analysis': response.text ?? 'Não foi possível analisar a imagem',
        'imageSize': '${(imageBytes.length / 1024).toStringAsFixed(1)} KB',
        'mimeType': mimeType,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('ImageVisionService: Erro na análise - $e');
      return {
        'success': false,
        'message': 'Erro na análise da imagem: $e',
      };
    }
  }

  /// Analisa múltiplas imagens (útil para conjuntos de documentos)
  static Future<Map<String, dynamic>> analyzeMultipleImages(List<File> images) async {
    try {
      if (images.isEmpty) {
        return {
          'success': false,
          'message': 'Nenhuma imagem fornecida para análise',
        };
      }

      List<DataPart> imageParts = [];
      int totalSize = 0;

      // Processa cada imagem
      for (File image in images) {
        final bytes = await image.readAsBytes();
        imageParts.add(DataPart('image/jpeg', bytes));
        totalSize += bytes.length;
      }

      final prompt = '''
Analise este conjunto de documentos para emplacamento veicular.

Para cada documento, forneça:
1. **Tipo de documento**
2. **Qualidade da imagem**
3. **Informações principais**
4. **Compatibilidade entre documentos**
5. **Problemas identificados**
6. **Recomendações finais**

Verifique se os documentos são consistentes entre si (nomes, dados do veículo, etc.).
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          ...imageParts,
        ])
      ];

      final response = await visionModel.generateContent(content);
      
      return {
        'success': true,
        'analysis': response.text ?? 'Não foi possível analisar as imagens',
        'imageCount': images.length,
        'totalSize': '${(totalSize / 1024).toStringAsFixed(1)} KB',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na análise de múltiplas imagens: $e',
      };
    }
  }

  /// Analisa imagem com contexto específico
  static Future<Map<String, dynamic>> analyzeImageWithContext(
    File imageFile, 
    String context,
  ) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
Contexto adicional: $context

Analise este documento considerando o contexto fornecido.

Forneça análise detalhada com foco no processo de emplacamento:
1. **Identificação do documento**
2. **Relevância para o contexto**
3. **Dados importantes extraídos**
4. **Validações necessárias**
5. **Próximos passos recomendados**
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await visionModel.generateContent(content);
      
      return {
        'success': true,
        'analysis': response.text ?? 'Não foi possível analisar a imagem',
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na análise contextual da imagem: $e',
      };
    }
  }

  /// Extrai texto específico de documentos (OCR focado)
  static Future<Map<String, dynamic>> extractDocumentText(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
Extraia APENAS o texto visível neste documento.

Organize as informações em formato estruturado:
- Nome completo:
- CPF:
- RG:
- Endereço:
- Dados do veículo (se aplicável):
  - Placa:
  - Renavam:
  - Chassi:
  - Marca/Modelo:
  - Ano:
- Outras informações relevantes:

Mantenha a formatação original dos dados quando possível.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await visionModel.generateContent(content);
      
      return {
        'success': true,
        'extractedText': response.text ?? 'Não foi possível extrair texto',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na extração de texto: $e',
      };
    }
  }

  /// Valida documento específico
  static Future<Map<String, dynamic>> validateDocument(
    File imageFile, 
    String documentType,
  ) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
Valide este $documentType para emplacamento veicular.

Critérios de validação:
1. **Autenticidade**: O documento parece autêntico?
2. **Legibilidade**: Todos os campos estão legíveis?
3. **Completude**: Todas as informações obrigatórias estão presentes?
4. **Validade**: O documento está dentro do prazo de validade?
5. **Conformidade**: Atende aos padrões do $documentType?

Forneça um relatório detalhado com aprovação/reprovação e justificativas.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await visionModel.generateContent(content);
      
      return {
        'success': true,
        'validation': response.text ?? 'Não foi possível validar o documento',
        'documentType': documentType,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na validação do documento: $e',
      };
    }
  }

  /// Analisa documento veicular com foco em chassi, placa e Renavam
  static Future<Map<String, dynamic>> analyzeVehicleDocument(File imageFile) async {
    try {
      print('ImageVisionService: Iniciando análise veicular de ${imageFile.path}');
      
      // Verifica se o arquivo existe
      if (!await imageFile.exists()) {
        throw Exception('Arquivo de imagem não encontrado');
      }

      // Verifica o tamanho do arquivo
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Arquivo de imagem está vazio');
      }

      // Primeira análise: extração específica de dados veiculares
      final vehicleDataResult = await VehicleDataExtractionService.extractVehicleData(imageFile);
      
      // Segunda análise: análise geral do documento
      final generalAnalysis = await analyzeImage(imageFile);
      
      // Combina os resultados
      String finalAnalysis;
      
      if (vehicleDataResult['success'] == true) {
        // Formata resultado da extração de dados veiculares
        final extractionText = VehicleDataExtractionService.formatExtractionResult(vehicleDataResult);
        
        // Combina com análise geral se houver
        if (generalAnalysis['success'] == true) {
          finalAnalysis = '''$extractionText

---

📄 **ANÁLISE GERAL DO DOCUMENTO:**
${generalAnalysis['analysis']}''';
        } else {
          finalAnalysis = extractionText;
        }
      } else {
        // Se extração falhou, usa análise geral
        if (generalAnalysis['success'] == true) {
          finalAnalysis = '''⚠️ **Extração automática de dados não foi possível**

${generalAnalysis['analysis']}

💡 **Dica:** Para melhor extração de chassi, placa e Renavam, certifique-se que estes dados estão bem visíveis na imagem.''';
        } else {
          finalAnalysis = '''❌ **Erro na análise do documento**

Não foi possível analisar o documento. Tente:
• Enviar uma imagem com melhor qualidade
• Garantir boa iluminação
• Certificar que o documento está totalmente visível
• Verificar se não há reflexos ou sombras''';
        }
      }
      
      return {
        'success': true,
        'analysis': finalAnalysis,
        'vehicleData': vehicleDataResult,
        'generalAnalysis': generalAnalysis,
        'imageSize': '${(fileSize / 1024).toStringAsFixed(1)} KB',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('ImageVisionService: Erro na análise veicular - $e');
      return {
        'success': false,
        'message': 'Erro na análise do documento veicular: $e',
      };
    }
  }

  /// Analisa documento veicular com foco em chassi, placa e Renavam a partir de bytes
  static Future<Map<String, dynamic>> analyzeVehicleDocumentFromBytes(Uint8List imageBytes) async {
    try {
      print('ImageVisionService: Iniciando análise veicular de bytes');
      
      if (imageBytes.isEmpty) {
        throw Exception('Dados de imagem estão vazios');
      }

      // Primeira análise: extração específica de dados veiculares
      final vehicleDataResult = await VehicleDataExtractionService.extractVehicleDataFromBytes(imageBytes);
      
      // Segunda análise: análise geral do documento (simulando um arquivo temporário)
      final generalAnalysis = await _analyzeImageFromBytes(imageBytes);
      
      // Combina os resultados
      String finalAnalysis;
      
      if (vehicleDataResult['success'] == true) {
        // Formata resultado da extração de dados veiculares
        final extractionText = VehicleDataExtractionService.formatExtractionResult(vehicleDataResult);
        
        // Combina com análise geral se houver
        if (generalAnalysis['success'] == true) {
          finalAnalysis = '''$extractionText

---

📄 **ANÁLISE GERAL DO DOCUMENTO:**
${generalAnalysis['analysis']}''';
        } else {
          finalAnalysis = extractionText;
        }
      } else {
        // Se extração falhou, usa análise geral
        if (generalAnalysis['success'] == true) {
          finalAnalysis = '''⚠️ **Extração automática de dados não foi possível**

${generalAnalysis['analysis']}

💡 **Dica:** Para melhor extração de chassi, placa e Renavam, certifique-se que estes dados estão bem visíveis na imagem.''';
        } else {
          finalAnalysis = '''❌ **Erro na análise do documento**

Não foi possível analisar o documento. Tente:
• Enviar uma imagem com melhor qualidade
• Garantir boa iluminação
• Certificar que o documento está totalmente visível
• Verificar se não há reflexos ou sombras''';
        }
      }
      
      return {
        'success': true,
        'analysis': finalAnalysis,
        'vehicleData': vehicleDataResult,
        'generalAnalysis': generalAnalysis,
        'imageSize': '${(imageBytes.length / 1024).toStringAsFixed(1)} KB',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('ImageVisionService: Erro na análise veicular de bytes - $e');
      return {
        'success': false,
        'message': 'Erro na análise do documento veicular: $e',
      };
    }
  }

  /// Método auxiliar para análise de imagem a partir de bytes
  static Future<Map<String, dynamic>> _analyzeImageFromBytes(Uint8List imageBytes) async {
    try {
      // Determina o tipo MIME da imagem
      String mimeType = 'image/jpeg';
      
      print('ImageVisionService: Analisando imagem de ${imageBytes.length} bytes');
      
      // Cria o conteúdo com imagem para análise
      final prompt = '''
Analise este documento relacionado ao emplacamento veicular.

Por favor, forneça:
1. **Tipo de documento**: Identifique qual documento é este
2. **Qualidade**: Avalie se a imagem está legível
3. **Dados extraídos**: Liste as informações visíveis e importantes
4. **Problemas identificados**: Aponte qualquer irregularidade
5. **Recomendações**: Sugira os próximos passos

Seja detalhista e prático em suas orientações.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      print('ImageVisionService: Enviando para análise...');
      
      // Envia para análise
      final response = await visionModel.generateContent(content);
      
      print('ImageVisionService: Análise concluída');
      
      return {
        'success': true,
        'analysis': response.text ?? 'Não foi possível analisar a imagem',
        'imageSize': '${(imageBytes.length / 1024).toStringAsFixed(1)} KB',
        'mimeType': mimeType,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('ImageVisionService: Erro na análise - $e');
      return {
        'success': false,
        'message': 'Erro na análise da imagem: $e',
      };
    }
  }
}
