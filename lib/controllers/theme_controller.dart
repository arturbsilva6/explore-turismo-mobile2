// PARA A APRESENTAÇÃO: este arquivo escolhe entre o visual claro e o escuro.
// Os comentários são explicações simples; as regras do código continuam iguais.
import 'package:flutter/material.dart';
import 'package:guia_turismo/themes/themes_widget.dart';

// A classe ThemeController junta as informações e funções deste assunto em um só lugar.
class ThemeController extends ChangeNotifier {
  ThemeMode _temaAtual = ThemeMode.light;
  // Esse getter permite consultar temaAtual sem alterar a informação guardada.
  ThemeMode get temaAtual => _temaAtual;

  // Esse getter permite consultar iconeAtual sem alterar a informação guardada.
  IconData get iconeAtual =>
      _temaAtual == ThemeMode.light ? Icons.light_mode : Icons.dark_mode;

  // A função _mudarTema altera a aparência do aplicativo.
  static ThemeData _mudarTema(Brightness brilho) {
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
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

  // A função temaClaro altera a aparência do aplicativo.
  ThemeData temaClaro() => _mudarTema(Brightness.light);
  // A função temaEscuro altera a aparência do aplicativo.
  ThemeData temaEscuro() => _mudarTema(Brightness.dark);

  // A função alternarTema altera a aparência do aplicativo.
  void alternarTema() {
    _temaAtual = _temaAtual == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners(); //Avisa a tela que atualizou (tipo "eventListener" do JS)
  }
}
