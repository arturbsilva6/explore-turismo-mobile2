// PARA A APRESENTAÇÃO: este serviço envia a foto de um lugar para a galeria cadastrada na API.
// Ele fica separado das telas para deixar o aplicativo mais organizado.
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:guia_turismo/services/session_service.dart';

/// Envio da foto para POST /lugares/{id}/galeria (multipart: campo foto).
class GaleriaService {
  GaleriaService({http.Client? client}) : this._interno(client);
  GaleriaService._interno(this._client);
  // Essa variável guarda um dado necessário para fazer a consulta.
  final http.Client? _client;

  // Esta função enviarFoto envia a imagem para a galeria de um lugar.
  Future<void> enviarFoto({
    required int lugarId,
    required String caminho,
    required String token,
  }) async {
    // Confere se a identificação da conta está correta antes de continuar.
    if (lugarId <= 0 || token.trim().isEmpty) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const FormatException('Lugar e autenticação são obrigatórios.');
    }
    // Guarda informações sobre a foto que será enviada.
    final arquivo = File(caminho);
    // Essa condição decide se a ação pode continuar.
    if (!await arquivo.exists()) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const FormatException('Foto não encontrada no dispositivo.');
    }
    // Guarda informações sobre a foto que será enviada.
    final tamanho = await arquivo.length();
    // Essa condição decide se a ação pode continuar.
    if (tamanho == 0 || tamanho > 8 * 1024 * 1024) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const FormatException('A foto deve ter até 8 MB.');
    }
    // Essa variável guarda um dado necessário para fazer a consulta.
    final nome = caminho.split(Platform.pathSeparator).last;
    // Essa variável guarda um dado necessário para fazer a consulta.
    final ext = nome.toLowerCase().split('.').last;
    // Essa condição decide se a ação pode continuar.
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const FormatException('Use imagem JPG, PNG ou WEBP.');
    }
    // Essa variável guarda um dado necessário para fazer a consulta.
    final tipo = ext == 'png' ? 'png' : ext == 'webp' ? 'webp' : 'jpeg';
    // Essa variável guarda um dado necessário para fazer a consulta.
    final requisicao = http.MultipartRequest(
      'POST',
      Uri.parse('https://guia.liliaborges.com.br/lugares/$lugarId/galeria'),
    );
    requisicao.headers['Authorization'] = 'Bearer $token';
    requisicao.files.add(await http.MultipartFile.fromPath(
      'foto', caminho, filename: nome, contentType: MediaType('image', tipo),
    ));
    // Guarda a resposta recebida para saber se a operação funcionou.
    final resposta = await (_client?.send(requisicao) ?? requisicao.send())
        .timeout(const Duration(seconds: 35));
    // Espera esta etapa terminar para não seguir antes da hora.
    await resposta.stream.drain<void>();
    // Confere o resultado que o servidor respondeu à solicitação.
    if (resposta.statusCode == 401 || resposta.statusCode == 403) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw const SessaoExpiradaException();
    }
    // Confere o resultado que o servidor respondeu à solicitação.
    if (resposta.statusCode != 201 && resposta.statusCode != 200) {
      // Se não for possível continuar, devolve um aviso para a tela tratar.
      throw Exception('Falha ao enviar foto (HTTP ${resposta.statusCode}).');
    }
  }
}
