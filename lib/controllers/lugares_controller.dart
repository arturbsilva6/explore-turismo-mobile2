import 'dart:io';
import 'package:flutter/material.dart';
import 'package:guia_turismo/services/galeria_service.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/lugares_services.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:guia_turismo/services/navegacao_service.dart';

class LugaresController extends ChangeNotifier {
  final LugaresServices _service;
  bool limiteAtingido = false;
  bool carregando = false;
  bool cadastrando = false;
  String erro = '';
  String erroCadastro = '';

  List<LugaresModel> _lugares = [];
  List<LugaresModel> get lugares => _lugares;

  LugaresController({LugaresServices? service, bool carregarAoIniciar = true})
    : _service = service ?? LugaresServices() {
    if (carregarAoIniciar) listaLugares();
  }

  Future<void> listaLugares() async {
    if (carregando) return;
    carregando = true;
    erro = '';
    notifyListeners();
    try {
      _lugares = await _service.buscarLugares();
      limiteAtingido = _service.limiteAtingido;
    } catch (e) {
      erro = 'Erro ao listar: $e';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<String> cadastrarLugarComFoto(LugaresModel dados, File? imagem) async {
    if (imagem == null) return cadastrarLugar(dados);
    final idsAntes = _lugares.map((l) => l.id).toSet();
    final mensagem = await cadastrarLugar(dados);
    if (erroCadastro.isNotEmpty) return mensagem;
    int? id = _service.ultimoLugarCriadoId;
    if (id == null) {
      // Se o POST não informou o ID, só atribuímos a foto quando existir
      // exatamente um novo registro compatível após atualizar a listagem.
      final candidatos = _lugares.where((l) =>
          !idsAntes.contains(l.id) &&
          l.nome.trim().toLowerCase() == dados.nome.trim().toLowerCase() &&
          (l.latitude.toDouble() - dados.latitude.toDouble()).abs() < 0.00001 &&
          (l.longitude.toDouble() - dados.longitude.toDouble()).abs() < 0.00001
      ).toList();
      if (candidatos.length == 1) id = candidatos.single.id;
    }
    if (id == null) {
      return '$mensagem Foto não enviada: não foi possível identificar '
          'com segurança o ID do novo lugar. Adicione a foto pelos detalhes.';
    }
    final token = await SessionService().pegarToken() ?? '';
    try {
      await GaleriaService().enviarFoto(
        lugarId: id, caminho: imagem.path, token: token,
      );
      await listaLugares();
      return '$mensagem Foto adicionada à galeria.';
    } on SessaoExpiradaException {
      if (await SessionService().invalidarSeAtual(token)) {
        NavegacaoService.irParaLogin();
      }
      return '$mensagem Porém, a foto não foi enviada: sessão expirada.';
    } catch (_) {
      return '$mensagem Porém, a foto não foi enviada. Confira a conexão.';
    }
  }

  Future<String> cadastrarLugar(LugaresModel dados) async {
    String tokenUsado = '';
    cadastrando = true;
    erroCadastro = '';
    notifyListeners();
    try {
      tokenUsado = await SessionService().pegarToken() ?? '';
      final mensagem = await _service.cadastrarLugar(dados, tokenUsado);
      // Atualiza a lista após o servidor confirmar o cadastro.
      await listaLugares();
      return mensagem;
    } on SessaoExpiradaException {
      erroCadastro = 'Sua sessão expirou. Entre novamente para cadastrar.';
      if (await SessionService().invalidarSeAtual(tokenUsado)) {
        NavegacaoService.irParaLogin();
      }
      return erroCadastro;
    } catch (e) {
      erroCadastro = 'Não foi possível cadastrar o lugar. Verifique os dados e a conexão.';
      return erroCadastro;
    } finally {
      cadastrando = false;
      notifyListeners();
    }
  }
}
