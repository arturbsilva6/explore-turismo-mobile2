import 'package:flutter/material.dart';
import 'package:guia_turismo/controller/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/screens/detalhe_lugar_screen.dart';
import 'package:provider/provider.dart';

class LugaresScreen extends StatefulWidget {
  const LugaresScreen({super.key});

  @override
  State<LugaresScreen> createState() => _LugaresScreenState();
}

class _LugaresScreenState extends State<LugaresScreen> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  int _categoriaId = 1;

  // Busca e filtro são locais: não alteram o cadastro na API.
  final _buscaController = TextEditingController();
  String _termoBusca = '';
  int? _categoriaFiltro;

  // Mantém compatibilidade com entradas usando vírgula decimal.
  double? _lerCoordenada(String valor) =>
      double.tryParse(valor.trim().replaceAll(',', '.'));

  String? _validarCoordenada(String? texto, double minimo, double maximo) {
    final coordenada = _lerCoordenada(texto ?? '');
    if (coordenada == null || !coordenada.isFinite) {
      return 'Informe um número válido';
    }
    if (coordenada < minimo || coordenada > maximo) {
      return 'O valor deve estar entre $minimo e $maximo';
    }
    return null;
  }

  Future<void> abrirForm() async {
    _nomeController.clear();
    _descricaoController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _categoriaId = 1;

    final formulario = GlobalKey<FormState>();
    bool salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, atualizarDialog) => AlertDialog(
          title: const Text('Cadastro de Lugares'),
          content: SingleChildScrollView(
            child: Form(
              key: formulario,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (valor) => (valor == null || valor.trim().isEmpty)
                        ? 'Informe o nome do lugar'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _categoriaId,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Praias')),
                      DropdownMenuItem(value: 2, child: Text('Points')),
                      DropdownMenuItem(value: 3, child: Text('Ilhas')),
                      DropdownMenuItem(value: 4, child: Text('Gastronomia')),
                      DropdownMenuItem(value: 5, child: Text('Dicas')),
                    ],
                    onChanged: salvando
                        ? null
                        : (valor) {
                            if (valor != null) {
                              atualizarDialog(() => _categoriaId = valor);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    validator: (valor) => _validarCoordenada(valor, -90, 90),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    validator: (valor) => _validarCoordenada(valor, -180, 180),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: salvando ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formulario.currentState!.validate()) return;
                      atualizarDialog(() => salvando = true);

                      final lugar = LugaresModel(
                        id: 0, // O servidor atribui o ID no cadastro.
                        nome: _nomeController.text.trim(),
                        descricao: _descricaoController.text.trim(),
                        latitude: _lerCoordenada(_latitudeController.text)!,
                        longitude: _lerCoordenada(_longitudeController.text)!,
                        categoriaId: _categoriaId,
                      );
                      final controller = context.read<LugaresController>();
                      final mensagem = await controller.cadastrarLugar(lugar);
                      if (!mounted || !dialogContext.mounted) return;
                      atualizarDialog(() => salvando = false);

                      final sucesso = controller.erroCadastro.isEmpty;
                      if (sucesso) Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(mensagem)),
                      );
                    },
              child: salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LugaresController>(
        builder: (context, controller, _) {
          final termo = _termoBusca.trim().toLowerCase();
          final lugaresFiltrados = controller.lugares.where((lugar) {
            final combinaNome = lugar.nome.toLowerCase().contains(termo);
            final combinaCategoria =
                _categoriaFiltro == null || lugar.categoriaId == _categoriaFiltro;
            return combinaNome && combinaCategoria;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _buscaController,
                      onChanged: (texto) => setState(() => _termoBusca = texto),
                      decoration: InputDecoration(
                        labelText: 'Buscar lugar por nome',
                        hintText: 'Ex.: Praia Grande',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _termoBusca.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  _buscaController.clear();
                                  setState(() => _termoBusca = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.filter_list, size: 21),
                        const SizedBox(width: 8),
                        const Text('Categoria:'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<int?>(
                            isExpanded: true,
                            value: _categoriaFiltro,
                            items: const [
                              DropdownMenuItem<int?>(
                                value: null, child: Text('Todas'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 1, child: Text('Praias'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 2, child: Text('Points'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 3, child: Text('Ilhas'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 4, child: Text('Gastronomia'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 5, child: Text('Dicas'),
                              ),
                            ],
                            onChanged: (id) => setState(() => _categoriaFiltro = id),
                          ),
                        ),
                        IconButton(
                          onPressed: controller.carregando ? null : controller.listaLugares,
                          tooltip: 'Atualizar lista',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    Text(
                      '${lugaresFiltrados.length} de ${controller.lugares.length} '
                      'lugares carregados',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _conteudoLugares(controller, lugaresFiltrados),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirForm,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Novo lugar'),
      ),
    );
  }

  Widget _conteudoLugares(
    LugaresController controller,
    List<LugaresModel> lugaresFiltrados,
  ) {
    if (controller.carregando && controller.lugares.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.erro.isNotEmpty && controller.lugares.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 44),
              const SizedBox(height: 10),
              Text(controller.erro, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.listaLugares,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    // RefreshIndicator funciona mesmo quando a lista está vazia.
    return RefreshIndicator(
      onRefresh: controller.listaLugares,
      child: lugaresFiltrados.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 85),
                Icon(Icons.search_off_outlined,
                    size: 52, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  controller.lugares.isEmpty
                      ? 'Nenhum lugar cadastrado ainda.'
                      : 'Nenhum lugar corresponde aos filtros.',
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
              itemCount: lugaresFiltrados.length,
              itemBuilder: (context, index) {
                final lugar = lugaresFiltrados[index];
                final descricao = lugar.descricao?.trim() ?? '';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: const CircleAvatar(
                      child: Icon(Icons.location_on_outlined),
                    ),
                    title: Text(
                      lugar.nome,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(lugar.categoria ?? 'Sem categoria'),
                        if (descricao.isNotEmpty)
                          Text(
                            descricao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => DetalheLugarScreen(lugar: lugar),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
