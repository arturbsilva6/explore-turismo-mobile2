class Coordenadas {
  final double latitude;
  final double longitude;

  const Coordenadas(this.latitude, this.longitude);

  bool get validas =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  static double? ler(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  static String? validar(String? texto, double minimo, double maximo) {
    final numero = ler(texto ?? '');
    if (numero == null || !numero.isFinite) return 'Informe um número válido';
    if (numero < minimo || numero > maximo) {
      return 'O valor deve estar entre $minimo e $maximo';
    }
    return null;
  }
}

class LocalizacaoResultado {
  final String endereco;
  final Coordenadas coordenadas;

  const LocalizacaoResultado({
    required this.endereco,
    required this.coordenadas,
  });

  factory LocalizacaoResultado.fromJson(Map<String, dynamic> json) {
    final latitude = Coordenadas.ler('${json['lat']}');
    final longitude = Coordenadas.ler('${json['lon']}');
    final coordenadas = Coordenadas(
      latitude ?? double.nan,
      longitude ?? double.nan,
    );
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

  Map<String, dynamic> toJson() => {
    'display_name': endereco,
    'lat': coordenadas.latitude,
    'lon': coordenadas.longitude,
  };
}
