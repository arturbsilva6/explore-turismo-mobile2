// PARA A APRESENTAÇÃO: estes testes verificam a separação de contas, os favoritos e o logout sem dados da conta anterior.
// O teste simula ações e compara os resultados para evitar erros na entrega.
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

// Aqui começa a sequência de testes deste arquivo.
void main() {
  // Prepara os dados para começar cada teste do zero.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('logout apaga JWT, nome e e-mail da identidade anterior', () async {
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final sessao = SessionService();
    // Espera a tarefa acabar para conferir o resultado.
    await sessao.salvarUsuario({'email': 'a@exemplo.com', 'nome': 'Conta A'});
    // Espera a tarefa acabar para conferir o resultado.
    await sessao.salvarToken('token-a');
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.temSessaoApi(), isTrue);
    // Espera a tarefa acabar para conferir o resultado.
    await sessao.logout();
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.pegarToken(), isNull);
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.pegarEmail(), isEmpty);
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.pegarNome(), isEmpty);
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.temSessaoApi(), isFalse);
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('resposta atrasada da conta A nao aparece apos sair da conta', () async {
    // Guarda uma informação de exemplo para o teste.
    final pendente = Completer<http.Response>();
    // Guarda uma informação de exemplo para o teste.
    final requisicaoIniciada = Completer<void>();
    // Usamos um exemplo controlado para não depender de internet ou mapa real.
    final service = FavoritosService(client: MockClient((request) async {
      // Muda o retorno do teste para simular uma situação diferente.
      if (request.method == 'GET') {
        // Muda o retorno do teste para simular uma situação diferente.
        if (!requisicaoIniciada.isCompleted) requisicaoIniciada.complete();
        return pendente.future;
      }
      // Devolve uma resposta simulada do servidor.
      return http.Response('{}', 201);
    }));
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final sessao = SessionService();
    // Espera a tarefa acabar para conferir o resultado.
    await sessao.salvarUsuario({'email': 'conta-a@teste.com', 'nome': 'A'});
    // Espera a tarefa acabar para conferir o resultado.
    await sessao.salvarToken('token-a');
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final favoritos = FavoritosController(service: service);
    addTearDown(favoritos.dispose);

    // Guarda uma informação de exemplo para o teste.
    final carregandoA = favoritos.carregar();
    // Espera a tarefa acabar para conferir o resultado.
    await requisicaoIniciada.future;
    favoritos.limpar();
    // Espera a tarefa acabar para conferir o resultado.
    await sessao.logout();
    // Espera a tarefa acabar para conferir o resultado.
    await favoritos.carregar(); // visitante, sem o token da conta A.
    // Confere se o resultado é exatamente o que esperamos.
    expect(favoritos.ids, isEmpty);

    pendente.complete(http.Response(jsonEncode({
      'data': [{'lugarId': 10}, {'lugarId': 20}],
    }), 200));
    // Espera a tarefa acabar para conferir o resultado.
    await carregandoA;
    // Confere se o resultado é exatamente o que esperamos.
    expect(favoritos.ids, isEmpty);
    // Confere se o resultado é exatamente o que esperamos.
    expect(favoritos.carregando, isFalse);
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('sessao nao pode invalidar um JWT que ja foi substituido', () async {
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final sessao = SessionService();
    // Espera a tarefa acabar para conferir o resultado.
    await sessao.salvarToken('token-b');
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.invalidarSeAtual('token-a'), isFalse);
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.pegarToken(), 'token-b');
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.invalidarSeAtual('token-b'), isTrue);
    // Confere se o resultado é exatamente o que esperamos.
    expect(await sessao.pegarToken(), isNull);
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('favoritos distinguem token expirado de erro de internet', () async {
    // Usamos um exemplo controlado para não depender de internet ou mapa real.
    final servico = FavoritosService(client: MockClient(
      (_) async => http.Response('', 401),
    ));
    // Confere se o resultado é exatamente o que esperamos.
    await expectLater(servico.listar('teste'), throwsA(isA<SessaoExpiradaException>()));
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test('cadastro trata JWT expirado separadamente', () async {
    // Usamos um exemplo controlado para não depender de internet ou mapa real.
    final service = LugaresServices(client: MockClient(
      (_) async => http.Response('{"message":"Sem acesso"}', 403),
    ));
    // Confere se o resultado é exatamente o que esperamos.
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
