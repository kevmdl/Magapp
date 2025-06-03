import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

class VehicleDataExtractionService {
  static GenerativeModel? _extractionModel;

  static GenerativeModel get extractionModel {
    _extractionModel ??= GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: ApiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Máxima precisão para extração de dados
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
      systemInstruction: Content.text(_getExtractionSystemPrompt()),
    );
    return _extractionModel!;
  }

  static String _getExtractionSystemPrompt() {
    return '''
Você é um especialista em extração de dados veiculares do Brasil.

FUNÇÃO: Extrair CHASSI, PLACA e RENAVAM de documentos veiculares e determinar necessidade de emplacamento.

FORMATOS DE PLACA BRASILEIRA:
1. MODELO ANTIGO: AAA-9999 (3 letras + hífen + 4 números)
   Exemplo: ABC-1234
   
2. MODELO MERCOSUL: AAA9A99 (3 letras + 1 número + 1 letra + 2 números)
   Exemplo: ABC1D23

REGRAS DE ANÁLISE:
• CHASSI: Sempre 17 caracteres alfanuméricos
• RENAVAM: 11 dígitos numéricos
• PLACA: Identificar modelo (antigo ou Mercosul)

DETERMINAÇÃO DE EMPLACAMENTO:
• PLACA MODELO ANTIGO → Não precisa emplacar (já atende legislação atual)
• PLACA MODELO MERCOSUL → Pode fazer pedido de nova placa se desejar
• SEM PLACA → Necessário emplacamento

FORMATO DE RESPOSTA:
```json
{
  "chassi": "valor_encontrado_ou_null",
  "placa": "valor_encontrado_ou_null", 
  "renavam": "valor_encontrado_ou_null",
  "modelo_placa": "antigo|mercosul|nao_identificado",
  "precisa_emplacar": true|false,
  "orientacao": "texto_explicativo",
  "dados_completos": true|false
}
```

Seja EXTREMAMENTE preciso na extração dos dados!
''';
  }

  /// Extrai dados específicos do veículo (chassi, placa, renavam)
  static Future<Map<String, dynamic>> extractVehicleData(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
Extraia APENAS os seguintes dados deste documento veicular:

1. **CHASSI** (17 caracteres alfanuméricos)
2. **PLACA** (formato brasileiro)
3. **RENAVAM** (11 dígitos)

Analise a PLACA para determinar:
- Se é modelo ANTIGO (AAA-9999) 
- Se é modelo MERCOSUL (AAA9A99)

IMPORTANTE: Responda SEMPRE no formato JSON especificado no sistema.

Se não encontrar algum dado, use null no campo correspondente.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await extractionModel.generateContent(content);
      
      if (response.text != null) {
        return _parseExtractionResponse(response.text!);
      } else {
        return _createErrorResponse('Resposta vazia da IA');
      }
      
    } catch (e) {
      return _createErrorResponse('Erro na extração: $e');
    }
  }

  /// Extrai dados específicos do veículo a partir de bytes da imagem
  static Future<Map<String, dynamic>> extractVehicleDataFromBytes(Uint8List imageBytes) async {
    try {
      final prompt = '''
Extraia APENAS os seguintes dados deste documento veicular:

1. **CHASSI** (17 caracteres alfanuméricos)
2. **PLACA** (formato brasileiro)
3. **RENAVAM** (11 dígitos)

Analise a PLACA para determinar:
- Se é modelo ANTIGO (AAA-9999) 
- Se é modelo MERCOSUL (AAA9A99)

IMPORTANTE: Responda SEMPRE no formato JSON especificado no sistema.

Se não encontrar algum dado, use null no campo correspondente.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await extractionModel.generateContent(content);
      
      if (response.text != null) {
        return _parseExtractionResponse(response.text!);
      } else {
        return _createErrorResponse('Resposta vazia da IA');
      }
      
    } catch (e) {
      return _createErrorResponse('Erro na extração: $e');
    }
  }

  /// Analisa múltiplas imagens para extrair dados do veículo
  static Future<Map<String, dynamic>> extractFromMultipleImages(List<File> images) async {
    try {
      List<Map<String, dynamic>> allExtractions = [];
      
      for (File image in images) {
        final extraction = await extractVehicleData(image);
        allExtractions.add(extraction);
      }
      
      // Consolida os dados de todas as imagens
      return _consolidateExtractions(allExtractions);
      
    } catch (e) {
      return _createErrorResponse('Erro na análise múltipla: $e');
    }
  }

  /// Valida formato de chassi brasileiro
  static bool isValidChassi(String chassi) {
    if (chassi.length != 17) return false;
    
    // Chassi não pode conter I, O, Q
    final invalidChars = ['I', 'O', 'Q'];
    for (String char in invalidChars) {
      if (chassi.toUpperCase().contains(char)) return false;
    }
    
    return RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(chassi.toUpperCase());
  }

  /// Valida formato de Renavam brasileiro
  static bool isValidRenavam(String renavam) {
    return RegExp(r'^\d{11}$').hasMatch(renavam);
  }

  /// Identifica modelo da placa brasileira
  static String identifyPlateModel(String placa) {
    // Remove espaços e converte para maiúsculo
    placa = placa.replaceAll(' ', '').toUpperCase();
    
    // Modelo antigo: AAA-9999 ou AAA9999
    if (RegExp(r'^[A-Z]{3}-?\d{4}$').hasMatch(placa)) {
      return 'antigo';
    }
    
    // Modelo Mercosul: AAA9A99
    if (RegExp(r'^[A-Z]{3}\d[A-Z]\d{2}$').hasMatch(placa)) {
      return 'mercosul';
    }
    
    return 'nao_identificado';
  }

  /// Gera orientação baseada no modelo da placa
  static String generatePlateGuidance(String modeloPlaca, bool hasPlaca) {
    if (!hasPlaca) {
      return '''🚗 **VEÍCULO SEM PLACA IDENTIFICADA**

✅ **Ação necessária:** Emplacamento obrigatório
📋 **Próximo passo:** Fazer pedido de emplacamento pelo app

➡️ **Como proceder:**
1. Clique no botão "Fazer Pedido" no menu (📎)
2. Preencha o formulário com os dados do veículo
3. Anexe todos os documentos necessários
4. Aguarde aprovação e agendamento

💡 **Documentos necessários:** CRV, comprovante de residência, documento do proprietário''';
    }
    
    switch (modeloPlaca) {
      case 'antigo':
        return '''🚗 **PLACA MODELO ANTIGO IDENTIFICADA**

✅ **Situação:** Sua placa está em conformidade com a legislação atual
❌ **Emplacamento:** NÃO é necessário fazer novo emplacamento
📋 **Status:** Pode circular normalmente

💡 **Informação importante:** 
Placas no modelo antigo (ABC-1234) continuam válidas e não precisam ser substituídas obrigatoriamente.

🔄 **Opção:** Se desejar, pode solicitar placa Mercosul voluntariamente''';

      case 'mercosul':
        return '''🚗 **PLACA MODELO MERCOSUL IDENTIFICADA**

✅ **Situação:** Sua placa já está no padrão Mercosul atual
📋 **Emplacamento:** Placa já atende às normas vigentes
🎯 **Opção disponível:** Pode solicitar nova placa se desejar

➡️ **Para solicitar nova placa Mercosul:**
1. Clique no botão "Fazer Pedido" no menu (📎)
2. Selecione "Pedido de nova placa"
3. Preencha os dados do veículo
4. Anexe documentação necessária

💡 **Motivos para nova placa:** Danos, roubo, personalização ou atualização''';

      default:
        return '''🚗 **PLACA NÃO IDENTIFICADA CLARAMENTE**

⚠️ **Situação:** Não foi possível determinar o modelo da placa
🔍 **Necessário:** Verificação manual ou nova imagem

➡️ **Recomendações:**
1. Envie nova foto da placa com melhor qualidade
2. Certifique-se que a placa está legível
3. Tire foto com boa iluminação

📞 **Dúvidas:** Entre em contato para análise personalizada''';
    }
  }

  /// Converte resposta da IA em dados estruturados
  static Map<String, dynamic> _parseExtractionResponse(String response) {
    try {
      // Remove possíveis marcações de código
      String cleanResponse = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Tenta fazer parse do JSON
      final data = _extractJsonFromText(cleanResponse);
      
      if (data != null) {
        // Valida e enriquece os dados
        return _enrichExtractionData(data);
      } else {
        // Se não conseguir parse, extrai manualmente
        return _manualExtraction(response);
      }
      
    } catch (e) {
      return _createErrorResponse('Erro no parse da resposta: $e');
    }
  }

  /// Extrai JSON de texto que pode conter outros conteúdos
  static Map<String, dynamic>? _extractJsonFromText(String text) {
    try {
      // Procura por { e } para extrair JSON
      int startIndex = text.indexOf('{');
      int endIndex = text.lastIndexOf('}');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        String jsonString = text.substring(startIndex, endIndex + 1);
        return _parseJsonSafely(jsonString);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse JSON com tratamento de erros
  static Map<String, dynamic>? _parseJsonSafely(String jsonString) {
    try {
      // Implementação básica de parse JSON
      // Em um ambiente real, usar dart:convert
      return _basicJsonParse(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Parse JSON básico (simplificado)
  static Map<String, dynamic> _basicJsonParse(String jsonString) {
    // Esta é uma implementação simplificada
    // Em produção, usar dart:convert
    Map<String, dynamic> result = {};
    
    // Remove chaves externas
    jsonString = jsonString.trim();
    if (jsonString.startsWith('{')) jsonString = jsonString.substring(1);
    if (jsonString.endsWith('}')) jsonString = jsonString.substring(0, jsonString.length - 1);
    
    // Divide por vírgulas (simplificado)
    List<String> pairs = jsonString.split(',');
    
    for (String pair in pairs) {
      List<String> keyValue = pair.split(':');
      if (keyValue.length == 2) {
        String key = keyValue[0].trim().replaceAll('"', '');
        String value = keyValue[1].trim().replaceAll('"', '');
        
        // Converte valores especiais
        if (value == 'null') {
          result[key] = null;
        } else if (value == 'true') {
          result[key] = true;
        } else if (value == 'false') {
          result[key] = false;
        } else {
          result[key] = value;
        }
      }
    }
    
    return result;
  }

  /// Enriquece dados extraídos com validações e informações adicionais
  static Map<String, dynamic> _enrichExtractionData(Map<String, dynamic> data) {
    // Valida e formata chassi
    String? chassi = data['chassi'];
    if (chassi != null && chassi != 'null') {
      chassi = chassi.toUpperCase().replaceAll(' ', '');
      data['chassi_valido'] = isValidChassi(chassi);
    } else {
      data['chassi_valido'] = false;
    }
    
    // Valida e formata Renavam
    String? renavam = data['renavam'];
    if (renavam != null && renavam != 'null') {
      renavam = renavam.replaceAll(' ', '').replaceAll('.', '');
      data['renavam_valido'] = isValidRenavam(renavam);
    } else {
      data['renavam_valido'] = false;
    }
    
    // Analisa placa
    String? placa = data['placa'];
    bool hasPlaca = placa != null && placa != 'null' && placa.trim().isNotEmpty;
      if (hasPlaca) {
      String modeloPlaca = identifyPlateModel(placa);
      data['modelo_placa'] = modeloPlaca;
      data['precisa_emplacar'] = false; // Tem placa, não precisa emplacar obrigatoriamente
      data['orientacao'] = generatePlateGuidance(modeloPlaca, true);
    } else {
      data['modelo_placa'] = 'nao_identificado';
      data['precisa_emplacar'] = true; // Sem placa, precisa emplacar
      data['orientacao'] = generatePlateGuidance('nao_identificado', false);
    }
    
    // Determina se os dados estão completos
    data['dados_completos'] = (chassi != null && chassi != 'null') &&
                               (renavam != null && renavam != 'null') &&
                               hasPlaca;
    
    data['success'] = true;
    data['timestamp'] = DateTime.now().toIso8601String();
    
    return data;
  }

  /// Extração manual quando JSON parse falha
  static Map<String, dynamic> _manualExtraction(String response) {
    Map<String, dynamic> result = {
      'success': true,
      'chassi': null,
      'placa': null,
      'renavam': null,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Busca padrões específicos no texto
    String upperResponse = response.toUpperCase();
    
    // Busca chassi (17 caracteres alfanuméricos)
    RegExp chassiRegex = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b');
    Match? chassiMatch = chassiRegex.firstMatch(upperResponse);
    if (chassiMatch != null) {
      result['chassi'] = chassiMatch.group(0);
    }
    
    // Busca Renavam (11 dígitos)
    RegExp renavamRegex = RegExp(r'\b\d{11}\b');
    Match? renavamMatch = renavamRegex.firstMatch(response);
    if (renavamMatch != null) {
      result['renavam'] = renavamMatch.group(0);
    }
    
    // Busca placa (modelos brasileiro)
    RegExp placaRegex = RegExp(r'\b[A-Z]{3}[-\s]?\d{4}\b|\b[A-Z]{3}\d[A-Z]\d{2}\b');
    Match? placaMatch = placaRegex.firstMatch(upperResponse);
    if (placaMatch != null) {
      result['placa'] = placaMatch.group(0);
    }
    
    return _enrichExtractionData(result);
  }

  /// Consolida extrações de múltiplas imagens
  static Map<String, dynamic> _consolidateExtractions(List<Map<String, dynamic>> extractions) {
    Map<String, dynamic> consolidated = {
      'success': true,
      'chassi': null,
      'placa': null,
      'renavam': null,
      'fontes': [],
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Consolida dados de todas as extrações
    for (int i = 0; i < extractions.length; i++) {
      Map<String, dynamic> extraction = extractions[i];
      
      // Prioriza dados válidos
      if (extraction['chassi'] != null && consolidated['chassi'] == null) {
        consolidated['chassi'] = extraction['chassi'];
        consolidated['fontes'].add('Imagem ${i + 1}: chassi');
      }
      
      if (extraction['placa'] != null && consolidated['placa'] == null) {
        consolidated['placa'] = extraction['placa'];
        consolidated['fontes'].add('Imagem ${i + 1}: placa');
      }
      
      if (extraction['renavam'] != null && consolidated['renavam'] == null) {
        consolidated['renavam'] = extraction['renavam'];
        consolidated['fontes'].add('Imagem ${i + 1}: renavam');
      }
    }
    
    return _enrichExtractionData(consolidated);
  }

  /// Cria resposta de erro padronizada
  static Map<String, dynamic> _createErrorResponse(String message) {
    return {
      'success': false,
      'error': message,
      'chassi': null,
      'placa': null,
      'renavam': null,
      'orientacao': 'Não foi possível analisar o documento. Tente enviar uma nova imagem com melhor qualidade.',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Formata resultado para exibição no chat
  static String formatExtractionResult(Map<String, dynamic> extraction) {
    if (extraction['success'] != true) {
      return '''❌ **Erro na análise do documento**

${extraction['error'] ?? 'Erro desconhecido'}

💡 **Dica:** Envie uma nova imagem com melhor qualidade e iluminação.''';
    }
    
    String result = '''🔍 **ANÁLISE DE DADOS VEICULARES**\n\n''';
    
    // Dados extraídos
    result += '''📋 **DADOS IDENTIFICADOS:**\n''';
    
    if (extraction['chassi'] != null) {
      String chassi = extraction['chassi'];
      bool valido = extraction['chassi_valido'] ?? false;
      result += '''• **CHASSI:** $chassi ${valido ? '✅' : '⚠️'}\n''';
    } else {
      result += '''• **CHASSI:** Não identificado ❌\n''';
    }
    
    if (extraction['placa'] != null) {
      String placa = extraction['placa'];
      String modelo = extraction['modelo_placa'] ?? 'nao_identificado';
      String modeloTexto = modelo == 'antigo' ? '(Modelo Antigo)' :
                          modelo == 'mercosul' ? '(Modelo Mercosul)' : '';
      result += '''• **PLACA:** $placa $modeloTexto ✅\n''';
    } else {
      result += '''• **PLACA:** Não identificada ❌\n''';
    }
    
    if (extraction['renavam'] != null) {
      String renavam = extraction['renavam'];
      bool valido = extraction['renavam_valido'] ?? false;
      result += '''• **RENAVAM:** $renavam ${valido ? '✅' : '⚠️'}\n''';
    } else {
      result += '''• **RENAVAM:** Não identificado ❌\n''';
    }
    
    result += '''\n${extraction['orientacao'] ?? ''}''';
    
    // Dados completos
    bool completo = extraction['dados_completos'] ?? false;
    if (completo) {
      result += '''\n\n✅ **DOCUMENTAÇÃO COMPLETA** - Todos os dados principais foram identificados!''';
    } else {
      result += '''\n\n⚠️ **DOCUMENTAÇÃO INCOMPLETA** - Alguns dados não foram identificados. Considere enviar imagens adicionais.''';
    }
    
    return result;
  }
}
