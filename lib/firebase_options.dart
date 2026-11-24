// PARA A APRESENTAÇÃO: este arquivo informa ao Firebase qual é o projeto do aplicativo no Android.
// Os comentários são explicações simples; as regras do código continuam iguais.
// Configuração Android do projeto Firebase explore-turismo.
// Validada com FlutterFire CLI; reconfigure ao alterar o projeto ou app Android.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

// A classe DefaultFirebaseOptions junta as informações e funções deste assunto em um só lugar.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Esse teste decide se o próximo passo deve acontecer.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase configurado apenas para Android. Rode flutterfire configure '
      'para adicionar outras plataformas.',
    );
  }

  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwrUvGF4Uaj-kFSA7VX1a0eOWDosM52x4',
    appId: '1:823103324756:android:be06f37d38d379b1f063c1',
    messagingSenderId: '823103324756',
    projectId: 'explore-turismo',
    storageBucket: 'explore-turismo.firebasestorage.app',
  );
}
