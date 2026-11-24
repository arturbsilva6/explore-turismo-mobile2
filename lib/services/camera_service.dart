// PARA A APRESENTAÇÃO: este serviço pede ao celular uma foto da câmera ou da galeria.
// Ele fica separado das telas para deixar o aplicativo mais organizado.
//image_piker -> Pega a camera e a galeria
//Dart:Io -> Permite trabalhar com arquivos dentro do dart (arquivo foto vira caminho da foto)
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Esta classe CameraService reúne o que precisamos para usar este serviço.
class CameraService {
  // Essa variável guarda um dado necessário para fazer a consulta.
  final ImagePicker _image = ImagePicker();

  //Abrir galeria
  Future <File?> chamarGaleria() async {
    // Guarda informações sobre a foto que será enviada.
    final XFile? imagem = await _image.pickImage(source: ImageSource.gallery);
    //Fecha a galeria
    if (imagem == null) return null;
    return File(imagem.path);
  }
  //Abrir Camera
  Future <File?> chamarCamera() async {
    // Guarda informações sobre a foto que será enviada.
    final XFile? imagem = await _image.pickImage(source: ImageSource.camera);
    //Fecha a camera
    if (imagem == null) return null;
    return File(imagem.path);
  }
}