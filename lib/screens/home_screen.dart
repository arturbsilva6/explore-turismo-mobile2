// PARA A APRESENTAÇÃO: este arquivo reúne as abas do aplicativo e permite sair da conta.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guia_turismo/services/firebase_auth_service.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:guia_turismo/controllers/favoritos_controller.dart';
import 'package:guia_turismo/controllers/theme_controller.dart';
import 'package:guia_turismo/screens/camera_screen.dart';
import 'package:guia_turismo/screens/cadastro_lugar.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/screens/mapa_screen.dart';

// Esta classe HomeScreen reúne tudo que essa tela precisa para funcionar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Esta classe _HomeScreenState reúne tudo que essa tela precisa para funcionar.
class _HomeScreenState extends State<HomeScreen> {
  // Lembra a escolha feita na tela, como categoria, busca ou aba.
  int _paginaAtual = 0;

  // A função _selecionarAba muda a aba que aparece na parte inferior.
  void _selecionarAba(int pagina) => setState(() => _paginaAtual = pagina);

  // A função _sair faz o logout e limpa os dados da conta.
  Future<void> _sair() async {
    // Ajuda a tela a usar os dados ou verificar o formulário.
    final favoritos = context.read<FavoritosController>();
    // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
    try {
      favoritos.limpar();
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await SessionService().logout();
      // Confere se faltam informações ou se há algum erro.
      if (Firebase.apps.isNotEmpty) await FirebaseAuthService().sair();
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await favoritos.carregar();
      // Só mexe na tela se ela ainda estiver aberta.
      if (!mounted) return;
      // Abre uma tela ou janela e mantém o caminho de navegação.
      Navigator.of(context).pushNamedAndRemoveUntil('login', (r) => false);
    } catch (_) {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Este texto aparece na tela para orientar quem está usando o app.
          const SnackBar(content: Text('Não foi possível sair. Tente novamente.')),
        );
      }
    }
  }

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Lembra a escolha feita na tela, como categoria, busca ou aba.
    final paginas = [
      _PaginaInicial(
        onAbrirLugares: () => _selecionarAba(2),
        onAbrirCamera: () => _selecionarAba(1),
      ),
      const CameraScreen(),
      const LugaresScreen(),
      const MapaScreen(),
    ];
    const cabecalhos = [
      'Explore Turismo',
      'Câmera',
      'Lugares para visitar',
      'Mapa',
    ];

    // Aqui é montada a estrutura principal desta tela.
    return Scaffold(
      appBar: AppBar(
        title: Text(cabecalhos[_paginaAtual]),
        actions: [
          // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
          IconButton(
            // Este texto aparece na tela para orientar quem está usando o app.
            tooltip: 'Sair da conta',
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onPressed: _sair,
            icon: const Icon(Icons.logout_outlined),
          ),
          Consumer<ThemeController>(
            // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
            builder: (context, tema, _) => IconButton(
              // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
              onPressed: tema.alternarTema,
              // Este texto aparece na tela para orientar quem está usando o app.
              tooltip: 'Alternar tema',
              icon: Icon(tema.iconeAtual),
            ),
          ),
        ],
      ),
      // Organiza os elementos na tela para que fiquem na ordem certa.
      body: IndexedStack(index: _paginaAtual, children: paginas),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _paginaAtual,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
        onTap: _selecionarAba,
        items: const [
          // Os índices das abas existentes são preservados.
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
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
        ],
      ),
    );
  }
}

/// Página de boas-vindas com acesso rápido aos recursos que já existem.
class _PaginaInicial extends StatelessWidget {
  // Essa variável guarda uma informação usada mais adiante.
  final VoidCallback onAbrirLugares;
  // Essa variável guarda uma informação usada mais adiante.
  final VoidCallback onAbrirCamera;

  const _PaginaInicial({
    required this.onAbrirLugares,
    required this.onAbrirCamera,
  });

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Essa variável guarda uma informação usada mais adiante.
    final cores = Theme.of(context).colorScheme;

    // Organiza os elementos na tela para que fiquem na ordem certa.
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
          // Organiza os elementos na tela para que fiquem na ordem certa.
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
                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                onPressed: onAbrirLugares,
                icon: const Icon(Icons.explore_outlined),
                // Este texto aparece na tela para orientar quem está usando o app.
                label: const Text('Explorar lugares'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'O que deseja fazer?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.map_outlined, size: 32),
            // Este texto aparece na tela para orientar quem está usando o app.
            title: const Text('Consultar destinos'),
            // Este texto aparece na tela para orientar quem está usando o app.
            subtitle: const Text('Busque por nome ou filtre uma categoria.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onTap: onAbrirLugares,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.add_location_alt_outlined, size: 32),
            // Este texto aparece na tela para orientar quem está usando o app.
            title: const Text('Cadastrar lugar'),
            // Este texto aparece na tela para orientar quem está usando o app.
            subtitle: const Text('Abra Lugares e toque no botão +.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onTap: onAbrirLugares,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.photo_camera_outlined, size: 32),
            // Este texto aparece na tela para orientar quem está usando o app.
            title: const Text('Usar câmera'),
            // Este texto aparece na tela para orientar quem está usando o app.
            subtitle: const Text('Tire uma foto ou escolha da galeria.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
            onTap: onAbrirCamera,
          ),
        ),
      ],
    );
  }
}
