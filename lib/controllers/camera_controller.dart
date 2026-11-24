// GUIA DE APRESENTAÇÃO — Neste arquivo, guarda a foto escolhida e conversa com a câmera ou galeria do celular.
// Os comentários explicam a ideia de cada trecho sem mudar o funcionamento.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guia_turismo/services/camera_service.dart';

// Esta classe CameraController reúne os dados e as ações dessa parte do aplicativo.
class CameraController extends ChangeNotifier {
  // Este objeto ajuda a tela a conversar com outra parte do aplicativo.
  final CameraService _service = CameraService();
  // Esta variável indica se há uma tarefa acontecendo, para mostrar carregamento e evitar cliques repetidos.
  bool carregando = false;
  // Aqui guardamos um aviso para mostrar quando alguma operação não dá certo.
  String? erro;
  File? _imagemSelecionada;
  File? get imagemSelecionada => _imagemSelecionada;

  // Esta função _selecionar organiza esta parte do funcionamento do aplicativo.
  Future<void> _selecionar(Future<File?> Function() escolher) async {
    // Evita começar outra tarefa igual enquanto a primeira ainda está em andamento.
    if (carregando) return;
    carregando = true;
    erro = null;
    notifyListeners();
    // Tentamos realizar essa tarefa, sabendo que ela pode falhar.
    try {
      // Aqui fica a imagem escolhida enquanto ela é usada na tela.
      final imagem = await escolher();
      // Cancelar o seletor não elimina uma foto escolhida anteriormente.
      if (imagem != null) _imagemSelecionada = imagem;
    } catch (_) {
      erro = 'Não foi possível abrir a câmera ou galeria. Confira as permissões.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // Esta função abrirGaleria abre a galeria de fotos do aparelho.
  Future<void> abrirGaleria() => _selecionar(_service.chamarGaleria);
  // Esta função abrirCamera abre a câmera para escolher uma fotografia.
  Future<void> abrirCamera() => _selecionar(_service.chamarCamera);
}
