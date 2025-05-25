class ApiConfig {
  static const String baseUrl = 'http://192.168.1.12:3000';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String verifyToken = '$baseUrl/api/auth/verify';
}
