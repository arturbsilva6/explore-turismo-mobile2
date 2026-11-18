import 'package:guia_turismo/services/auth_service.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  int idLogado = 0;
  bool carregando = false;
  String erro = '';

  Future<bool> autenticarUsuario(String email, String senha) async {
    if (carregando) return false;
    carregando = true;
    erro = '';
    notifyListeners();
    try {
      final Map dados = await AuthService().autenticar(email, senha);
      final token = dados['token'];
      final usuario = dados['usuario'];
      if (token is! String || token.trim().isEmpty || usuario is! Map ||
          usuario['email'] == null || usuario['nome'] == null) {
        erro = 'A API não retornou uma sessão válida. Tente novamente.';
        return false;
      }
      // Salva o JWT somente depois de validar o perfil completo.
      await SessionService().salvarUsuario(usuario);
      await SessionService().salvarToken(token);
      return true;
    } catch (e) {
      erro = 'Não foi possível entrar. Confira seus dados e a conexão.';
      return false;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> deslogarUsuario() async {
    await SessionService().logout();
  }
}
