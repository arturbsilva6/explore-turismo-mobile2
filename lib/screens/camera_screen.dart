// PARA A APRESENTAÇÃO: este arquivo deixa a pessoa tirar uma foto ou escolher uma da galeria.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/camera_controller.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  Future<void> _selecionar(BuildContext context, bool camera) async {
    final controller = context.read<CameraController>();
    if (camera) {
      await controller.abrirCamera();
    } else {
      await controller.abrirGaleria();
    }
    if (context.mounted && controller.erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.erro!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Consumer<CameraController>(
      builder: (context, controller, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Sua fotografia', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Tire uma foto ou selecione uma imagem da galeria.'),
          const SizedBox(height: 16),
          Container(
            height: 300,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cores.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cores.outlineVariant),
            ),
            child: controller.carregando
                ? const Center(child: CircularProgressIndicator())
                : controller.imagemSelecionada == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 72, color: cores.primary),
                          const SizedBox(height: 12),
                          const Text('Nenhuma foto selecionada'),
                        ],
                      )
                    : Image.file(
                        File(controller.imagemSelecionada!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text('A imagem selecionada não está disponível.'),
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.carregando ? null : () => _selecionar(context, true),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Tirar foto'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.carregando ? null : () => _selecionar(context, false),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Escolher da galeria'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para anexar uma foto a um lugar, use a opção de fotografia no formulário de cadastro.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
