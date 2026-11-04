import 'dart:convert';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:http/http.dart' as http;

class LugaresServices {
  final http.Client? client;
  LugaresServices({this.client});

  final String endpoint = 'https://guia.liliaborges.com.br/lugares';
  final int limite = 30;
  static const maxPaginas = 10;
  bool limiteAtingido = false;

  // Consulta lugares já cadastrados (GET /lugares).
  Future<List<LugaresModel>> buscarLugares() async {
    limiteAtingido = false;
    final lugares = <int, LugaresModel>{};
    final prazo = DateTime.now().add(const Duration(seconds: 60));
    for (var pagina = 1; pagina <= maxPaginas; pagina++) {
      final restante = prazo.difference(DateTime.now());
      if (restante <= Duration.zero) {
        throw Exception('Tempo limite ao consultar lugares. Tente novamente.');
      }
      final uri = Uri.parse('$endpoint?pagina=$pagina&limite=$limite');
      final response = await (client?.get(uri) ?? http.get(uri)).timeout(
        restante < const Duration(seconds: 20)
            ? restante
            : const Duration(seconds: 20),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao consultar lugares (HTTP ${response.statusCode}).',
        );
      }

      final resposta = jsonDecode(utf8.decode(response.bodyBytes));
      if (resposta is! Map<String, dynamic> || resposta['data'] is! List) {
        throw const FormatException('Resposta inválida ao consultar lugares.');
      }
      final itens = resposta['data'] as List;
      var novos = 0;
      for (final item in itens.take(limite)) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Lugar inválido na resposta da API.');
        }
        final lugar = LugaresModel.fromJson(item);
        if (!lugares.containsKey(lugar.id)) novos++;
        lugares[lugar.id] = lugar;
      }
      if (itens.length < limite) return lugares.values.toList();
      // Protege contra servidores que ignoram a página solicitada.
      if (novos == 0 || pagina == maxPaginas || itens.length > limite) {
        limiteAtingido = true;
        break;
      }
    }
    return lugares.values.toList();
  }

  // Cadastra um novo lugar (POST /lugares) com token de autenticação.
  Future<String> cadastrarLugar(LugaresModel dados, String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Você precisa fazer login antes de cadastrar um lugar.');
    }
    if (!dados.coordenadasValidas) {
      throw const FormatException('Informe latitude e longitude válidas.');
    }

    final requisicao = http.Request('POST', Uri.parse(endpoint))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode(dados.toCadastroJson());
    final response =
        await (client?.post(
                  requisicao.url,
                  headers: requisicao.headers,
                  body: requisicao.body,
                ) ??
                http.post(
                  requisicao.url,
                  headers: requisicao.headers,
                  body: requisicao.body,
                ))
            .timeout(const Duration(seconds: 20));

    Map<String, dynamic> corpo = {};
    try {
      final decodificado = jsonDecode(utf8.decode(response.bodyBytes));
      if (decodificado is Map<String, dynamic>) corpo = decodificado;
    } on FormatException {
      // Algumas falhas do servidor podem não retornar JSON.
    }

    if (response.statusCode == 201) {
      return corpo['message']?.toString() ?? 'Lugar cadastrado com sucesso!';
    }

    throw Exception(
      corpo['message']?.toString() ??
          'Falha ao cadastrar lugar (HTTP ${response.statusCode}).',
    );
  }
}
