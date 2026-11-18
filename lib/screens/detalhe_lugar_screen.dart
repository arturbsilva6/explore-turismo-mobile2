import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/widgets/lugar_foto.dart';
import 'package:guia_turismo/controller/favoritos_controller.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/services/galeria_service.dart';
import 'package:guia_turismo/services/rotas_service.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DetalheLugarScreen extends StatefulWidget {
  final LugaresModel lugar;
  const DetalheLugarScreen({super.key, required this.lugar});

  @override
  State<DetalheLugarScreen> createState() => _DetalheLugarScreenState();
}

class _DetalheLugarScreenState extends State<DetalheLugarScreen> {
  late LugaresModel _lugarAtual = widget.lugar;
  bool _enviandoFoto = false;

  LugaresModel get lugar => _lugarAtual;

  Future<void> _comoChegar(BuildContext context) async {
    try {
      await RotasService().comoChegar(
        lugar.latitude.toDouble(), lugar.longitude.toDouble(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir a rota: $e')),
        );
      }
    }
  }

  Future<void> _anexarFoto(BuildContext context) async {
    if (_enviandoFoto) return;
    final tokenAntes = await SessionService().pegarToken() ?? '';
    if (!mounted) return;
    if (tokenAntes.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Entre com sua conta da API para adicionar fotos.'),
      ));
      return;
    }
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (!mounted || origem == null) return;
    setState(() => _enviandoFoto = true);
    try {
      final imagem = await ImagePicker().pickImage(
        source: origem, imageQuality: 75, maxWidth: 1600,
      );
      if (imagem == null) return;
      // Uma troca de conta durante o seletor não deve autorizar o upload antigo.
      final tokenAtual = await SessionService().pegarToken() ?? '';
      if (tokenAtual.isEmpty || tokenAtual != tokenAntes) {
        throw const FormatException('A sessão mudou. Entre novamente.');
      }
      await GaleriaService().enviarFoto(
        lugarId: lugar.id, caminho: File(imagem.path).path, token: tokenAtual,
      );
      if (!mounted) return;
      final controller = context.read<LugaresController>();
      await controller.listaLugares();
      if (!mounted) return;
      for (final atualizado in controller.lugares) {
        if (atualizado.id == lugar.id) {
          setState(() => _lugarAtual = atualizado);
          break;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto enviada. A imagem aparecerá quando a API disponibilizar a galeria.'),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível enviar a foto. Confira a conexão e a sessão.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final coordenadas = '${lugar.latitude}, ${lugar.longitude}';
    final descricao = lugar.descricao?.trim() ?? '';
    FavoritosController? favoritos;
    try {
      favoritos = context.watch<FavoritosController>();
    } on ProviderNotFoundException {
      // Não impede apresentação dos detalhes nos testes sem provider.
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do lugar'),
        actions: [
          if (favoritos != null)
            IconButton(
              tooltip: favoritos.contem(lugar.id)
                  ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
              icon: Icon(
                favoritos.contem(lugar.id) ? Icons.favorite : Icons.favorite_border,
                color: favoritos.contem(lugar.id) ? cores.error : null,
              ),
              onPressed: () async {
                final salvo = await favoritos!.alternar(lugar.id);
                if (!salvo && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(favoritos?.erro ?? 'Não foi possível alterar favorito.'),
                  ));
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cores.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
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
            onPressed: _enviandoFoto ? null : () => _anexarFoto(context),
            icon: _enviandoFoto
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_enviandoFoto ? 'Enviando foto...' : 'Adicionar foto à galeria'),
          ),
          const SizedBox(height: 12),
          Text('Sobre este lugar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            descricao.isEmpty ? 'Este lugar ainda não possui descrição.' : descricao,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          Text('Localização', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    title: const Text('Latitude'),
                    subtitle: Text('${lugar.latitude}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.explore_outlined),
                    title: const Text('Longitude'),
                    subtitle: Text('${lugar.longitude}'),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: coordenadas));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coordenadas copiadas!')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar coordenadas'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: lugar.coordenadasValidas
                        ? () => _comoChegar(context)
                        : null,
                    icon: const Icon(Icons.directions_outlined),
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
