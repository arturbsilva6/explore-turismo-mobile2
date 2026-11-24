// PARA A APRESENTAÇÃO: este arquivo organiza a busca por localização antes de preencher o cadastro.
// Os comentários são explicações simples; as regras do código continuam iguais.
import 'package:flutter/foundation.dart';
import 'package:guia_turismo/models/localizacao_model.dart';
import 'package:guia_turismo/services/geocodificacao_service.dart';

// A classe GeocodificacaoController junta as informações e funções deste assunto em um só lugar.
class GeocodificacaoController extends ChangeNotifier {
  // É o objeto que faz a ligação com outra parte do aplicativo.
  final GeocodificacaoService service;
  // Indica que há uma ação acontecendo e ajuda a impedir ações repetidas.
  bool carregando = false;
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  bool pesquisou = false;
  // Guarda uma mensagem para explicar problemas ao usuário.
  String erro = '';
  List<LocalizacaoResultado> resultados = [];
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  bool _descartado = false;

  GeocodificacaoController(this.service);

  // A função buscar faz uma busca e devolve o que encontrou.
  Future<void> buscar(String consulta) async {
    // Evita repetir uma ação enquanto ela ainda está acontecendo.
    if (carregando) return;
    carregando = true;
    pesquisou = false;
    erro = '';
    resultados = [];
    notifyListeners();
    // Tentamos realizar a tarefa, pois serviços externos podem falhar.
    try {
      resultados = await service.buscar(consulta);
      pesquisou = true;
    } catch (e) {
      erro = e is GeocodificacaoException
          ? e.mensagem
          : 'Não foi possível buscar a localização. Tente novamente.';
    } finally {
      carregando = false;
      // Esse teste decide se o próximo passo deve acontecer.
      if (!_descartado) notifyListeners();
    }
  }

  @override
  // A função dispose libera os recursos ao fechar a tela.
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
