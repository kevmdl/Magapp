class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Para emulador Android
  
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String verifyToken = '/api/auth/verify';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
