// PARA A APRESENTAÇÃO: estes testes verificam o cadastro de lugar, o token enviado à API e o tratamento dos erros.
// Usamos dados de exemplo para conferir o app sem mexer nos registros reais.
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

// Aqui começam os testes deste arquivo.
void main() {
  // Prepara um ambiente limpo antes de cada teste.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Este teste verifica se essa regra funciona do jeito esperado.
  test(
    'controller envia POST autenticado com coordenadas e atualiza a lista simulada',
    () async {
      SharedPreferences.setMockInitialValues({
        'token': 'credencial-ficticia-de-teste',
      });
      // Aqui preparamos uma informação que será usada para verificar o comportamento.
      final metodos = <String>[];
      // Esse objeto imita o serviço que a tela usaria de verdade.
      final service = LugaresServices(
        // Finge que o servidor respondeu, sem criar ou apagar lugares reais.
        client: MockClient((request) async {
          metodos.add(request.method);
          // Compara o resultado encontrado com o resultado que deveria aparecer.
          expect(request.url.host, 'guia.liliaborges.com.br');
          // Compara o resultado encontrado com o resultado que deveria aparecer.
          expect(request.url.path, '/lugares');
          // O teste muda de resposta conforme o cenário que estamos simulando.
          if (request.method == 'POST') {
            // Compara o resultado encontrado com o resultado que deveria aparecer.
            expect(
              request.headers['Authorization'],
              'Bearer credencial-ficticia-de-teste',
            );
            // Compara o resultado encontrado com o resultado que deveria aparecer.
            expect(jsonDecode(request.body), {
              'nome': 'Destino simulado',
              'descricao': 'Somente teste local',
              'latitude': -23.5,
              'longitude': -46.6,
              'categoriaId': 1,
            });
            // Devolve uma resposta de mentira para ver como o app reage.
            return http.Response(
              '{"message":"Cadastro simulado confirmado"}',
              201,
            );
          }
          // Devolve uma resposta de mentira para ver como o app reage.
          return http.Response('{"data":[]}', 200);
        }),
      );
      // Esse objeto imita o serviço que a tela usaria de verdade.
      final controller = LugaresController(
        service: service,
        carregarAoIniciar: false,
      );
      addTearDown(controller.dispose);
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(
        // Aguarda a etapa do teste terminar antes de conferir o resultado.
        await controller.cadastrarLugar(dados()),
        'Cadastro simulado confirmado',
      );
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(controller.erroCadastro, isEmpty);
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(metodos, ['POST', 'GET']);
    },
  );

  // Este teste verifica se essa regra funciona do jeito esperado.
  test(
    'recusa cadastro sem token ou com coordenadas inválidas sem acessar rede',
    () async {
      // Aqui preparamos uma informação que será usada para verificar o comportamento.
      var chamadas = 0;
      // Esse objeto imita o serviço que a tela usaria de verdade.
      final service = LugaresServices(
        // Finge que o servidor respondeu, sem criar ou apagar lugares reais.
        client: MockClient((_) async {
          chamadas++;
          // Devolve uma resposta de mentira para ver como o app reage.
          return http.Response('', 201);
        }),
      );
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      await expectLater(service.cadastrarLugar(dados(), ''), throwsException);
      for (final lugar in [
        dados(latitude: double.nan),
        dados(latitude: 91),
        dados(longitude: double.infinity),
        dados(longitude: -181),
      ]) {
        // Compara o resultado encontrado com o resultado que deveria aparecer.
        await expectLater(
          service.cadastrarLugar(lugar, 'credencial-ficticia-de-teste'),
          throwsFormatException,
        );
      }
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(chamadas, 0);
    },
  );

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('cadastro trata token recusado e resposta de erro sem JSON', () async {
    for (final status in [401, 403, 500]) {
      // Esse objeto imita o serviço que a tela usaria de verdade.
      final service = LugaresServices(
        // Finge que o servidor respondeu, sem criar ou apagar lugares reais.
        client: MockClient(
          (_) async => http.Response('<html>Erro</html>', status),
        ),
      );
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      await expectLater(
        service.cadastrarLugar(dados(), 'credencial-ficticia-de-teste'),
        throwsException,
      );
    }
  });
}
