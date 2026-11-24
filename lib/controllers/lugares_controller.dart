// PARA A APRESENTAÇÃO: este arquivo carrega os lugares e salva novos lugares, incluindo fotos.
// Os comentários são explicações simples; as regras do código continuam iguais.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:guia_turismo/services/galeria_service.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/lugares_services.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:guia_turismo/services/navegacao_service.dart';

// A classe LugaresController junta as informações e funções deste assunto em um só lugar.
class LugaresController extends ChangeNotifier {
  // É o objeto que faz a ligação com outra parte do aplicativo.
  final LugaresServices _service;
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  bool limiteAtingido = false;
  // Indica que há uma ação acontecendo e ajuda a impedir ações repetidas.
  bool carregando = false;
  // Indica que há uma ação acontecendo e ajuda a impedir ações repetidas.
  bool cadastrando = false;
  // Guarda uma mensagem para explicar problemas ao usuário.
  String erro = '';
  // Indica que há uma ação acontecendo e ajuda a impedir ações repetidas.
  String erroCadastro = '';

  List<LugaresModel> _lugares = [];
  List<LugaresModel> get lugares => _lugares;

  LugaresController({LugaresServices? service, bool carregarAoIniciar = true})
    : _service = service ?? LugaresServices() {
    // Evita repetir uma ação enquanto ela ainda está acontecendo.
    if (carregarAoIniciar) listaLugares();
  }

  // A função listaLugares busca a lista mais recente dos destinos.
  Future<void> listaLugares() async {
    // Evita repetir uma ação enquanto ela ainda está acontecendo.
    if (carregando) return;
    carregando = true;
    erro = '';
    notifyListeners();
    // Tentamos realizar a tarefa, pois serviços externos podem falhar.
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

  // A função cadastrarLugarComFoto salva o lugar e depois tenta enviar a foto.
  Future<String> cadastrarLugarComFoto(LugaresModel dados, File? imagem) async {
    // Confere se há algum dado faltando ou inválido.
    if (imagem == null) return cadastrarLugar(dados);
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
    final idsAntes = _lugares.map((l) => l.id).toSet();
    // Indica que há uma ação acontecendo e ajuda a impedir ações repetidas.
    final mensagem = await cadastrarLugar(dados);
    // Confere se há algum dado faltando ou inválido.
    if (erroCadastro.isNotEmpty) return mensagem;
    int? id = _service.ultimoLugarCriadoId;
    // Confere se há algum dado faltando ou inválido.
    if (id == null) {
      // Se o POST não informou o ID, só atribuímos a foto quando existir
      // exatamente um novo registro compatível após atualizar a listagem.
      final candidatos = _lugares.where((l) =>
          !idsAntes.contains(l.id) &&
          l.nome.trim().toLowerCase() == dados.nome.trim().toLowerCase() &&
          (l.latitude.toDouble() - dados.latitude.toDouble()).abs() < 0.00001 &&
          (l.longitude.toDouble() - dados.longitude.toDouble()).abs() < 0.00001
      ).toList();
      // Esse teste decide se o próximo passo deve acontecer.
      if (candidatos.length == 1) id = candidatos.single.id;
    }
    // Confere se há algum dado faltando ou inválido.
    if (id == null) {
      return '$mensagem Foto não enviada: não foi possível identificar '
          'com segurança o ID do novo lugar. Adicione a foto pelos detalhes.';
    }
    // Guarda uma informação sobre a conta que está usando o app.
    final token = await SessionService().pegarToken() ?? '';
    // Tentamos realizar a tarefa, pois serviços externos podem falhar.
    try {
      // Espera esta etapa terminar antes de continuar.
      await GaleriaService().enviarFoto(
        lugarId: id, caminho: imagem.path, token: token,
      );
      // Espera esta etapa terminar antes de continuar.
      await listaLugares();
      return '$mensagem Foto adicionada à galeria.';
    } on SessaoExpiradaException {
      // Verifica se o login permite continuar.
      if (await SessionService().invalidarSeAtual(token)) {
        NavegacaoService.irParaLogin();
      }
      return '$mensagem Porém, a foto não foi enviada: sessão expirada.';
    } catch (_) {
      return '$mensagem Porém, a foto não foi enviada. Confira a conexão.';
    }
  }

  // A função cadastrarLugar envia um lugar novo para a API da faculdade.
  Future<String> cadastrarLugar(LugaresModel dados) async {
    // Guarda uma informação sobre a conta que está usando o app.
    String tokenUsado = '';
    cadastrando = true;
    erroCadastro = '';
    notifyListeners();
    // Tentamos realizar a tarefa, pois serviços externos podem falhar.
    try {
      tokenUsado = await SessionService().pegarToken() ?? '';
      // Guarda uma informação sobre a conta que está usando o app.
      final mensagem = await _service.cadastrarLugar(dados, tokenUsado);
      // Atualiza a lista após o servidor confirmar o cadastro.
      await listaLugares();
      return mensagem;
    } on SessaoExpiradaException {
      erroCadastro = 'Sua sessão expirou. Entre novamente para cadastrar.';
      // Verifica se o login permite continuar.
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
