import 'package:flutter/material.dart';
import 'package:guia_turismo/services/localizacao_atual_service.dart';
import 'package:guia_turismo/services/rotas_service.dart';
import 'package:guia_turismo/widgets/lugar_foto.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/screens/detalhe_lugar_screen.dart';

class MapaScreen extends StatefulWidget {
  final TileProvider? tileProvider;
  final LocalizacaoAtualService? localizacaoService;
  const MapaScreen({super.key, this.tileProvider, this.localizacaoService});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  bool _erroTiles = false;
  final MapController _mapaController = MapController();
  LatLng? _minhaPosicao;
  bool _buscandoGps = false;
  String? _erroGps;
  int? _filtroCategoria;

  @override
  void dispose() {
    _mapaController.dispose();
    super.dispose();
  }

  Future<void> _localizar() async {
    if (_buscandoGps) return;
    setState(() {
      _buscandoGps = true;
      _erroGps = null;
    });
    try {
      final posicao = await (widget.localizacaoService ?? LocalizacaoAtualService())
          .obterPosicao();
      if (!mounted) return;
      final ponto = LatLng(posicao.latitude, posicao.longitude);
      setState(() => _minhaPosicao = ponto);
      _mapaController.move(ponto, 15);
    } catch (e) {
      if (mounted) setState(() => _erroGps = e.toString());
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  void _mostrarLugar(BuildContext context, LugaresModel lugar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  LugarFoto(url: lugar.fotoUrl),
                  const SizedBox(width: 12),
                  Expanded(child: Text(lugar.nome, style: Theme.of(context).textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lugar.categoria?.trim().isNotEmpty == true
                    ? lugar.categoria!
                    : 'Sem categoria',
              ),
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
                label: const Text('Como chegar'),
                onPressed: () async {
                  try {
                    await RotasService().comoChegar(
                      lugar.latitude.toDouble(), lugar.longitude.toDouble(),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Ver detalhes'),
                onPressed: () {
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
  Widget build(BuildContext context) {
    final controller = context.watch<LugaresController>();
    final cores = Theme.of(context).colorScheme;
    if (controller.carregando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando lugares no mapa…'),
          ],
        ),
      );
    }
    final lugares = controller.lugares
        .where((l) => l.coordenadasValidas &&
            (_filtroCategoria == null || l.categoriaId == _filtroCategoria))
        .toList();
    if (controller.erro.isEmpty && _filtroCategoria != null &&
        lugares.isEmpty && controller.lugares.any((l) => l.coordenadasValidas)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nenhum lugar dessa categoria no mapa.'),
            TextButton(
              onPressed: () => setState(() => _filtroCategoria = null),
              child: const Text('Limpar filtro'),
            ),
          ],
        ),
      );
    }
    if (controller.erro.isNotEmpty || lugares.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.erro.isNotEmpty
                    ? Icons.wifi_off
                    : Icons.map_outlined,
                size: 56,
                color: cores.primary,
              ),
              const SizedBox(height: 16),
              Text(
                controller.erro.isNotEmpty
                    ? 'Não foi possível carregar os lugares. Verifique sua conexão.'
                    : controller.lugares.isEmpty
                    ? 'Nenhum lugar cadastrado.'
                    : 'Nenhum lugar possui coordenadas válidas para o mapa.',
                textAlign: TextAlign.center,
              ),
              if (controller.limiteAtingido && controller.erro.isEmpty)
                const Text('A consulta atingiu o limite de páginas.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.listaLugares,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    final pontos = lugares
        .map((l) => LatLng(l.latitude.toDouble(), l.longitude.toDouble()))
        .toList();
    return Column(
      children: [
        Material(
          color: cores.surfaceContainer,
          child: ListTile(
            dense: true,
            title: Text('${lugares.length} lugares no mapa'),
            subtitle: controller.limiteAtingido
                ? const Text(
                    'Exibição parcial: limite seguro da consulta atingido.',
                  )
                : null,
            trailing: IconButton(
              onPressed: () {
                setState(() => _erroTiles = false);
                controller.listaLugares();
              },
              tooltip: 'Atualizar lugares',
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _filtroCategoria,
                  items: const [
                    DropdownMenuItem<int?>(value: null, child: Text('Todas as categorias')),
                    DropdownMenuItem<int?>(value: 1, child: Text('Praias')),
                    DropdownMenuItem<int?>(value: 2, child: Text('Points')),
                    DropdownMenuItem<int?>(value: 3, child: Text('Ilhas')),
                    DropdownMenuItem<int?>(value: 4, child: Text('Gastronomia')),
                    DropdownMenuItem<int?>(value: 5, child: Text('Dicas')),
                  ],
                  onChanged: (id) => setState(() => _filtroCategoria = id),
                ),
              ),
              IconButton(
                tooltip: 'Minha localização GPS',
                onPressed: _buscandoGps ? null : _localizar,
                icon: _buscandoGps
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        if (_erroGps != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_erroGps!, style: TextStyle(color: cores.error)),
          ),
        if (_erroTiles)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Não foi possível carregar parte do mapa. Verifique sua conexão e atualize.',
              style: TextStyle(color: cores.error),
            ),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _mapaController,
            options: MapOptions(
              initialCenter: pontos.first,
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
                  if (_erroTiles) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_erroTiles) {
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
                      child: IconButton(
                        tooltip: lugares[i].nome,
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
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('OpenStreetMap'),
                    content: const SelectableText(
                      '© OpenStreetMap contributors\n'
                      'Dados disponíveis sob a licença ODbL.\n'
                      'https://www.openstreetmap.org/copyright',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
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
