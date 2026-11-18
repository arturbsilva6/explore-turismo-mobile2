import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/services/favoritos_service.dart';
import 'package:guia_turismo/services/session_service.dart';

/// Favoritos remotos para a sessão API; locais para acesso só via Google.
class FavoritosController extends ChangeNotifier {
  FavoritosController({FavoritosService? service})
      : _service = service ?? FavoritosService();

  final FavoritosService _service;
  Set<int> _ids = {};
  bool carregando = false;
  String? erro;
  bool _iniciado = false;
  String _chave = 'favoritos_local_visitante';

  bool contem(int id) => _ids.contains(id);
  int get quantidade => _ids.length;
  List<int> get ids => _ids.toList(growable: false);

  Future<void> carregar() async {
    if (carregando) return;
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      final sessao = SessionService();
      final email = await sessao.pegarEmail();
      final token = await sessao.pegarToken();
      _chave = 'favoritos_v2_${token != null && token.isNotEmpty ? email : 'visitante'}';
      final prefs = await SharedPreferences.getInstance();
      _ids = prefs.getStringList(_chave)
              ?.map(int.tryParse).whereType<int>().toSet() ?? <int>{};
      _iniciado = true;
      notifyListeners();
      if (token != null && token.isNotEmpty) {
        try {
          _ids = await _service.listar(token);
          await prefs.setStringList(_chave, _ids.map((v) => '$v').toList());
        } catch (_) {
          erro = 'Sem conexão para sincronizar favoritos. Exibindo dados locais.';
        }
      }
    } catch (_) {
      erro = 'Não foi possível carregar os favoritos.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<bool> alternar(int id) async {
    if (id <= 0) return false;
    if (!_iniciado) await carregar();
    final antigo = _ids.contains(id);
    final token = await SessionService().pegarToken();
    erro = null;
    try {
      if (token != null && token.isNotEmpty) {
        await _service.definir(token, id, favorito: !antigo);
      }
      if (antigo) {
        _ids.remove(id);
      } else {
        _ids.add(id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_chave, _ids.map((v) => '$v').toList());
      notifyListeners();
      return true;
    } catch (_) {
      erro = 'Não foi possível alterar o favorito. Tente novamente.';
      notifyListeners();
      return false;
    }
  }
}
