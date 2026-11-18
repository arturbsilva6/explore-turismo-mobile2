// Configuração Android preparada a partir de android/app/google-services.json.
// NÃO foi gerada pelo FlutterFire CLI. Quando estiver em seu PC, rode
// flutterfire configure --platforms=android --project=explore-turismo
// para validar/regenerar o arquivo oficial, especialmente após cadastrar SHA-1.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase configurado apenas para Android. Rode flutterfire configure '
      'para adicionar outras plataformas.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwrUvGF4Uaj-kFSA7VX1a0eOWDosM52x4',
    appId: '1:823103324756:android:be06f37d38d379b1f063c1',
    messagingSenderId: '823103324756',
    projectId: 'explore-turismo',
    storageBucket: 'explore-turismo.firebasestorage.app',
  );
}
