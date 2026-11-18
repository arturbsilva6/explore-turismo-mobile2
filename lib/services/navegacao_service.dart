import 'package:flutter/material.dart';

/// Navegação controlada quando uma sessão da API expira fora da camada de UI.
class NavegacaoService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void irParaLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('login', (_) => false);
    });
  }
}
