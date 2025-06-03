import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../config/api_config.dart';

class DocumentAnalysisService {
  static GenerativeModel? _visionModel;

  static GenerativeModel get visionModel {
    _visionModel ??= GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: ApiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
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
      systemInstruction: Content.text(_getSystemPrompt()),
    );
    return _visionModel!;
  }

  static String _getSystemPrompt() {
    return '''
Você é a Mag IA, especialista em análise de documentos de emplacamento veicular brasileiro.

FUNÇÃO PRINCIPAL: Analisar documentos relacionados ao emplacamento de veículos em diversos formatos.

TIPOS DE ARQUIVOS SUPORTADOS:
• Imagens: JPG, PNG, WEBP, GIF
• Documentos PDF
• Documentos de texto
• Planilhas

DOCUMENTOS QUE VOCÊ ANALISA:
1. CRV (Certificado de Registro de Veículo)
2. CRLV-e (Certificado de Registro e Licenciamento de Veículo eletrônico)
3. CNH (Carteira Nacional de Habilitação)
4. Comprovantes de residência
5. Notas fiscais de veículos
6. Documentos de transferência
7. Contratos de financiamento
8. Laudos de vistoria
9. Certidões e declarações

ANÁLISE DETALHADA:
• Verificar legibilidade e integridade dos dados
• Identificar informações obrigatórias presentes/ausentes
• Validar formato e autenticidade dos documentos
• Detectar possíveis problemas ou irregularidades
• Orientar sobre correções necessárias
• Sugerir próximos passos no processo

FORMATO DE RESPOSTA:
1. **Tipo de documento**: Identificação clara do documento
2. **Formato do arquivo**: Tipo e qualidade do arquivo
3. **Dados extraídos**: Informações principais encontradas
4. **Validação**: Verificação de completude e correção
5. **Problemas**: Irregularidades ou dados faltantes
6. **Recomendações**: Próximos passos e orientações

Sempre mantenha o contexto de emplacamento veicular e seja prestativo!
''';
  }
  /// Seleciona e analisa qualquer tipo de documento
  static Future<Map<String, dynamic>> pickAndAnalyzeDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // Garante que os bytes são carregados
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        // Para web ou quando path não está disponível, usa bytes
        if (file.bytes != null) {
          return await analyzeDocumentFromBytes(
            file.bytes!, 
            file.name, 
            file.extension,
          );
        } 
        // Para mobile/desktop quando path está disponível
        else if (file.path != null) {
          return await analyzeDocument(File(file.path!));
        } 
        else {
          return {
            'success': false,
            'message': 'Arquivo não pôde ser carregado. Tente novamente.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Nenhum arquivo foi selecionado',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao selecionar arquivo: $e',
      };
    }
  }

  /// Analisa um documento específico
  static Future<Map<String, dynamic>> analyzeDocument(File documentFile) async {
    try {
      // Verifica o tipo MIME do arquivo
      final mimeType = lookupMimeType(documentFile.path);
      final fileName = documentFile.path.split('/').last;
      final fileSize = await documentFile.length();
      
      // Verifica se o arquivo é muito grande (máximo 20MB)
      if (fileSize > 20 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Arquivo muito grande. Tamanho máximo: 20MB',
        };
      }

      String analysisResult;

      if (mimeType != null && mimeType.startsWith('image/')) {
        // Análise de imagem
        analysisResult = await _analyzeImageDocument(documentFile, mimeType);
      } else if (mimeType == 'application/pdf') {
        // Análise de PDF
        analysisResult = await _analyzePdfDocument(documentFile);
      } else {
        // Análise de texto ou outros formatos
        analysisResult = await _analyzeTextDocument(documentFile);
      }

      return {
        'success': true,
        'analysis': analysisResult,
        'fileName': fileName,
        'fileSize': '${(fileSize / 1024).toStringAsFixed(1)} KB',
        'mimeType': mimeType ?? 'Desconhecido',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na análise do documento: $e',
      };
    }
  }

  /// Analisa documento de imagem
  static Future<String> _analyzeImageDocument(File imageFile, String mimeType) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    
    final prompt = '''
Analise este documento de emplacamento veicular na imagem.

Por favor, forneça uma análise completa incluindo:
1. **Tipo de documento**: Identifique qual documento é este
2. **Qualidade da imagem**: Avalie se está legível e nítida
3. **Dados extraídos**: Liste as informações visíveis e importantes
4. **Validação**: Verifique se os dados estão completos e corretos
5. **Problemas identificados**: Aponte qualquer irregularidade
6. **Recomendações**: Sugira os próximos passos

Seja detalhista e prático em suas orientações.
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ])
    ];

    final response = await visionModel.generateContent(content);
    return response.text ?? 'Não foi possível analisar a imagem';
  }

  /// Analisa documento PDF
  static Future<String> _analyzePdfDocument(File pdfFile) async {
    // Para PDFs, enviamos o arquivo como dados binários para análise
    final Uint8List pdfBytes = await pdfFile.readAsBytes();
    
    final prompt = '''
Analise este documento PDF relacionado ao emplacamento veicular.

