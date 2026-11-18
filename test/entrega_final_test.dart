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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rota Google Maps valida coordenadas e codifica destino', () {
    final uri = RotasService.criarUriGoogleMaps(-23.55, -46.63);
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['destination'], '-23.55,-46.63');
    expect(uri.queryParameters['travelmode'], 'driving');
    expect(
      () => RotasService.criarUriGoogleMaps(99, -46),
      throwsFormatException,
    );
  });

  test('modelo lê fotos de galeria e rejeita urls inseguras', () {
    expect(
      LugaresModel.extrairFotoUrl({
        'galeria': [{'url': 'https://example.com/foto.jpg'}],
      }),
      'https://example.com/foto.jpg',
    );
    expect(
      LugaresModel.extrairFotoUrl({'foto': '/uploads/arquivo.png'}),
      'https://guia.liliaborges.com.br/uploads/arquivo.png',
    );
    expect(
      LugaresModel.extrairFotoUrl({'foto': 'javascript:alert(1)'}),
      isNull,
    );
    expect(
      LugaresModel.extrairFotoUrl({'galeria': [{'urlFoto': 'uploads/foto.jpg'}]}),
      'https://guia.liliaborges.com.br/uploads/foto.jpg',
    );
    expect(
      LugaresModel.extrairFotoUrl({'foto': 'http://exemplo.com/a.png'}),
      isNull,
    );
  });

  test('favoritos da API usam JWT e métodos documentados', () async {
    final chamadas = <String>[];
    final service = FavoritosService(client: MockClient((r) async {
      chamadas.add('${r.method} ${r.url.path}');
      expect(r.headers['Authorization'], 'Bearer teste-simulado');
      if (r.method == 'GET') {
        return http.Response(jsonEncode({
          'data': [{'lugarId': 1}, {'lugar': {'id': 2}}],
        }), 200);
      }
      return http.Response('{}', r.method == 'POST' ? 201 : 200);
    }));
    final ids = await service.listar('teste-simulado');
    expect(ids, {1, 2});
    await service.definir('teste-simulado', 3, favorito: true);
    await service.definir('teste-simulado', 3, favorito: false);
    expect(chamadas, [
      'GET /favoritos',
      'POST /favoritos/3',
      'DELETE /favoritos/3',
    ]);
  });

  test('favoritos locais sobrevivem à recriação do controlador', () async {
    final a = FavoritosController();
    await a.carregar();
    expect(await a.alternar(45), isTrue);
    expect(a.contem(45), isTrue);
    a.dispose();
    final b = FavoritosController();
    await b.carregar();
    expect(b.contem(45), isTrue);
    expect(await b.alternar(45), isTrue);
    expect(b.contem(45), isFalse);
    b.dispose();
  });

  test('cadastro captura ID quando API o retorna', () async {
    final service = LugaresServices(client: MockClient((r) async {
      expect(r.method, 'POST');
      return http.Response('{"message":"Criado","data":{"id":71}}', 201);
    }));
    final retorno = await service.cadastrarLugar(
      LugaresModel(
        id: 0, nome: 'Teste', categoriaId: 1, descricao: '',
        latitude: -23.5, longitude: -46.6,
      ),
      'token-ficticio',
    );
    expect(retorno, 'Criado');
    expect(service.ultimoLugarCriadoId, 71);
  });

  testWidgets('câmera mostra estado vazio sem placeholder de rede', (tester) async {
    final camera = CameraController();
    addTearDown(camera.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<CameraController>.value(
      value: camera,
      child: const MaterialApp(home: CameraScreen()),
    ));
    expect(find.text('Nenhuma foto selecionada'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Tirar foto'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('Escolher da galeria'), findsOneWidget);
  });
}
