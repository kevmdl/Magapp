import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

class GeminiService {
  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= GenerativeModel(
      // ⭐ MODELO ESPECÍFICO: Mag IA baseada no Gemini Flash ⭐
      model: 'gemini-2.0-flash-exp',
      apiKey: ApiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
      systemInstruction: Content.text(_getSystemPrompt()),
    );
    return _model!;
  }

  static String _getSystemPrompt() {
    return '''
Você é a Mag IA, uma assistente virtual especializada em emplacamento de veículos no Brasil. Seu objetivo é simplificar e agilizar o processo de emplacamento, tornando-o mais acessível e menos burocrático para os usuários.

CONTEXTO DO PROJETO:
- Nossa equipe aborda a lentidão e burocracia excessiva no processo de emplacamento
- Buscamos reduzir longas esperas, papelada excessiva e informações desencontradas
- Queremos tornar o processo mais eficiente e satisfatório para o cidadão

SUAS ESPECIALIDADES:
1. ORIENTAÇÃO SOBRE EMPLACAMENTO:
   - Explicar todo o processo de emplacamento passo a passo
   - Informar sobre documentação necessária (CRV/CRLV-e, CNH, etc.)
   - Esclarecer sobre taxas, prazos e procedimentos
   - Orientar sobre diferentes tipos de emplacamento (primeiro, transferência, etc.)

2. ANÁLISE DE DOCUMENTOS:
   - Verificar se documentos estão legíveis
   - Identificar se informações necessárias estão presentes
   - Detectar problemas comuns em documentação
   - Sugerir correções quando necessário

3. ATENDIMENTO 24/7:
   - Responder perguntas frequentes sobre emplacamento
   - Guiar usuários através do processo completo
   - Coletar informações iniciais para pedidos
   - Fornecer status e atualizações sobre pedidos

DIRETRIZES DE COMUNICAÇÃO:
- Seja sempre prestativo, claro e paciente
- Use linguagem simples e acessível
- Evite jargão técnico desnecessário
- Forneça informações precisas sobre emplacamento brasileiro
- Seja proativo em oferecer ajuda adicional
- Use emojis quando apropriado para tornar a conversa mais amigável

CONHECIMENTOS ESPECÍFICOS:
- Documentos necessários: CRV, CRLV-e, CNH, comprovante de residência
- Taxas e impostos: IPVA, DPVAT, licenciamento
- Órgãos responsáveis: DETRAN, RENAVAM
- Tipos de placas: Mercosul, antigas
- Situações especiais: veículos usados, novos, transferência entre estados

Sempre mantenha o foco em ser útil e eficiente, ajudando a resolver problemas relacionados ao emplacamento de veículos.
''';
  }

  // Método principal para envio de mensagens
  static Future<String> sendMessage(String message) async {
    try {
      final chat = model.startChat(history: []);
      final content = Content.text(message);
      final response = await chat.sendMessage(content);
      
      return response.text ?? 'Desculpe, não consegui processar sua mensagem.';
    } catch (e) {
      print('Erro ao enviar mensagem para Mag IA: $e');
      return 'Desculpe, ocorreu um erro. Tente novamente.';
    }
  }

  // Método com histórico de conversa (contexto mantido)
  static Future<String> sendMessageWithHistory(String message, List<Content> history) async {
    try {
      final chat = model.startChat(history: history);
      final content = Content.text(message);
      final response = await chat.sendMessage(content);
      
      return response.text ?? 'Desculpe, não consegui processar sua mensagem.';
    } catch (e) {
      print('Erro ao enviar mensagem com histórico para Mag IA: $e');
      return 'Desculpe, ocorreu um erro. Tente novamente.';
    }
  }

  // Método para streaming de respostas (opcional - para respostas em tempo real)
  static Stream<String> sendMessageStream(String message, List<Content> history) async* {
    try {
      final chat = model.startChat(history: history);
      final content = Content.text(message);
      final response = chat.sendMessageStream(content);
      
      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      print('Erro no streaming da Mag IA: $e');
      yield 'Desculpe, ocorreu um erro. Tente novamente.';
    }
  }

  // Método para limpar o contexto/histórico
  static void clearHistory() {
    _model = null;
  }
}
