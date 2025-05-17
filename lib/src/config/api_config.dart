class ApiConfig {
  // Get your computer's IP address
  static const String baseUrl = 'http://192.168.1.12:3000'; // Replace xxx with your IP
  
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String verifyToken = '/api/auth/verify';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
