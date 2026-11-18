import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guia_turismo/services/galeria_service.dart';
import 'package:guia_turismo/services/localizacao_atual_service.dart';
import 'package:http/http.dart' as http;

class ClienteGaleriaSimulado extends http.BaseClient {
  final int status;
  int chamadas = 0;
  ClienteGaleriaSimulado(this.status);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    chamadas++;
    expect(request.method, 'POST');
    expect(request.url.path, '/lugares/71/galeria');
    expect(request.headers['Authorization'], 'Bearer token-ficticio');
    expect(request, isA<http.MultipartRequest>());
    final multipart = request as http.MultipartRequest;
    expect(multipart.files.single.field, 'foto');
    expect(multipart.files.single.filename, endsWith('.jpg'));
    return http.StreamedResponse(Stream<List<int>>.value([]), status);
  }
}

void main() {
  late Directory pasta;
  late File foto;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('teste-galeria-');
    foto = File('${pasta.path}${Platform.pathSeparator}foto.jpg');
    await foto.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
  });

  tearDown(() async {
    if (await pasta.exists()) await pasta.delete(recursive: true);
  });

  test('upload envia foto no campo multipart foto com JWT', () async {
    final client = ClienteGaleriaSimulado(201);
    await GaleriaService(client: client).enviarFoto(
      lugarId: 71,
      caminho: foto.path,
      token: 'token-ficticio',
    );
    expect(client.chamadas, 1);
  });

  test('upload informa falhas da API e valida campos sem enviar', () async {
    final client = ClienteGaleriaSimulado(400);
    final service = GaleriaService(client: client);
    await expectLater(
      service.enviarFoto(
        lugarId: 71, caminho: foto.path, token: 'token-ficticio',
      ),
      throwsException,
    );
    expect(client.chamadas, 1);
    await expectLater(
      service.enviarFoto(lugarId: 0, caminho: foto.path, token: ''),
      throwsFormatException,
    );
    expect(client.chamadas, 1);
  });

  test('distância é zero na mesma coordenada', () {
    expect(LocalizacaoAtualService.distanciaMetros(-23.5, -46.6, -23.5, -46.6),
        closeTo(0, 0.01));
  });
}
