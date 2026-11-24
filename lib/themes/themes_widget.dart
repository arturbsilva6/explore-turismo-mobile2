// PARA A APRESENTAÇÃO: este arquivo define as cores e o estilo visual claro e escuro do aplicativo.
// As explicações abaixo ajudam a entender os passos sem alterar o resultado.
import 'package:flutter/material.dart';

/*
  Essa pagina só existe para mudar especificamente
  as cores dos objetos do código como o bottomNavigation, AppBar, 
  FloatActionButton e etc
*/
// Esta função escolhe como fica a barra de cima das telas.
AppBarTheme defineAppBar(ColorScheme cor) {
  return AppBarTheme(
    // Deixa o título centralizado.
    centerTitle: true,
    // Usa a cor principal do tema no fundo da barra.
    backgroundColor: cor.primary,
    // Usa uma cor que facilita ler o título e enxergar os ícones.
    foregroundColor: cor.onPrimary, //cor de texto
    // Coloca uma sombra leve para destacar a barra.
    elevation: 4, //Box shadow
  );
}

// Esta função cuida das cores do menu de abas na parte de baixo.
BottomNavigationBarThemeData defineNavegacaoBase(ColorScheme cor) {
  return BottomNavigationBarThemeData(
    backgroundColor: cor.primary,
    // Destaca o ícone da aba que está selecionada.
    selectedItemColor: cor.onPrimary,
    //Não deixa os items "Não selecionados" ficarem apagados
    // As outras abas ficam um pouco mais suaves, mas continuam visíveis.
    unselectedItemColor: cor.onPrimary.withValues(alpha: 0.8),
    elevation: 4,
  );
}

// Este ajuste deixa os botões com aparência parecida em todas as telas.
ElevatedButtonThemeData defineBotaoElevated(ColorScheme cor) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // Essa é a cor de fundo que escolhemos para esse tipo de botão.
      backgroundColor: const Color.fromARGB(255, 199, 199, 199),
      elevation: 3,
    ),
  );
}
