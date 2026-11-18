class LugaresModel {
  final int id;
  final String nome;
  final String? categoria;
  final num latitude;
  final num longitude;
  final String? descricao;
  final int categoriaId;
  final String? fotoUrl;

  bool get coordenadasValidas =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  LugaresModel({
    required this.id,
    required this.nome,
    this.categoria,
    required this.latitude,
    required this.longitude,
    this.descricao,
    required this.categoriaId,
    this.fotoUrl,
  });

  // Converte a resposta do GET /lugares em um objeto Dart.
  factory LugaresModel.fromJson(Map<String, dynamic> json) {
    final categoriaRecebida = json['categoria'];
    final String? nomeCategoria = categoriaRecebida is Map
        ? categoriaRecebida['nome']?.toString()
        : categoriaRecebida?.toString();

    return LugaresModel(
      id: _lerIdentificador(json['id']),
      nome: json['nome']?.toString() ?? '',
      latitude: _lerNumero(json['latitude']),
      longitude: _lerNumero(json['longitude']),
      descricao: json['descricao']?.toString(),
      categoria: nomeCategoria,
      categoriaId: _lerIdentificador(json['categoriaId'] ?? json['categoria_id']),
      fotoUrl: extrairFotoUrl(json),
    );
  }

  static String? extrairFotoUrl(Map<String, dynamic> json) {
    final diretos = [
      json['fotoUrl'], json['foto_url'], json['imagem'],
      json['foto'], json['urlImagem'], json['capa'],
    ];
    for (final valor in diretos) {
      final foto = _normalizarFoto(valor);
      if (foto != null) return foto;
    }
    var galeria = json['galeria'] ?? json['fotos'];
    if (galeria is Map) {
      galeria = galeria['data'] ?? galeria['fotos'] ?? galeria['itens'];
    }
    if (galeria is List) {
      for (final item in galeria) {
        final foto = _normalizarFoto(item);
        if (foto != null) return foto;
      }
    }
    return _normalizarFoto(galeria);
  }

  static String? _normalizarFoto(Object? valor) {
    if (valor is Map) {
      valor = valor['urlFoto'] ?? valor['url'] ?? valor['caminho'] ??
          valor['foto'] ?? valor['imagem'];
    }
    if (valor is! String || valor.trim().isEmpty) return null;
    final uri = Uri.tryParse(valor.trim());
    if (uri == null) return null;
    if (uri.scheme == 'https' && uri.host.isNotEmpty) return uri.toString();
    // URLs HTTP e esquemas que não são de imagem HTTPS não são aceitos.
    if (uri.hasScheme || uri.hasAuthority || uri.path.isEmpty) return null;
    if (uri.pathSegments.any((segmento) => segmento == '..' || segmento == '.')) {
      return null;
    }
    final caminho = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    return Uri.https(
      'guia.liliaborges.com.br', caminho,
      uri.hasQuery ? uri.queryParameters : null,
    ).toString();
  }

  static int _lerIdentificador(dynamic valor) {
    if (valor is! num ||
        !valor.isFinite ||
        valor < 0 ||
        valor != valor.toInt()) {
      throw const FormatException(
        'Identificador inválido na resposta de lugares.',
      );
    }
    return valor.toInt();
  }

  static num _lerNumero(dynamic valor) {
    if (valor is num) return valor;
    if (valor is String) {
      final numero = num.tryParse(valor.replaceAll(',', '.'));
      if (numero != null) return numero;
    }
    // Mantém o lugar na listagem; o mapa ignora coordenadas ausentes/inválidas.
    return double.nan;
  }

  // O POST /lugares exige apenas estes cinco campos no corpo da requisição.
  // id e categoria são definidos/retornados pelo servidor e não devem ser enviados.
  Map<String, dynamic> toCadastroJson() => {
    'nome': nome,
    'descricao': descricao ?? '',
    'latitude': latitude,
    'longitude': longitude,
    'categoriaId': categoriaId,
  };

  // Representação completa para uso local.
  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'latitude': latitude,
    'longitude': longitude,
    'categoria': categoria,
    'descricao': descricao,
    'categoriaId': categoriaId,
    'fotoUrl': fotoUrl,
  };
}
