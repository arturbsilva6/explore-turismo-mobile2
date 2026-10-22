import 'dart:convert';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:http/http.dart' as http;

class LugaresServices {
  final String endpoint = 'https://guia.liliaborges.com.br/lugares';
  final int pagina = 1;
  final int limite = 30;

  // Consulta lugares já cadastrados (GET /lugares).
  Future<List<LugaresModel>> buscarLugares() async {
    final response = await http
        .get(Uri.parse('$endpoint?pagina=$pagina&limite=$limite'))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Falha ao consultar lugares (HTTP ${response.statusCode}).');
    }

    final resposta = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    final itens = resposta['data'] as List<dynamic>;
    return itens
        .map((item) => LugaresModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Cadastra um novo lugar (POST /lugares) com token de autenticação.
  Future<String> cadastrarLugar(LugaresModel dados, String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Você precisa fazer login antes de cadastrar um lugar.');
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dados.toCadastroJson()),
    ).timeout(const Duration(seconds: 20));

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
