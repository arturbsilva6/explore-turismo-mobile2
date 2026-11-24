// PARA A APRESENTAÇÃO: estes testes verificam o envio de foto e o cálculo de distância por coordenadas.
// Usamos dados de exemplo para conferir o app sem mexer nos registros reais.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guia_turismo/services/galeria_service.dart';
import 'package:guia_turismo/services/localizacao_atual_service.dart';
import 'package:http/http.dart' as http;

// Esta classe ClienteGaleriaSimulado finge ser uma parte do aplicativo para testarmos sem depender da internet real.
class ClienteGaleriaSimulado extends http.BaseClient {
  // Guarda a resposta ou os dados de acesso simulados para este teste.
  final int status;
  // Aqui preparamos uma informação que será usada para verificar o comportamento.
  int chamadas = 0;
  ClienteGaleriaSimulado(this.status);

  @override
  // Esta função send prepara dados ou executa uma parte do teste.
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    chamadas++;
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(request.method, 'POST');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(request.url.path, '/lugares/71/galeria');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(request.headers['Authorization'], 'Bearer token-ficticio');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(request, isA<http.MultipartRequest>());
    // Aqui preparamos uma informação que será usada para verificar o comportamento.
    final multipart = request as http.MultipartRequest;
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(multipart.files.single.field, 'foto');
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(multipart.files.single.filename, endsWith('.jpg'));
    // Devolve uma resposta de mentira para ver como o app reage.
    return http.StreamedResponse(Stream<List<int>>.value([]), status);
  }
}

// Aqui começam os testes deste arquivo.
void main() {
  // Aqui preparamos uma informação que será usada para verificar o comportamento.
  late Directory pasta;
  // Aqui preparamos uma informação que será usada para verificar o comportamento.
  late File foto;

  // Prepara um ambiente limpo antes de cada teste.
  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('teste-galeria-');
    foto = File('${pasta.path}${Platform.pathSeparator}foto.jpg');
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await foto.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
  });

  // Limpa os recursos usados depois de cada teste.
  tearDown(() async {
    // O teste muda de resposta conforme o cenário que estamos simulando.
    if (await pasta.exists()) await pasta.delete(recursive: true);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('upload envia foto no campo multipart foto com JWT', () async {
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final client = ClienteGaleriaSimulado(201);
    // Aguarda a etapa do teste terminar antes de conferir o resultado.
    await GaleriaService(client: client).enviarFoto(
      lugarId: 71,
      caminho: foto.path,
      token: 'token-ficticio',
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(client.chamadas, 1);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('upload informa falhas da API e valida campos sem enviar', () async {
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final client = ClienteGaleriaSimulado(400);
    // Esse objeto imita o serviço que a tela usaria de verdade.
    final service = GaleriaService(client: client);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    await expectLater(
      service.enviarFoto(
        lugarId: 71, caminho: foto.path, token: 'token-ficticio',
      ),
      throwsException,
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(client.chamadas, 1);
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    await expectLater(
      service.enviarFoto(lugarId: 0, caminho: foto.path, token: ''),
      throwsFormatException,
    );
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(client.chamadas, 1);
  });

  // Este teste verifica se essa regra funciona do jeito esperado.
  test('distância é zero na mesma coordenada', () {
    // Compara o resultado encontrado com o resultado que deveria aparecer.
    expect(LocalizacaoAtualService.distanciaMetros(-23.5, -46.6, -23.5, -46.6),
        closeTo(0, 0.01));
  });
}
