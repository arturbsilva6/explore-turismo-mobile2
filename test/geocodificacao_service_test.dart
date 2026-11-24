// PARA A APRESENTAÇÃO: estes testes verificam a busca por CEP/endereço e os limites de consulta do Nominatim.
// Usamos dados de exemplo para conferir o app sem mexer nos registros reais.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_parser/http_parser.dart' show formatHttpDate;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/models/localizacao_model.dart';
import 'package:guia_turismo/services/geocodificacao_service.dart';

// Esta função resultado prepara dados ou executa uma parte do teste.
Map<String, dynamic> resultado({String lat = '-23.5', String lon = '-46.6'}) =>
    {'display_name': 'Praça da Sé, São Paulo, Brasil', 'lat': lat, 'lon': lon};

NominatimService servico(
  // Esta função Function prepara dados ou executa uma parte do teste.
  Future<http.Response> Function(http.Request) handler, {
  FilaGeocodificacao? fila,
  // Esta função Function prepara dados ou executa uma parte do teste.
  Future<Uri> Function()? resolverEndpoint,
}) => NominatimService(
  // Finge que o servidor respondeu, sem criar ou apagar lugares reais.
  client: MockClient(handler),
  fila: fila ?? FilaGeocodificacao(),
  resolverEndpoint: resolverEndpoint,
);

