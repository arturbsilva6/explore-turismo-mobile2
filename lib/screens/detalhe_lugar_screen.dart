// PARA A APRESENTAÇÃO: este arquivo mostra os detalhes do destino e os botões de foto, favorito e rota.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/widgets/lugar_foto.dart';
import 'package:guia_turismo/controllers/favoritos_controller.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/services/galeria_service.dart';
import 'package:guia_turismo/services/rotas_service.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:guia_turismo/services/navegacao_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Esta classe DetalheLugarScreen reúne tudo que essa tela precisa para funcionar.
class DetalheLugarScreen extends StatefulWidget {
  // Essa variável guarda uma informação usada mais adiante.
  final LugaresModel lugar;
  const DetalheLugarScreen({super.key, required this.lugar});

  @override
  State<DetalheLugarScreen> createState() => _DetalheLugarScreenState();
}

// Esta classe _DetalheLugarScreenState reúne tudo que essa tela precisa para funcionar.
class _DetalheLugarScreenState extends State<DetalheLugarScreen> {
  // Essa variável guarda uma informação usada mais adiante.
  late LugaresModel _lugarAtual = widget.lugar;
  // Guarda a foto escolhida ou o caminho dela.
  bool _enviandoFoto = false;

  LugaresModel get lugar => _lugarAtual;

