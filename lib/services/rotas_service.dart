import 'package:url_launcher/url_launcher.dart';

/// Abre o trajeto em um aplicativo de mapas instalado ou navegador.
class RotasService {
  static Uri criarUriGoogleMaps(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite ||
        latitude < -90 || latitude > 90 ||
        longitude < -180 || longitude > 180) {
      throw const FormatException('Coordenadas inválidas para a rota.');
    }
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    });
  }

  Future<void> comoChegar(double latitude, double longitude) async {
    final uri = criarUriGoogleMaps(latitude, longitude);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o mapa de navegação.');
    }
  }
}
