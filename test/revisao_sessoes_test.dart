import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guia_turismo/controllers/favoritos_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/favoritos_service.dart';
import 'package:guia_turismo/services/lugares_services.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('logout apaga JWT, nome e e-mail da identidade anterior', () async {
    final sessao = SessionService();
    await sessao.salvarUsuario({'email': 'a@exemplo.com', 'nome': 'Conta A'});
    await sessao.salvarToken('token-a');
    expect(await sessao.temSessaoApi(), isTrue);
    await sessao.logout();
    expect(await sessao.pegarToken(), isNull);
    expect(await sessao.pegarEmail(), isEmpty);
    expect(await sessao.pegarNome(), isEmpty);
    expect(await sessao.temSessaoApi(), isFalse);
  });

  test('resposta atrasada da conta A nao aparece apos sair da conta', () async {
    final pendente = Completer<http.Response>();
    final requisicaoIniciada = Completer<void>();
    final service = FavoritosService(client: MockClient((request) async {
      if (request.method == 'GET') {
        if (!requisicaoIniciada.isCompleted) requisicaoIniciada.complete();
        return pendente.future;
      }
      return http.Response('{}', 201);
    }));
    final sessao = SessionService();
    await sessao.salvarUsuario({'email': 'conta-a@teste.com', 'nome': 'A'});
    await sessao.salvarToken('token-a');
    final favoritos = FavoritosController(service: service);
    addTearDown(favoritos.dispose);

    final carregandoA = favoritos.carregar();
    await requisicaoIniciada.future;
    favoritos.limpar();
    await sessao.logout();
    await favoritos.carregar(); // visitante, sem o token da conta A.
    expect(favoritos.ids, isEmpty);

    pendente.complete(http.Response(jsonEncode({
      'data': [{'lugarId': 10}, {'lugarId': 20}],
    }), 200));
    await carregandoA;
    expect(favoritos.ids, isEmpty);
    expect(favoritos.carregando, isFalse);
  });

  test('sessao nao pode invalidar um JWT que ja foi substituido', () async {
    final sessao = SessionService();
    await sessao.salvarToken('token-b');
    expect(await sessao.invalidarSeAtual('token-a'), isFalse);
    expect(await sessao.pegarToken(), 'token-b');
    expect(await sessao.invalidarSeAtual('token-b'), isTrue);
    expect(await sessao.pegarToken(), isNull);
  });

  test('favoritos distinguem token expirado de erro de internet', () async {
    final servico = FavoritosService(client: MockClient(
      (_) async => http.Response('', 401),
    ));
    await expectLater(servico.listar('teste'), throwsA(isA<SessaoExpiradaException>()));
  });

  test('cadastro trata JWT expirado separadamente', () async {
    final service = LugaresServices(client: MockClient(
      (_) async => http.Response('{"message":"Sem acesso"}', 403),
    ));
    await expectLater(
      service.cadastrarLugar(
        LugaresModel(id: 0, nome: 'Teste', categoriaId: 1,
          latitude: -23.5, longitude: -46.6),
        'token-ficticio',
      ),
      throwsA(isA<SessaoExpiradaException>()),
    );
  });
}
