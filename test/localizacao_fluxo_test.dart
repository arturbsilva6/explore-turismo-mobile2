// PARA A APRESENTAÇÃO: estes testes verificam o caminho de buscar um endereço, ajustar o pino e voltar ao formulário.
// O teste simula ações e compara os resultados para evitar erros na entrega.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// A classe FakeGeocodificacao cria uma versão de teste de algo que o app usa.
class FakeGeocodificacao implements GeocodificacaoService {
  // Guarda uma informação de exemplo para o teste.
  int chamadas = 0;
  List<LocalizacaoResultado> resultados = [resultado];
  // Guarda uma informação de exemplo para o teste.
  bool falhar = false;
  @override
  Future<List<LocalizacaoResultado>> buscar(String consulta) async {
    chamadas++;
    // Muda o retorno do teste para simular uma situação diferente.
    if (falhar) throw const GeocodificacaoException('Falha de conexão');
    return resultados;
  }
}

// A classe TilesLocais cria uma versão de teste de algo que o app usa.
class TilesLocais extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      // Usamos um exemplo controlado para não depender de internet ou mapa real.
      MemoryImage(TileProvider.transparentImage);
}

// A classe LugaresSemCadastro cria uma versão de teste de algo que o app usa.
class LugaresSemCadastro extends LugaresController {
  // Guarda uma informação de exemplo para o teste.
  int cadastros = 0;
  LugaresSemCadastro() : super(carregarAoIniciar: false);
  @override
  // Essa função prepara informações ou ações que serão usadas pelos testes.
  Future<String> cadastrarLugar(LugaresModel dados) async {
    cadastros++;
    // Provoca um erro intencional para conferir o aviso que o app mostra.
    throw StateError('Testes de localização não devem cadastrar lugares');
  }
}

