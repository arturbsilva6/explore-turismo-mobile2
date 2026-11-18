import 'package:flutter/material.dart';

/// Exibe foto real enviada pela API, com fallback neutro quando indisponível.
class LugarFoto extends StatelessWidget {
  const LugarFoto({super.key, required this.url, this.tamanho = 52});
  final String? url;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final uri = url == null ? null : Uri.tryParse(url!);
    final valido = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    return SizedBox(
      height: tamanho,
      width: tamanho,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: valido
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _semImagem(cores),
              )
            : _semImagem(cores),
      ),
    );
  }

  Widget _semImagem(ColorScheme cores) => ColoredBox(
        color: cores.primaryContainer,
        child: Icon(Icons.landscape_outlined, color: cores.primary),
      );
}
