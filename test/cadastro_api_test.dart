import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/lugares_services.dart';

LugaresModel dados({num latitude = -23.5, num longitude = -46.6}) =>
    LugaresModel(
      id: 0,
      nome: 'Destino simulado',
      descricao: 'Somente teste local',
      latitude: latitude,
      longitude: longitude,
      categoriaId: 1,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'controller envia POST autenticado com coordenadas e atualiza a lista simulada',
    () async {
      SharedPreferences.setMockInitialValues({
        'token': 'credencial-ficticia-de-teste',
      });
      final metodos = <String>[];
      final service = LugaresServices(
        client: MockClient((request) async {
          metodos.add(request.method);
          expect(request.url.host, 'guia.liliaborges.com.br');
          expect(request.url.path, '/lugares');
          if (request.method == 'POST') {
            expect(
              request.headers['Authorization'],
              'Bearer credencial-ficticia-de-teste',
            );
            expect(jsonDecode(request.body), {
              'nome': 'Destino simulado',
              'descricao': 'Somente teste local',
              'latitude': -23.5,
              'longitude': -46.6,
              'categoriaId': 1,
            });
            return http.Response(
              '{"message":"Cadastro simulado confirmado"}',
              201,
            );
          }
          return http.Response('{"data":[]}', 200);
        }),
      );
      final controller = LugaresController(
        service: service,
        carregarAoIniciar: false,
      );
      addTearDown(controller.dispose);
      expect(
        await controller.cadastrarLugar(dados()),
        'Cadastro simulado confirmado',
      );
      expect(controller.erroCadastro, isEmpty);
      expect(metodos, ['POST', 'GET']);
    },
  );

  test(
    'recusa cadastro sem token ou com coordenadas inválidas sem acessar rede',
    () async {
      var chamadas = 0;
      final service = LugaresServices(
        client: MockClient((_) async {
          chamadas++;
          return http.Response('', 201);
        }),
      );
      await expectLater(service.cadastrarLugar(dados(), ''), throwsException);
      for (final lugar in [
        dados(latitude: double.nan),
        dados(latitude: 91),
        dados(longitude: double.infinity),
        dados(longitude: -181),
      ]) {
        await expectLater(
          service.cadastrarLugar(lugar, 'credencial-ficticia-de-teste'),
          throwsFormatException,
        );
      }
      expect(chamadas, 0);
    },
  );

  test('cadastro trata token recusado e resposta de erro sem JSON', () async {
    for (final status in [401, 403, 500]) {
      final service = LugaresServices(
        client: MockClient(
          (_) async => http.Response('<html>Erro</html>', status),
        ),
      );
      await expectLater(
        service.cadastrarLugar(dados(), 'credencial-ficticia-de-teste'),
        throwsException,
      );
    }
  });
}
