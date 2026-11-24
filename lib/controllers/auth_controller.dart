// GUIA DE APRESENTAÇÃO — Neste arquivo, cuida do login pela API e mostra se a entrada deu certo ou falhou.
// Os comentários explicam a ideia de cada trecho sem mudar o funcionamento.
import 'package:guia_turismo/services/auth_service.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:flutter/foundation.dart';

// Esta classe AuthController reúne os dados e as ações dessa parte do aplicativo.
class AuthController extends ChangeNotifier {
  // Esta variável guarda uma informação usada nas próximas etapas.
  int idLogado = 0;
  // Esta variável indica se há uma tarefa acontecendo, para mostrar carregamento e evitar cliques repetidos.
  bool carregando = false;
  // Aqui guardamos um aviso para mostrar quando alguma operação não dá certo.
  String erro = '';

  // Esta função autenticarUsuario confere e envia os dados usados para entrar na API.
  Future<bool> autenticarUsuario(String email, String senha) async {
    // Evita começar outra tarefa igual enquanto a primeira ainda está em andamento.
    if (carregando) return false;
    carregando = true;
    erro = '';
    notifyListeners();
    // Tentamos realizar essa tarefa, sabendo que ela pode falhar.
    try {
      // Este dado ajuda a reconhecer a conta que está usando o aplicativo.
      final Map dados = await AuthService().autenticar(email, senha);
      // Este dado ajuda a reconhecer a conta que está usando o aplicativo.
      final token = dados['token'];
      // Este dado ajuda a reconhecer a conta que está usando o aplicativo.
      final usuario = dados['usuario'];
      // Só continua quando a situação de login permite esta ação.
      if (token is! String || token.trim().isEmpty || usuario is! Map ||
          usuario['email'] == null || usuario['nome'] == null) {
        erro = 'A API não retornou uma sessão válida. Tente novamente.';
        // Devolve o resultado desta verificação para quem chamou a função.
        return false;
      }
      // Salva o JWT somente depois de validar o perfil completo.
      await SessionService().salvarUsuario(usuario);
      // Espera esta etapa terminar antes de continuar.
      await SessionService().salvarToken(token);
      // Devolve o resultado desta verificação para quem chamou a função.
      return true;
    } catch (e) {
      erro = 'Não foi possível entrar. Confira seus dados e a conexão.';
      // Devolve o resultado desta verificação para quem chamou a função.
      return false;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // Esta função deslogarUsuario encerra a sessão da API.
  Future<void> deslogarUsuario() async {
    // Espera esta etapa terminar antes de continuar.
    await SessionService().logout();
  }
}
