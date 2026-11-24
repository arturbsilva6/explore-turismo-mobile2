// PARA A APRESENTAÇÃO: este arquivo mantém favoritos separados por conta, mesmo se a internet responder atrasada.
// Os comentários são explicações simples; as regras do código continuam iguais.
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/services/favoritos_service.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:guia_turismo/services/navegacao_service.dart';

/// Mantém favoritos separados por identidade e ignora respostas de sessões antigas.
class FavoritosController extends ChangeNotifier {
  FavoritosController({FavoritosService? service})
      : _service = service ?? FavoritosService();

  // É o objeto que faz a ligação com outra parte do aplicativo.
  final FavoritosService _service;
  Set<int> _ids = {};
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  final Set<int> _alterando = {};
  // Esse dado ajuda a separar a conta atual das operações antigas.
  int _geracao = 0;
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  bool _descartado = false;
  // Indica que há uma ação acontecendo e ajuda a impedir ações repetidas.
  bool carregando = false;
  // Guarda uma mensagem para explicar problemas ao usuário.
  String? erro;
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  bool _iniciado = false;
  // Esse dado ajuda a separar a conta atual das operações antigas.
  String _chave = 'favoritos_v2_visitante';

  // A função contem realiza os passos desta parte do aplicativo.
  bool contem(int id) => _ids.contains(id);
  // Esse getter permite consultar quantidade sem alterar a informação guardada.
  int get quantidade => _ids.length;
  List<int> get ids => _ids.toList(growable: false);

  // A função _vigente realiza os passos desta parte do aplicativo.
  bool _vigente(int geracao) => !_descartado && geracao == _geracao;

  /// Invalida operações pendentes e apaga os favoritos visíveis imediatamente.
  /// Não apaga os favoritos persistidos da conta: eles pertencem àquela conta.
  void limpar() {
    // Esse teste decide se o próximo passo deve acontecer.
    if (_descartado) return;
    _geracao++;
    _ids = {};
    _alterando.clear();
    _chave = 'favoritos_v2_visitante';
    _iniciado = false;
    carregando = false;
    erro = null;
    notifyListeners();
  }

  // A função carregar busca os dados que devem aparecer.
  Future<void> carregar() async {
    // Esse teste decide se o próximo passo deve acontecer.
    if (_descartado) return;
    // Uma mudança de conta pode ocorrer enquanto o GET anterior está pendente.
    final geracao = ++_geracao;
    _ids = {};
    _chave = 'favoritos_v2_visitante';
    _iniciado = false;
    carregando = true;
    erro = null;
    notifyListeners();
    // Tentamos realizar a tarefa, pois serviços externos podem falhar.
    try {
      // Guarda uma informação sobre a conta que está usando o app.
      final sessao = SessionService();
      // Guarda uma informação sobre a conta que está usando o app.
      final token = await sessao.pegarToken();
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (!_vigente(geracao)) return;
      // Guarda uma informação sobre a conta que está usando o app.
      final email = await sessao.pegarEmail();
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (!_vigente(geracao)) return;
      // Guarda um valor que será usado para decidir ou mostrar alguma informação.
      final uidGoogle = Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser?.uid : null;
      // Esse dado ajuda a separar a conta atual das operações antigas.
      final identidade = token != null && token.isNotEmpty
          ? 'api_${email.isNotEmpty ? email : 'sem_email'}'
          : uidGoogle != null ? 'google_$uidGoogle' : 'visitante';
      // Esse dado ajuda a separar a conta atual das operações antigas.
      final chave = 'favoritos_v2_$identidade';
      // É o objeto que faz a ligação com outra parte do aplicativo.
      final prefs = await SharedPreferences.getInstance();
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (!_vigente(geracao)) return;
      _chave = chave;
      _ids = prefs.getStringList(chave)
              ?.map(int.tryParse).whereType<int>().toSet() ?? <int>{};
      _iniciado = true;
      notifyListeners();

      // Verifica se o login permite continuar.
      if (token != null && token.isNotEmpty) {
        // Tentamos realizar a tarefa, pois serviços externos podem falhar.
        try {
          // Guarda uma informação sobre a conta que está usando o app.
          final recebidos = await _service.listar(token);
          // Ignora resultados de uma conta antiga para não misturar os favoritos.
          if (!_vigente(geracao)) return;
          _ids = recebidos;
          notifyListeners();
          // Espera o dado ser guardado ou recuperado no celular.
          await prefs.setStringList(chave, recebidos.map((v) => '$v').toList());
        } on SessaoExpiradaException {
          // Ignora resultados de uma conta antiga para não misturar os favoritos.
          if (_vigente(geracao) &&
              // Espera esta etapa terminar antes de continuar.
              await SessionService().invalidarSeAtual(token)) {
            limpar();
            NavegacaoService.irParaLogin();
          }
        } catch (_) {
          // Ignora resultados de uma conta antiga para não misturar os favoritos.
          if (_vigente(geracao)) {
            erro = 'Não foi possível sincronizar favoritos. Exibindo dados salvos.';
          }
        }
      }
    } catch (_) {
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (_vigente(geracao)) erro = 'Não foi possível carregar os favoritos.';
    } finally {
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (_vigente(geracao)) {
        carregando = false;
        notifyListeners();
      }
    }
  }

