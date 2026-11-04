import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/lugares_services.dart';

Map<String, dynamic> lugar(int id, {dynamic latitude = -23.5}) => {
  'id': id,
  'nome': 'Lugar $id',
  'categoriaId': 1,
  'categoria': {'nome': 'Parque'},
  'latitude': latitude,
  'longitude': '-46,6',
};

void main() {
  test('coordenadas inválidas não impedem a leitura dos lugares', () {
    for (final valor in [null, 'inválida', 'NaN', 'Infinity', 91, -91]) {
      expect(
        LugaresModel.fromJson(lugar(1, latitude: valor)).coordenadasValidas,
        isFalse,
      );
    }
    final valido = LugaresModel.fromJson(lugar(2));
    expect(valido.coordenadasValidas, isTrue);
    expect(valido.longitude, -46.6);
    expect(valido.categoria, 'Parque');
  });

  test('consulta páginas até a última e remove IDs repetidos', () async {
    final paginas = <String?>[];
    final service = LugaresServices(
      client: MockClient((uri) async {
        paginas.add(uri.url.queryParameters['pagina']);
        final itens = paginas.length == 1
            ? List.generate(30, (i) => lugar(i))
            : [lugar(29), lugar(30)];
        return http.Response(jsonEncode({'data': itens}), 200);
      }),
    );
    expect((await service.buscarLugares()).length, 31);
    expect(paginas, ['1', '2']);
    expect(service.limiteAtingido, isFalse);
  });

  test('interrompe quando o servidor repete uma página cheia', () async {
    var chamadas = 0;
    final service = LugaresServices(
      client: MockClient((_) async {
        chamadas++;
        return http.Response(
          jsonEncode({'data': List.generate(30, (i) => lugar(i))}),
          200,
        );
      }),
    );
    expect((await service.buscarLugares()).length, 30);
    expect(chamadas, 2);
    expect(service.limiteAtingido, isTrue);
  });

  test('limita a consulta a dez páginas', () async {
    var chamadas = 0;
    final service = LugaresServices(
      client: MockClient((_) async {
        final inicio = chamadas++ * 30;
        return http.Response(
          jsonEncode({'data': List.generate(30, (i) => lugar(inicio + i))}),
          200,
        );
      }),
    );
    expect((await service.buscarLugares()).length, 300);
    expect(chamadas, 10);
    expect(service.limiteAtingido, isTrue);
  });

  test('propaga erro HTTP em páginas posteriores', () async {
    var chamadas = 0;
    final service = LugaresServices(
      client: MockClient((_) async {
        if (chamadas++ > 0) return http.Response('erro', 503);
        return http.Response(
          jsonEncode({'data': List.generate(30, (i) => lugar(i))}),
          200,
        );
      }),
    );
    await expectLater(service.buscarLugares(), throwsException);
  });

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
        final service = LugaresServices(
          client: MockClient(
            (_) async => http.Response.bytes(utf8.encode(corpo), 200),
          ),
        );
        await expectLater(service.buscarLugares(), throwsFormatException);
      }
      for (final id in [null, double.nan, double.infinity, -1, 1.5]) {
        expect(
          () => LugaresModel.fromJson({...lugar(1), 'id': id}),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'respeita o limite se o servidor enviar itens além do solicitado',
    () async {
      var chamadas = 0;
      final service = LugaresServices(
        client: MockClient((_) async {
          chamadas++;
          return http.Response(
            jsonEncode({'data': List.generate(50, lugar)}),
            200,
          );
        }),
      );
      expect((await service.buscarLugares()).length, 30);
      expect(chamadas, 1);
      expect(service.limiteAtingido, isTrue);
    },
  );

  test(
    'propaga falha de conexão sem apresentar consulta como bem sucedida',
    () async {
      final service = LugaresServices(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        service.buscarLugares(),
        throwsA(isA<http.ClientException>()),
      );
    },
  );
}
