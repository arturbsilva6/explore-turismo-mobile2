// PARA A APRESENTAÇÃO: este arquivo exibe a foto do lugar ou um desenho quando não há foto disponível.
// As explicações abaixo ajudam a entender os passos sem alterar o resultado.
import 'package:flutter/material.dart';

/// Exibe foto real enviada pela API, com fallback neutro quando indisponível.
class LugarFoto extends StatelessWidget {
  const LugarFoto({super.key, required this.url, this.tamanho = 52});
  // Guarda o endereço ou a localização que será utilizada.
  final String? url;
  // Guarda uma informação que será usada nesta parte.
  final double tamanho;

  @override
  // A função build monta a parte visual que será mostrada.
  Widget build(BuildContext context) {
    // Guarda uma cor para o visual do aplicativo.
    final cores = Theme.of(context).colorScheme;
    // Guarda o endereço ou a localização que será utilizada.
    final uri = url == null ? null : Uri.tryParse(url!);
    // Guarda o endereço ou a localização que será utilizada.
    final valido = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    // Entrega a informação ou o componente que será usado depois.
    return SizedBox(
      height: tamanho,
      width: tamanho,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: valido
            // Este componente mostra informação ou permite que a pessoa faça uma escolha.
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: (tamanho * MediaQuery.devicePixelRatioOf(context)).ceil(),
                cacheHeight: (tamanho * MediaQuery.devicePixelRatioOf(context)).ceil(),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : ColoredBox(
                        color: cores.primaryContainer,
                        child: const Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                errorBuilder: (_, _, _) => _semImagem(cores),
              )
            : _semImagem(cores),
      ),
    );
  }

  // A função _semImagem mostra um ícone quando não é possível usar uma foto.
  Widget _semImagem(ColorScheme cores) => ColoredBox(
        color: cores.primaryContainer,
        child: Icon(Icons.landscape_outlined, color: cores.primary),
      );
}
