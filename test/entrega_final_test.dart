// PARA A APRESENTAÇÃO: estes testes verificam as principais exigências finais, como rota, imagens, favoritos e câmera.
// Usamos dados de exemplo para conferir o app sem mexer nos registros reais.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guia_turismo/controller/camera_controller.dart';
import 'package:guia_turismo/controller/favoritos_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/screens/camera_screen.dart';
import 'package:guia_turismo/services/favoritos_service.dart';
import 'package:guia_turismo/services/lugares_services.dart';
import 'package:guia_turismo/services/rotas_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Aqui começam os testes deste arquivo.
void main() {
  // Prepara um ambiente limpo antes de cada teste.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('rota Google Maps valida coordenadas e codifica destino', () {
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final uri = RotasService.criarUriGoogleMaps(-23.55, -46.63);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(uri.scheme, 'https');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(uri.host, 'www.google.com');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(uri.queryParameters['destination'], '-23.55,-46.63');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(uri.queryParameters['travelmode'], 'driving');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      () => RotasService.criarUriGoogleMaps(99, -46),
      throwsFormatException,
    );
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('modelo lê fotos de galeria e rejeita urls inseguras', () {
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      LugaresModel.extrairFotoUrl({
        'galeria': [{'url': 'https://example.com/foto.jpg'}],
      }),
      'https://example.com/foto.jpg',
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      LugaresModel.extrairFotoUrl({'foto': '/uploads/arquivo.png'}),
      'https://guia.liliaborges.com.br/uploads/arquivo.png',
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      LugaresModel.extrairFotoUrl({'foto': 'javascript:alert(1)'}),
      isNull,
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      LugaresModel.extrairFotoUrl({'galeria': [{'urlFoto': 'uploads/foto.jpg'}]}),
      'https://guia.liliaborges.com.br/uploads/foto.jpg',
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      LugaresModel.extrairFotoUrl({'foto': 'http://exemplo.com/a.png'}),
      isNull,
    );
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('favoritos da API usam JWT e métodos documentados', () async {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final chamadas = <String>[];
    // Finge que o servidor respondeu, sem criar ou apagar lugares reais.
    final service = FavoritosService(client: MockClient((r) async {
      chamadas.add('${r.method} ${r.url.path}');
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(r.headers['Authorization'], 'Bearer teste-simulado');
      // O teste muda de resposta conforme o cenário que estamos simulando.
      if (r.method == 'GET') {
        // Devolve uma resposta de mentira para ver como o app reage.
        return http.Response(jsonEncode({
          'data': [{'lugarId': 1}, {'lugar': {'id': 2}}],
        }), 200);
      }
      // Devolve uma resposta de mentira para ver como o app reage.
      return http.Response('{}', r.method == 'POST' ? 201 : 200);
    }));
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final ids = await service.listar('teste-simulado');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(ids, {1, 2});
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await service.definir('teste-simulado', 3, favorito: true);
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await service.definir('teste-simulado', 3, favorito: false);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(chamadas, [
      'GET /favoritos',
      'POST /favoritos/3',
      'DELETE /favoritos/3',
    ]);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('favoritos locais sobrevivem à recriação do controlador', () async {
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final a = FavoritosController();
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await a.carregar();
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(await a.alternar(45), isTrue);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(a.contem(45), isTrue);
    a.dispose();
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final b = FavoritosController();
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await b.carregar();
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(b.contem(45), isTrue);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(await b.alternar(45), isTrue);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(b.contem(45), isFalse);
    b.dispose();
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('cadastro captura ID quando API o retorna', () async {
    // Finge que o servidor respondeu, sem criar ou apagar lugares reais.
    final service = LugaresServices(client: MockClient((r) async {
      // Compara o resultado encontrado com o resultado que deveria aparecer.
      expect(r.method, 'POST');
      // Devolve uma resposta de mentira para ver como o app reage.
      return http.Response('{"message":"Criado","data":{"id":71}}', 201);
    }));
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final retorno = await service.cadastrarLugar(
      LugaresModel(
        id: 0, nome: 'Teste', categoriaId: 1, descricao: '',
        latitude: -23.5, longitude: -46.6,
      ),
      'token-ficticio',
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(retorno, 'Criado');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(service.ultimoLugarCriadoId, 71);
  });

  // Este teste abre uma tela simulada e confere o que aparece nela.
  testWidgets('câmera mostra estado vazio sem placeholder de rede', (tester) async {
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final camera = CameraController();
    addTearDown(camera.dispose);
    // Abre a tela no ambiente de testes, sem precisar do celular.
    await tester.pumpWidget(ChangeNotifierProvider<CameraController>.value(
      value: camera,
      child: const MaterialApp(home: CameraScreen()),
    ));
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(find.text('Nenhuma foto selecionada'), findsOneWidget);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(find.byType(Image), findsNothing);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(find.text('Tirar foto'), findsOneWidget);
    // Simula uma ação na tela e verifica seu resultado.
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    // Espera a tela terminar de atualizar.
    await tester.pumpAndSettle();
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(find.text('Escolher da galeria'), findsOneWidget);
  });
}
