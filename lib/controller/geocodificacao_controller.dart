import 'package:flutter/foundation.dart';
import 'package:guia_turismo/models/localizacao_model.dart';
import 'package:guia_turismo/services/geocodificacao_service.dart';

class GeocodificacaoController extends ChangeNotifier {
  final GeocodificacaoService service;
  bool carregando = false;
  bool pesquisou = false;
  String erro = '';
  List<LocalizacaoResultado> resultados = [];
  bool _descartado = false;

  GeocodificacaoController(this.service);

  Future<void> buscar(String consulta) async {
    if (carregando) return;
    carregando = true;
    pesquisou = false;
    erro = '';
    resultados = [];
    notifyListeners();
    try {
      resultados = await service.buscar(consulta);
      pesquisou = true;
    } catch (e) {
      erro = e is GeocodificacaoException
          ? e.mensagem
          : 'Não foi possível buscar a localização. Tente novamente.';
    } finally {
      carregando = false;
      if (!_descartado) notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
