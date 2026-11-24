// PARA A APRESENTAÇÃO: este serviço busca os lugares cadastrados e envia novos cadastros.
// Ele fica separado das telas para deixar o aplicativo mais organizado.
import 'dart:convert';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:http/http.dart' as http;
import 'package:guia_turismo/services/session_service.dart';

// Esta classe LugaresServices reúne o que precisamos para usar este serviço.
class LugaresServices {
  // Essa variável guarda um dado necessário para fazer a consulta.
  final http.Client? client;
  LugaresServices({this.client});

  // Este é o endereço usado para conversar com o serviço na internet.
  final String endpoint = 'https://guia.liliaborges.com.br/lugares';
  // Ajuda a respeitar limites e não repetir consultas demais.
  final int limite = 30;
  // Essa variável guarda um dado necessário para fazer a consulta.
  static const maxPaginas = 10;
  // Ajuda a respeitar limites e não repetir consultas demais.
  bool limiteAtingido = false;
  int? ultimoLugarCriadoId;

  // Consulta lugares já cadastrados (GET /lugares).
  Future<List<LugaresModel>> buscarLugares() async {
    limiteAtingido = false;
    // Essa variável guarda um dado necessário para fazer a consulta.
    final lugares = <int, LugaresModel>{};
    // Ajuda a respeitar limites e não repetir consultas demais.
    final prazo = DateTime.now().add(const Duration(seconds: 60));
    for (var pagina = 1; pagina <= maxPaginas; pagina++) {
      // Ajuda a respeitar limites e não repetir consultas demais.
      final restante = prazo.difference(DateTime.now());
      // Essa condição decide se a ação pode continuar.
      if (restante <= Duration.zero) {
        // Se não for possível continuar, devolve um aviso para a tela tratar.
        throw Exception('Tempo limite ao consultar lugares. Tente novamente.');
      }
      // Este é o endereço usado para conversar com o serviço na internet.
      final uri = Uri.parse('$endpoint?pagina=$pagina&limite=$limite');
      // Este é o endereço usado para conversar com o serviço na internet.
      final response = await (client?.get(uri) ?? http.get(uri)).timeout(
        restante < const Duration(seconds: 20)
            ? restante
            : const Duration(seconds: 20),
      );

      // Confere o resultado que o servidor respondeu à solicitação.
      if (response.statusCode != 200) {
        // Se não for possível continuar, devolve um aviso para a tela tratar.
        throw Exception(
          'Falha ao consultar lugares (HTTP ${response.statusCode}).',
        );
      }

      // Guarda a resposta recebida para saber se a operação funcionou.
      final resposta = jsonDecode(utf8.decode(response.bodyBytes));
      // Essa condição decide se a ação pode continuar.
      if (resposta is! Map<String, dynamic> || resposta['data'] is! List) {
        // Se não for possível continuar, devolve um aviso para a tela tratar.
        throw const FormatException('Resposta inválida ao consultar lugares.');
      }
      // Guarda a resposta recebida para saber se a operação funcionou.
      final itens = resposta['data'] as List;
      // Essa variável guarda um dado necessário para fazer a consulta.
      var novos = 0;
      for (final item in itens.take(limite)) {
        // Essa condição decide se a ação pode continuar.
        if (item is! Map<String, dynamic>) {
          // Se não for possível continuar, devolve um aviso para a tela tratar.
          throw const FormatException('Lugar inválido na resposta da API.');
        }
        // Essa variável guarda um dado necessário para fazer a consulta.
        final lugar = LugaresModel.fromJson(item);
        // Essa condição decide se a ação pode continuar.
        if (!lugares.containsKey(lugar.id)) novos++;
        lugares[lugar.id] = lugar;
      }
      // Evita continuar com informações vazias ou inválidas.
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
    ultimoLugarCriadoId = null;
    // Confere se a identificação da conta está correta antes de continuar.
    if (token.trim().isEmpty) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw Exception('Você precisa fazer login antes de cadastrar um lugar.');
    }
    // Essa condição decide se a ação pode continuar.
    if (!dados.coordenadasValidas) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const FormatException('Informe latitude e longitude válidas.');
    }

    // Este é o endereço usado para conversar com o serviço na internet.
    final requisicao = http.Request('POST', Uri.parse(endpoint))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      })
      // Converte os dados entre o formato usado pelo servidor e o formato do aplicativo.
      ..body = jsonEncode(dados.toCadastroJson());
    // Guarda a resposta recebida para saber se a operação funcionou.
    final response =
        // Espera a resposta do servidor antes de seguir.
        await (client?.post(
                  requisicao.url,
                  headers: requisicao.headers,
                  body: requisicao.body,
                ) ??
                // Aqui acontece a comunicação com o servidor, como consultar, salvar ou remover.
                http.post(
                  requisicao.url,
                  headers: requisicao.headers,
                  body: requisicao.body,
                ))
            .timeout(const Duration(seconds: 20));

    Map<String, dynamic> corpo = {};
    // Tentamos executar a solicitação, mesmo sabendo que pode haver erro de internet.
    try {
      // Guarda a resposta recebida para saber se a operação funcionou.
      final decodificado = jsonDecode(utf8.decode(response.bodyBytes));
      // Essa condição decide se a ação pode continuar.
      if (decodificado is Map<String, dynamic>) corpo = decodificado;
    } on FormatException {
      // Algumas falhas do servidor podem não retornar JSON.
    }

    // Confere o resultado que o servidor respondeu à solicitação.
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const SessaoExpiradaException();
    }
    // Confere o resultado que o servidor respondeu à solicitação.
    if (response.statusCode == 201) {
      // Essa variável guarda um dado necessário para fazer a consulta.
      final criado = corpo['data'] is Map ? corpo['data'] :
          corpo['lugar'] is Map ? corpo['lugar'] : corpo;
      // Essa variável guarda um dado necessário para fazer a consulta.
      final id = int.tryParse((criado['id'] ?? criado['lugarId'] ?? '').toString());
      // Evita continuar com informações vazias ou inválidas.
      if (id != null && id > 0) ultimoLugarCriadoId = id;
      return corpo['message']?.toString() ?? 'Lugar cadastrado com sucesso!';
    }

    // Se não for possível continuar, devolve um aviso para a tela tratar.
    throw Exception(
      corpo['message']?.toString() ??
          'Falha ao cadastrar lugar (HTTP ${response.statusCode}).',
    );
  }
}
