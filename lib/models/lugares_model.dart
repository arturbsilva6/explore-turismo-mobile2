// PARA A APRESENTAÇÃO: este arquivo representa cada destino e transforma os dados da API em informações para a tela.
// Os comentários são explicações simples; as regras do código continuam iguais.
// A classe LugaresModel junta as informações e funções deste assunto em um só lugar.
class LugaresModel {
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  final int id;
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  final String nome;
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  final String? categoria;
  // A API pode devolver coordenadas inteiras ou decimais.
  final num latitude;
  final num longitude;
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  final String? descricao;
  // Guarda um valor que será usado para decidir ou mostrar alguma informação.
  final int categoriaId;
  // Guarda uma referência da foto que queremos mostrar ou enviar.
  final String? fotoUrl;

  // Esse getter permite consultar coordenadasValidas sem alterar a informação guardada.
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
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
    final categoriaRecebida = json['categoria'];
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
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

  // A função extrairFotoUrl procura uma foto nas informações que a API enviou.
  static String? extrairFotoUrl(Map<String, dynamic> json) {
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
    final diretos = [
      json['fotoUrl'], json['foto_url'], json['imagem'],
      json['foto'], json['urlImagem'], json['capa'],
    ];
    for (final valor in diretos) {
      // Guarda uma referência da foto que queremos mostrar ou enviar.
      final foto = _normalizarFoto(valor);
      // Confere se há algum dado faltando ou inválido.
      if (foto != null) return foto;
    }
    // Guarda uma referência da foto que queremos mostrar ou enviar.
    var galeria = json['galeria'] ?? json['fotos'];
    // Esse teste decide se o próximo passo deve acontecer.
    if (galeria is Map) {
      galeria = galeria['data'] ?? galeria['fotos'] ?? galeria['itens'];
    }
    // Esse teste decide se o próximo passo deve acontecer.
    if (galeria is List) {
      for (final item in galeria) {
        // Guarda uma referência da foto que queremos mostrar ou enviar.
        final foto = _normalizarFoto(item);
        // Confere se há algum dado faltando ou inválido.
        if (foto != null) return foto;
      }
    }
    return _normalizarFoto(galeria);
  }

  // A função _normalizarFoto aceita links seguros e completa os caminhos das imagens.
  static String? _normalizarFoto(Object? valor) {
    // Esse teste decide se o próximo passo deve acontecer.
    if (valor is Map) {
      valor = valor['urlFoto'] ?? valor['url'] ?? valor['caminho'] ??
          valor['foto'] ?? valor['imagem'];
    }
    // Confere se há algum dado faltando ou inválido.
    if (valor is! String || valor.trim().isEmpty) return null;
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
    final uri = Uri.tryParse(valor.trim());
    // Confere se há algum dado faltando ou inválido.
    if (uri == null) return null;
    // Confere se há algum dado faltando ou inválido.
    if (uri.scheme == 'https' && uri.host.isNotEmpty) return uri.toString();
    // URLs HTTP e esquemas que não são de imagem HTTPS não são aceitos.
    if (uri.hasScheme || uri.hasAuthority || uri.path.isEmpty) return null;
    // Esse teste decide se o próximo passo deve acontecer.
    if (uri.pathSegments.any((segmento) => segmento == '..' || segmento == '.')) {
      // Devolve o resultado dessa conferência para quem chamou a função.
      return null;
    }
    // Guarda um valor que será usado para decidir ou mostrar alguma informação.
    final caminho = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    return Uri.https(
      'guia.liliaborges.com.br', caminho,
      uri.hasQuery ? uri.queryParameters : null,
    ).toString();
  }

  // A função _lerIdentificador realiza os passos desta parte do aplicativo.
  static int _lerIdentificador(dynamic valor) {
    // Esse teste decide se o próximo passo deve acontecer.
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

  // A função _lerNumero realiza os passos desta parte do aplicativo.
  static num _lerNumero(dynamic valor) {
    // Esse teste decide se o próximo passo deve acontecer.
    if (valor is num) return valor;
    // Esse teste decide se o próximo passo deve acontecer.
    if (valor is String) {
      // Guarda um valor que será usado para decidir ou mostrar alguma informação.
      final numero = num.tryParse(valor.replaceAll(',', '.'));
      // Confere se há algum dado faltando ou inválido.
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
