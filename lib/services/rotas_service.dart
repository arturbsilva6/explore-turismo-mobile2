// PARA A APRESENTAÇÃO: este arquivo monta o link do Google Maps com as coordenadas do lugar.
// As explicações abaixo ajudam a entender os passos sem alterar o resultado.
import 'package:url_launcher/url_launcher.dart';

/// Abre o trajeto em um aplicativo de mapas instalado ou navegador.
class RotasService {
  // A função criarUriGoogleMaps monta um endereço para abrir a rota até o destino.
  static Uri criarUriGoogleMaps(double latitude, double longitude) {
    // Essa condição escolhe qual caminho o aplicativo seguirá.
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

  // A função comoChegar tenta abrir esse endereço no Google Maps ou navegador.
  Future<void> comoChegar(double latitude, double longitude) async {
    // Guarda o endereço ou a localização que será utilizada.
    final uri = criarUriGoogleMaps(latitude, longitude);
    // Evita abrir endereços ou coordenadas incorretos.
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o mapa de navegação.');
    }
  }
}
