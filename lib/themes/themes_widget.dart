import 'package:flutter/material.dart';

/*
  Essa pagina só existe para mudar especificamente
  as cores dos objetos do código como o bottomNavigation, AppBar, 
  FloatActionButton e etc
*/
AppBarTheme defineAppBar(ColorScheme cor) {
  return AppBarTheme(
    centerTitle: true,
    backgroundColor: cor.primary,
    foregroundColor: cor.onPrimary, //cor de texto
    elevation: 4, //Box shadow
  );
}

BottomNavigationBarThemeData defineNavegacaoBase(ColorScheme cor) {
  return BottomNavigationBarThemeData(
    backgroundColor: cor.primary,
    selectedItemColor: cor.onPrimary,
    //Não deixa os items "Não selecionados" ficarem apagados
    unselectedItemColor: cor.onPrimary.withValues(alpha: 0.8),
    elevation: 4,
  );
}

ElevatedButtonThemeData defineBotaoElevated(ColorScheme cor) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 199, 199, 199),
      elevation: 3,
    ),
  );
}
