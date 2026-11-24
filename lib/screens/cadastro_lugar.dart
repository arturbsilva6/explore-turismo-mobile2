// PARA A APRESENTAÇÃO: este arquivo mostra os lugares e permite cadastrar um novo com nome, categoria, posição e foto.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:guia_turismo/controllers/favoritos_controller.dart';
import 'package:guia_turismo/widgets/lugar_foto.dart';
import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/screens/detalhe_lugar_screen.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/models/localizacao_model.dart';
import 'package:guia_turismo/widgets/busca_localizacao.dart';
import 'package:guia_turismo/services/geocodificacao_service.dart';
import 'package:guia_turismo/services/session_service.dart';

// Esta classe LugaresScreen reúne tudo que essa tela precisa para funcionar.
class LugaresScreen extends StatefulWidget {
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final GeocodificacaoService? geocodificacaoService;
  // Essa variável guarda uma informação usada mais adiante.
  final Widget Function(LocalizacaoResultado)? construirMapa;
  const LugaresScreen({
    super.key,
    this.geocodificacaoService,
    this.construirMapa,
  });

  @override
  State<LugaresScreen> createState() => _LugaresScreenState();
}

// Esta classe _LugaresScreenState reúne tudo que essa tela precisa para funcionar.
class _LugaresScreenState extends State<LugaresScreen> {
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final _nomeController = TextEditingController();
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final _descricaoController = TextEditingController();
  // Guarda a localização que será usada no mapa.
  final _latitudeController = TextEditingController();
  // Guarda a localização que será usada no mapa.
  final _longitudeController = TextEditingController();
  // Lembra a escolha feita na tela, como categoria, busca ou aba.
  int _categoriaId = 1;
  File? _fotoCadastro;
  // Essa variável guarda uma informação usada mais adiante.
  bool _somenteFavoritos = false;

  // Busca e filtro são locais: não alteram o cadastro na API.
  final _buscaController = TextEditingController();
  // Lembra a escolha feita na tela, como categoria, busca ou aba.
  String _termoBusca = '';
  int? _categoriaFiltro;

  // Mantém compatibilidade com entradas usando vírgula decimal.
  double? _lerCoordenada(String valor) => Coordenadas.ler(valor);

  // A função _validarCoordenada confere os valores de latitude e longitude.
  String? _validarCoordenada(String? texto, double minimo, double maximo) {
    return Coordenadas.validar(texto, minimo, maximo);
  }

