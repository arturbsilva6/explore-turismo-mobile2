// PARA A APRESENTAÇÃO: este arquivo representa um endereço e as coordenadas de um lugar.
// Os comentários são explicações simples; as regras do código continuam iguais.
// A classe Coordenadas junta as informações e funções deste assunto em um só lugar.
class Coordenadas {
  // Guarda um dado de posição no mapa.
  final double latitude;
  // Guarda um dado de posição no mapa.
  final double longitude;

  const Coordenadas(this.latitude, this.longitude);

  // Esse getter permite consultar validas sem alterar a informação guardada.
  bool get validas =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  // A função ler realiza os passos desta parte do aplicativo.
  static double? ler(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  // A função validar realiza os passos desta parte do aplicativo.
  static String? validar(String? texto, double minimo, double maximo) {
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
    final numero = ler(texto ?? '');
    // Confere se há algum dado faltando ou inválido.
    if (numero == null || !numero.isFinite) return 'Informe um número válido';
    // Esse teste decide se o próximo passo deve acontecer.
    if (numero < minimo || numero > maximo) {
      return 'O valor deve estar entre $minimo e $maximo';
    }
    // Devolve o resultado dessa conferência para quem chamou a função.
    return null;
  }
}

// A classe LocalizacaoResultado junta as informações e funções deste assunto em um só lugar.
class LocalizacaoResultado {
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  final String endereco;
  // Guarda um dado de posição no mapa.
  final Coordenadas coordenadas;

  const LocalizacaoResultado({
    required this.endereco,
    required this.coordenadas,
  });

  factory LocalizacaoResultado.fromJson(Map<String, dynamic> json) {
    // Guarda um dado de posição no mapa.
    final latitude = Coordenadas.ler('${json['lat']}');
    // Guarda um dado de posição no mapa.
    final longitude = Coordenadas.ler('${json['lon']}');
    // Guarda um dado de posição no mapa.
    final coordenadas = Coordenadas(
      latitude ?? double.nan,
      longitude ?? double.nan,
    );
    // Confere se há algum dado faltando ou inválido.
    if (!coordenadas.validas) {
      throw const FormatException(
        'Coordenadas inválidas na resposta da busca.',
      );
    }
    return LocalizacaoResultado(
      endereco: json['display_name']?.toString() ?? 'Localização encontrada',
      coordenadas: coordenadas,
    );
  }

  // A função toJson organiza as informações para serem usadas em outro lugar.
  Map<String, dynamic> toJson() => {
    'display_name': endereco,
    'lat': coordenadas.latitude,
    'lon': coordenadas.longitude,
  };
}
