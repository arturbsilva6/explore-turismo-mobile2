import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/screens/detalhe_lugar_screen.dart';

class MapaScreen extends StatefulWidget {
  final TileProvider? tileProvider;
  const MapaScreen({super.key, this.tileProvider});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  bool _erroTiles = false;

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
              Text(lugar.nome, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                lugar.categoria?.trim().isNotEmpty == true
                    ? lugar.categoria!
                    : 'Sem categoria',
              ),
              const SizedBox(height: 16),
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
        .where((l) => l.coordenadasValidas)
        .toList();
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
                        icon: const Icon(Icons.location_on, size: 32),
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