  // A função _abrirCadastroAutorizado confere se a conta pode cadastrar.
  Future<void> _abrirCadastroAutorizado() async {
    // Ajuda a tela a usar os dados ou verificar o formulário.
    final token = await SessionService().pegarToken();
    // Só mexe na tela se ela ainda estiver aberta.
    if (!mounted) return;
    // Confere se faltam informações ou se há algum erro.
    if (token == null || token.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        // Este texto aparece na tela para orientar quem está usando o app.
        content: Text('Para cadastrar um lugar, entre com uma conta da API da disciplina.'),
      ));
      return;
    }
    // Espera essa tarefa terminar para seguir para a próxima etapa.
    await abrirForm();
  }

  // A função abrirForm abre o cadastro de um lugar.
  Future<void> abrirForm() async {
    _nomeController.clear();
    _descricaoController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _categoriaId = 1;
    _fotoCadastro = null;

    // Ajuda a tela a usar os dados ou verificar o formulário.
    final formulario = GlobalKey<FormState>();
    // Indica se a tarefa ainda está acontecendo, para mostrar o carregamento.
    bool salvando = false;

    // Espera essa tarefa terminar para seguir para a próxima etapa.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, atualizarDialog) => AlertDialog(
          // Este texto aparece na tela para orientar quem está usando o app.
          title: const Text('Cadastro de Lugares'),
          content: SingleChildScrollView(
            child: Form(
              key: formulario,
              // Organiza os elementos na tela para que fiquem na ordem certa.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.sentences,
                    // Este texto aparece na tela para orientar quem está usando o app.
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (valor) =>
                        (valor == null || valor.trim().isEmpty)
                        ? 'Informe o nome do lugar'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                  TextFormField(
                    controller: _descricaoController,
                    // Este texto aparece na tela para orientar quem está usando o app.
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _categoriaId,
                    // Este texto aparece na tela para orientar quem está usando o app.
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      // Este texto aparece na tela para orientar quem está usando o app.
                      DropdownMenuItem(value: 1, child: Text('Praias')),
                      // Este texto aparece na tela para orientar quem está usando o app.
                      DropdownMenuItem(value: 2, child: Text('Points')),
                      // Este texto aparece na tela para orientar quem está usando o app.
                      DropdownMenuItem(value: 3, child: Text('Ilhas')),
                      // Este texto aparece na tela para orientar quem está usando o app.
                      DropdownMenuItem(value: 4, child: Text('Gastronomia')),
                      // Este texto aparece na tela para orientar quem está usando o app.
                      DropdownMenuItem(value: 5, child: Text('Dicas')),
                    ],
                    // Atualiza a tela quando a pessoa muda essa opção.
                    onChanged: salvando
                        ? null
                        : (valor) {
                            // Confere se faltam informações ou se há algum erro.
                            if (valor != null) {
                              atualizarDialog(() => _categoriaId = valor);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  // Este texto aparece na tela para orientar quem está usando o app.
                  const Text('Fotografia do lugar (opcional)'),
                  const SizedBox(height: 8),
                  // Confere se faltam informações ou se há algum erro.
                  if (_fotoCadastro != null)
                    SizedBox(
                      height: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _fotoCadastro!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              // Este texto aparece na tela para orientar quem está usando o app.
                              const Center(child: Text('Foto indisponível')),
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                        onPressed: salvando ? null : () async {
                          // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
                          try {
                            // Essa variável guarda uma informação usada mais adiante.
                            final selecionada = await ImagePicker().pickImage(
                              source: ImageSource.camera,
                              imageQuality: 75,
                              maxWidth: 1600,
                            );
                            // Só mexe na tela se ela ainda estiver aberta.
                            if (selecionada != null && dialogContext.mounted) {
                              atualizarDialog(() => _fotoCadastro = File(selecionada.path));
                            }
                          } catch (_) {
                            // Só mexe na tela se ela ainda estiver aberta.
                            if (mounted && dialogContext.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                // Este texto aparece na tela para orientar quem está usando o app.
                                const SnackBar(content: Text('Não foi possível abrir a câmera.')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        // Este texto aparece na tela para orientar quem está usando o app.
                        label: const Text('Câmera'),
                      ),
                      OutlinedButton.icon(
                        // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                        onPressed: salvando ? null : () async {
                          // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
                          try {
                            // Essa variável guarda uma informação usada mais adiante.
                            final selecionada = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 75,
                              maxWidth: 1600,
                            );
                            // Só mexe na tela se ela ainda estiver aberta.
                            if (selecionada != null && dialogContext.mounted) {
                              atualizarDialog(() => _fotoCadastro = File(selecionada.path));
                            }
                          } catch (_) {
                            // Só mexe na tela se ela ainda estiver aberta.
                            if (mounted && dialogContext.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                // Este texto aparece na tela para orientar quem está usando o app.
                                const SnackBar(content: Text('Não foi possível abrir a galeria.')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        // Este texto aparece na tela para orientar quem está usando o app.
                        label: const Text('Galeria'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BuscaLocalizacao(
                    enabled: !salvando,
                    service: widget.geocodificacaoService,
                    construirMapa: widget.construirMapa,
                    onConfirmar: (ponto) {
                      _latitudeController.text = ponto.latitude.toString();
                      _longitudeController.text = ponto.longitude.toString();
                    },
                  ),
                  // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                  TextFormField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    validator: (valor) => _validarCoordenada(valor, -90, 90),
                  ),
                  const SizedBox(height: 12),
                  // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                  TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    // Este texto aparece na tela para orientar quem está usando o app.
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    validator: (valor) => _validarCoordenada(valor, -180, 180),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
              onPressed: salvando ? null : () => Navigator.pop(dialogContext),
              // Este texto aparece na tela para orientar quem está usando o app.
              child: const Text('Cancelar'),
            ),
            // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
            FilledButton(
              // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
              onPressed: salvando
                  ? null
                  : () async {
                      // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
                      if (!formulario.currentState!.validate()) return;
                      atualizarDialog(() => salvando = true);

                      // Essa variável guarda uma informação usada mais adiante.
                      final lugar = LugaresModel(
                        id: 0, // O servidor atribui o ID no cadastro.
                        nome: _nomeController.text.trim(),
                        descricao: _descricaoController.text.trim(),
                        latitude: _lerCoordenada(_latitudeController.text)!,
                        longitude: _lerCoordenada(_longitudeController.text)!,
                        categoriaId: _categoriaId,
                      );
                      // Ajuda a tela a usar os dados ou verificar o formulário.
                      final controller = context.read<LugaresController>();
                      // Guarda a foto escolhida ou o caminho dela.
                      final mensagem = await controller.cadastrarLugarComFoto(lugar, _fotoCadastro);
                      // Só mexe na tela se ela ainda estiver aberta.
                      if (!mounted || !dialogContext.mounted) return;
                      atualizarDialog(() => salvando = false);

                      // Guarda o aviso que será exibido quando algo não funcionar.
                      final sucesso = controller.erroCadastro.isEmpty;
                      // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
                      if (sucesso) Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(mensagem)));
                    },
              child: salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  // Este texto aparece na tela para orientar quem está usando o app.
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  // A função dispose libera os recursos quando a tela fecha.
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Aqui é montada a estrutura principal desta tela.
    return Scaffold(
      body: Consumer<LugaresController>(
        builder: (context, controller, _) {
          FavoritosController? favoritos;
          // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
          try {
            favoritos = context.watch<FavoritosController>();
          } on ProviderNotFoundException {
            // Compatibilidade com telas e testes legados sem este provider.
          }
          // Lembra a escolha feita na tela, como categoria, busca ou aba.
          final termo = _termoBusca.trim().toLowerCase();
          // Ajuda a tela a usar os dados ou verificar o formulário.
          final lugaresFiltrados = controller.lugares.where((lugar) {
            // Lembra a escolha feita na tela, como categoria, busca ou aba.
            final combinaNome = lugar.nome.toLowerCase().contains(termo);
            // Lembra a escolha feita na tela, como categoria, busca ou aba.
            final combinaCategoria =
                _categoriaFiltro == null ||
                lugar.categoriaId == _categoriaFiltro;
            // Essa variável guarda uma informação usada mais adiante.
            final combinaFavoritos = !_somenteFavoritos || (favoritos?.contem(lugar.id) ?? false);
            return combinaNome && combinaCategoria && combinaFavoritos;
          }).toList();

          // Organiza os elementos na tela para que fiquem na ordem certa.
          return Column(
            children: [
              // Organiza os elementos na tela para que fiquem na ordem certa.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                // Organiza os elementos na tela para que fiquem na ordem certa.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                    TextField(
                      controller: _buscaController,
                      // Atualiza a tela quando a pessoa muda essa opção.
                      onChanged: (texto) => setState(() => _termoBusca = texto),
                      decoration: InputDecoration(
                        // Este texto aparece na tela para orientar quem está usando o app.
                        labelText: 'Buscar lugar por nome',
                        // Este texto aparece na tela para orientar quem está usando o app.
                        hintText: 'Ex.: Praia Grande',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _termoBusca.isEmpty
                            ? null
                            // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                            : IconButton(
                                // Este texto aparece na tela para orientar quem está usando o app.
                                tooltip: 'Limpar busca',
                                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                                onPressed: () {
                                  _buscaController.clear();
                                  // Avisa ao Flutter que precisa mostrar uma informação atualizada.
                                  setState(() => _termoBusca = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Organiza os elementos na tela para que fiquem na ordem certa.
                    Row(
                      children: [
                        const Icon(Icons.filter_list, size: 21),
                        const SizedBox(width: 8),
                        // Este texto aparece na tela para orientar quem está usando o app.
                        const Text('Categoria:'),
                        const SizedBox(width: 12),
                        // Organiza os elementos na tela para que fiquem na ordem certa.
                        Expanded(
                          // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                          child: DropdownButton<int?>(
                            isExpanded: true,
                            value: _categoriaFiltro,
                            items: const [
                              DropdownMenuItem<int?>(
                                value: null,
                                // Este texto aparece na tela para orientar quem está usando o app.
                                child: Text('Todas'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 1,
                                // Este texto aparece na tela para orientar quem está usando o app.
                                child: Text('Praias'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 2,
                                // Este texto aparece na tela para orientar quem está usando o app.
                                child: Text('Points'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 3,
                                // Este texto aparece na tela para orientar quem está usando o app.
                                child: Text('Ilhas'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 4,
                                // Este texto aparece na tela para orientar quem está usando o app.
                                child: Text('Gastronomia'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 5,
                                // Este texto aparece na tela para orientar quem está usando o app.
                                child: Text('Dicas'),
                              ),
                            ],
                            // Atualiza a tela quando a pessoa muda essa opção.
                            onChanged: (id) =>
                                // Avisa ao Flutter que precisa mostrar uma informação atualizada.
                                setState(() => _categoriaFiltro = id),
                          ),
                        ),
                        // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                        IconButton(
                          // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                          onPressed: controller.carregando
                              ? null
                              : controller.listaLugares,
                          // Este texto aparece na tela para orientar quem está usando o app.
                          tooltip: 'Atualizar lista',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    // Confere se faltam informações ou se há algum erro.
                    if (favoritos != null)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        // Este texto aparece na tela para orientar quem está usando o app.
                        title: const Text('Somente favoritos'),
                        secondary: const Icon(Icons.favorite_outline),
                        value: _somenteFavoritos,
                        // Atualiza a tela quando a pessoa muda essa opção.
                        onChanged: (v) => setState(() => _somenteFavoritos = v),
                      ),
                    Text(
                      '${lugaresFiltrados.length} de ${controller.lugares.length} '
                      'lugares carregados',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Organiza os elementos na tela para que fiquem na ordem certa.
              Expanded(child: _conteudoLugares(controller, lugaresFiltrados, favoritos)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
        onPressed: _abrirCadastroAutorizado,
        icon: const Icon(Icons.add_location_alt_outlined),
        // Este texto aparece na tela para orientar quem está usando o app.
        label: const Text('Novo lugar'),
      ),
    );
  }

  // A função _conteudoLugares mostra lista, aviso ou carregamento conforme os lugares disponíveis.
  Widget _conteudoLugares(
    LugaresController controller,
    List<LugaresModel> lugaresFiltrados,
    FavoritosController? favoritos,
  ) {
    // Evita começar uma segunda tarefa enquanto a primeira ainda acontece.
    if (controller.carregando && controller.lugares.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Confere se faltam informações ou se há algum erro.
    if (controller.erro.isNotEmpty && controller.lugares.isEmpty) {
      return Center(
        // Organiza os elementos na tela para que fiquem na ordem certa.
        child: Padding(
          padding: const EdgeInsets.all(20),
          // Organiza os elementos na tela para que fiquem na ordem certa.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 44),
              const SizedBox(height: 10),
              Text(controller.erro, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
              FilledButton(
                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                onPressed: controller.listaLugares,
                // Este texto aparece na tela para orientar quem está usando o app.
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
          // Organiza os elementos na tela para que fiquem na ordem certa.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 85),
                Icon(
                  Icons.search_off_outlined,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                // Essa variável guarda uma informação usada mais adiante.
                final lugar = lugaresFiltrados[index];
                // Essa variável guarda uma informação usada mais adiante.
                final descricao = lugar.descricao?.trim() ?? '';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: LugarFoto(url: lugar.fotoUrl),
                    title: Text(
                      lugar.nome,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    // Organiza os elementos na tela para que fiquem na ordem certa.
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(lugar.categoria ?? 'Sem categoria'),
                        // Confere se faltam informações ou se há algum erro.
                        if (descricao.isNotEmpty)
                          Text(
                            descricao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    // Organiza os elementos na tela para que fiquem na ordem certa.
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Confere se faltam informações ou se há algum erro.
                        if (favoritos != null)
                          // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                          IconButton(
                            tooltip: favoritos.contem(lugar.id)
                                ? 'Remover dos favoritos'
                                : 'Adicionar aos favoritos',
                            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                            onPressed: () async {
                              // Essa variável guarda uma informação usada mais adiante.
                              final salvo = await favoritos.alternar(lugar.id);
                              // Só mexe na tela se ela ainda estiver aberta.
                              if (!salvo && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(favoritos.erro ?? 'Erro ao salvar favorito')),
                                );
                              }
                            },
                            icon: Icon(
                              favoritos.contem(lugar.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: favoritos.contem(lugar.id)
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
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
