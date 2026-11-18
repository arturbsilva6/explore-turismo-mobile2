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

  final FavoritosService _service;
  Set<int> _ids = {};
  final Set<int> _alterando = {};
  int _geracao = 0;
  bool _descartado = false;
  bool carregando = false;
  String? erro;
  bool _iniciado = false;
  String _chave = 'favoritos_v2_visitante';

  bool contem(int id) => _ids.contains(id);
  int get quantidade => _ids.length;
  List<int> get ids => _ids.toList(growable: false);

  bool _vigente(int geracao) => !_descartado && geracao == _geracao;

  /// Invalida operações pendentes e apaga os favoritos visíveis imediatamente.
  /// Não apaga os favoritos persistidos da conta: eles pertencem àquela conta.
  void limpar() {
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

  Future<void> carregar() async {
    if (_descartado) return;
    // Uma mudança de conta pode ocorrer enquanto o GET anterior está pendente.
    final geracao = ++_geracao;
    _ids = {};
    _chave = 'favoritos_v2_visitante';
    _iniciado = false;
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      final sessao = SessionService();
      final token = await sessao.pegarToken();
      if (!_vigente(geracao)) return;
      final email = await sessao.pegarEmail();
      if (!_vigente(geracao)) return;
      final uidGoogle = Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser?.uid : null;
      final identidade = token != null && token.isNotEmpty
          ? 'api_${email.isNotEmpty ? email : 'sem_email'}'
          : uidGoogle != null ? 'google_${uidGoogle}' : 'visitante';
      final chave = 'favoritos_v2_${identidade}';
      final prefs = await SharedPreferences.getInstance();
      if (!_vigente(geracao)) return;
      _chave = chave;
      _ids = prefs.getStringList(chave)
              ?.map(int.tryParse).whereType<int>().toSet() ?? <int>{};
      _iniciado = true;
      notifyListeners();

      if (token != null && token.isNotEmpty) {
        try {
          final recebidos = await _service.listar(token);
          if (!_vigente(geracao)) return;
          _ids = recebidos;
          notifyListeners();
          await prefs.setStringList(chave, recebidos.map((v) => '${v}').toList());
        } on SessaoExpiradaException {
          if (_vigente(geracao) &&
              await SessionService().invalidarSeAtual(token)) {
            limpar();
            NavegacaoService.irParaLogin();
          }
        } catch (_) {
          if (_vigente(geracao)) {
            erro = 'Não foi possível sincronizar favoritos. Exibindo dados salvos.';
          }
        }
      }
    } catch (_) {
      if (_vigente(geracao)) erro = 'Não foi possível carregar os favoritos.';
    } finally {
      if (_vigente(geracao)) {
        carregando = false;
        notifyListeners();
      }
    }
  }

  Future<bool> alternar(int id) async {
    if (_descartado || id <= 0 || _alterando.contains(id)) return false;
    if (!_iniciado) await carregar();
    if (_descartado || !_iniciado || _alterando.contains(id)) return false;
    final geracao = _geracao;
    final chave = _chave;
    final antigo = _ids.contains(id);
    _alterando.add(id);
    erro = null;
    try {
      final token = await SessionService().pegarToken();
      if (!_vigente(geracao)) return false;
      if (token != null && token.isNotEmpty) {
        await _service.definir(token, id, favorito: !antigo);
        if (!_vigente(geracao)) return false;
      }
      final proximo = Set<int>.of(_ids);
      if (antigo) {
        proximo.remove(id);
      } else {
        proximo.add(id);
      }
      final prefs = await SharedPreferences.getInstance();
      if (!_vigente(geracao)) return false;
      await prefs.setStringList(chave, proximo.map((v) => '${v}').toList());
      if (!_vigente(geracao)) return false;
      _ids = proximo;
      notifyListeners();
      return true;
    } on SessaoExpiradaException {
      if (_vigente(geracao)) {
        final tokenAtual = await SessionService().pegarToken();
        if (tokenAtual != null &&
            await SessionService().invalidarSeAtual(tokenAtual)) {
          limpar();
          NavegacaoService.irParaLogin();
        }
      }
      return false;
    } catch (_) {
      if (_vigente(geracao)) {
        erro = 'Não foi possível alterar o favorito. Tente novamente.';
        notifyListeners();
      }
      return false;
    } finally {
      // Nunca permita que a conclusão de uma conta afete outra.
      if (_vigente(geracao)) _alterando.remove(id);
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _geracao++;
    super.dispose();
  }
}
