import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String url = 'https://guia.liliaborges.com.br/login';

  Future<Map> autenticar(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "senha": senha}),
      );
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('REDIRECIONANDO PARA: ${response.headers['location']}');
      debugPrint('TIPO: ${response.headers['content-type']}');
      debugPrint('STATUS LOGIN: ${response.statusCode}');
      debugPrint('TIPO RESPOSTA: ${response.headers['content-type']}');

      if (!response.body.trimLeft().startsWith('{')) {
        throw Exception(
          'Servidor retornou uma resposta diferente de JSON. '
          'HTTP ${response.statusCode}',
        );
      }
      final dados = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return dados['data'];
      } else {
        debugPrint(dados.toString());
        return {};
      }
    } catch (e) {
      rethrow;
    }
  }
}
