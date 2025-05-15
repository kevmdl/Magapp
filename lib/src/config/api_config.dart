class ApiConfig {
  // Configuração para localhost - Ajuste conforme seu ambiente de desenvolvimento
  // Para emulador Android: use 10.0.2.2 (que aponta para o localhost da sua máquina)
  // Para dispositivo físico: use o IP da sua máquina na rede local
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Endpoints da API
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyToken = '/auth/verify';
  
  // Cabeçalhos padrão
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
