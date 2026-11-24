// PARA A APRESENTAÇÃO: este serviço manda e-mail e senha para a API da faculdade e recebe a resposta.
// Ele fica separado das telas para deixar o aplicativo mais organizado.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Esta classe AuthService reúne o que precisamos para usar este serviço.
class AuthService {
  // Este é o endereço usado para conversar com o serviço na internet.
  final String url = 'https://guia.liliaborges.com.br/login';

  // Esta função autenticar envia os dados para conferir o login acadêmico.
  Future<Map> autenticar(String email, String senha) async {
    // Tentamos executar a solicitação, mesmo sabendo que pode haver erro de internet.
    try {
      // Guarda a resposta recebida para saber se a operação funcionou.
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        // Converte os dados entre o formato usado pelo servidor e o formato do aplicativo.
        body: jsonEncode({"email": email, "senha": senha}),
      );
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('REDIRECIONANDO PARA: ${response.headers['location']}');
      debugPrint('TIPO: ${response.headers['content-type']}');
      debugPrint('STATUS LOGIN: ${response.statusCode}');
      debugPrint('TIPO RESPOSTA: ${response.headers['content-type']}');

      // Essa condição decide se a ação pode continuar.
      if (!response.body.trimLeft().startsWith('{')) {
        // Se não for possível continuar, devolve um aviso para a tela tratar.
        throw Exception(
          'Servidor retornou uma resposta diferente de JSON. '
          'HTTP ${response.statusCode}',
        );
      }
      // Guarda a resposta recebida para saber se a operação funcionou.
      final dados = jsonDecode(response.body);
      // Confere o resultado que o servidor respondeu à solicitação.
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
