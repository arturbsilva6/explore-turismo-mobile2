import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guia_turismo/services/firebase_auth_service.dart';

void main() {
  test('Erro de e-mail inválido tem mensagem clara', () {
    final erro = FirebaseAuthException(code: 'invalid-email');
    expect(
      FirebaseAuthService.mensagemDoErro(erro),
      contains('e-mail'),
    );
  });

  test('Credenciais inválidas não exibem detalhes internos', () {
    final erro = FirebaseAuthException(code: 'invalid-credential');
    expect(
      FirebaseAuthService.mensagemDoErro(erro),
      'E-mail ou senha inválidos.',
    );
  });

  test('Provedor desabilitado informa configuração pendente', () {
    final erro = FirebaseAuthException(code: 'operation-not-allowed');
    expect(
      FirebaseAuthService.mensagemDoErro(erro),
      contains('Firebase Console'),
    );
  });
}
