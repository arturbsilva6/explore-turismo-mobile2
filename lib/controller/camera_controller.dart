import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guia_turismo/services/camera_service.dart';

class CameraController extends ChangeNotifier{
  final CameraService _service = CameraService();
  bool carregando = false;
  File? _imagemSelecionada;
  File? get imagemSelecionada => _imagemSelecionada;

  Future <void> abrirGaleria() async {
    carregando = true;
    notifyListeners();
    _imagemSelecionada = await _service.chamarGaleria();
    carregando = false;
    notifyListeners();
  }

  Future <void> abrirCamera() async{
    carregando = true;
    notifyListeners();
    _imagemSelecionada = await _service.chamarCamera();
    carregando = false;
    notifyListeners();
  }
}