// PARA A APRESENTAÇÃO: este arquivo guarda a sessão da API da faculdade e limpa os dados ao sair.
// As explicações abaixo ajudam a entender os passos sem alterar o resultado.
import 'package:shared_preferences/shared_preferences.dart';

/// Sessão da API acadêmica. Não confundir com o usuário do Firebase.
/// O token é armazenado localmente apenas para a demonstração acadêmica.
class SessionService {
  static String nome = '';
  static String email = '';

  // A função pegarNome busca o nome salvo no celular.
  Future<String> pegarNome() async {
    // Permite ler e escrever informações simples salvas no aparelho.
    final prefs = await SharedPreferences.getInstance();
    nome = prefs.getString('nome') ?? '';
    return nome;
  }

  // A função pegarEmail busca o e-mail da conta acadêmica.
  Future<String> pegarEmail() async {
    // Permite ler e escrever informações simples salvas no aparelho.
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';
    return email;
  }

  // A função salvarToken guarda o código de sessão devolvido pela API.
  Future<void> salvarToken(String token) async {
    // Permite ler e escrever informações simples salvas no aparelho.
    final prefs = await SharedPreferences.getInstance();
    // Aguarda essa etapa ser concluída antes de continuar.
    await prefs.setString('token', token);
  }

  // A função pegarToken busca o código que identifica a sessão na API.
  Future<String?> pegarToken() async {
    // Permite ler e escrever informações simples salvas no aparelho.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // A função temSessaoApi confere se há um código de acesso acadêmico salvo.
  Future<bool> temSessaoApi() async {
    // Guarda uma informação que será usada nesta parte.
    final token = await pegarToken();
    // Entrega a informação ou o componente que será usado depois.
    return token != null && token.trim().isNotEmpty;
  }

  /// Só invalida a identidade que enviou a requisição recusada.
  Future<bool> invalidarSeAtual(String tokenUsado) async {
    // Guarda uma informação que será usada nesta parte.
    final atual = await pegarToken();
    // Verifica se a informação de login pode ser usada.
    if (atual == null || atual != tokenUsado) return false;
    // Aguarda essa etapa ser concluída antes de continuar.
    await logout();
    // Entrega a informação ou o componente que será usado depois.
    return true;
  }

  // A função logout apaga do aparelho os dados de login da API.
  Future<void> logout() async {
    // Permite ler e escrever informações simples salvas no aparelho.
    final prefs = await SharedPreferences.getInstance();
    // Aguarda essa etapa ser concluída antes de continuar.
    await prefs.remove('token');
    // Aguarda essa etapa ser concluída antes de continuar.
    await prefs.remove('nome');
    // Aguarda essa etapa ser concluída antes de continuar.
    await prefs.remove('email');
    nome = '';
    email = '';
  }

  // A função salvarUsuario guarda nome e e-mail recebidos da API.
  Future<void> salvarUsuario(Map user) async {
    // Permite ler e escrever informações simples salvas no aparelho.
    final prefs = await SharedPreferences.getInstance();
    // Guarda uma informação que será usada nesta parte.
    final novoEmail = user['email']?.toString() ?? '';
    // Guarda uma informação que será usada nesta parte.
    final novoNome = user['nome']?.toString() ?? '';
    // Aguarda essa etapa ser concluída antes de continuar.
    await prefs.setString('email', novoEmail);
    // Aguarda essa etapa ser concluída antes de continuar.
    await prefs.setString('nome', novoNome);
    email = novoEmail;
    nome = novoNome;
  }
}

/// Requisição autenticada recusada por credencial inválida ou expirada.
class SessaoExpiradaException implements Exception {
  const SessaoExpiradaException();

  @override
  // A função toString function toString() { [native code] }.
  String toString() => 'Sua sessão da API expirou. Entre novamente.';
}
