import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Envio da foto para POST /lugares/{id}/galeria (multipart: campo foto).
class GaleriaService {
  GaleriaService({http.Client? client}) : _client = client;
  final http.Client? _client;

  Future<void> enviarFoto({
    required int lugarId,
    required String caminho,
    required String token,
  }) async {
    if (lugarId <= 0 || token.trim().isEmpty) {
      throw const FormatException('Lugar e autenticação são obrigatórios.');
    }
    final arquivo = File(caminho);
    if (!await arquivo.exists()) {
      throw const FormatException('Foto não encontrada no dispositivo.');
    }
    final tamanho = await arquivo.length();
    if (tamanho == 0 || tamanho > 8 * 1024 * 1024) {
      throw const FormatException('A foto deve ter até 8 MB.');
    }
    final nome = caminho.split(Platform.pathSeparator).last;
    final ext = nome.toLowerCase().split('.').last;
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      throw const FormatException('Use imagem JPG, PNG ou WEBP.');
    }
    final tipo = ext == 'png' ? 'png' : ext == 'webp' ? 'webp' : 'jpeg';
    final requisicao = http.MultipartRequest(
      'POST',
      Uri.parse('https://guia.liliaborges.com.br/lugares/$lugarId/galeria'),
    );
    requisicao.headers['Authorization'] = 'Bearer $token';
    requisicao.files.add(await http.MultipartFile.fromPath(
      'foto', caminho, filename: nome, contentType: MediaType('image', tipo),
    ));
    final resposta = await (_client?.send(requisicao) ?? requisicao.send())
        .timeout(const Duration(seconds: 35));
    await resposta.stream.drain<void>();
    if (resposta.statusCode != 201 && resposta.statusCode != 200) {
      throw Exception('Falha ao enviar foto (HTTP ${resposta.statusCode}).');
    }
  }
}
