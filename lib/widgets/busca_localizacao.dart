// PARA A APRESENTAÇÃO: este arquivo mostra o campo de CEP ou endereço e os resultados da pesquisa.
// As explicações abaixo ajudam a entender os passos sem alterar o resultado.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/geocodificacao_controller.dart';
import 'package:guia_turismo/models/localizacao_model.dart';
import 'package:guia_turismo/screens/selecionar_localizacao_screen.dart';
import 'package:guia_turismo/services/geocodificacao_service.dart';

// Esta classe BuscaLocalizacao reúne as ações e informações usadas aqui.
class BuscaLocalizacao extends StatefulWidget {
  // Guarda o endereço ou a localização que será utilizada.
  final ValueChanged<Coordenadas> onConfirmar;
  // Guarda uma informação que será usada nesta parte.
  final bool enabled;
  // Ajuda o componente a conversar com os dados do aplicativo.
  final GeocodificacaoService? service;
  // Guarda uma informação que será usada nesta parte.
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

// Esta classe _BuscaLocalizacaoState reúne as ações e informações usadas aqui.
class _BuscaLocalizacaoState extends State<BuscaLocalizacao> {
  // Ajuda o componente a conversar com os dados do aplicativo.
  final _texto = TextEditingController();
  // Guarda uma informação que será usada nesta parte.
  bool _selecionando = false;

  @override
  // A função dispose organiza uma parte deste recurso.
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  // A função build monta a parte visual que será mostrada.
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) =>
        GeocodificacaoController(widget.service ?? NominatimService()),
    child: Consumer<GeocodificacaoController>(
      builder: (context, controller, _) {
        // Guarda uma informação que será usada nesta parte.
        final habilitado =
            widget.enabled && !controller.carregando && !_selecionando;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Este componente mostra informação ou permite que a pessoa faça uma escolha.
            TextField(
              controller: _texto,
              enabled: habilitado,
              maxLength: 200,
              // Este componente mostra informação ou permite que a pessoa faça uma escolha.
              decoration: const InputDecoration(
                // Este texto é uma dica ou aviso que aparece na tela.
                labelText: 'Endereço ou CEP',
                // Este texto é uma dica ou aviso que aparece na tela.
                hintText: 'Rua, número, cidade ou 00000-000',
                helperText:
                    'Busca opcional. Você também pode digitar as coordenadas.',
                helperMaxLines: 3,
                prefixIcon: Icon(Icons.search),
              ),
            ),
            OutlinedButton.icon(
              // Aqui fica a ação executada quando a pessoa toca.
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
              // Este texto é uma dica ou aviso que aparece na tela.
              label: const Text('Buscar localização'),
            ),
            // Mostra um aviso se não houver informação suficiente.
            if (controller.erro.isNotEmpty)
              Text(
                controller.erro,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            // Mostra um aviso se não houver informação suficiente.
            if (controller.pesquisou && controller.resultados.isEmpty)
              const Text(
                'Nenhuma localização encontrada. Tente incluir cidade e estado ou digite as coordenadas.',
              ),
            for (final resultado in controller.resultados)
              // Este componente mostra informação ou permite que a pessoa faça uma escolha.
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(resultado.endereco),
                trailing: const Icon(Icons.chevron_right),
                // Aqui fica a ação executada quando a pessoa toca.
                onTap: !habilitado
                    ? null
                    : () async {
                        setState(() => _selecionando = true);
                        // Guarda uma informação que será usada nesta parte.
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
                        // Essa condição escolhe qual caminho o aplicativo seguirá.
                        if (!mounted) return;
                        setState(() => _selecionando = false);
                        // Evita abrir endereços ou coordenadas incorretos.
                        if (widget.enabled && ponto != null && ponto.validas) {
                          widget.onConfirmar(ponto);
                        }
                      },
              ),
            const SizedBox(height: 8),
            const Text(
              'Busca: ViaCEP e Nominatim · © OpenStreetMap contributors · ODbL',
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
