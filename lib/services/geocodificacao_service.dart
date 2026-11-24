// PARA A APRESENTAÇÃO: este serviço procura endereços e CEPs usando os dados do OpenStreetMap.
// Ele fica separado das telas para deixar o aplicativo mais organizado.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show parseHttpDate;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/models/localizacao_model.dart';

abstract interface class GeocodificacaoService {
  Future<List<LocalizacaoResultado>> buscar(String consulta);
}

// Esta classe GeocodificacaoException reúne o que precisamos para usar este serviço.
class GeocodificacaoException implements Exception {
  // Essa variável guarda um dado necessário para fazer a consulta.
  final String mensagem;
  const GeocodificacaoException(this.mensagem);
  @override
  // Esta função toString executa esta etapa da comunicação com outro serviço.
  String toString() => mensagem;
}

/// Serializa todas as instâncias no processo; nunca dispara retries automáticos.
/// Um proxy é necessário para limitar o tráfego agregado de várias instalações.
class FilaGeocodificacao {
  // Ajuda a respeitar limites e não repetir consultas demais.
  static final compartilhada = FilaGeocodificacao();
  Future<void> _fila = Future.value();
  // Essa variável guarda um dado necessário para fazer a consulta.
  final Stopwatch _relogio = Stopwatch()..start();
  Duration? _ultima;
  Duration _bloqueadoAte = Duration.zero;

  Future<T> executar<T>(Future<T> Function() tarefa) {
    // Ajuda a respeitar limites e não repetir consultas demais.
    final resultado = _fila.then((_) async {
      // Essa variável guarda um dado necessário para fazer a consulta.
      final ultima = _ultima;
      // Essa variável guarda um dado necessário para fazer a consulta.
      final proxima = ultima == null
          ? Duration.zero
          : ultima + const Duration(seconds: 1);
      // Essa variável guarda um dado necessário para fazer a consulta.
      final espera = proxima - _relogio.elapsed;
      // Essa condição decide se a ação pode continuar.
      if (espera > Duration.zero) await Future<void>.delayed(espera);
      return tarefa();
    });
    _fila = resultado.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return resultado;
  }

  // Esta função registrarRequisicao executa esta etapa da comunicação com outro serviço.
  void registrarRequisicao() {
    // Essa condição decide se a ação pode continuar.
    if (_bloqueadoAte > _relogio.elapsed) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const GeocodificacaoException(
        'Serviço temporariamente ocupado. Aguarde antes de tentar novamente.',
      );
    }
    _ultima = _relogio.elapsed;
  }

  // Esta função bloquear executa esta etapa da comunicação com outro serviço.
  void bloquear(Duration duracao) {
    // Essa variável guarda um dado necessário para fazer a consulta.
    final ate = _relogio.elapsed + duracao;
    // Essa condição decide se a ação pode continuar.
    if (ate > _bloqueadoAte) _bloqueadoAte = ate;
  }
}

// Esta classe NominatimService reúne o que precisamos para usar este serviço.
class NominatimService implements GeocodificacaoService {
  // Este é o endereço usado para conversar com o serviço na internet.
  static const endpointPadrao = 'https://nominatim.openstreetmap.org/search';
  // Este é o endereço usado para conversar com o serviço na internet.
  static const chaveEndpoint = 'geocodificacao_endpoint';
  // Ajuda a respeitar limites e não repetir consultas demais.
  static const _chaveCache = 'geocodificacao_cache_v1';
  // Essa variável guarda um dado necessário para fazer a consulta.
  static const _validade = Duration(days: 7);
  // Essa variável guarda um dado necessário para fazer a consulta.
  final http.Client? client;
  // Ajuda a respeitar limites e não repetir consultas demais.
  final FilaGeocodificacao fila;
  // Pode receber configuração remota/proxy sem acoplar a UI ao Nominatim.
  final Future<Uri> Function()? resolverEndpoint;

  NominatimService({
    this.client,
    this.resolverEndpoint,
    FilaGeocodificacao? fila,
  }) : fila = fila ?? FilaGeocodificacao.compartilhada;