// Essa função prepara informações ou ações que serão usadas pelos testes.
Future<void> telaGrande(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder campo(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

// Aqui começa a sequência de testes deste arquivo.
void main() {
  // Este teste simula a tela como se alguém estivesse usando o celular.
  testWidgets(
    'digitação não consulta; clique mostra resultados, vazio e erro',
    (tester) async {
      // Espera a tarefa acabar para conferir o resultado.
      await telaGrande(tester);
      // Usamos um exemplo controlado para não depender de internet ou mapa real.
      final service = FakeGeocodificacao();
      // Abre a tela no simulador de testes do Flutter.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuscaLocalizacao(service: service, onConfirmar: (_) {}),
          ),
        ),
      );
      // Simula alguém preenchendo um campo.
      await tester.enterText(campo('Endereço ou CEP'), 'Praça da Sé');
      // Simula uma ação que seria feita pelo usuário.
      await tester.pump(const Duration(seconds: 2));
      // Confere se o resultado é exatamente o que esperamos.
      expect(service.chamadas, 0);
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text('Buscar localização'));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(service.chamadas, 1);
      // Confere se o resultado é exatamente o que esperamos.
      expect(find.text(resultado.endereco), findsOneWidget);
      service.resultados = [];
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text('Buscar localização'));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(
        find.textContaining('Nenhuma localização encontrada'),
        findsOneWidget,
      );
      service.falhar = true;
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text('Buscar localização'));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(find.text('Falha de conexão'), findsOneWidget);
    },
  );

  // Este teste simula a tela como se alguém estivesse usando o celular.
  testWidgets(
    'ajuste e confirmação transferem coordenadas ao formulário sem POST',
    (tester) async {
      // Espera a tarefa acabar para conferir o resultado.
      await telaGrande(tester);
      SharedPreferences.setMockInitialValues({'token': 'token-teste-api'});
      // Guarda uma informação de exemplo para o teste.
      final lugares = LugaresSemCadastro();
      // Abre a tela no simulador de testes do Flutter.
      await tester.pumpWidget(
        ChangeNotifierProvider<LugaresController>.value(
          value: lugares,
          child: MaterialApp(
            theme: ThemeData(colorSchemeSeed: Colors.teal),
            home: LugaresScreen(
              // Usamos um exemplo controlado para não depender de internet ou mapa real.
              geocodificacaoService: FakeGeocodificacao(),
              construirMapa: (r) => SelecionarLocalizacaoScreen(
                resultado: r,
                tileProvider: TilesLocais(),
              ),
            ),
          ),
        ),
      );
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text('Novo lugar'));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Simula alguém preenchendo um campo.
      await tester.enterText(campo('Latitude'), '-10,5');
      // Simula alguém preenchendo um campo.
      await tester.enterText(campo('Longitude'), '-40');
      // Simula alguém preenchendo um campo.
      await tester.enterText(campo('Endereço ou CEP'), 'Praça da Sé');
      // Simula uma ação que seria feita pelo usuário.
      await tester.ensureVisible(find.text('Buscar localização'));
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text('Buscar localização'));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Simula uma ação que seria feita pelo usuário.
      await tester.ensureVisible(find.text(resultado.endereco));
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text(resultado.endereco));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(find.text('Confirmar localização'), findsOneWidget);
      // Ajuste manual pelo mesmo callback usado por um toque no mapa.
      final mapa = tester.widget<FlutterMap>(find.byType(FlutterMap));
      // Prepara um ponto ou situação no mapa para conferir depois.
      final ponto = mapa.options.initialCenter;
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(50, 30),
      );
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Simula uma ação que seria feita pelo usuário.
      await tester.pump(const Duration(milliseconds: 500));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Guarda uma informação de exemplo para o teste.
      final marcador = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers
          .single
          .point;
      // Confere se o resultado é exatamente o que esperamos.
      expect(marcador, isNot(ponto));
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text('Usar estas coordenadas'));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(
        tester.widget<TextField>(campo('Latitude')).controller!.text,
        marcador.latitude.toString(),
      );
      // Confere se o resultado é exatamente o que esperamos.
      expect(
        tester.widget<TextField>(campo('Longitude')).controller!.text,
        marcador.longitude.toString(),
      );
      // Simula uma ação que seria feita pelo usuário.
      await tester.ensureVisible(campo('Latitude'));
      // Simula alguém preenchendo um campo.
      await tester.enterText(campo('Latitude'), '-12,3');
      // Confere se o resultado é exatamente o que esperamos.
      expect(
        tester.widget<TextField>(campo('Latitude')).controller!.text,
        '-12,3',
      );
      // Confere se o resultado é exatamente o que esperamos.
      expect(lugares.cadastros, 0);
      // Abre a tela no simulador de testes do Flutter.
      await tester.pumpWidget(const SizedBox());
      lugares.dispose();
    },
  );

  // Este teste simula a tela como se alguém estivesse usando o celular.
  testWidgets(
    'cancelar seleção preserva as coordenadas manuais no tema escuro',
    (tester) async {
      // Espera a tarefa acabar para conferir o resultado.
      await telaGrande(tester);
      // Guarda um serviço de mentirinha para controlar o resultado do teste.
      final latitude = TextEditingController(text: '-10');
      addTearDown(latitude.dispose);
      // Abre a tela no simulador de testes do Flutter.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BuscaLocalizacao(
              // Usamos um exemplo controlado para não depender de internet ou mapa real.
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
      // Simula alguém preenchendo um campo.
      await tester.enterText(campo('Endereço ou CEP'), 'Praça da Sé');
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text('Buscar localização'));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Simula um toque na tela para testar o botão ou o mapa.
      await tester.tap(find.text(resultado.endereco));
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Simula uma ação que seria feita pelo usuário.
      await tester.pageBack();
      // Espera animações e mudanças da tela terminarem.
      await tester.pumpAndSettle();
      // Confere se o resultado é exatamente o que esperamos.
      expect(latitude.text, '-10');
    },
  );

  // Este teste simula a tela como se alguém estivesse usando o celular.
  testWidgets('coordenadas inválidas não podem ser confirmadas', (
    tester,
  ) async {
    // Abre a tela no simulador de testes do Flutter.
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
    // Confere se o resultado é exatamente o que esperamos.
    expect(find.textContaining('Coordenadas inválidas'), findsOneWidget);
    // Guarda uma informação de exemplo para o teste.
    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    // Confere se o resultado é exatamente o que esperamos.
    expect(botao.onPressed, isNull);
    // Confere se o resultado é exatamente o que esperamos.
    expect(find.byType(FlutterMap), findsNothing);
  });

  // Este teste confere uma regra do aplicativo sem abrir uma tela real.
  test(
    'controller bloqueia buscas duplicadas e tolera descarte durante busca',
    () async {
      // Prepara um ponto ou situação no mapa para conferir depois.
      final pending = Completer<List<LocalizacaoResultado>>();
      // Guarda um serviço de mentirinha para controlar o resultado do teste.
      final fake = _Pendente(pending);
      // Guarda um serviço de mentirinha para controlar o resultado do teste.
      final controller = GeocodificacaoController(fake);
      // Guarda um serviço de mentirinha para controlar o resultado do teste.
      final busca = controller.buscar('Praça');
      // Confere se o resultado é exatamente o que esperamos.
      expect(controller.carregando, isTrue);
      // Espera a tarefa acabar para conferir o resultado.
      await controller.buscar('Outra praça');
      // Confere se o resultado é exatamente o que esperamos.
      expect(fake.chamadas, 1);
      controller.dispose();
      pending.complete([resultado]);
      // Espera a tarefa acabar para conferir o resultado.
      await busca;
    },
  );
}

// A classe _Pendente cria uma versão de teste de algo que o app usa.
class _Pendente implements GeocodificacaoService {
  // Prepara um ponto ou situação no mapa para conferir depois.
  final Completer<List<LocalizacaoResultado>> pending;
  // Guarda uma informação de exemplo para o teste.
  int chamadas = 0;
  _Pendente(this.pending);
  @override
  Future<List<LocalizacaoResultado>> buscar(String consulta) {
    chamadas++;
    return pending.future;
  }
}
