/*
  Para permitir o app a acessar a camera tem que dar permissões, que estão em:
  android/app/src/main/AndroidManifest.xml - Linha 2

  Para mudar o texto das configurações de "Deseja permitir que o aplicativo acesse camera e bla bla"
  Se não me engano é importante para IOS:
  ios/Runner/info.plist - Linhas 70 a 73
*/

import 'package:flutter/material.dart';
import 'package:guia_turismo/controller/auth_controller.dart';
import 'package:guia_turismo/controller/camera_controller.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/controller/theme_controller.dart';
import 'package:guia_turismo/screens/camera_screen.dart';
import 'package:guia_turismo/screens/home_screen.dart';
import 'package:guia_turismo/screens/login_screen.dart';
import 'package:guia_turismo/screens/cadastro_lugar.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(Inicializar());
}

class Inicializar extends StatefulWidget {
  const Inicializar({super.key});

  @override
  State<Inicializar> createState() => _InicializarState();
}

class _InicializarState extends State<Inicializar> {
  @override
  Widget build(BuildContext context) {
    /* 
    (_) -> BuildContext
      Escuta as mudanças e "compartilha" o controller com o resto do código
    */
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => LugaresController()),
      ChangeNotifierProvider(create: (_) => AuthController()),
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => CameraController()),
    ],
    child: Consumer<ThemeController>(
        builder: (context, controllerThema, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: controllerThema.temaClaro(),
        darkTheme: controllerThema.temaEscuro(),
        themeMode: controllerThema.temaAtual,
        initialRoute: 'login',
        //Define as rotas e em quais classes devem ser chamadas
        routes: {
          'login': (context) => LoginScreen(),
          'home': (context) => HomeScreen(),
          'lugares': (context) => LugaresScreen(),
          'camera': (context) => CameraScreen()
        },
      ),
    ),
    );
  }
}