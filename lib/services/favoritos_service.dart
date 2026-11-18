import 'dart:convert';

import 'package:http/http.dart' as http;

/// Endpoints documentados em /favoritos (JWT da API acadêmica).
class FavoritosService {
  FavoritosService({http.Client? client}) : this._interno(client);
  FavoritosService._interno(this._client);
  final http.Client? _client;
  static final Uri _endpoint = Uri.parse('https://guia.liliaborges.com.br/favoritos');

  Future<Set<int>> listar(String token) async {
    final resposta = await (_client?.get(_endpoint, headers: _headers(token)) ??
        http.get(_endpoint, headers: _headers(token)))
        .timeout(const Duration(seconds: 15));
    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível carregar favoritos (HTTP ${resposta.statusCode}).');
    }
    final json = jsonDecode(utf8.decode(resposta.bodyBytes));
    final lista = json is List ? json :
        json is Map && json['data'] is List ? json['data'] :
        json is Map && json['favoritos'] is List ? json['favoritos'] : null;
    if (lista == null) throw const FormatException('Lista de favoritos inválida.');
    final ids = <int>{};
    for (final item in lista) {
      final value = item is Map
          ? (item['lugarId'] ?? item['lugar_id'] ??
             (item['lugar'] is Map ? item['lugar']['id'] : null) ??
             item['id'])
          : item;
      final numero = int.tryParse(value.toString());
      if (numero != null && numero > 0) ids.add(numero);
    }
    return ids;
  }

  Future<void> definir(String token, int id, {required bool favorito}) async {
    final uri = _endpoint.replace(path: '${_endpoint.path}/$id');
    final resposta = favorito
        ? await (_client?.post(uri, headers: _headers(token)) ??
                http.post(uri, headers: _headers(token)))
            .timeout(const Duration(seconds: 15))
        : await (_client?.delete(uri, headers: _headers(token)) ??
                http.delete(uri, headers: _headers(token)))
            .timeout(const Duration(seconds: 15));
    if (favorito && resposta.statusCode != 201 && resposta.statusCode != 200 ||
        !favorito && resposta.statusCode != 200 && resposta.statusCode != 204) {
      throw Exception('Erro ao salvar favorito (HTTP ${resposta.statusCode}).');
    }
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };
}