  @override
  Future<List<LocalizacaoResultado>> buscar(String consulta) async {
    // Essa variável guarda um dado necessário para fazer a consulta.
    final termo = consulta.trim().replaceAll(RegExp(r'\s+'), ' ');
    // Confere o resultado que o servidor respondeu à solicitação.
    if (termo.length < 3 || termo.length > 200) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const GeocodificacaoException(
        'Informe um endereço ou CEP entre 3 e 200 caracteres.',
      );
    }
    return fila.executar(() async {
      // Tentamos executar a solicitação, mesmo sabendo que pode haver erro de internet.
      try {
        // Essa variável guarda um dado necessário para fazer a consulta.
        final prefs = await SharedPreferences.getInstance();
        // Este é o endereço usado para conversar com o serviço na internet.
        final endpoint = resolverEndpoint != null
            ? await resolverEndpoint!()
            : Uri.parse(prefs.getString(chaveEndpoint) ?? endpointPadrao);
        // Evita continuar com informações vazias ou inválidas.
        if (endpoint.scheme != 'https' || endpoint.host.isEmpty) {
          // Se não for possível continuar, devolve um aviso para a tela tratar.
          throw const GeocodificacaoException(
            'O serviço de localização está indisponível.',
          );
        }
        // Essa variável guarda um dado necessário para fazer a consulta.
        final parametros = <String, String>{
          'format': 'jsonv2',
          'limit': '5',
          'accept-language': 'pt-BR',
        };
        // Essa variável guarda um dado necessário para fazer a consulta.
        final ehCep = RegExp(r'^\d{5}-?\d{3}$').hasMatch(termo);
        // Essa variável guarda um dado necessário para fazer a consulta.
        final cep = termo.replaceAll('-', '');
        // Essa condição decide se a ação pode continuar.
        if (ehCep) {
          parametros.addAll({
            'postalcode': '${cep.substring(0, 5)}-${cep.substring(5)}',
            'countrycodes': 'br',
          });
        } else {
          parametros['q'] = termo;
        }
        // Este é o endereço usado para conversar com o serviço na internet.
        final uri = endpoint.replace(
          queryParameters: {...endpoint.queryParameters, ...parametros},
        );
        // Este é o endereço usado para conversar com o serviço na internet.
        final chaveConsulta = uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                // Essa condição decide se a ação pode continuar.
                if (parametros.containsKey('q')) 'q': termo.toLowerCase(),
              },
            )
            .toString();
        // Separa consultas de CEP dos resultados antigos por código postal.
        final chave = ehCep ? 'viacep:$chaveConsulta' : chaveConsulta;
        Map<String, dynamic> cache = {};
        // Tentamos executar a solicitação, mesmo sabendo que pode haver erro de internet.
        try {
          // Converte os dados entre o formato usado pelo servidor e o formato do aplicativo.
          cache = jsonDecode(
            prefs.getString(_chaveCache) ?? '{}',
          ) as Map<String, dynamic>;
        } on FormatException {
          // Cache local corrompido pode ser reconstruído.
        } on TypeError {
          // Ignora formatos de versões antigas.
        }
        // Essa variável guarda um dado necessário para fazer a consulta.
        final agora = DateTime.now();
        cache.removeWhere(
          (_, valor) =>
              valor is! Map ||
              DateTime.tryParse('${valor['ate']}')?.isAfter(agora) != true,
        );
        // Ajuda a respeitar limites e não repetir consultas demais.
        final salvo = cache[chave];
        // Essa condição decide se a ação pode continuar.
        if (salvo is Map && salvo['itens'] is List) {
          // Essa variável guarda um dado necessário para fazer a consulta.
          final itens = salvo['itens'] as List;
          // Essa variável guarda um dado necessário para fazer a consulta.
          final resultados = _lerResultados(itens);
          // Evita continuar com informações vazias ou inválidas.
          if (itens.isEmpty || resultados.isNotEmpty) return resultados;
          cache.remove(chave);
        }
        // Essa variável guarda um dado necessário para fazer a consulta.
        final requisicoes = client ?? http.Client();
        // Guarda a resposta recebida para saber se a operação funcionou.
        late http.Response resposta;
        // Tentamos executar a solicitação, mesmo sabendo que pode haver erro de internet.
        try {
          // Este é o endereço usado para conversar com o serviço na internet.
          var destino = uri;
          // Essa condição decide se a ação pode continuar.
          if (ehCep) {
            // Essa variável guarda um dado necessário para fazer a consulta.
            final endereco = await _buscarEnderecoCep(requisicoes, cep);
            // Evita continuar com informações vazias ou inválidas.
            if (endereco == null) return const [];
            // Evita continuar com informações vazias ou inválidas.
            if (endereco.isNotEmpty) {
              // Este é o endereço usado para conversar com o serviço na internet.
              final parametrosEndereco = {...uri.queryParameters}
                ..remove('postalcode')
                ..['q'] = endereco;
              destino = uri.replace(queryParameters: parametrosEndereco);
            }
          }
          fila.registrarRequisicao();
          resposta = await requisicoes
              .get(destino, headers: _headers)
              .timeout(const Duration(seconds: 15));
        } finally {
          // Encerra também uma requisição que tenha excedido o timeout.
          if (client == null) requisicoes.close();
        }
        // Confere o resultado que o servidor respondeu à solicitação.
        if (resposta.statusCode == 429 || resposta.statusCode == 503) {
          // Guarda a resposta recebida para saber se a operação funcionou.
          final segundos = int.tryParse(resposta.headers['retry-after'] ?? '');
          DateTime? data;
          // Tentamos executar a solicitação, mesmo sabendo que pode haver erro de internet.
          try {
            data = parseHttpDate(resposta.headers['retry-after'] ?? '');
          } on FormatException {
            // Sem data HTTP válida, usa segundos ou a pausa padrão.
          }
          // Essa variável guarda um dado necessário para fazer a consulta.
          final recebidoEm = DateTime.now();
          fila.bloquear(
            segundos != null
                ? Duration(seconds: segundos < 1 ? 1 : segundos)
                : data != null && data.isAfter(recebidoEm)
                ? data.difference(recebidoEm)
                : const Duration(seconds: 60),
          );
          // Se não for possível continuar, devolve um aviso para a tela tratar.
          throw const GeocodificacaoException(
            'Serviço temporariamente ocupado. Aguarde antes de tentar novamente.',
          );
        }
        // Confere o resultado que o servidor respondeu à solicitação.
        if (resposta.statusCode != 200) {
          // Se não for possível continuar, devolve um aviso para a tela tratar.
          throw const GeocodificacaoException(
            'Não foi possível buscar a localização. Tente novamente mais tarde.',
          );
        }
        // Guarda a resposta recebida para saber se a operação funcionou.
        final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
        // Essa condição decide se a ação pode continuar.
        if (dados is! List) throw const FormatException();
        // Essa variável guarda um dado necessário para fazer a consulta.
        final resultados = _lerResultados(dados);
        // Evita continuar com informações vazias ou inválidas.
        if (resultados.isEmpty && dados.isNotEmpty) {
          // Se não for possível continuar, devolve um aviso para a tela tratar.
          throw const GeocodificacaoException(
            'O serviço retornou coordenadas inválidas. Tente outro endereço.',
          );
        }
        cache.remove(chave);
        while (cache.length >= 50) {
          cache.remove(cache.keys.first);
        }
        cache[chave] = {
          'ate': agora.add(_validade).toIso8601String(),
          'itens': resultados.map((r) => r.toJson()).toList(),
        };
        // Falha de persistência não invalida um resultado já recebido.
        try {
          // Espera ler ou salvar uma informação no celular.
          await prefs.setString(_chaveCache, jsonEncode(cache));
        } catch (_) {}
        return resultados;
      } on GeocodificacaoException {
        rethrow;
      } on FormatException {
        // Se não for possível continuar, devolve um aviso para a tela tratar.
        throw const GeocodificacaoException(
          'Resposta inválida do serviço de localização.',
        );
      } catch (_) {
        // Se não for possível continuar, devolve um aviso para a tela tratar.
        throw const GeocodificacaoException(
          'Não foi possível conectar. Verifique sua conexão e tente novamente.',
        );
      }
    });
  }

  // Um CEP geral pode existir sem logradouro. Nesse caso, mantém a busca
  // pelo código postal para evitar sugerir arbitrariamente o centro da cidade.
  Future<String?> _buscarEnderecoCep(
    http.Client requisicoes,
    String cep,
  ) async {
    // Guarda a resposta recebida para saber se a operação funcionou.
    final resposta = await requisicoes
        .get(Uri.https('viacep.com.br', '/ws/$cep/json/'))
        .timeout(const Duration(seconds: 15));
    // Confere o resultado que o servidor respondeu à solicitação.
    if (resposta.statusCode != 200) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const GeocodificacaoException(
        'Não foi possível consultar o CEP. Tente novamente ou busque pelo endereço.',
      );
    }
    // Guarda a resposta recebida para saber se a operação funcionou.
    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    // Essa condição decide se a ação pode continuar.
    if (dados is! Map<String, dynamic>) throw const FormatException();
    // Evita continuar com informações vazias ou inválidas.
    if (dados['erro'] == true || dados['erro'] == 'true') return null;

    // Essa variável guarda um dado necessário para fazer a consulta.
    final rua = dados['logradouro'];
    // Essa variável guarda um dado necessário para fazer a consulta.
    final cidade = dados['localidade'];
    // Essa variável guarda um dado necessário para fazer a consulta.
    final uf = dados['uf'];
    // Essa condição decide se a ação pode continuar.
    if (rua is! String ||
        cidade is! String ||
        uf is! String ||
        cidade.trim().isEmpty ||
        uf.trim().isEmpty) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const FormatException();
    }
    // Evita continuar com informações vazias ou inválidas.
    if (rua.trim().isEmpty) return '';
    return '${rua.trim()}, ${cidade.trim()}, ${uf.trim()}';
  }

  // Essa variável guarda um dado necessário para fazer a consulta.
  static const _headers = {
    'User-Agent': 'ExploreTurismo-MobileII/1.0 (Flutter Android)',
    'Accept': 'application/json',
  };

  // Esta função _lerResultados executa esta etapa da comunicação com outro serviço.
  List<LocalizacaoResultado> _lerResultados(List<dynamic> dados) {
    // Essa variável guarda um dado necessário para fazer a consulta.
    final resultados = <LocalizacaoResultado>[];
    for (final item in dados.take(5)) {
      // Essa condição decide se a ação pode continuar.
      if (item is! Map<String, dynamic>) continue;
      // Tentamos executar a solicitação, mesmo sabendo que pode haver erro de internet.
      try {
        resultados.add(LocalizacaoResultado.fromJson(item));
      } on FormatException {
        /* Descarta apenas o resultado inválido. */
      }
    }
    return List.unmodifiable(resultados);
  }
}
