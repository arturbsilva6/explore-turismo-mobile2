import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_parser/http_parser.dart' show formatHttpDate;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/models/localizacao_model.dart';
import 'package:guia_turismo/services/geocodificacao_service.dart';

Map<String, dynamic> resultado({String lat = '-23.5', String lon = '-46.6'}) =>
    {'display_name': 'Praça da Sé, São Paulo, Brasil', 'lat': lat, 'lon': lon};

NominatimService servico(
  Future<http.Response> Function(http.Request) handler, {
  FilaGeocodificacao? fila,
  Future<Uri> Function()? resolverEndpoint,
}) => NominatimService(
  client: MockClient(handler),
  fila: fila ?? FilaGeocodificacao(),
  resolverEndpoint: resolverEndpoint,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'consulta endereço com identificação, idioma e limite de resultados',
    () async {
      final service = servico((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, 'nominatim.openstreetmap.org');
        expect(request.url.queryParameters['q'], 'Praça da Sé, São Paulo');
        expect(request.url.queryParameters['format'], 'jsonv2');
        expect(request.url.queryParameters['limit'], '5');
        expect(request.url.queryParameters['accept-language'], 'pt-BR');
        expect(request.headers['User-Agent'], contains('ExploreTurismo'));
        return http.Response(
          jsonEncode([resultado()]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final encontrados = await service.buscar('  Praça da Sé,   São Paulo  ');
      expect(encontrados.single.endereco, contains('São Paulo'));
      expect(encontrados.single.coordenadas.latitude, -23.5);
    },
  );

  test(
    'CEP com e sem hífen usa busca estruturada brasileira e cache',
    () async {
      var chamadas = 0;
      final service = servico((request) async {
        chamadas++;
        expect(request.url.queryParameters['postalcode'], '01001-000');
        expect(request.url.queryParameters['countrycodes'], 'br');
        expect(request.url.queryParameters.containsKey('q'), isFalse);
        return http.Response.bytes(utf8.encode(jsonEncode([resultado()])), 200);
      });
      await service.buscar('01001000');
      await service.buscar('01001-000');
      expect(chamadas, 1);
    },
  );

  test(
    'cache persistente reutilizado por outra instância e guarda resultado vazio',
    () async {
      var chamadas = 0;
      Future<http.Response> handler(http.Request _) async {
        chamadas++;
        return http.Response('[]', 200);
      }

      expect(await servico(handler).buscar('Endereço inexistente'), isEmpty);
      expect(await servico(handler).buscar('endereço   inexistente'), isEmpty);
      expect(chamadas, 1);
    },
  );

  test('cache vencido e cache corrompido são reconstruídos', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geocodificacao_cache_v1', 'inválido');
    var chamadas = 0;
    final service = servico((_) async {
      chamadas++;
      return http.Response('[]', 200);
    });
    await service.buscar('Rua teste');
    final cache =
        jsonDecode(prefs.getString('geocodificacao_cache_v1')!) as Map;
    (cache.values.single as Map)['ate'] = '2000-01-01T00:00:00';
    await prefs.setString('geocodificacao_cache_v1', jsonEncode(cache));
    await service.buscar('Rua teste');
    expect(chamadas, 2);
  });

  test(
    'fila compartilhada serializa requisições de instâncias diferentes',
    () async {
      final fila = FilaGeocodificacao();
      final relogio = Stopwatch()..start();
      final instantes = <Duration>[];
      Future<http.Response> handler(http.Request _) async {
        instantes.add(relogio.elapsed);
        return http.Response('[]', 200);
      }

      await Future.wait([
        servico(handler, fila: fila).buscar('Rua primeira'),
        servico(handler, fila: fila).buscar('Rua segunda'),
      ]);
      expect(
        instantes[1] - instantes[0],
        greaterThanOrEqualTo(const Duration(seconds: 1)),
      );
    },
  );

  test('rejeita consultas inválidas sem acessar a rede', () async {
    final service = servico(
      (_) async => throw StateError('Não deve consultar'),
    );
    for (final termo in ['', '  ', 'ab', 'a' * 201]) {
      await expectLater(
        service.buscar(termo),
        throwsA(isA<GeocodificacaoException>()),
      );
    }
  });

  test(
    'descarta coordenadas inválidas e preserva resultados válidos',
    () async {
      final service = servico(
        (_) async => http.Response(
          jsonEncode([
            resultado(lat: 'NaN'),
            resultado(lon: '181'),
            resultado(),
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      expect((await service.buscar('Rua teste')).length, 1);
    },
  );

  test('sinaliza resposta contendo somente coordenadas inválidas', () async {
    final service = servico(
      (_) async => http.Response.bytes(
        utf8.encode(jsonEncode([resultado(lat: '91')])),
        200,
      ),
    );
    await expectLater(
      service.buscar('Rua teste'),
      throwsA(isA<GeocodificacaoException>()),
    );
  });

  test(
    'trata erro HTTP, excesso de uso, JSON inválido e falha de conexão',
    () async {
      for (final status in [403, 429, 503]) {
        var chamadas = 0;
        final service = servico((_) async {
          chamadas++;
          return http.Response('erro', status, headers: {'retry-after': '1'});
        });
        await expectLater(
          service.buscar('Rua teste'),
          throwsA(isA<GeocodificacaoException>()),
        );
        expect(chamadas, 1); // Sem repetição automática.
      }
      await expectLater(
        servico(
          (_) async => http.Response('inválido', 200),
        ).buscar('Rua teste'),
        throwsA(isA<GeocodificacaoException>()),
      );
      await expectLater(
        servico(
          (_) async => throw http.ClientException('offline'),
        ).buscar('Rua teste'),
        throwsA(isA<GeocodificacaoException>()),
      );
    },
  );

  test('HTTP 429 bloqueia novas requisições durante a pausa', () async {
    var chamadas = 0;
    final service = servico((_) async {
      chamadas++;
      return http.Response('', 429, headers: {'retry-after': '60'});
    });
    await expectLater(
      service.buscar('Rua primeira'),
      throwsA(isA<GeocodificacaoException>()),
    );
    await expectLater(
      service.buscar('Rua segunda'),
      throwsA(isA<GeocodificacaoException>()),
    );
    expect(chamadas, 1);
  });

  test('respeita Retry-After no formato de data HTTP', () async {
    final fila = FilaGeocodificacao();
    var chamadas = 0;
    final service = servico((_) async {
      chamadas++;
      return http.Response(
        '',
        429,
        headers: {
          'retry-after': formatHttpDate(
            DateTime.now().toUtc().add(const Duration(minutes: 2)),
          ),
        },
      );
    }, fila: fila);
    await expectLater(
      service.buscar('Rua primeira'),
      throwsA(isA<GeocodificacaoException>()),
    );
    expect(
      () => fila.registrarRequisicao(),
      throwsA(isA<GeocodificacaoException>()),
    );
    expect(chamadas, 1);
  });

  test('permite trocar endpoint em tempo de execução', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      NominatimService.chaveEndpoint,
      'https://geocoder.turismo.test/search',
    );
    final service = servico((request) async {
      expect(request.url.host, 'geocoder.turismo.test');
      return http.Response('[]', 200);
    });
    await service.buscar('Rua teste');
  });

  test(
    'validação de coordenadas aceita vírgula e rejeita valores fora do domínio',
    () {
      expect(Coordenadas.validar('-23,5', -90, 90), isNull);
      expect(Coordenadas.validar('0', -180, 180), isNull);
      for (final texto in ['', 'NaN', 'Infinity', '91', '-91']) {
        expect(Coordenadas.validar(texto, -90, 90), isNotNull);
      }
      expect(const Coordenadas(-90, 180).validas, isTrue);
      expect(const Coordenadas(0, 181).validas, isFalse);
    },
  );
}
