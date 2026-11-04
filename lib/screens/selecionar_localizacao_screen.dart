import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:guia_turismo/models/localizacao_model.dart';

class SelecionarLocalizacaoScreen extends StatefulWidget {
  final LocalizacaoResultado resultado;
  final TileProvider? tileProvider;
  const SelecionarLocalizacaoScreen({
    super.key,
    required this.resultado,
    this.tileProvider,
  });

  @override
  State<SelecionarLocalizacaoScreen> createState() =>
      _SelecionarLocalizacaoScreenState();
}

class _SelecionarLocalizacaoScreenState
    extends State<SelecionarLocalizacaoScreen> {
  late Coordenadas _ponto = widget.resultado.coordenadas;
  bool _erroTiles = false;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar localização')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    widget.resultado.endereco,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque no mapa para ajustar o marcador. Confirme o ponto antes de usar.',
                  ),
                ],
              ),
            ),
            if (_erroTiles)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Não foi possível carregar parte do mapa. Verifique sua conexão antes de confirmar.',
                ),
              ),
            Expanded(
              child: _ponto.validas
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          _ponto.latitude,
                          _ponto.longitude,
                        ),
                        initialZoom: 16,
                        minZoom: 2,
                        maxZoom: 19,
                        onTap: (_, ponto) {
                          final coordenadas = Coordenadas(
                            ponto.latitude,
                            ponto.longitude,
                          );
                          if (coordenadas.validas) {
                            setState(() => _ponto = coordenadas);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'br.exploreturismo.mobileii',
                          tileProvider: widget.tileProvider,
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
                            Marker(
                              point: LatLng(_ponto.latitude, _ponto.longitude),
                              width: 48,
                              height: 48,
                              child: Semantics(
                                label: 'Localização selecionada',
                                child: Icon(
                                  Icons.location_on,
                                  color: cores.primary,
                                  size: 44,
                                  shadows: [
                                    Shadow(color: cores.surface, blurRadius: 4),
                                  ],
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
                                '© OpenStreetMap contributors · ODbL\n'
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
                          source: const Text('OpenStreetMap contributors'),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        'Coordenadas inválidas. Volte e escolha outro resultado.',
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Latitude: ${_ponto.latitude.toStringAsFixed(6)}\n'
                    'Longitude: ${_ponto.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _ponto.validas
                        ? () => Navigator.pop(context, _ponto)
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Usar estas coordenadas'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
