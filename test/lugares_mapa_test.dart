// PARA A APRESENTAÇÃO: estes testes verificam as coordenadas recebidas e a lista de lugares carregados em páginas.
// O teste simula ações e compara os resultados para evitar erros na entrega.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/lugares_services.dart';

// Essa função prepara informações ou ações que serão usadas pelos testes.
Map<String, dynamic> lugar(int id, {dynamic latitude = -23.5}) => {
  'id': id,
  'nome': 'Lugar $id',
  'categoriaId': 1,
  'categoria': {'nome': 'Parque'},
  'latitude': latitude,
  'longitude': '-46,6',
};

// Aqui começa a sequência de testes deste arquivo.
void main() {
  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('coordenadas inválidas não impedem a leitura dos lugares', () {
    for (final valor in [null, 'inválida', 'NaN', 'Infinity', 91, -91]) {
      // Confere se o resultado é exatamente o que esperamos.
      expect(
        LugaresModel.fromJson(lugar(1, latitude: valor)).coordenadasValidas,
        isFalse,
      );
    }
    // Guarda uma informação de exemplo para o teste.
    final valido = LugaresModel.fromJson(lugar(2, latitude: -23));
    expect(valido.latitude, isA<int>());
    // Confere se o resultado é exatamente o que esperamos.
    expect(valido.coordenadasValidas, isTrue);
    // Confere se o resultado é exatamente o que esperamos.
    expect(valido.longitude, -46.6);
    // Confere se o resultado é exatamente o que esperamos.
    expect(valido.categoria, 'Parque');
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('consulta páginas até a última e remove IDs repetidos', () async {
    // Guarda uma informação de exemplo para o teste.
    final paginas = <String?>[];
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final service = LugaresServices(
      // Usamos um exemplo controlado para não depender de internet ou mapa real.
      client: MockClient((uri) async {
        paginas.add(uri.url.queryParameters['pagina']);
        expect(uri.url.queryParameters['limite'], '100');
        // Guarda uma informação de exemplo para o teste.
        final itens = paginas.length == 1
            ? List.generate(100, (i) => lugar(i))
            : [lugar(99), lugar(100)];
        // Devolve uma resposta simulada do servidor.
        return http.Response(jsonEncode({'data': itens}), 200);
      }),
    );
    // Confere se o resultado é exatamente o que esperamos.
    expect((await service.buscarLugares()).length, 101);
    // Confere se o resultado é exatamente o que esperamos.
    expect(paginas, ['1', '2']);
    // Confere se o resultado é exatamente o que esperamos.
    expect(service.limiteAtingido, isFalse);
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('interrompe quando o servidor repete uma página cheia', () async {
    // Guarda uma informação de exemplo para o teste.
    var chamadas = 0;
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final service = LugaresServices(
      // Usamos um exemplo controlado para não depender de internet ou mapa real.
      client: MockClient((_) async {
        chamadas++;
        // Devolve uma resposta simulada do servidor.
        return http.Response(
          jsonEncode({'data': List.generate(100, (i) => lugar(i))}),
          200,
        );
      }),
    );
    // Confere se o resultado é exatamente o que esperamos.
    expect((await service.buscarLugares()).length, 100);
    // Confere se o resultado é exatamente o que esperamos.
    expect(chamadas, 2);
    // Confere se o resultado é exatamente o que esperamos.
    expect(service.limiteAtingido, isTrue);
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('limita a consulta a dez páginas', () async {
    // Guarda uma informação de exemplo para o teste.
    var chamadas = 0;
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final service = LugaresServices(
      // Usamos um exemplo controlado para não depender de internet ou mapa real.
      client: MockClient((_) async {
        // Guarda uma informação de exemplo para o teste.
        final inicio = chamadas++ * 100;
        // Devolve uma resposta simulada do servidor.
        return http.Response(
          jsonEncode({'data': List.generate(100, (i) => lugar(inicio + i))}),
          200,
        );
      }),
    );
    // Confere se o resultado é exatamente o que esperamos.
    expect((await service.buscarLugares()).length, 1000);
    // Confere se o resultado é exatamente o que esperamos.
    expect(chamadas, 10);
    // Confere se o resultado é exatamente o que esperamos.
    expect(service.limiteAtingido, isTrue);
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('propaga erro HTTP em páginas posteriores', () async {
    // Guarda uma informação de exemplo para o teste.
    var chamadas = 0;
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final service = LugaresServices(
      // Usamos um exemplo controlado para não depender de internet ou mapa real.
      client: MockClient((_) async {
        // Muda o retorno do teste para simular uma situação diferente.
        if (chamadas++ > 0) return http.Response('erro', 503);
        // Devolve uma resposta simulada do servidor.
        return http.Response(
          jsonEncode({'data': List.generate(100, (i) => lugar(i))}),
          200,
        );
      }),
    );
    // Confere se o resultado é exatamente o que esperamos.
    await expectLater(service.buscarLugares(), throwsException);
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test(
    'rejeita respostas e identificadores inesperados de forma controlada',
    () async {
      for (final corpo in [
        'null',
        '[]',
        '{}',
        '{"data":{}}',
        '{"data":[null]}',
        '{"data":[{"id":"inválido"}]}',
        'html',
      ]) {
        // Guarda um serviço de mentirinha para controlar o resultado do teste.
        final service = LugaresServices(
          // Usamos um exemplo controlado para não depender de internet ou mapa real.
          client: MockClient(
            (_) async => http.Response.bytes(utf8.encode(corpo), 200),
          ),
        );
        // Confere se o resultado é exatamente o que esperamos.
        await expectLater(service.buscarLugares(), throwsFormatException);
      }
      for (final id in [null, double.nan, double.infinity, -1, 1.5]) {
        // Confere se o resultado é exatamente o que esperamos.
        expect(
          () => LugaresModel.fromJson({...lugar(1), 'id': id}),
          throwsFormatException,
        );
      }
    },
  );

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test(
    'respeita o limite se o servidor enviar itens além do solicitado',
    () async {
      // Guarda uma informação de exemplo para o teste.
      var chamadas = 0;
      // Guarda um serviço de mentirinha para controlar o resultado do teste.
      final service = LugaresServices(
        // Usamos um exemplo controlado para não depender de internet ou mapa real.
        client: MockClient((_) async {
          chamadas++;
          // Devolve uma resposta simulada do servidor.
          return http.Response(
            jsonEncode({'data': List.generate(50, lugar)}),
            200,
          );
        }),
      );
      // Confere se o resultado é exatamente o que esperamos.
      expect((await service.buscarLugares()).length, 100);
      // Confere se o resultado é exatamente o que esperamos.
      expect(chamadas, 1);
      // Confere se o resultado é exatamente o que esperamos.
      expect(service.limiteAtingido, isTrue);
    },
  );

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test(
    'propaga falha de conexão sem apresentar consulta como bem sucedida',
    () async {
      // Guarda um serviço de mentirinha para controlar o resultado do teste.
      final service = LugaresServices(
        // Usamos um exemplo controlado para não depender de internet ou mapa real.
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      // Confere se o resultado é exatamente o que esperamos.
      await expectLater(
        service.buscarLugares(),
        throwsA(isA<http.ClientException>()),
      );
    },
  );
}