// Aqui começam os testes deste arquivo.
void main() {
  // Prepara um ambiente limpo antes de cada teste.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Este teste verifica se essa regra funciona do jeito esperado.
  test(
    'consulta endereço com identificação, idioma e limite de resultados',
    () async {
      // Esse objeto imita o serviço que a tela usaria de verdade.
      final service = servico((request) async {
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(request.method, 'GET');
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(request.url.host, 'nominatim.openstreetmap.org');
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(request.url.queryParameters['q'], 'Praça da Sé, São Paulo');
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(request.url.queryParameters['format'], 'jsonv2');
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(request.url.queryParameters['limit'], '5');
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(request.url.queryParameters['accept-language'], 'pt-BR');
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(request.headers['User-Agent'], contains('ExploreTurismo'));
        // Devolve uma resposta de mentira para ver como o app reage.
        return http.Response(
          jsonEncode([resultado()]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      // Esse objeto imita o serviço que a tela usaria de verdade.
      final encontrados = await service.buscar('  Praça da Sé,   São Paulo  ');
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(encontrados.single.endereco, contains('São Paulo'));
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(encontrados.single.coordenadas.latitude, -23.5);
    },
  );

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('CEP com e sem hífen resolve a rua e compartilha o cache', () async {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final chamadas = <String>[];
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = servico((request) async {
      chamadas.add(request.url.host);
      // O teste muda de resposta conforme o cenário que estamos simulando.
      if (request.url.host == 'viacep.com.br') {
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(request.url.path, '/ws/18143750/json/');
        // Devolve uma resposta de mentira para ver como o app reage.
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'logradouro': 'Rua Getulio Ribeiro dos Santos',
              'localidade': 'São Roque',
              'uf': 'SP',
            }),
          ),
          200,
        );
      }
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(
        request.url.queryParameters['q'],
        'Rua Getulio Ribeiro dos Santos, São Roque, SP',
      );
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(request.url.queryParameters['countrycodes'], 'br');
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(request.url.queryParameters, isNot(contains('postalcode')));
      // Devolve uma resposta de mentira para ver como o app reage.
      return http.Response.bytes(utf8.encode(jsonEncode([resultado()])), 200);
    });

    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(await service.buscar('18143750'), hasLength(1));
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(await service.buscar('18143-750'), hasLength(1));
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(chamadas, ['viacep.com.br', 'nominatim.openstreetmap.org']);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('CEP inexistente retorna vazio sem consultar o Nominatim', () async {
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = servico((request) async {
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(request.url.host, 'viacep.com.br');
      // Devolve uma resposta de mentira para ver como o app reage.
      return http.Response('{"erro":"true"}', 200);
    });

    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(await service.buscar('99999-999'), isEmpty);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('cache persistente reutilizado por outra instância e guarda resultado vazio', () async {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    var chamadas = 0;
    // Esta função handler prepara dados ou executa uma parte do teste.
    Future<http.Response> handler(http.Request _) async {
      chamadas++;
      // Devolve uma resposta de mentira para ver como o app reage.
      return http.Response('[]', 200);
    }

    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(await servico(handler).buscar('Endereço inexistente'), isEmpty);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(await servico(handler).buscar('endereço   inexistente'), isEmpty);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(chamadas, 1);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('cache vencido e cache corrompido são reconstruídos', () async {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final prefs = await SharedPreferences.getInstance();
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await prefs.setString('geocodificacao_cache_v1', 'inválido');
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    var chamadas = 0;
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = servico((_) async {
      chamadas++;
      // Devolve uma resposta de mentira para ver como o app reage.
      return http.Response('[]', 200);
    });
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await service.buscar('Rua teste');
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final cache =
        jsonDecode(prefs.getString('geocodificacao_cache_v1')!) as Map;
    (cache.values.single as Map)['ate'] = '2000-01-01T00:00:00';
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await prefs.setString('geocodificacao_cache_v1', jsonEncode(cache));
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await service.buscar('Rua teste');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(chamadas, 2);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test(
    'fila compartilhada serializa requisições de instâncias diferentes',
    () async {
      // Aqui preparamos uma informação que será usada para verificar o comportamento.
      final fila = FilaGeocodificacao();
      // Aqui preparamos uma informação que será usada para verificar o comportamento.
      final relogio = Stopwatch()..start();
      // Aqui preparamos uma informação que será usada para verificar o comportamento.
      final instantes = <Duration>[];
      // Esta função handler prepara dados ou executa uma parte do teste.
      Future<http.Response> handler(http.Request _) async {
        instantes.add(relogio.elapsed);
        // Devolve uma resposta de mentira para ver como o app reage.
        return http.Response('[]', 200);
      }

      // Aguarda a etapa do teste terminar antes de conferir o resultado.
      await Future.wait([
        servico(handler, fila: fila).buscar('Rua primeira'),
        servico(handler, fila: fila).buscar('Rua segunda'),
      ]);
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(
        instantes[1] - instantes[0],
        greaterThanOrEqualTo(const Duration(seconds: 1)),
      );
    },
  );

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('rejeita consultas inválidas sem acessar a rede', () async {
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = servico(
      (_) async => throw StateError('Não deve consultar'),
    );
    for (final termo in ['', '  ', 'ab', 'a' * 201]) {
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      await expectLater(
        service.buscar(termo),
        throwsA(isA<GeocodificacaoException>()),
      );
    }
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test(
    'descarta coordenadas inválidas e preserva resultados válidos',
    () async {
      // Esse objeto imita o serviço que a tela usaria de verdade.
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
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect((await service.buscar('Rua teste')).length, 1);
    },
  );

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('sinaliza resposta contendo somente coordenadas inválidas', () async {
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = servico(
      (_) async => http.Response.bytes(
        utf8.encode(jsonEncode([resultado(lat: '91')])),
        200,
      ),
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    await expectLater(
      service.buscar('Rua teste'),
      throwsA(isA<GeocodificacaoException>()),
    );
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test(
    'trata erro HTTP, excesso de uso, JSON inválido e falha de conexão',
    () async {
      for (final status in [403, 429, 503]) {
        // Aqui preparamos uma informação que será usada para verificar o comportamento.
        var chamadas = 0;
        // Esse objeto imita o serviço que a tela usaria de verdade.
        final service = servico((_) async {
          chamadas++;
          // Devolve uma resposta de mentira para ver como o app reage.
          return http.Response('erro', status, headers: {'retry-after': '1'});
        });
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        await expectLater(
          service.buscar('Rua teste'),
          throwsA(isA<GeocodificacaoException>()),
        );
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(chamadas, 1); // Sem repetição automática.
      }
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      await expectLater(
        servico((_) async => http.Response('inválido', 200))
            .buscar('Rua teste'),
        throwsA(isA<GeocodificacaoException>()),
      );
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      await expectLater(
        servico((_) async => throw http.ClientException('offline'))
            .buscar('Rua teste'),
        throwsA(isA<GeocodificacaoException>()),
      );
    },
  );

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('HTTP 429 bloqueia novas requisições durante a pausa', () async {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    var chamadas = 0;
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = servico((_) async {
      chamadas++;
      // Devolve uma resposta de mentira para ver como o app reage.
      return http.Response('', 429, headers: {'retry-after': '60'});
    });
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    await expectLater(
      service.buscar('Rua primeira'),
      throwsA(isA<GeocodificacaoException>()),
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    await expectLater(
      service.buscar('Rua segunda'),
      throwsA(isA<GeocodificacaoException>()),
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(chamadas, 1);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('respeita Retry-After no formato de data HTTP', () async {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final fila = FilaGeocodificacao();
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    var chamadas = 0;
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = servico((_) async {
      chamadas++;
      // Devolve uma resposta de mentira para ver como o app reage.
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
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    await expectLater(
      service.buscar('Rua primeira'),
      throwsA(isA<GeocodificacaoException>()),
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      () => fila.registrarRequisicao(),
      throwsA(isA<GeocodificacaoException>()),
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(chamadas, 1);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('permite trocar endpoint em tempo de execução', () async {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final prefs = await SharedPreferences.getInstance();
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await prefs.setString(
      NominatimService.chaveEndpoint,
      'https://geocoder.turismo.test/search',
    );
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = servico((request) async {
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(request.url.host, 'geocoder.turismo.test');
      // Devolve uma resposta de mentira para ver como o app reage.
      return http.Response('[]', 200);
    });
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await service.buscar('Rua teste');
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test(
    'validação de coordenadas aceita vírgula e rejeita valores fora do domínio',
    () {
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(Coordenadas.validar('-23,5', -90, 90), isNull);
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(Coordenadas.validar('0', -180, 180), isNull);
      for (final texto in ['', 'NaN', 'Infinity', '91', '-91']) {
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        expect(Coordenadas.validar(texto, -90, 90), isNotNull);
      }
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(const Coordenadas(-90, 180).validas, isTrue);
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(const Coordenadas(0, 181).validas, isFalse);
    },
  );
}
