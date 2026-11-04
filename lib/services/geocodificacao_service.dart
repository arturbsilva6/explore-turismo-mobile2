import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show parseHttpDate;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/models/localizacao_model.dart';

abstract interface class GeocodificacaoService {
  Future<List<LocalizacaoResultado>> buscar(String consulta);
}

class GeocodificacaoException implements Exception {
  final String mensagem;
  const GeocodificacaoException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Serializa todas as instâncias no processo; nunca dispara retries automáticos.
/// Um proxy é necessário para limitar o tráfego agregado de várias instalações.
class FilaGeocodificacao {
  static final compartilhada = FilaGeocodificacao();
  Future<void> _fila = Future.value();
  final Stopwatch _relogio = Stopwatch()..start();
  Duration? _ultima;
  Duration _bloqueadoAte = Duration.zero;

  Future<T> executar<T>(Future<T> Function() tarefa) {
    final resultado = _fila.then((_) async {
      final ultima = _ultima;
      final proxima = ultima == null
          ? Duration.zero
          : ultima + const Duration(seconds: 1);
      final espera = proxima - _relogio.elapsed;
      if (espera > Duration.zero) await Future<void>.delayed(espera);
      return tarefa();
    });
    _fila = resultado.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return resultado;
  }

  void registrarRequisicao() {
    if (_bloqueadoAte > _relogio.elapsed) {
      throw const GeocodificacaoException(
        'Serviço temporariamente ocupado. Aguarde antes de tentar novamente.',
      );
    }
    _ultima = _relogio.elapsed;
  }

  void bloquear(Duration duracao) {
    final ate = _relogio.elapsed + duracao;
    if (ate > _bloqueadoAte) _bloqueadoAte = ate;
  }
}

class NominatimService implements GeocodificacaoService {
  static const endpointPadrao = 'https://nominatim.openstreetmap.org/search';
  static const chaveEndpoint = 'geocodificacao_endpoint';
  static const _chaveCache = 'geocodificacao_cache_v1';
  static const _validade = Duration(days: 7);
  final http.Client? client;
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
    final termo = consulta.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (termo.length < 3 || termo.length > 200) {
      throw const GeocodificacaoException(
        'Informe um endereço ou CEP entre 3 e 200 caracteres.',
      );
    }
    return fila.executar(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final endpoint = resolverEndpoint != null
            ? await resolverEndpoint!()
            : Uri.parse(prefs.getString(chaveEndpoint) ?? endpointPadrao);
        if (endpoint.scheme != 'https' || endpoint.host.isEmpty) {
          throw const GeocodificacaoException(
            'O serviço de localização está indisponível.',
          );
        }
        final parametros = <String, String>{
          'format': 'jsonv2',
          'limit': '5',
          'accept-language': 'pt-BR',
        };
        final cep = termo.replaceAll('-', '');
        if (RegExp(r'^\d{8}$').hasMatch(cep)) {
          parametros.addAll({
            'postalcode': '${cep.substring(0, 5)}-${cep.substring(5)}',
            'countrycodes': 'br',
          });
        } else {
          parametros['q'] = termo;
        }
        final uri = endpoint.replace(
          queryParameters: {...endpoint.queryParameters, ...parametros},
        );
        final chave = uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                if (parametros.containsKey('q')) 'q': termo.toLowerCase(),
              },
            )
            .toString();
        Map<String, dynamic> cache = {};
        try {
          cache =
              jsonDecode(prefs.getString(_chaveCache) ?? '{}')
                  as Map<String, dynamic>;
        } on FormatException {
          // Cache local corrompido pode ser reconstruído.
        } on TypeError {
          // Ignora formatos de versões antigas.
        }
        final agora = DateTime.now();
        cache.removeWhere(
          (_, valor) =>
              valor is! Map ||
              DateTime.tryParse('${valor['ate']}')?.isAfter(agora) != true,
        );
        final salvo = cache[chave];
        if (salvo is Map && salvo['itens'] is List) {
          final itens = salvo['itens'] as List;
          final resultados = _lerResultados(itens);
          if (itens.isEmpty || resultados.isNotEmpty) return resultados;
          cache.remove(chave);
        }
        fila.registrarRequisicao();
        final requisicoes = client ?? http.Client();
        late http.Response resposta;
        try {
          resposta = await requisicoes
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 15));
        } finally {
          // Encerra também uma requisição que tenha excedido o timeout.
          if (client == null) requisicoes.close();
        }
        if (resposta.statusCode == 429 || resposta.statusCode == 503) {
          final segundos = int.tryParse(resposta.headers['retry-after'] ?? '');
          DateTime? data;
          try {
            data = parseHttpDate(resposta.headers['retry-after'] ?? '');
          } on FormatException {
            // Sem data HTTP válida, usa segundos ou a pausa padrão.
          }
          final recebidoEm = DateTime.now();
          fila.bloquear(
            segundos != null
                ? Duration(seconds: segundos < 1 ? 1 : segundos)
                : data != null && data.isAfter(recebidoEm)
                ? data.difference(recebidoEm)
                : const Duration(seconds: 60),
          );
          throw const GeocodificacaoException(
            'Serviço temporariamente ocupado. Aguarde antes de tentar novamente.',
          );
        }
        if (resposta.statusCode != 200) {
          throw const GeocodificacaoException(
            'Não foi possível buscar a localização. Tente novamente mais tarde.',
          );
        }
        final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (dados is! List) throw const FormatException();
        final resultados = _lerResultados(dados);
        if (resultados.isEmpty && dados.isNotEmpty) {
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
          await prefs.setString(_chaveCache, jsonEncode(cache));
        } catch (_) {}
        return resultados;
      } on GeocodificacaoException {
        rethrow;
      } on FormatException {
        throw const GeocodificacaoException(
          'Resposta inválida do serviço de localização.',
        );
      } catch (_) {
        throw const GeocodificacaoException(
          'Não foi possível conectar. Verifique sua conexão e tente novamente.',
        );
      }
    });
  }

  static const _headers = {
    'User-Agent': 'ExploreTurismo-MobileII/1.0 (Flutter Android)',
    'Accept': 'application/json',
  };

  List<LocalizacaoResultado> _lerResultados(List<dynamic> dados) {
    final resultados = <LocalizacaoResultado>[];
    for (final item in dados.take(5)) {
      if (item is! Map<String, dynamic>) continue;
      try {
        resultados.add(LocalizacaoResultado.fromJson(item));
      } on FormatException {
        /* Descarta apenas o resultado inválido. */
      }
    }
    return List.unmodifiable(resultados);
  }
}
