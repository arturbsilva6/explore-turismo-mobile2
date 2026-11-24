// PARA A APRESENTAÇÃO: este arquivo desenha os lugares no mapa e permite consultar o GPS do celular.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'package:flutter/material.dart';
import 'package:guia_turismo/services/localizacao_atual_service.dart';
import 'package:guia_turismo/services/rotas_service.dart';
import 'package:guia_turismo/widgets/lugar_foto.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/screens/detalhe_lugar_screen.dart';

// Esta classe MapaScreen reúne tudo que essa tela precisa para funcionar.
class MapaScreen extends StatefulWidget {
  // Essa variável guarda uma informação usada mais adiante.
  final TileProvider? tileProvider;
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final LocalizacaoAtualService? localizacaoService;
  const MapaScreen({super.key, this.tileProvider, this.localizacaoService});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

// Esta classe _MapaScreenState reúne tudo que essa tela precisa para funcionar.
class _MapaScreenState extends State<MapaScreen> {
  // Guarda o aviso que será exibido quando algo não funcionar.
  bool _erroTiles = false;
  // Essa variável guarda uma informação usada mais adiante.
  bool _mapaPronto = false;
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final MapController _mapaController = MapController();
  LatLng? _minhaPosicao;
  // Indica se a tarefa ainda está acontecendo, para mostrar o carregamento.
  bool _buscandoGps = false;
  // Guarda o aviso que será exibido quando algo não funcionar.
  String? _erroGps;
  // Essa variável guarda uma informação usada mais adiante.
  bool _exigeConfiguracoesGps = false;
  int? _filtroCategoria;

  @override
  // A função dispose libera os recursos quando a tela fecha.
  void dispose() {
    _mapaController.dispose();
    super.dispose();
  }