Este é um arquivo PDF que pode conter:
- Documentos digitalizados (CRV, CRLV-e, CNH)
- Comprovantes de residência
- Notas fiscais
- Contratos e certidões

Por favor, forneça:
1. **Tipo de documento**: Identifique o tipo de documento PDF
2. **Conteúdo**: Descreva o conteúdo principal encontrado
3. **Dados importantes**: Liste informações relevantes para emplacamento
4. **Qualidade**: Avalie se o documento está legível
5. **Completude**: Verifique se todas as informações necessárias estão presentes
6. **Recomendações**: Orientações sobre uso do documento no processo

Seja específico sobre documentos de emplacamento veicular.
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('application/pdf', pdfBytes),
      ])
    ];

    final response = await visionModel.generateContent(content);
    return response.text ?? 'Não foi possível analisar o documento PDF';
  }

  /// Analisa documento de texto
  static Future<String> _analyzeTextDocument(File textFile) async {
    try {
      // Lê o conteúdo do arquivo de texto
      final String content = await textFile.readAsString();
      
      final prompt = '''
Analise este documento de texto relacionado ao emplacamento veicular.

Conteúdo do documento:
$content

Por favor, analise e forneça:
1. **Tipo de documento**: Identifique o tipo de documento
2. **Informações extraídas**: Liste dados relevantes para emplacamento
3. **Completude**: Verifique se está completo
4. **Formato**: Comente sobre a formatação e organização
5. **Validade**: Avalie se pode ser usado no processo de emplacamento
6. **Sugestões**: Recomendações para melhorar ou complementar

Seja específico sobre aspectos relacionados ao emplacamento de veículos.
''';

      final response = await visionModel.generateContent([Content.text(prompt)]);
      return response.text ?? 'Não foi possível analisar o documento de texto';
      
    } catch (e) {
      return 'Erro ao ler arquivo de texto: $e';
    }
  }

  /// Analisa múltiplos documentos
  static Future<Map<String, dynamic>> analyzeMultipleDocuments(List<File> documents) async {
    if (documents.isEmpty) {
      return {
        'success': false,
        'message': 'Nenhum documento fornecido para análise',
      };
    }

    try {
      List<Map<String, dynamic>> analyses = [];
      
      for (int i = 0; i < documents.length; i++) {
        final result = await analyzeDocument(documents[i]);
        analyses.add({
          'documentIndex': i + 1,
          'fileName': documents[i].path.split('/').last,
          'result': result,
        });
      }

      // Análise consolidada
      final consolidatedAnalysis = await _generateConsolidatedAnalysis(analyses);

      return {
        'success': true,
        'individualAnalyses': analyses,
        'consolidatedAnalysis': consolidatedAnalysis,
        'totalDocuments': documents.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na análise de múltiplos documentos: $e',
      };
    }
  }

  /// Gera análise consolidada de múltiplos documentos
  static Future<String> _generateConsolidatedAnalysis(List<Map<String, dynamic>> analyses) async {
    final prompt = '''
Com base nas análises individuais dos documentos a seguir, forneça uma análise consolidada para o processo de emplacamento:

${analyses.map((analysis) => '''
Documento ${analysis['documentIndex']}: ${analysis['fileName']}
Análise: ${analysis['result']['success'] ? analysis['result']['analysis'] : analysis['result']['message']}
''').join('\n')}

Por favor, forneça:
1. **Resumo geral**: Visão geral dos documentos analisados
2. **Documentos completos**: Quais estão prontos para uso
3. **Documentos pendentes**: Quais precisam de correção ou complemento
4. **Análise de completude**: O que está faltando para o processo completo
5. **Próximos passos**: Orientações prioritárias
6. **Cronograma sugerido**: Ordem recomendada de ações

Seja prático e direto nas recomendações.
''';

    final response = await visionModel.generateContent([Content.text(prompt)]);
    return response.text ?? 'Não foi possível gerar análise consolidada';
  }

  /// Lista tipos de documentos suportados
  static List<String> getSupportedDocumentTypes() {
    return [
      'Imagens (JPG, PNG, WEBP, GIF)',
      'Documentos PDF',
      'Arquivos de texto (TXT, DOC)',
      'Planilhas (CSV, XLS)',
      'Todos os tipos de arquivo',
    ];
  }

  /// Verifica se um tipo de arquivo é suportado
  static bool isFileTypeSupported(String? mimeType) {
    if (mimeType == null) return true; // Permite tipos desconhecidos
    
    return mimeType.startsWith('image/') ||
           mimeType == 'application/pdf' ||
           mimeType.startsWith('text/') ||
           mimeType.contains('document') ||
           mimeType.contains('spreadsheet');
  }

  /// Analisa documento a partir de bytes (útil para web)
  static Future<Map<String, dynamic>> analyzeDocumentFromBytes(
    Uint8List bytes, 
    String fileName, 
    String? extension,
  ) async {
    try {
      // Determina o tipo MIME baseado na extensão
      String? mimeType;
      if (extension != null) {
        switch (extension.toLowerCase()) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          case 'pdf':
            mimeType = 'application/pdf';
            break;
          case 'txt':
            mimeType = 'text/plain';
            break;
          case 'doc':
          case 'docx':
            mimeType = 'application/msword';
            break;
          default:
            mimeType = 'application/octet-stream';
        }
      }
      
      final fileSize = bytes.length;
      
      // Verifica se o arquivo é muito grande (máximo 20MB)
      if (fileSize > 20 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Arquivo muito grande. Tamanho máximo: 20MB',
        };
      }

      String analysisResult;

      if (mimeType != null && mimeType.startsWith('image/')) {
        // Análise de imagem
        analysisResult = await _analyzeImageDocumentFromBytes(bytes, mimeType);
      } else if (mimeType == 'application/pdf') {
        // Análise de PDF
        analysisResult = await _analyzePdfDocumentFromBytes(bytes);
      } else if (mimeType != null && mimeType.startsWith('text/')) {
        // Análise de texto
        analysisResult = await _analyzeTextDocumentFromBytes(bytes);
      } else {
        // Tentativa genérica
        analysisResult = await _analyzeGenericDocumentFromBytes(bytes, fileName);
      }

      return {
        'success': true,
        'analysis': analysisResult,
        'fileName': fileName,
        'fileSize': '${(fileSize / 1024).toStringAsFixed(1)} KB',
        'mimeType': mimeType ?? 'Desconhecido',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro na análise do documento: $e',
      };
    }
  }

  /// Analisa documento de imagem a partir de bytes
  static Future<String> _analyzeImageDocumentFromBytes(Uint8List imageBytes, String mimeType) async {
    final prompt = '''
Analise este documento de emplacamento veicular na imagem.

Por favor, forneça uma análise completa incluindo:
1. **Tipo de documento**: Identifique qual documento é este
2. **Qualidade da imagem**: Avalie se está legível e nítida
3. **Dados extraídos**: Liste as informações visíveis e importantes
4. **Validação**: Verifique se os dados estão completos e corretos
5. **Problemas identificados**: Aponte qualquer irregularidade
6. **Recomendações**: Sugira os próximos passos

Seja detalhista e prático em suas orientações.
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ])
    ];

    final response = await visionModel.generateContent(content);
    return response.text ?? 'Não foi possível analisar a imagem';
  }

  /// Analisa documento PDF a partir de bytes
  static Future<String> _analyzePdfDocumentFromBytes(Uint8List pdfBytes) async {
    final prompt = '''
Analise este documento PDF relacionado ao emplacamento veicular.

Este é um arquivo PDF que pode conter:
- Documentos digitalizados (CRV, CRLV-e, CNH)
- Comprovantes de residência
- Notas fiscais
- Contratos e certidões

Por favor, forneça:
1. **Tipo de documento**: Identifique o tipo de documento PDF
2. **Conteúdo**: Descreva o conteúdo principal encontrado
3. **Dados importantes**: Liste informações relevantes para emplacamento
4. **Qualidade**: Avalie se o documento está legível
5. **Completude**: Verifique se todas as informações necessárias estão presentes
6. **Recomendações**: Orientações sobre uso do documento no processo

Seja específico sobre documentos de emplacamento veicular.
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('application/pdf', pdfBytes),
      ])
    ];

    final response = await visionModel.generateContent(content);
    return response.text ?? 'Não foi possível analisar o documento PDF';
  }

  /// Analisa documento de texto a partir de bytes
  static Future<String> _analyzeTextDocumentFromBytes(Uint8List textBytes) async {
    try {
      // Converte os bytes para string
      final String content = String.fromCharCodes(textBytes);
      
      final prompt = '''
Analise este documento de texto relacionado ao emplacamento veicular.

Conteúdo do documento:
$content

Por favor, analise e forneça:
1. **Tipo de documento**: Identifique o tipo de documento
2. **Informações extraídas**: Liste dados relevantes para emplacamento
3. **Completude**: Verifique se está completo
4. **Formato**: Comente sobre a formatação e organização
5. **Validade**: Avalie se pode ser usado no processo de emplacamento
6. **Sugestões**: Recomendações para melhorar ou complementar

Seja específico sobre aspectos relacionados ao emplacamento de veículos.
''';

      final response = await visionModel.generateContent([Content.text(prompt)]);
      return response.text ?? 'Não foi possível analisar o documento de texto';
      
    } catch (e) {
      return 'Erro ao processar arquivo de texto: $e';
    }
  }

  /// Analisa documento genérico a partir de bytes
  static Future<String> _analyzeGenericDocumentFromBytes(Uint8List bytes, String fileName) async {
    final prompt = '''
Analise este documento relacionado ao emplacamento veicular.

Por favor, forneça uma análise completa incluindo:
1. **Tipo de documento**: Identifique qual documento é este
2. **Dados extraídos**: Liste as informações visíveis e importantes
3. **Problemas identificados**: Aponte qualquer irregularidade
4. **Recomendações**: Sugira os próximos passos

Seja detalhista e prático em suas orientações.
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('application/octet-stream', bytes),
      ])
    ];    final response = await visionModel.generateContent(content);
    return response.text ?? 'Não foi possível analisar o documento';
  }
}
