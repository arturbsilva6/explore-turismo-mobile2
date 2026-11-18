import 'package:geolocator/geolocator.dart';

/// Solicita somente localização em primeiro plano, sob ação do usuário.
class LocalizacaoAtualService {
  Future<Position> obterPosicao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocalizacaoIndisponivel(
        'Ative a localização (GPS) do celular e tente novamente.',
      );
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw const LocalizacaoIndisponivel(
        'Permissão de localização negada. Autorize o acesso nas configurações.',
      );
    }
    if (permissao == LocationPermission.deniedForever) {
      throw const LocalizacaoIndisponivel(
        'Localização bloqueada permanentemente. Abra as permissões do aplicativo.',
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const LocalizacaoIndisponivel(
        'Não foi possível obter sua posição. Tente em uma área com sinal GPS.',
      );
    }
  }

  static double distanciaMetros(
    double latitudeOrigem, double longitudeOrigem,
    double latitudeDestino, double longitudeDestino,
  ) => Geolocator.distanceBetween(
    latitudeOrigem, longitudeOrigem, latitudeDestino, longitudeDestino,
  );
}

class LocalizacaoIndisponivel implements Exception {
  final String mensagem;
  const LocalizacaoIndisponivel(this.mensagem);
  @override
  String toString() => mensagem;
}
