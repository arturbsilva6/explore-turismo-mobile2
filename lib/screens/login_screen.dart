// PARA A APRESENTAÇÃO: este arquivo oferece o login da API da faculdade e o login com Google.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:guia_turismo/screens/firebase_login_screen.dart';
import 'package:guia_turismo/controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/services/firebase_auth_service.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:guia_turismo/controllers/favoritos_controller.dart';

// Esta classe LoginScreen reúne tudo que essa tela precisa para funcionar.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Esta classe _LoginScreenState reúne tudo que essa tela precisa para funcionar.
class _LoginScreenState extends State<LoginScreen> {
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final _email = TextEditingController();
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final _senha = TextEditingController();
  // Indica se a tarefa ainda está acontecendo, para mostrar o carregamento.
  bool _entrandoGoogle = false;
  // Guarda o aviso que será exibido quando algo não funcionar.
  String? _erroGoogle;

  @override
  // A função dispose libera os recursos quando a tela fecha.
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  // A função _loginGoogle entra com Google e troca a sessão atual.
  Future<void> _loginGoogle() async {
    // Evita começar uma segunda tarefa enquanto a primeira ainda acontece.
    if (_entrandoGoogle) return;
    // Avisa ao Flutter que precisa mostrar uma informação atualizada.
    setState(() {
      _entrandoGoogle = true;
      _erroGoogle = null;
    });
    // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
    try {
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await FirebaseAuthService().entrarComGoogle();
      // Descarta imediatamente favoritos antigos; só então limpa o JWT da API.
      if (!mounted) return;
      // Ajuda a tela a usar os dados ou verificar o formulário.
      final favoritos = context.read<FavoritosController>();
      favoritos.limpar();
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await SessionService().logout();
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await favoritos.carregar();
      // Só mexe na tela se ela ainda estiver aberta.
      if (!mounted) return;
      // Abre uma tela ou janela e mantém o caminho de navegação.
      Navigator.of(context).pushNamedAndRemoveUntil('home', (r) => false);
    } catch (e) {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) setState(() => _erroGoogle = FirebaseAuthService.mensagemDoErro(e));
    } finally {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) setState(() => _entrandoGoogle = false);
    }
  }

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Aqui é montada a estrutura principal desta tela.
    return Scaffold(
      // Este texto aparece na tela para orientar quem está usando o app.
      appBar: AppBar(title: Text("Login")),
      //Consumer vai ler/ouvir o controller de Autenticação
      body: Consumer<AuthController>(
        // Organiza os elementos na tela para que fiquem na ordem certa.
        builder: (context, controleAuth, _) => Padding(
          padding: EdgeInsets.all(16),
          // Organiza os elementos na tela para que fiquem na ordem certa.
          child: ListView(
            children: [const SizedBox(height: 60),
              // Organiza os elementos na tela para que fiquem na ordem certa.
              Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
              TextField(
                controller: _email,
                // Este texto aparece na tela para orientar quem está usando o app.
                decoration: InputDecoration(labelText: "E-mail"),
              ),
              // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
              TextField(
                controller: _senha,
                obscureText: true, //Esconde a senha
                // Este texto aparece na tela para orientar quem está usando o app.
                decoration: InputDecoration(labelText: "Senha"),
              ),
              SizedBox(height: 16),
              //Fica vazio se não tiver erro
              Text(controleAuth.erro),
              ElevatedButton(
                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                onPressed: () async {
                  //Tentar logar
                  final logou = await controleAuth.autenticarUsuario(_email.text, _senha.text);
                  // Só mexe na tela se ela ainda estiver aberta.
                  if (logou && context.mounted) {
                    // Substitui a sessão Firebase pela conta da API, sem misturar identidades.
                    if (Firebase.apps.isNotEmpty) {
                      // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
                      try { await FirebaseAuthService().sair(); } catch (_) {}
                    }
                    // Só mexe na tela se ela ainda estiver aberta.
                    if (!context.mounted) return;
                    // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
                    try {
                      // Ajuda a tela a usar os dados ou verificar o formulário.
                      final favoritos = context.read<FavoritosController>();
                      favoritos.limpar();
                      // Espera essa tarefa terminar para seguir para a próxima etapa.
                      await favoritos.carregar();
                    }
                    on ProviderNotFoundException { /* testes legados */ }
                    // Só mexe na tela se ela ainda estiver aberta.
                    if (context.mounted) {
                      // Abre uma tela ou janela e mantém o caminho de navegação.
                      Navigator.pushNamedAndRemoveUntil(context, 'home', (r) => false);
                    }
                  }
                },
                // Este texto aparece na tela para orientar quem está usando o app.
                child: Text("Entrar"),
              ),
              // Confere se faltam informações ou se há algum erro.
              if (Firebase.apps.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                  onPressed: _entrandoGoogle ? null : _loginGoogle,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(_entrandoGoogle ? 'Conectando ao Google...' : 'Entrar com Google'),
                ),
                // Confere se faltam informações ou se há algum erro.
                if (_erroGoogle != null)
                  Text(_erroGoogle!, textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 18),
              const Text(
                'Autenticação do Guia Turismo (API da disciplina)',
                textAlign: TextAlign.center,
              ),
              TextButton.icon(
                icon: const Icon(Icons.verified_user_outlined),
                // Este texto aparece na tela para orientar quem está usando o app.
                label: const Text('Experimentar Firebase Authentication'),
                // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                onPressed: () {
                  // Confere se faltam informações ou se há algum erro.
                  if (Firebase.apps.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Firebase ainda não configurado. Consulte FIREBASE_AULA.md.',
                        ),
                      ),
                    );
                    return;
                  }
                  // Abre uma tela ou janela e mantém o caminho de navegação.
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FirebaseLoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          ],
          ),
        ),
      ),
    );
  }
}