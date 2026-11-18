/*
  Para permitir o app a acessar a camera tem que dar permissões, que estão em:
  android/app/src/main/AndroidManifest.xml - Linha 2

  Para mudar o texto das configurações de "Deseja permitir que o aplicativo acesse camera e bla bla"
  Se não me engano é importante para IOS:
  ios/Runner/info.plist - Linhas 70 a 73
*/

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guia_turismo/controller/favoritos_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guia_turismo/firebase_options.dart';
import 'package:guia_turismo/controller/auth_controller.dart';
import 'package:guia_turismo/controller/camera_controller.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/controller/theme_controller.dart';
import 'package:guia_turismo/screens/camera_screen.dart';
import 'package:guia_turismo/screens/home_screen.dart';
import 'package:guia_turismo/screens/login_screen.dart';
import 'package:guia_turismo/screens/cadastro_lugar.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:provider/provider.dart';

// No Android, Firebase está ativo por padrão; a API acadêmica é independente.
// A flag FIREBASE_ENABLED=false desativa Firebase em testes ou ambientes sem OAuth.
const bool firebaseHabilitado = bool.fromEnvironment(
  'FIREBASE_ENABLED',
  defaultValue: true,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (firebaseHabilitado && !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (erro) {
      debugPrint('Firebase indisponível: $erro');
      // API acadêmica permanece utilizável se Firebase falhar.
    }
  }
  // A sessão da API é independente da autenticação Firebase e também persiste.
  final sessaoApi = await SessionService().temSessaoApi();
  runApp(Inicializar(sessaoApiRestaurada: sessaoApi));
}

class Inicializar extends StatefulWidget {
  const Inicializar({super.key, this.sessaoApiRestaurada = false});

  final bool sessaoApiRestaurada;

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
      ChangeNotifierProvider(create: (_) => FavoritosController()..carregar()),
    ],
    child: Consumer<ThemeController>(
        builder: (context, controllerThema, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: controllerThema.temaClaro(),
        darkTheme: controllerThema.temaEscuro(),
        themeMode: controllerThema.temaAtual,
        initialRoute: widget.sessaoApiRestaurada ||
                (Firebase.apps.isNotEmpty &&
                    FirebaseAuth.instance.currentUser != null)
            ? 'home' : 'login',
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