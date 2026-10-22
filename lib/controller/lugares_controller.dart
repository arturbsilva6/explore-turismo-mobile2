import 'package:flutter/material.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/lugares_services.dart';
import 'package:guia_turismo/services/session_service.dart';

class LugaresController extends ChangeNotifier {
  bool carregando = false;
  bool cadastrando = false;
  String erro = '';
  String erroCadastro = '';

  List<LugaresModel> _lugares = [];
  List<LugaresModel> get lugares => _lugares;

  LugaresController() {
    listaLugares();
  }

  Future<void> listaLugares() async {
    carregando = true;
    erro = '';
    notifyListeners();
    try {
      _lugares = await LugaresServices().buscarLugares();
    } catch (e) {
      erro = 'Erro ao listar: $e';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<String> cadastrarLugar(LugaresModel dados) async {
    cadastrando = true;
    erroCadastro = '';
    notifyListeners();
    try {
      final token = await SessionService().pegarToken() ?? '';
      final mensagem = await LugaresServices().cadastrarLugar(dados, token);
      // Atualiza a lista após o servidor confirmar o cadastro.
      await listaLugares();
      return mensagem;
    } catch (e) {
      erroCadastro = 'Erro ao cadastrar: $e';
      return erroCadastro;
    } finally {
      cadastrando = false;
      notifyListeners();
    }
  }
}
