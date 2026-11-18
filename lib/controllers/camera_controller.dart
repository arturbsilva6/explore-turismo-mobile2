import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guia_turismo/services/camera_service.dart';

class CameraController extends ChangeNotifier {
  final CameraService _service = CameraService();
  bool carregando = false;
  String? erro;
  File? _imagemSelecionada;
  File? get imagemSelecionada => _imagemSelecionada;

  Future<void> _selecionar(Future<File?> Function() escolher) async {
    if (carregando) return;
    carregando = true;
    erro = null;
    notifyListeners();
    try {
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

  Future<void> abrirGaleria() => _selecionar(_service.chamarGaleria);
  Future<void> abrirCamera() => _selecionar(_service.chamarCamera);
}
