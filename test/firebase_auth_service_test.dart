// PARA A APRESENTAÇÃO: estes testes verificam as mensagens mostradas quando o Firebase não consegue autenticar.
// Usamos dados de exemplo para conferir o app sem mexer nos registros reais.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guia_turismo/services/firebase_auth_service.dart';

// Aqui começam os testes deste arquivo.
void main() {
  // Este teste verifica se essa regra funciona do jeito esperado.
  test('Erro de e-mail inválido tem mensagem clara', () {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final erro = FirebaseAuthException(code: 'invalid-email');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      FirebaseAuthService.mensagemDoErro(erro),
      contains('e-mail'),
    );
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('Credenciais inválidas não exibem detalhes internos', () {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final erro = FirebaseAuthException(code: 'invalid-credential');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      FirebaseAuthService.mensagemDoErro(erro),
      'E-mail ou senha inválidos.',
    );
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('Provedor desabilitado informa configuração pendente', () {
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final erro = FirebaseAuthException(code: 'operation-not-allowed');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(
      FirebaseAuthService.mensagemDoErro(erro),
      contains('Firebase Console'),
    );
  });
}
