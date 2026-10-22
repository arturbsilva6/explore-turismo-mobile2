import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guia_turismo/models/lugares_model.dart';

/// Exibe os dados de um lugar já carregado da API.
/// Não realiza uma nova requisição porque recebe o objeto pela navegação.
class DetalheLugarScreen extends StatelessWidget {
  final LugaresModel lugar;

  const DetalheLugarScreen({super.key, required this.lugar});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final coordenadas = '${lugar.latitude}, ${lugar.longitude}';
    final descricao = lugar.descricao?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do lugar')),
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
                Icon(Icons.landscape_rounded, size: 64, color: cores.primary),
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
          const SizedBox(height: 24),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
