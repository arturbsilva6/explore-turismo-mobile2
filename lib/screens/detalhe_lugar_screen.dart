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

class DetalheLugarScreen extends StatelessWidget {
  final LugaresModel lugar;
  const DetalheLugarScreen({super.key, required this.lugar});

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
    final token = await SessionService().pegarToken() ?? '';
    if (!context.mounted) return;
    if (token.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Faça login na API da faculdade para adicionar fotos.'),
      ));
      return;
    }
    try {
      final imagem = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600,
      );
      if (imagem == null) return;
      await GaleriaService().enviarFoto(
        lugarId: lugar.id, caminho: File(imagem.path).path, token: token,
      );
      if (!context.mounted) return;
      context.read<LugaresController>().listaLugares();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto enviada para a galeria do lugar. Atualize a tela para ver.'),
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Falha ao adicionar foto: $e'),
        ));
      }
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
            onPressed: () => _anexarFoto(context),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Adicionar foto à galeria'),
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
