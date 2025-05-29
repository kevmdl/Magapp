class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';
  
  // ⭐ ADICIONE SUA API KEY DA MAG IA (BASEADA NO GEMINI) AQUI ⭐
  static const String geminiApiKey = 'AIzaSyC1JRQRC9xj1KPrU7eHss2RYepUXFykKmI';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String verifyToken = '$baseUrl/api/auth/verify';
}
