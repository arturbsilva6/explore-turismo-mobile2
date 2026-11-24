// PARA A APRESENTAÇÃO: este serviço consulta e altera favoritos na API usando a conta acadêmica.
// Ele fica separado das telas para deixar o aplicativo mais organizado.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:guia_turismo/services/session_service.dart';

/// Endpoints documentados em /favoritos (JWT da API acadêmica).
class FavoritosService {
  FavoritosService({http.Client? client}) : this._interno(client);
  FavoritosService._interno(this._client);
  // Essa variável guarda um dado necessário para fazer a consulta.
  final http.Client? _client;
  // Este é o endereço usado para conversar com o serviço na internet.
  static final Uri _endpoint = Uri.parse('https://guia.liliaborges.com.br/favoritos');

  Future<Set<int>> listar(String token) async {
    // Este é o endereço usado para conversar com o serviço na internet.
    final resposta = await (_client?.get(_endpoint, headers: _headers(token)) ??
        // Aqui acontece a comunicação com o servidor, como consultar, salvar ou remover.
        http.get(_endpoint, headers: _headers(token)))
        .timeout(const Duration(seconds: 15));
    // Confere o resultado que o servidor respondeu à solicitação.
    if (resposta.statusCode == 401 || resposta.statusCode == 403) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const SessaoExpiradaException();
    }
    // Confere o resultado que o servidor respondeu à solicitação.
    if (resposta.statusCode != 200) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw Exception('Não foi possível carregar favoritos (HTTP ${resposta.statusCode}).');
    }
    // Guarda a resposta recebida para saber se a operação funcionou.
    final json = jsonDecode(utf8.decode(resposta.bodyBytes));
    // Essa variável guarda um dado necessário para fazer a consulta.
    final lista = json is List ? json :
        json is Map && json['data'] is List ? json['data'] :
        json is Map && json['favoritos'] is List ? json['favoritos'] : null;
    // Evita continuar com informações vazias ou inválidas.
    if (lista == null) throw const FormatException('Lista de favoritos inválida.');
    // Essa variável guarda um dado necessário para fazer a consulta.
    final ids = <int>{};
    for (final item in lista) {
      // Essa variável guarda um dado necessário para fazer a consulta.
      final value = item is Map
          ? (item['lugarId'] ?? item['lugar_id'] ??
             (item['lugar'] is Map ? item['lugar']['id'] : null) ??
             item['id'])
          : item;
      // Essa variável guarda um dado necessário para fazer a consulta.
      final numero = int.tryParse(value.toString());
      // Evita continuar com informações vazias ou inválidas.
      if (numero != null && numero > 0) ids.add(numero);
    }
    return ids;
  }

  // Esta função definir marca ou desmarca um lugar no servidor.
  Future<void> definir(String token, int id, {required bool favorito}) async {
    // Este é o endereço usado para conversar com o serviço na internet.
    final uri = _endpoint.replace(path: '${_endpoint.path}/$id');
    // Guarda a resposta recebida para saber se a operação funcionou.
    final resposta = favorito
        ? await (_client?.post(uri, headers: _headers(token)) ??
                // Aqui acontece a comunicação com o servidor, como consultar, salvar ou remover.
                http.post(uri, headers: _headers(token)))
            .timeout(const Duration(seconds: 15))
        : await (_client?.delete(uri, headers: _headers(token)) ??
                // Aqui acontece a comunicação com o servidor, como consultar, salvar ou remover.
                http.delete(uri, headers: _headers(token)))
            .timeout(const Duration(seconds: 15));
    // Confere o resultado que o servidor respondeu à solicitação.
    if (resposta.statusCode == 401 || resposta.statusCode == 403) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const SessaoExpiradaException();
    }
    // Confere o resultado que o servidor respondeu à solicitação.
    if (favorito && resposta.statusCode != 201 && resposta.statusCode != 200 ||
        !favorito && resposta.statusCode != 200 && resposta.statusCode != 204) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw Exception('Erro ao salvar favorito (HTTP ${resposta.statusCode}).');
    }
  }

  // Esta função _headers prepara as informações de identificação para a API.
  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };
}
