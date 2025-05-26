import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

class GeminiService {
  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= GenerativeModel(
      // ⭐ MODELO ESPECÍFICO: Gemini Flash Lite 2.0 ⭐
      model: 'gemini-2.0-flash-exp',
      apiKey: ApiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192, // Flash Lite 2.0 suporta mais tokens
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
    return _model!;
  }

  // Método principal para envio de mensagens
  static Future<String> sendMessage(String message) async {
    try {
      final chat = model.startChat(history: []);
      final content = Content.text(message);
      final response = await chat.sendMessage(content);
      
      return response.text ?? 'Desculpe, não consegui processar sua mensagem.';
    } catch (e) {
      print('Erro ao enviar mensagem para Gemini Flash Lite 2.0: $e');
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
      print('Erro ao enviar mensagem com histórico para Gemini Flash Lite 2.0: $e');
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
      print('Erro no streaming do Gemini Flash Lite 2.0: $e');
      yield 'Desculpe, ocorreu um erro. Tente novamente.';
    }
  }

  // Método para limpar o contexto/histórico
  static void clearHistory() {
    _model = null;
  }
}
