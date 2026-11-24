// PARA A APRESENTAÇÃO: este arquivo leva a pessoa para o login quando a sessão não pode mais ser usada.
// As explicações abaixo ajudam a entender os passos sem alterar o resultado.
import 'package:flutter/material.dart';

/// Navegação controlada quando uma sessão da API expira fora da camada de UI.
class NavegacaoService {
  // Guarda uma informação que será usada nesta parte.
  static final navigatorKey = GlobalKey<NavigatorState>();

  // A função irParaLogin abre a tela de login e tira as telas da sessão antiga.
  static void irParaLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('login', (_) => false);
    });
  }
}
