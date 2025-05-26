class ApiConfig {
  static const String baseUrl = 'http://192.168.15.49:3000';
  
  // ⭐ ADICIONE SUA API KEY DO GEMINI FLASH LITE 2.0 AQUI ⭐
  static const String geminiApiKey = 'AIzaSyC1JRQRC9xj1KPrU7eHss2RYepUXFykKmI';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String verifyToken = '$baseUrl/api/auth/verify';
}
