import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controller/geocodificacao_controller.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/models/localizacao_model.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/screens/cadastro_lugar.dart';
import 'package:guia_turismo/screens/selecionar_localizacao_screen.dart';
import 'package:guia_turismo/services/geocodificacao_service.dart';
import 'package:guia_turismo/widgets/busca_localizacao.dart';

const resultado = LocalizacaoResultado(
  endereco: 'Praça da Sé, São Paulo',
  coordenadas: Coordenadas(-23.55, -46.63),
);

class FakeGeocodificacao implements GeocodificacaoService {
  int chamadas = 0;
  List<LocalizacaoResultado> resultados = [resultado];
  bool falhar = false;
  @override
  Future<List<LocalizacaoResultado>> buscar(String consulta) async {
    chamadas++;
    if (falhar) throw const GeocodificacaoException('Falha de conexão');
    return resultados;
  }
}

class TilesLocais extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

class LugaresSemCadastro extends LugaresController {
  int cadastros = 0;
  LugaresSemCadastro() : super(carregarAoIniciar: false);
  @override
  Future<String> cadastrarLugar(LugaresModel dados) async {
    cadastros++;
    throw StateError('Testes de localização não devem cadastrar lugares');
  }
}

Future<void> telaGrande(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder campo(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void main() {
  testWidgets(
    'digitação não consulta; clique mostra resultados, vazio e erro',
    (tester) async {
      await telaGrande(tester);
      final service = FakeGeocodificacao();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuscaLocalizacao(service: service, onConfirmar: (_) {}),
          ),
        ),
      );
      await tester.enterText(campo('Endereço ou CEP'), 'Praça da Sé');
      await tester.pump(const Duration(seconds: 2));
      expect(service.chamadas, 0);
      await tester.tap(find.text('Buscar localização'));
      await tester.pumpAndSettle();
      expect(service.chamadas, 1);
      expect(find.text(resultado.endereco), findsOneWidget);
      service.resultados = [];
      await tester.tap(find.text('Buscar localização'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nenhuma localização encontrada'),
        findsOneWidget,
      );
      service.falhar = true;
      await tester.tap(find.text('Buscar localização'));
      await tester.pumpAndSettle();
      expect(find.text('Falha de conexão'), findsOneWidget);
    },
  );

  testWidgets(
    'ajuste e confirmação transferem coordenadas ao formulário sem POST',
    (tester) async {
      await telaGrande(tester);
      final lugares = LugaresSemCadastro();
      await tester.pumpWidget(
        ChangeNotifierProvider<LugaresController>.value(
          value: lugares,
          child: MaterialApp(
            theme: ThemeData(colorSchemeSeed: Colors.teal),
            home: LugaresScreen(
              geocodificacaoService: FakeGeocodificacao(),
              construirMapa: (r) => SelecionarLocalizacaoScreen(
                resultado: r,
                tileProvider: TilesLocais(),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Novo lugar'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Latitude'), '-10,5');
      await tester.enterText(campo('Longitude'), '-40');
      await tester.enterText(campo('Endereço ou CEP'), 'Praça da Sé');
      await tester.ensureVisible(find.text('Buscar localização'));
      await tester.tap(find.text('Buscar localização'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(resultado.endereco));
      await tester.tap(find.text(resultado.endereco));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar localização'), findsOneWidget);
      // Ajuste manual pelo mesmo callback usado por um toque no mapa.
      final mapa = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final ponto = mapa.options.initialCenter;
      await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(50, 30),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      final marcador = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers
          .single
          .point;
      expect(marcador, isNot(ponto));
      await tester.tap(find.text('Usar estas coordenadas'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(campo('Latitude')).controller!.text,
        marcador.latitude.toString(),
      );
      expect(
        tester.widget<TextField>(campo('Longitude')).controller!.text,
        marcador.longitude.toString(),
      );
      await tester.ensureVisible(campo('Latitude'));
      await tester.enterText(campo('Latitude'), '-12,3');
      expect(
        tester.widget<TextField>(campo('Latitude')).controller!.text,
        '-12,3',
      );
      expect(lugares.cadastros, 0);
      await tester.pumpWidget(const SizedBox());
      lugares.dispose();
    },
  );

  testWidgets(
    'cancelar seleção preserva as coordenadas manuais no tema escuro',
    (tester) async {
      await telaGrande(tester);
      final latitude = TextEditingController(text: '-10');
      addTearDown(latitude.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BuscaLocalizacao(
              service: FakeGeocodificacao(),
              construirMapa: (r) => SelecionarLocalizacaoScreen(
                resultado: r,
                tileProvider: TilesLocais(),
              ),
              onConfirmar: (ponto) => latitude.text = '${ponto.latitude}',
            ),
          ),
        ),
      );
      await tester.enterText(campo('Endereço ou CEP'), 'Praça da Sé');
      await tester.tap(find.text('Buscar localização'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(resultado.endereco));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(latitude.text, '-10');
    },
  );

  testWidgets('coordenadas inválidas não podem ser confirmadas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SelecionarLocalizacaoScreen(
          resultado: LocalizacaoResultado(
            endereco: 'Inválido',
            coordenadas: Coordenadas(91, 0),
          ),
        ),
      ),
    );
    expect(find.textContaining('Coordenadas inválidas'), findsOneWidget);
    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNull);
    expect(find.byType(FlutterMap), findsNothing);
  });

  test(
    'controller bloqueia buscas duplicadas e tolera descarte durante busca',
    () async {
      final pending = Completer<List<LocalizacaoResultado>>();
      final fake = _Pendente(pending);
      final controller = GeocodificacaoController(fake);
      final busca = controller.buscar('Praça');
      expect(controller.carregando, isTrue);
      await controller.buscar('Outra praça');
      expect(fake.chamadas, 1);
      controller.dispose();
      pending.complete([resultado]);
      await busca;
    },
  );
}

class _Pendente implements GeocodificacaoService {
  final Completer<List<LocalizacaoResultado>> pending;
  int chamadas = 0;
  _Pendente(this.pending);
  @override
  Future<List<LocalizacaoResultado>> buscar(String consulta) {
    chamadas++;
    return pending.future;
  }
}
