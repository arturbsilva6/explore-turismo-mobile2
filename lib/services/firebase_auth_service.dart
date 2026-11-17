import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Demonstra autenticação Firebase sem substituir o JWT da API da faculdade.
/// O token Firebase NÃO autoriza POST /lugares na API atual.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  static Future<void>? _googleInicializado;

  Stream<User?> get mudancasDeUsuario => _auth.authStateChanges();

  User? get usuarioAtual => _auth.currentUser;

  Future<UserCredential> entrarComEmail(String email, String senha) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<UserCredential> criarContaComEmail(String email, String senha) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<UserCredential> entrarComGoogle() async {
    // google_sign_in 7.x: initialize + authenticate (não usar signIn() antigo).
    final google = GoogleSignIn.instance;
    _googleInicializado ??= google.initialize();
    await _googleInicializado;
    final conta = await google.authenticate();
    final idToken = conta.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'O Google não retornou um ID token. Verifique SHA-1/SHA-256 '
        'e a configuração OAuth no Firebase.',
      );
    }
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> sair() async {
    await _auth.signOut();
    // A sessão Google é independente. Um usuário de e-mail pode não tê-la.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // O logout do Firebase já foi realizado.
    }
  }

  static String mensagemDoErro(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'invalid-email':
          return 'Confira o formato do e-mail.';
        case 'weak-password':
          return 'Escolha uma senha mais forte.';
        case 'email-already-in-use':
          return 'Esse e-mail já está cadastrado no Firebase.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'E-mail ou senha inválidos.';
        case 'operation-not-allowed':
          return 'Ative o método de login no Firebase Console.';
        case 'network-request-failed':
          return 'Sem conexão com o Firebase. Verifique a internet.';
        default:
          return 'Não foi possível autenticar no Firebase (${erro.code}).';
      }
    }
    return 'Não foi possível concluir a autenticação. Confira a configuração do Firebase.';
  }
}