  // A função _comoChegar abre uma rota no aplicativo de mapas.
  Future<void> _comoChegar(BuildContext context) async {
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
          const SnackBar(content: Text('Não foi possível abrir a rota. Verifique o aplicativo de mapas.')),
        );
      }
    }
  }

  // A função _anexarFoto permite adicionar uma foto ao lugar.
  Future<void> _anexarFoto() async {
    // Evita começar uma segunda tarefa enquanto a primeira ainda acontece.
    if (_enviandoFoto) return;
    // Ajuda a tela a usar os dados ou verificar o formulário.
    final tokenAntes = await SessionService().pegarToken() ?? '';
    // Só mexe na tela se ela ainda estiver aberta.
    if (!mounted) return;
    // Confere se faltam informações ou se há algum erro.
    if (tokenAntes.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        // Este texto aparece na tela para orientar quem está usando o app.
        content: Text('Entre com sua conta da API para adicionar fotos.'),
      ));
      return;
    }
    // Essa variável guarda uma informação usada mais adiante.
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            // Este texto aparece na tela para orientar quem está usando o app.
            title: const Text('Tirar foto'),
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            // Este texto aparece na tela para orientar quem está usando o app.
            title: const Text('Escolher da galeria'),
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ]),
      ),
    );
    // Só mexe na tela se ela ainda estiver aberta.
    if (!mounted || origem == null) return;
    // Avisa ao Flutter que precisa mostrar uma informação atualizada.
    setState(() => _enviandoFoto = true);
    // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
    try {
      // Guarda a foto escolhida ou o caminho dela.
      final imagem = await ImagePicker().pickImage(
        source: origem, imageQuality: 75, maxWidth: 1600,
      );
      // Confere se faltam informações ou se há algum erro.
      if (imagem == null) return;
      // Uma troca de conta durante o seletor não deve autorizar o upload antigo.
      final tokenAtual = await SessionService().pegarToken() ?? '';
      // Confere se faltam informações ou se há algum erro.
      if (tokenAtual.isEmpty || tokenAtual != tokenAntes) {
        throw const FormatException('A sessão mudou. Entre novamente.');
      }
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await GaleriaService().enviarFoto(
        lugarId: lugar.id, caminho: File(imagem.path).path, token: tokenAtual,
      );
      // Só mexe na tela se ela ainda estiver aberta.
      if (!mounted) return;
      // Ajuda a tela a usar os dados ou verificar o formulário.
      final controller = context.read<LugaresController>();
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await controller.listaLugares();
      // Só mexe na tela se ela ainda estiver aberta.
      if (!mounted) return;
      for (final atualizado in controller.lugares) {
        // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
        if (atualizado.id == lugar.id) {
          // Avisa ao Flutter que precisa mostrar uma informação atualizada.
          setState(() => _lugarAtual = atualizado);
          break;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        // Este texto aparece na tela para orientar quem está usando o app.
        content: Text('Foto enviada. A imagem aparecerá quando a API disponibilizar a galeria.'),
      ));
    } on SessaoExpiradaException {
      // Confere se a conta está autorizada para essa ação.
      if (await SessionService().invalidarSeAtual(tokenAntes)) {
        // Só mexe na tela se ela ainda estiver aberta.
        if (mounted) {
          context.read<FavoritosController>().limpar();
        }
        NavegacaoService.irParaLogin();
      }
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          // Este texto aparece na tela para orientar quem está usando o app.
          content: Text('Sua sessão expirou. Entre novamente para enviar a foto.'),
        ));
      }
    } catch (_) {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          // Este texto aparece na tela para orientar quem está usando o app.
          content: Text('Não foi possível enviar a foto. Confira a conexão e a sessão.'),
        ));
      }
    } finally {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Essa variável guarda uma informação usada mais adiante.
    final cores = Theme.of(context).colorScheme;
    // Guarda a localização que será usada no mapa.
    final coordenadas = '${lugar.latitude}, ${lugar.longitude}';
    // Essa variável guarda uma informação usada mais adiante.
    final descricao = lugar.descricao?.trim() ?? '';
    FavoritosController? favoritos;
    // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
    try {
      favoritos = context.watch<FavoritosController>();
    } on ProviderNotFoundException {
      // Não impede apresentação dos detalhes nos testes sem provider.
    }
    // Aqui é montada a estrutura principal desta tela.
    return Scaffold(
      appBar: AppBar(
        // Este texto aparece na tela para orientar quem está usando o app.
        title: const Text('Detalhes do lugar'),
        actions: [
          // Confere se faltam informações ou se há algum erro.
          if (favoritos != null)
            // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
            IconButton(
              tooltip: favoritos.contem(lugar.id)
                  ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
              icon: Icon(
                favoritos.contem(lugar.id) ? Icons.favorite : Icons.favorite_border,
                color: favoritos.contem(lugar.id) ? cores.error : null,
              ),
              // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
              onPressed: () async {
                // Essa variável guarda uma informação usada mais adiante.
                final salvo = await favoritos!.alternar(lugar.id);
                // Só mexe na tela se ela ainda estiver aberta.
                if (!salvo && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(favoritos?.erro ?? 'Não foi possível alterar favorito.'),
                  ));
                }
              },
            ),
        ],
      ),
      // Organiza os elementos na tela para que fiquem na ordem certa.
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cores.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            // Organiza os elementos na tela para que fiquem na ordem certa.
            child: Column(
              children: [
                LugarFoto(url: lugar.fotoUrl, tamanho: 160),
                const SizedBox(height: 12),
                Text(
                  lugar.nome,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(lugar.categoria ?? 'Sem categoria'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onPressed: _enviandoFoto ? null : _anexarFoto,
            icon: _enviandoFoto
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_enviandoFoto ? 'Enviando foto...' : 'Adicionar foto à galeria'),
          ),
          const SizedBox(height: 12),
          // Este texto aparece na tela para orientar quem está usando o app.
          Text('Sobre este lugar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            descricao.isEmpty ? 'Este lugar ainda não possui descrição.' : descricao,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          // Este texto aparece na tela para orientar quem está usando o app.
          Text('Localização', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            // Organiza os elementos na tela para que fiquem na ordem certa.
            child: Padding(
              padding: const EdgeInsets.all(14),
              // Organiza os elementos na tela para que fiquem na ordem certa.
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    title: const Text('Latitude'),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    subtitle: Text('${lugar.latitude}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.explore_outlined),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    title: const Text('Longitude'),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    subtitle: Text('${lugar.longitude}'),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                    onPressed: () async {
                      // Espera essa tarefa terminar para seguir para a próxima etapa.
                      await Clipboard.setData(ClipboardData(text: coordenadas));
                      // Só mexe na tela se ela ainda estiver aberta.
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        // Este texto aparece na tela para orientar quem está usando o app.
                        const SnackBar(content: Text('Coordenadas copiadas!')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    label: const Text('Copiar coordenadas'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                    onPressed: lugar.coordenadasValidas
                        ? () => _comoChegar(context)
                        : null,
                    icon: const Icon(Icons.directions_outlined),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    label: const Text('Como chegar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
