// PARA A APRESENTAÇÃO: este serviço pede permissão para consultar o GPS e calcula distâncias.
// Ele fica separado das telas para deixar o aplicativo mais organizado.
import 'package:geolocator/geolocator.dart';

/// Solicita somente localização em primeiro plano, sob ação do usuário.
class LocalizacaoAtualService {
  // Esta função obterPosicao consulta a posição atual depois de verificar as permissões.
  Future<Position> obterPosicao() async {
    // Confere se o celular permite consultar a localização.
    if (!await Geolocator.isLocationServiceEnabled()) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const LocalizacaoIndisponivel(
        'Ative a localização (GPS) do celular e tente novamente.',
      );
    }
    // Essa variável guarda um dado necessário para fazer a consulta.
    var permissao = await Geolocator.checkPermission();
    // Confere se o celular permite consultar a localização.
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    // Confere se o celular permite consultar a localização.
    if (permissao == LocationPermission.denied) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const LocalizacaoIndisponivel(
        'Permissão de localização negada. Autorize o acesso nas configurações.',
      );
    }
    // Confere se o celular permite consultar a localização.
    if (permissao == LocationPermission.deniedForever) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const LocalizacaoIndisponivel(
        'Localização bloqueada permanentemente. Abra as permissões do aplicativo.',
        exigeConfiguracoes: true,
      );
    }
    // Tentamos executar a solicitação, mesmo sabendo que pode haver erro de internet.
    try {
      // Aqui usamos um recurso pronto para conversar com o celular ou com o serviço de login.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const LocalizacaoIndisponivel(
        'Não foi possível obter sua posição. Tente em uma área com sinal GPS.',
      );
    }
  }

  // Esta função abrirConfiguracoes abre os ajustes do Android para alterar permissões.
  Future<bool> abrirConfiguracoes() => Geolocator.openAppSettings();

  // Esta função distanciaMetros calcula aproximadamente a distância entre dois pontos.
  static double distanciaMetros(
    double latitudeOrigem, double longitudeOrigem,
    double latitudeDestino, double longitudeDestino,
  ) => Geolocator.distanceBetween(
    latitudeOrigem, longitudeOrigem, latitudeDestino, longitudeDestino,
  );
}

// Esta classe LocalizacaoIndisponivel reúne o que precisamos para usar este serviço.
class LocalizacaoIndisponivel implements Exception {
  // Essa variável guarda um dado necessário para fazer a consulta.
  final String mensagem;
  // Essa variável guarda um dado necessário para fazer a consulta.
  final bool exigeConfiguracoes;
  const LocalizacaoIndisponivel(this.mensagem,
      {this.exigeConfiguracoes = false});
  @override
  // Esta função toString executa esta etapa da comunicação com outro serviço.
  String toString() => mensagem;
}
