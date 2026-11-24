// PARA A APRESENTAÇÃO: estes testes verificam os marcadores, o GPS e os avisos que aparecem no mapa.
// O teste simula ações e compara os resultados para evitar erros na entrega.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/controller/theme_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/screens/mapa_screen.dart';
import 'package:guia_turismo/screens/detalhe_lugar_screen.dart';
import 'package:guia_turismo/services/lugares_services.dart';

// A classe _TilesLocais cria uma versão de teste de algo que o app usa.
class _TilesLocais extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      // Usamos um exemplo controlado para não depender de internet ou mapa real.
      MemoryImage(TileProvider.transparentImage);
}

// A classe _Lugares cria uma versão de teste de algo que o app usa.
class _Lugares extends LugaresServices {
  List<LugaresModel> itens = [];
  // Guarda uma informação de exemplo para o teste.
  bool falhar = false;
  Completer<List<LugaresModel>>? pendente;
  @override
  Future<List<LugaresModel>> buscarLugares() async {
    // Muda o retorno do teste para simular uma situação diferente.
    if (falhar) throw Exception('Rede indisponível');
    return pendente?.future ?? itens;
  }
}

LugaresModel _lugar(int id, {num latitude = -23.5}) => LugaresModel(
  id: id,
  nome: 'Destino simulado $id',
  categoria: 'Parque',
  latitude: latitude,
  longitude: -46.6,
  categoriaId: 1,
);

// Essa função prepara informações ou ações que serão usadas pelos testes.
Widget _app(LugaresController controller, {bool escuro = false}) =>
    ChangeNotifierProvider<LugaresController>.value(
      value: controller,
      child: MaterialApp(
        theme: escuro
            ? ThemeController().temaEscuro()
            : ThemeController().temaClaro(),
        home: Scaffold(body: MapaScreen(tileProvider: _TilesLocais())),
      ),
    );

// Aqui começa a sequência de testes deste arquivo.
void main() {
  for (final escuro in [false, true]) {
    // Este teste simula a tela como se alguém estivesse usando o celular.
    testWidgets(
      'marcador abre nome, categoria e detalhes no tema ${escuro ? 'escuro' : 'claro'}',
      (tester) async {
        // Guarda um serviço de mentirinha para controlar o resultado do teste.
        final service = _Lugares()
          ..itens = [_lugar(1), _lugar(2, latitude: double.nan)];
        // Guarda um serviço de mentirinha para controlar o resultado do teste.
        final controller = LugaresController(
          service: service,
          carregarAoIniciar: false,
        );
        addTearDown(controller.dispose);
        // Espera a tarefa acabar para conferir o resultado.
        await controller.listaLugares();
        // Abre a tela no simulador de testes do Flutter.
        await tester.pumpWidget(_app(controller, escuro: escuro));
        // Espera animações e mudanças da tela terminarem.
        await tester.pumpAndSettle();
        // Confere se o resultado é exatamente o que esperamos.
        expect(
          tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
          1,
        );
        // Confere se o resultado é exatamente o que esperamos.
        expect(find.text('OpenStreetMap contributors'), findsOneWidget);
        // Guarda uma informação de exemplo para o teste.
        final layer = tester.widget<TileLayer>(find.byType(TileLayer));
        // Confere se o resultado é exatamente o que esperamos.
        expect(
          layer.urlTemplate,
          startsWith('https://tile.openstreetmap.org/'),
        );
        // Confere se o resultado é exatamente o que esperamos.
        expect(
          layer.tileProvider.headers['User-Agent'],
          contains('br.exploreturismo.mobileii'),
        );
        // Confere se o resultado é exatamente o que esperamos.
        expect(layer.panBuffer, 0);
        // Simula um toque na tela para testar o botão ou o mapa.
        await tester.tap(find.byTooltip('Destino simulado 1'));
        // Espera animações e mudanças da tela terminarem.
        await tester.pumpAndSettle();
        // Confere se o resultado é exatamente o que esperamos.
        expect(find.text('Destino simulado 1'), findsOneWidget);
        // Confere se o resultado é exatamente o que esperamos.
        expect(find.text('Parque'), findsOneWidget);
        // Simula um toque na tela para testar o botão ou o mapa.
        await tester.tap(find.text('Ver detalhes'));
        // Espera animações e mudanças da tela terminarem.
        await tester.pumpAndSettle();
        // Confere se o resultado é exatamente o que esperamos.
        expect(find.byType(DetalheLugarScreen), findsOneWidget);
        // Confere se o resultado é exatamente o que esperamos.
        expect(find.text('Destino simulado 1'), findsOneWidget);
      },
    );
  }

  // Este teste simula a tela como se alguém estivesse usando o celular.
  testWidgets(
    'mapa trata vazio, coordenadas inválidas e erro com nova tentativa',
    (tester) async {
      // Guarda um serviço de mentirinha para controlar o resultado do teste.
      final service = _Lugares();
      // Guarda um serviço de mentirinha para controlar o resultado do teste.
      final controller = LugaresController(
        service: service,
        carregarAoIniciar: false,
      );
      addTearDown(controller.dispose);
      // Abre a tela no simulador de testes do Flutter.
      await tester.pumpWidget(_app(controller));
      // Confere se o resultado é exatamente o que esperamos.
      expect(find.textContaining('Nenhum lugar cadastrado.'), findsOneWidget);
      // Confere se o resultado é exatamente o que esperamos.
      expect(find.byType(FlutterMap), findsOneWidget);
      // Confere se o resultado é exatamente o que esperamos.
      expect(find.byTooltip('Minha localização GPS'), findsOneWidget);
      service.itens = [_lugar(1, latitude: 91)];
      // Espera a tarefa acabar para conferir o resultado.
      await controller.listaLugares();
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(
        find.textContaining('Nenhum lugar possui coordenadas válidas'),
        findsOneWidget,
      );
      service.falhar = true;
      // Espera a tarefa acabar para conferir o resultado.
      await controller.listaLugares();
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(
        find.textContaining('Não foi possível atualizar os lugares'),
        findsOneWidget,
      );
      service.falhar = false;
      service.itens = [_lugar(2)];
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.byTooltip('Tentar novamente'));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(find.byType(FlutterMap), findsOneWidget);
    },
  );

  // Este teste simula a tela como se alguém estivesse usando o celular.
  testWidgets('mapa exibe carregamento até a resposta chegar', (tester) async {
    // Guarda uma informação de exemplo para o teste.
    final pendente = Completer<List<LugaresModel>>();
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final service = _Lugares()..pendente = pendente;
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final controller = LugaresController(
      service: service,
      carregarAoIniciar: false,
    );
    addTearDown(controller.dispose);
    // Guarda um serviço de mentirinha para controlar o resultado do teste.
    final consulta = controller.listaLugares();
    // Abre a tela no simulador de testes do Flutter.
    await tester.pumpWidget(_app(controller));
    // Confere se o resultado é exatamente o que esperamos.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pendente.complete([]);
    // Espera a tarefa acabar para conferir o resultado.
    await consulta;
    // Espera animações e mudanças da tela terminarem.
    await tester.pumpAndSettle();
    // Confere se o resultado é exatamente o que esperamos.
    expect(find.textContaining('Nenhum lugar cadastrado.'), findsOneWidget);
  });
}
