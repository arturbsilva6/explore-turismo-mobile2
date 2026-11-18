import 'package:shared_preferences/shared_preferences.dart';

/// Sessão da API acadêmica. Não confundir com o usuário do Firebase.
/// O token é armazenado localmente apenas para a demonstração acadêmica.
class SessionService {
  static String nome = '';
  static String email = '';

  Future<String> pegarNome() async {
    final prefs = await SharedPreferences.getInstance();
    nome = prefs.getString('nome') ?? '';
    return nome;
  }

  Future<String> pegarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';
    return email;
  }

  Future<void> salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> pegarToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> temSessaoApi() async {
    final token = await pegarToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nome');
    await prefs.remove('email');
    nome = '';
    email = '';
  }

  Future<void> salvarUsuario(Map user) async {
    final prefs = await SharedPreferences.getInstance();
    final novoEmail = user['email']?.toString() ?? '';
    final novoNome = user['nome']?.toString() ?? '';
    await prefs.setString('email', novoEmail);
    await prefs.setString('nome', novoNome);
    email = novoEmail;
    nome = novoNome;
  }
}

/// Requisição autenticada recusada por credencial inválida ou expirada.
class SessaoExpiradaException implements Exception {
  const SessaoExpiradaException();

  @override
  String toString() => 'Sua sessão da API expirou. Entre novamente.';
}
