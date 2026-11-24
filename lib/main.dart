// PARA A APRESENTAÇÃO: este arquivo inicia o aplicativo, configura os serviços e decide qual tela abrir.
// Os comentários são explicações simples; as regras do código continuam iguais.
// Permissões de câmera/localização: AndroidManifest.xml e ios/Runner/Info.plist.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guia_turismo/controllers/favoritos_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guia_turismo/firebase_options.dart';
import 'package:guia_turismo/controllers/auth_controller.dart';
import 'package:guia_turismo/controllers/camera_controller.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/controllers/theme_controller.dart';
import 'package:guia_turismo/screens/camera_screen.dart';
import 'package:guia_turismo/screens/home_screen.dart';
import 'package:guia_turismo/screens/login_screen.dart';
import 'package:guia_turismo/screens/cadastro_lugar.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:guia_turismo/services/navegacao_service.dart';
import 'package:provider/provider.dart';

// No Android, Firebase está ativo por padrão; a API acadêmica é independente.
// A flag FIREBASE_ENABLED=false desativa Firebase em testes ou ambientes sem OAuth.
// Essa opção permite ligar ou desligar o Firebase sem reescrever o aplicativo.
const bool firebaseHabilitado = bool.fromEnvironment(
  'FIREBASE_ENABLED',
  defaultValue: true,
);

// A função main inicia o aplicativo.
Future<void> main() async {
  // Prepara o Flutter antes de usar recursos do celular e do Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Verifica se o login permite continuar.
  // O Firebase é iniciado no Android; outras plataformas seguem usando a API acadêmica.
  if (firebaseHabilitado && !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    // Tentamos realizar a tarefa, pois serviços externos podem falhar.
    try {
      // Espera o Firebase responder.
      // Faz a conexão inicial com o Firebase usando os dados do projeto.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (erro) {
      debugPrint('Firebase indisponível: $erro');
      // API acadêmica permanece utilizável se Firebase falhar.
    }
  }
  // A sessão da API é independente da autenticação Firebase e também persiste.
  // Confere se a conta da API já tinha ficado conectada.
  final sessaoApi = await SessionService().temSessaoApi();
  // Com tudo preparado, abre a primeira tela do Explore Turismo.
  runApp(Inicializar(sessaoApiRestaurada: sessaoApi));
}

// A classe Inicializar junta as informações e funções deste assunto em um só lugar.
class Inicializar extends StatefulWidget {
  const Inicializar({super.key, this.sessaoApiRestaurada = false});

  // Guarda uma informação sobre a conta que está usando o app.
  final bool sessaoApiRestaurada;

  @override
  State<Inicializar> createState() => _InicializarState();
}

// A classe _InicializarState junta as informações e funções deste assunto em um só lugar.
class _InicializarState extends State<Inicializar> {
  @override
  // A função build organiza o que aparece na tela.
  Widget build(BuildContext context) {
    /*
    (_) -> BuildContext
      Escuta as mudanças e "compartilha" o controller com o resto do código
    */
    // Compartilha os controladores para várias telas usarem os mesmos dados.
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
        navigatorKey: NavegacaoService.navigatorKey,
        theme: controllerThema.temaClaro(),
        darkTheme: controllerThema.temaEscuro(),
        themeMode: controllerThema.temaAtual,
        // Se já houver login válido salvo, o aplicativo pode começar na Home.
        initialRoute: widget.sessaoApiRestaurada ||
                (Firebase.apps.isNotEmpty &&
                    FirebaseAuth.instance.currentUser != null)
            ? 'home' : 'login',
        //Define as rotas e em quais classes devem ser chamadas
        // Esses nomes servem para abrir a tela de login, início, lugares e câmera.
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