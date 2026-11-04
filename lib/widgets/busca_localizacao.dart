import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controller/geocodificacao_controller.dart';
import 'package:guia_turismo/models/localizacao_model.dart';
import 'package:guia_turismo/screens/selecionar_localizacao_screen.dart';
import 'package:guia_turismo/services/geocodificacao_service.dart';

class BuscaLocalizacao extends StatefulWidget {
  final ValueChanged<Coordenadas> onConfirmar;
  final bool enabled;
  final GeocodificacaoService? service;
  final Widget Function(LocalizacaoResultado)? construirMapa;
  const BuscaLocalizacao({
    super.key,
    required this.onConfirmar,
    this.enabled = true,
    this.service,
    this.construirMapa,
  });

  @override
  State<BuscaLocalizacao> createState() => _BuscaLocalizacaoState();
}

class _BuscaLocalizacaoState extends State<BuscaLocalizacao> {
  final _texto = TextEditingController();
  bool _selecionando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) =>
        GeocodificacaoController(widget.service ?? NominatimService()),
    child: Consumer<GeocodificacaoController>(
      builder: (context, controller, _) {
        final habilitado =
            widget.enabled && !controller.carregando && !_selecionando;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _texto,
              enabled: habilitado,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Endereço ou CEP',
                hintText: 'Rua, número, cidade ou 00000-000',
                helperText:
                    'Busca opcional. Você também pode digitar as coordenadas.',
                helperMaxLines: 3,
                prefixIcon: Icon(Icons.search),
              ),
            ),
            OutlinedButton.icon(
              onPressed: habilitado
                  ? () {
                      FocusScope.of(context).unfocus();
                      controller.buscar(_texto.text);
                    }
                  : null,
              icon: controller.carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_searching),
              label: const Text('Buscar localização'),
            ),
            if (controller.erro.isNotEmpty)
              Text(
                controller.erro,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (controller.pesquisou && controller.resultados.isEmpty)
              const Text(
                'Nenhuma localização encontrada. Tente incluir cidade e estado ou digite as coordenadas.',
              ),
            for (final resultado in controller.resultados)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(resultado.endereco),
                trailing: const Icon(Icons.chevron_right),
                onTap: !habilitado
                    ? null
                    : () async {
                        setState(() => _selecionando = true);
                        final ponto = await Navigator.of(context)
                            .push<Coordenadas>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    widget.construirMapa?.call(resultado) ??
                                    SelecionarLocalizacaoScreen(
                                      resultado: resultado,
                                    ),
                              ),
                            );
                        if (!mounted) return;
                        setState(() => _selecionando = false);
                        if (widget.enabled && ponto != null && ponto.validas) {
                          widget.onConfirmar(ponto);
                        }
                      },
              ),
            const SizedBox(height: 8),
            const Text(
              'Busca: Nominatim · © OpenStreetMap contributors · ODbL',
              style: TextStyle(fontSize: 12),
            ),
            const SelectableText(
              'https://www.openstreetmap.org/copyright',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    ),
  );
}
