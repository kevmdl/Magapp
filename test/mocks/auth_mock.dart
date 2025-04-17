class AuthMock {
  bool login(String username, String password) {
    return username == 'test' && password == 'password';
  }

  bool register(String username, String password) {
    return username.isNotEmpty && password.length >= 6;
  }

  bool loginWithEmail(String email, String password) {
    return email == 'test@example.com' && password == 'password123';
  }

  bool registerWithEmail(String email, String nome, String telefone, String senha) {
    return email.contains('@') && 
           nome.isNotEmpty && 
           telefone.length >= 11 && 
           senha.length >= 6;
  }

  bool recoverPassword(String email) {
    return email.contains('@');
  }
}