  // A função alternar troca o estado atual.
  Future<bool> alternar(int id) async {
    // Esse teste decide se o próximo passo deve acontecer.
    if (_descartado || id <= 0 || _alterando.contains(id)) return false;
    // Evita repetir uma ação enquanto ela ainda está acontecendo.
    if (!_iniciado) await carregar();
    // Esse teste decide se o próximo passo deve acontecer.
    if (_descartado || !_iniciado || _alterando.contains(id)) return false;
    // Esse dado ajuda a separar a conta atual das operações antigas.
    final geracao = _geracao;
    // Esse dado ajuda a separar a conta atual das operações antigas.
    final chave = _chave;
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
    final antigo = _ids.contains(id);
    _alterando.add(id);
    erro = null;
    // Guarda uma informação sobre a conta que está usando o app.
    String? tokenUsado;
    // Tentamos realizar a tarefa, pois serviços externos podem falhar.
    try {
      tokenUsado = await SessionService().pegarToken();
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (!_vigente(geracao)) return false;
      // Verifica se o login permite continuar.
      if (tokenUsado != null && tokenUsado.isNotEmpty) {
        // Espera esta etapa terminar antes de continuar.
        await _service.definir(tokenUsado, id, favorito: !antigo);
        // Ignora resultados de uma conta antiga para não misturar os favoritos.
        if (!_vigente(geracao)) return false;
      }
      // Guarda um valor que será usado para decidir ou mostrar alguma informação.
      final proximo = Set<int>.of(_ids);
      // Esse teste decide se o próximo passo deve acontecer.
      if (antigo) {
        proximo.remove(id);
      } else {
        proximo.add(id);
      }
      // É o objeto que faz a ligação com outra parte do aplicativo.
      final prefs = await SharedPreferences.getInstance();
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (!_vigente(geracao)) return false;
      // Espera o dado ser guardado ou recuperado no celular.
      await prefs.setStringList(chave, proximo.map((v) => '$v').toList());
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (!_vigente(geracao)) return false;
      _ids = proximo;
      notifyListeners();
      // Devolve o resultado dessa conferência para quem chamou a função.
      return true;
    } on SessaoExpiradaException {
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (_vigente(geracao)) {
        // Verifica se o login permite continuar.
        if (tokenUsado != null &&
            // Espera esta etapa terminar antes de continuar.
            await SessionService().invalidarSeAtual(tokenUsado)) {
          limpar();
          NavegacaoService.irParaLogin();
        }
      }
      // Devolve o resultado dessa conferência para quem chamou a função.
      return false;
    } catch (_) {
      // Ignora resultados de uma conta antiga para não misturar os favoritos.
      if (_vigente(geracao)) {
        erro = 'Não foi possível alterar o favorito. Tente novamente.';
        notifyListeners();
      }
      // Devolve o resultado dessa conferência para quem chamou a função.
      return false;
    } finally {
      // Nunca permita que a conclusão de uma conta afete outra.
      if (_vigente(geracao)) _alterando.remove(id);
    }
  }

  @override
  // A função dispose libera os recursos ao fechar a tela.
  void dispose() {
    _descartado = true;
    _geracao++;
    super.dispose();
  }
}
