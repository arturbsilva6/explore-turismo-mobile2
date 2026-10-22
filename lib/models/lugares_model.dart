class LugaresModel {
  final int id;
  final String nome;
  final String? categoria;
  final num latitude;
  final num longitude;
  final String? descricao;
  final int categoriaId;

  LugaresModel({
    required this.id,
    required this.nome,
    this.categoria,
    required this.latitude,
    required this.longitude,
    this.descricao,
    required this.categoriaId,
  });

  // Converte a resposta do GET /lugares em um objeto Dart.
  factory LugaresModel.fromJson(Map<String, dynamic> json) {
    final categoriaRecebida = json['categoria'];
    final String? nomeCategoria = categoriaRecebida is Map
        ? categoriaRecebida['nome']?.toString()
        : categoriaRecebida?.toString();

    return LugaresModel(
      id: (json['id'] as num).toInt(),
      nome: json['nome']?.toString() ?? '',
      latitude: _lerNumero(json['latitude']),
      longitude: _lerNumero(json['longitude']),
      descricao: json['descricao']?.toString(),
      categoria: nomeCategoria,
      categoriaId: (json['categoriaId'] as num).toInt(),
    );
  }

  static num _lerNumero(dynamic valor) {
    if (valor is num) return valor;
    if (valor is String) {
      final numero = num.tryParse(valor.replaceAll(',', '.'));
      if (numero != null) return numero;
    }
    throw FormatException('Coordenada inválida recebida da API: $valor');
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
      };
}
