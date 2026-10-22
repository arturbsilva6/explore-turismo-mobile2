import 'package:flutter/material.dart';
import 'package:guia_turismo/controller/camera_controller.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Consumer vai escutar/ler o controller da camera
      //DEIXANDO CLARO QUE A CAMERA AINDA NÃO SALVA AS FOTOS TIRADAS
      body: Consumer<CameraController>(
        builder: (context, controleCamera, _) => Column(
          //Tudo bagulho de design e layout
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    border: Border.all(width: 2),
                    borderRadius: BorderRadius.circular(16),
                    //chama o metodo exibirImagem que está logo a baixo
                    image: exibirImagem(controleCamera)
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => abrirModal(controleCamera, context),
                    icon: Icon(Icons.camera_alt_rounded)
                  ) 
                ),
              ],
            )  
          ],
        ),
        ),
    );
  }
}


DecorationImage exibirImagem(CameraController controleCamera){
  //Se não houver nenhuma imagem selecionada, ele aparece como o placeholder
  if (controleCamera.imagemSelecionada == null){
    return DecorationImage(image: NetworkImage('https://placehold.co/150x150.png', scale: 1.0));
  } else {
    //Se houver, ele carrega a imagem e faz ela caber no box
    return DecorationImage(image: FileImage(controleCamera.imagemSelecionada!),
    fit: BoxFit.cover
    );
  }
}

void abrirModal(CameraController controleCamera, context) {
  showBottomSheet(
    context: context, 
    builder: (context) => SafeArea(
      bottom: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          ListTile(
            title: Text("Camera"),
            leading: Icon(Icons.camera),
            onTap: (){
              controleCamera.abrirCamera();
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text("Galeria"),
            leading: Icon(Icons.photo_album),
            onTap: () {
              controleCamera.abrirGaleria();
              Navigator.pop(context);
            },
          )
        ],
      ),
      )
    );
}