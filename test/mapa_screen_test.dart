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

class _TilesLocais extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

class _Lugares extends LugaresServices {
  List<LugaresModel> itens = [];
  bool falhar = false;
  Completer<List<LugaresModel>>? pendente;
  @override
  Future<List<LugaresModel>> buscarLugares() async {
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

void main() {
  for (final escuro in [false, true]) {
    testWidgets(
      'marcador abre nome, categoria e detalhes no tema ${escuro ? 'escuro' : 'claro'}',
      (tester) async {
        final service = _Lugares()
          ..itens = [_lugar(1), _lugar(2, latitude: double.nan)];
        final controller = LugaresController(
          service: service,
          carregarAoIniciar: false,
        );
        addTearDown(controller.dispose);
        await controller.listaLugares();
        await tester.pumpWidget(_app(controller, escuro: escuro));
        await tester.pumpAndSettle();
        expect(
          tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
          1,
        );
        expect(find.text('OpenStreetMap contributors'), findsOneWidget);
        final layer = tester.widget<TileLayer>(find.byType(TileLayer));
        expect(
          layer.urlTemplate,
          startsWith('https://tile.openstreetmap.org/'),
        );
        expect(
          layer.tileProvider.headers['User-Agent'],
          contains('br.exploreturismo.mobileii'),
        );
        expect(layer.panBuffer, 0);
        await tester.tap(find.byTooltip('Destino simulado 1'));
        await tester.pumpAndSettle();
        expect(find.text('Destino simulado 1'), findsOneWidget);
        expect(find.text('Parque'), findsOneWidget);
        await tester.tap(find.text('Ver detalhes'));
        await tester.pumpAndSettle();
        expect(find.byType(DetalheLugarScreen), findsOneWidget);
        expect(find.text('Destino simulado 1'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'mapa trata vazio, coordenadas inválidas e erro com nova tentativa',
    (tester) async {
      final service = _Lugares();
      final controller = LugaresController(
        service: service,
        carregarAoIniciar: false,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      expect(find.text('Nenhum lugar cadastrado.'), findsOneWidget);
      service.itens = [_lugar(1, latitude: 91)];
      await controller.listaLugares();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nenhum lugar possui coordenadas válidas'),
        findsOneWidget,
      );
      service.falhar = true;
      await controller.listaLugares();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não foi possível carregar os lugares'),
        findsOneWidget,
      );
      service.falhar = false;
      service.itens = [_lugar(2)];
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
    },
  );

  testWidgets('mapa exibe carregamento até a resposta chegar', (tester) async {
    final pendente = Completer<List<LugaresModel>>();
    final service = _Lugares()..pendente = pendente;
    final controller = LugaresController(
      service: service,
      carregarAoIniciar: false,
    );
    addTearDown(controller.dispose);
    final consulta = controller.listaLugares();
    await tester.pumpWidget(_app(controller));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pendente.complete([]);
    await consulta;
    await tester.pumpAndSettle();
    expect(find.text('Nenhum lugar cadastrado.'), findsOneWidget);
  });
}
