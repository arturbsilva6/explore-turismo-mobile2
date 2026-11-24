// PARA A APRESENTAÇÃO: este arquivo deixa a pessoa tirar uma foto ou escolher uma da galeria.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/camera_controller.dart';
import 'package:provider/provider.dart';

// Esta classe CameraScreen reúne tudo que essa tela precisa para funcionar.
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  // A função _selecionar abre a câmera ou galeria conforme a escolha.
  Future<void> _selecionar(BuildContext context, bool camera) async {
    // Ajuda a tela a usar os dados ou verificar o formulário.
    final controller = context.read<CameraController>();
    // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
    if (camera) {
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await controller.abrirCamera();
    } else {
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await controller.abrirGaleria();
    }
    // Só mexe na tela se ela ainda estiver aberta.
    if (context.mounted && controller.erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.erro!)),
      );
    }
  }

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Essa variável guarda uma informação usada mais adiante.
    final cores = Theme.of(context).colorScheme;
    return Consumer<CameraController>(
      // Organiza os elementos na tela para que fiquem na ordem certa.
      builder: (context, controller, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Este texto aparece na tela para orientar quem está usando o app.
          Text('Sua fotografia', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          // Este texto aparece na tela para orientar quem está usando o app.
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
                    // Organiza os elementos na tela para que fiquem na ordem certa.
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 72, color: cores.primary),
                          const SizedBox(height: 12),
                          // Este texto aparece na tela para orientar quem está usando o app.
                          const Text('Nenhuma foto selecionada'),
                        ],
                      )
                    : Image.file(
                        File(controller.imagemSelecionada!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          // Este texto aparece na tela para orientar quem está usando o app.
                          child: Text('A imagem selecionada não está disponível.'),
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onPressed: controller.carregando ? null : () => _selecionar(context, true),
            icon: const Icon(Icons.camera_alt_outlined),
            // Este texto aparece na tela para orientar quem está usando o app.
            label: const Text('Tirar foto'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onPressed: controller.carregando ? null : () => _selecionar(context, false),
            icon: const Icon(Icons.photo_library_outlined),
            // Este texto aparece na tela para orientar quem está usando o app.
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
