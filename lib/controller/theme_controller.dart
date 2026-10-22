import 'package:flutter/material.dart';
import 'package:guia_turismo/themes/themes_widget.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _temaAtual = ThemeMode.light;
  ThemeMode get temaAtual => _temaAtual;

  IconData get iconeAtual =>
      _temaAtual == ThemeMode.light ? Icons.light_mode : Icons.dark_mode;

  static ThemeData _mudarTema(Brightness brilho) {
    final cor = ColorScheme.fromSeed(
      seedColor: const Color(0xFF087F72),
      brightness: brilho,
    );
    return ThemeData(
      //primarySwatch: Colors.cyan,
      useMaterial3: true,
      colorScheme: cor,
      appBarTheme: defineAppBar(cor),
      bottomNavigationBarTheme: defineNavegacaoBase(cor),
      //Fazer desses 3 abaixo dps - Barbara faz <------
      elevatedButtonTheme: defineBotaoElevated(cor),
      iconButtonTheme: IconButtonThemeData(),
      cardTheme: CardThemeData(),
    );
  }

  ThemeData temaClaro() => _mudarTema(Brightness.light);
  ThemeData temaEscuro() => _mudarTema(Brightness.dark);

  void alternarTema() {
    _temaAtual = _temaAtual == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners(); //Avisa a tela que atualizou (tipo "eventListener" do JS)
  }
}