  // A função _localizar pede a posição atual e coloca um pino no mapa.
  Future<void> _localizar() async {
    // Evita começar uma segunda tarefa enquanto a primeira ainda acontece.
    if (_buscandoGps) return;
    // Avisa ao Flutter que precisa mostrar uma informação atualizada.
    setState(() {
      _buscandoGps = true;
      _erroGps = null;
      _exigeConfiguracoesGps = false;
    });
    // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
    try {
      // Guarda a localização que será usada no mapa.
      final posicao = await (widget.localizacaoService ?? LocalizacaoAtualService())
          .obterPosicao();
      // Só mexe na tela se ela ainda estiver aberta.
      if (!mounted) return;
      // Guarda a localização que será usada no mapa.
      final ponto = LatLng(posicao.latitude, posicao.longitude);
      // Avisa ao Flutter que precisa mostrar uma informação atualizada.
      setState(() => _minhaPosicao = ponto);
      // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
      if (_mapaPronto) _mapaController.move(ponto, 15);
    } catch (e) {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) {
        // Avisa ao Flutter que precisa mostrar uma informação atualizada.
        setState(() {
          _erroGps = e.toString();
          _exigeConfiguracoesGps =
              e is LocalizacaoIndisponivel && e.exigeConfiguracoes;
        });
      }
    } finally {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  // A função _mostrarLugar mostra um resumo do lugar escolhido.
  void _mostrarLugar(BuildContext context, LugaresModel lugar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        // Organiza os elementos na tela para que fiquem na ordem certa.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          // Organiza os elementos na tela para que fiquem na ordem certa.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Organiza os elementos na tela para que fiquem na ordem certa.
              Row(
                children: [
                  LugarFoto(url: lugar.fotoUrl),
                  const SizedBox(width: 12),
                  // Organiza os elementos na tela para que fiquem na ordem certa.
                  Expanded(child: Text(lugar.nome, style: Theme.of(context).textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lugar.categoria?.trim().isNotEmpty == true
                    ? lugar.categoria!
                    : 'Sem categoria',
              ),
              // Confere se faltam informações ou se há algum erro.
              if (_minhaPosicao != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Distância aproximada: ${(LocalizacaoAtualService.distanciaMetros(
                    _minhaPosicao!.latitude, _minhaPosicao!.longitude,
                    lugar.latitude.toDouble(), lugar.longitude.toDouble(),
                  ) / 1000).toStringAsFixed(1)} km',
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.directions_outlined),
                // Este texto aparece na tela para orientar quem está usando o app.
                label: const Text('Como chegar'),
                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                onPressed: () async {
                  // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
                  try {
                    // Espera essa tarefa terminar para seguir para a próxima etapa.
                    await RotasService().comoChegar(
                      lugar.latitude.toDouble(), lugar.longitude.toDouble(),
                    );
                  } catch (_) {
                    // Só mexe na tela se ela ainda estiver aberta.
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        // Este texto aparece na tela para orientar quem está usando o app.
                        const SnackBar(content: Text('Não foi possível abrir a rota no aplicativo de mapas.')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.info_outline),
                // Este texto aparece na tela para orientar quem está usando o app.
                label: const Text('Ver detalhes'),
                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                onPressed: () {
                  // Essa variável guarda uma informação usada mais adiante.
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) => DetalheLugarScreen(lugar: lugar),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Ajuda a tela a usar os dados ou verificar o formulário.
    final controller = context.watch<LugaresController>();
    // Essa variável guarda uma informação usada mais adiante.
    final cores = Theme.of(context).colorScheme;
    // GPS e mapa não dependem da API: inclusive durante loading/erro/lista vazia.
    final lugares = controller.lugares
        .where((l) => l.coordenadasValidas &&
            (_filtroCategoria == null || l.categoriaId == _filtroCategoria))
        .toList();
    // Guarda a localização que será usada no mapa.
    final pontos = lugares
        .map((l) => LatLng(l.latitude.toDouble(), l.longitude.toDouble()))
        .toList();
    // Guarda o aviso que será exibido quando algo não funcionar.
    final mensagemSemLugares = controller.erro.isNotEmpty
        ? 'Não foi possível atualizar os lugares. O GPS continua disponível.'
        : controller.lugares.isEmpty
            ? 'Nenhum lugar cadastrado. Você ainda pode usar o GPS.'
            : _filtroCategoria != null && lugares.isEmpty
                ? 'Nenhum lugar desta categoria no mapa.'
                : lugares.isEmpty
                    ? 'Nenhum lugar possui coordenadas válidas.'
                    : null;
    // Organiza os elementos na tela para que fiquem na ordem certa.
    return Column(
      children: [
        // Evita começar uma segunda tarefa enquanto a primeira ainda acontece.
        if (controller.carregando)
          const LinearProgressIndicator(),
        Material(
          color: cores.surfaceContainer,
          child: ListTile(
            dense: true,
            // Este texto aparece na tela para orientar quem está usando o app.
            title: Text('${lugares.length} lugares no mapa'),
            subtitle: controller.limiteAtingido
                ? const Text(
                    'Exibição parcial: limite seguro da consulta atingido.',
                  )
                : null,
            // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
            trailing: IconButton(
              // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
              onPressed: () {
                // Avisa ao Flutter que precisa mostrar uma informação atualizada.
                setState(() => _erroTiles = false);
                controller.listaLugares();
              },
              // Este texto aparece na tela para orientar quem está usando o app.
              tooltip: 'Atualizar lugares',
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),
        // Confere se faltam informações ou se há algum erro.
        if (mensagemSemLugares != null)
          Material(
            color: cores.surfaceContainerLow,
            // Organiza os elementos na tela para que fiquem na ordem certa.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // Organiza os elementos na tela para que fiquem na ordem certa.
              child: Row(
                children: [
                  // Organiza os elementos na tela para que fiquem na ordem certa.
                  Expanded(child: Text(mensagemSemLugares)),
                  // Confere se faltam informações ou se há algum erro.
                  if (_filtroCategoria != null && controller.erro.isEmpty)
                    TextButton(
                      // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                      onPressed: () => setState(() => _filtroCategoria = null),
                      // Este texto aparece na tela para orientar quem está usando o app.
                      child: const Text('Limpar filtro'),
                    ),
                  // Confere se faltam informações ou se há algum erro.
                  if (controller.erro.isNotEmpty)
                    // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                    IconButton(
                      // Este texto aparece na tela para orientar quem está usando o app.
                      tooltip: 'Tentar novamente',
                      // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                      onPressed: controller.listaLugares,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
          ),
        // Organiza os elementos na tela para que fiquem na ordem certa.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          // Organiza os elementos na tela para que fiquem na ordem certa.
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              // Organiza os elementos na tela para que fiquem na ordem certa.
              Expanded(
                // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _filtroCategoria,
                  items: const [
                    // Este texto aparece na tela para orientar quem está usando o app.
                    DropdownMenuItem<int?>(value: null, child: Text('Todas as categorias')),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    DropdownMenuItem<int?>(value: 1, child: Text('Praias')),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    DropdownMenuItem<int?>(value: 2, child: Text('Points')),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    DropdownMenuItem<int?>(value: 3, child: Text('Ilhas')),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    DropdownMenuItem<int?>(value: 4, child: Text('Gastronomia')),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    DropdownMenuItem<int?>(value: 5, child: Text('Dicas')),
                  ],
                  // Atualiza a tela quando a pessoa muda essa opção.
                  onChanged: (id) => setState(() => _filtroCategoria = id),
                ),
              ),
              // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
              IconButton(
                // Este texto aparece na tela para orientar quem está usando o app.
                tooltip: 'Minha localização GPS',
                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                onPressed: _buscandoGps ? null : _localizar,
                icon: _buscandoGps
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        // Confere se faltam informações ou se há algum erro.
        if (_erroGps != null)
          // Organiza os elementos na tela para que fiquem na ordem certa.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_erroGps!, style: TextStyle(color: cores.error)),
          ),
        // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
        if (_exigeConfiguracoesGps)
          TextButton.icon(
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onPressed: () async {
              // Espera essa tarefa terminar para seguir para a próxima etapa.
              await (widget.localizacaoService ?? LocalizacaoAtualService())
                  .abrirConfiguracoes();
            },
            icon: const Icon(Icons.settings_outlined),
            // Este texto aparece na tela para orientar quem está usando o app.
            label: const Text('Abrir permissões do aplicativo'),
          ),
        // Confere se faltam informações ou se há algum erro.
        if (_erroTiles)
          // Organiza os elementos na tela para que fiquem na ordem certa.
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Não foi possível carregar parte do mapa. Verifique sua conexão e atualize.',
              style: TextStyle(color: cores.error),
            ),
          ),
        // Organiza os elementos na tela para que fiquem na ordem certa.
        Expanded(
          child: FlutterMap(
            mapController: _mapaController,
            options: MapOptions(
              initialCenter: pontos.isNotEmpty
                  ? pontos.first
                  : (_minhaPosicao ?? LatLng(-23.55052, -46.63330)),
              onMapReady: () {
                // Só mexe na tela se ela ainda estiver aberta.
                if (!mounted) return;
                _mapaPronto = true;
                // Confere se faltam informações ou se há algum erro.
                if (_minhaPosicao != null) {
                  _mapaController.move(_minhaPosicao!, 15);
                }
              },
              initialZoom: 13,
              minZoom: 2,
              maxZoom: 19,
              initialCameraFit: pontos.length > 1
                  ? CameraFit.coordinates(
                      coordinates: pontos,
                      padding: const EdgeInsets.all(48),
                      maxZoom: 15,
                    )
                  : null,
            ),
            children: [
              // O cache HTTP nativo do flutter_map 8.3.2 permanece habilitado.
              // Sem prefetch, downloads offline ou cabeçalhos que ignorem o cache.
              TileLayer(
                tileProvider: widget.tileProvider,
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.exploreturismo.mobileii',
                panBuffer: 0,
                maxNativeZoom: 19,
                errorTileCallback: (_, _, _) {
                  // Confere se faltam informações ou se há algum erro.
                  if (_erroTiles) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Só mexe na tela se ela ainda estiver aberta.
                    if (mounted && !_erroTiles) {
                      // Avisa ao Flutter que precisa mostrar uma informação atualizada.
                      setState(() => _erroTiles = true);
                    }
                  });
                },
              ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < lugares.length; i++)
                    Marker(
                      point: pontos[i],
                      width: 48,
                      height: 48,
                      // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                      child: IconButton(
                        tooltip: lugares[i].nome,
                        // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                        onPressed: () => _mostrarLugar(context, lugares[i]),
                        style: IconButton.styleFrom(
                          backgroundColor: cores.surface,
                          foregroundColor: cores.primary,
                        ),
                        icon: lugares[i].fotoUrl == null
                            ? const Icon(Icons.location_on, size: 32)
                            : LugarFoto(url: lugares[i].fotoUrl, tamanho: 44),
                      ),
                    ),
                  // Confere se faltam informações ou se há algum erro.
                  if (_minhaPosicao != null)
                    Marker(
                      point: _minhaPosicao!,
                      width: 56,
                      height: 56,
                      child: Semantics(
                        label: 'Sua localização atual',
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 42,
                        ),
                      ),
                    ),
                ],
              ),
              SimpleAttributionWidget(
                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    // Este texto aparece na tela para orientar quem está usando o app.
                    title: const Text('OpenStreetMap'),
                    content: const SelectableText(
                      '© OpenStreetMap contributors\n'
                      'Dados disponíveis sob a licença ODbL.\n'
                      'https://www.openstreetmap.org/copyright',
                    ),
                    actions: [
                      TextButton(
                        // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                        onPressed: () => Navigator.pop(context),
                        // Este texto aparece na tela para orientar quem está usando o app.
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                ),
                source: const Text(
                  'OpenStreetMap contributors',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
