// PARA A APRESENTAÇÃO: este arquivo permite ajustar o pino no mapa antes de preencher o cadastro.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:guia_turismo/models/localizacao_model.dart';

// Esta classe SelecionarLocalizacaoScreen reúne tudo que essa tela precisa para funcionar.
class SelecionarLocalizacaoScreen extends StatefulWidget {
  // Essa variável guarda uma informação usada mais adiante.
  final LocalizacaoResultado resultado;
  // Essa variável guarda uma informação usada mais adiante.
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

// Esta classe _SelecionarLocalizacaoScreenState reúne tudo que essa tela precisa para funcionar.
class _SelecionarLocalizacaoScreenState
    extends State<SelecionarLocalizacaoScreen> {
  // Guarda a localização que será usada no mapa.
  late Coordenadas _ponto = widget.resultado.coordenadas;
  // Guarda o aviso que será exibido quando algo não funcionar.
  bool _erroTiles = false;

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Essa variável guarda uma informação usada mais adiante.
    final cores = Theme.of(context).colorScheme;
    // Aqui é montada a estrutura principal desta tela.
    return Scaffold(
      // Este texto aparece na tela para orientar quem está usando o app.
      appBar: AppBar(title: const Text('Confirmar localização')),
      body: SafeArea(
        // Organiza os elementos na tela para que fiquem na ordem certa.
        child: Column(
          children: [
            // Organiza os elementos na tela para que fiquem na ordem certa.
            Padding(
              padding: const EdgeInsets.all(16),
              // Organiza os elementos na tela para que fiquem na ordem certa.
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
            // Confere se faltam informações ou se há algum erro.
            if (_erroTiles)
              // Organiza os elementos na tela para que fiquem na ordem certa.
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Não foi possível carregar parte do mapa. Verifique sua conexão antes de confirmar.',
                ),
              ),
            // Organiza os elementos na tela para que fiquem na ordem certa.
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
                        // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                        onTap: (_, ponto) {
                          // Essa variável guarda uma informação usada mais adiante.
                          final coordenadas = Coordenadas(
                            ponto.latitude,
                            ponto.longitude,
                          );
                          // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
                          if (coordenadas.validas) {
                            // Avisa ao Flutter que precisa mostrar uma informação atualizada.
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
                          // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              // Este texto aparece na tela para orientar quem está usando o app.
                              title: const Text('OpenStreetMap'),
                              content: const SelectableText(
                                '© OpenStreetMap contributors · ODbL\n'
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
                          // Este texto aparece na tela para orientar quem está usando o app.
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
            // Organiza os elementos na tela para que fiquem na ordem certa.
            Padding(
              padding: const EdgeInsets.all(16),
              // Organiza os elementos na tela para que fiquem na ordem certa.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Latitude: ${_ponto.latitude.toStringAsFixed(6)}\n'
                    'Longitude: ${_ponto.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                    onPressed: _ponto.validas
                        // Abre uma tela ou janela e mantém o caminho de navegação.
                        ? () => Navigator.pop(context, _ponto)
                        : null,
                    icon: const Icon(Icons.check),
                    // Este texto aparece na tela para orientar quem está usando o app.
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
