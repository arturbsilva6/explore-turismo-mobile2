import 'package:flutter/material.dart';
import 'package:guia_turismo/controller/theme_controller.dart';
import 'package:guia_turismo/screens/camera_screen.dart';
import 'package:guia_turismo/screens/cadastro_lugar.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _paginaAtual = 0;

  void _selecionarAba(int pagina) => setState(() => _paginaAtual = pagina);

  @override
  Widget build(BuildContext context) {
    final paginas = [
      _PaginaInicial(
        onAbrirLugares: () => _selecionarAba(2),
        onAbrirCamera: () => _selecionarAba(1),
      ),
      const CameraScreen(),
      const LugaresScreen(),
    ];
    const cabecalhos = ['Explore Turismo', 'Câmera', 'Lugares para visitar'];

    return Scaffold(
      appBar: AppBar(
        title: Text(cabecalhos[_paginaAtual]),
        actions: [
          Consumer<ThemeController>(
            builder: (context, tema, _) => IconButton(
              onPressed: tema.alternarTema,
              tooltip: 'Alternar tema',
              icon: Icon(tema.iconeAtual),
            ),
          ),
        ],
      ),
      body: paginas[_paginaAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaAtual,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _selecionarAba,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Câmera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.place_outlined),
            activeIcon: Icon(Icons.place),
            label: 'Lugares',
          ),
        ],
      ),
    );
  }
}

/// Página de boas-vindas com acesso rápido aos recursos que já existem.
class _PaginaInicial extends StatelessWidget {
  final VoidCallback onAbrirLugares;
  final VoidCallback onAbrirCamera;

  const _PaginaInicial({
    required this.onAbrirLugares,
    required this.onAbrirCamera,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [cores.primary, cores.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.travel_explore, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Seu próximo passeio começa aqui',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Conheça lugares, consulte detalhes e registre novos destinos.',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: cores.primary,
                ),
                onPressed: onAbrirLugares,
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explorar lugares'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('O que deseja fazer?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.map_outlined, size: 32),
            title: const Text('Consultar destinos'),
            subtitle: const Text('Busque por nome ou filtre uma categoria.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onAbrirLugares,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.add_location_alt_outlined, size: 32),
            title: const Text('Cadastrar lugar'),
            subtitle: const Text('Abra Lugares e toque no botão +.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onAbrirLugares,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.photo_camera_outlined, size: 32),
            title: const Text('Usar câmera'),
            subtitle: const Text('Tire uma foto ou escolha da galeria.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onAbrirCamera,
          ),
        ),
      ],
    );
  }
}
