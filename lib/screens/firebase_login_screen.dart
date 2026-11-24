// PARA A APRESENTAÇÃO: este arquivo mostra o login de teste com Google ou e-mail e senha.
// Comentários em linguagem simples: explicam o que a tela faz, sem alterar o código.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guia_turismo/services/firebase_auth_service.dart';
import 'package:guia_turismo/services/session_service.dart';
import 'package:guia_turismo/controllers/favoritos_controller.dart';
import 'package:provider/provider.dart';

/// Tela de exercício conforme a aula: e-mail/senha, Google e dados do usuário.
/// Mantém o login da API de Turismo em uma tela independente.
class FirebaseLoginScreen extends StatefulWidget {
  const FirebaseLoginScreen({super.key});

  @override
  State<FirebaseLoginScreen> createState() => _FirebaseLoginScreenState();
}

// Esta classe _FirebaseLoginScreenState reúne tudo que essa tela precisa para funcionar.
class _FirebaseLoginScreenState extends State<FirebaseLoginScreen> {
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final _email = TextEditingController();
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final _senha = TextEditingController();
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final _formKey = GlobalKey<FormState>();
  // Ajuda a tela a usar os dados ou verificar o formulário.
  final _service = FirebaseAuthService();
  // Indica se a tarefa ainda está acontecendo, para mostrar o carregamento.
  bool _carregando = false;
  // Essa variável guarda uma informação usada mais adiante.
  bool _criarConta = false;
  // Guarda o aviso que será exibido quando algo não funcionar.
  String? _erro;

  @override
  // A função dispose libera os recursos quando a tela fecha.
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  // A função _executar controla o carregamento de uma tentativa de login.
  Future<void> _executar(Future<void> Function() acao,
      {bool iniciarSessaoFirebase = false}) async {
    // Evita começar uma segunda tarefa enquanto a primeira ainda acontece.
    if (_carregando) return;
    // Avisa ao Flutter que precisa mostrar uma informação atualizada.
    setState(() {
      _carregando = true;
      _erro = null;
    });
    // Tentamos realizar esta ação porque ela pode depender da internet ou do celular.
    try {
      // Espera essa tarefa terminar para seguir para a próxima etapa.
      await acao();
      // Confere se a conta está autorizada para essa ação.
      if (iniciarSessaoFirebase) {
        // Só mexe na tela se ela ainda estiver aberta.
        if (!mounted) return;
        // Ajuda a tela a usar os dados ou verificar o formulário.
        final favoritos = context.read<FavoritosController>();
        favoritos.limpar();
        // Nunca herdar JWT de uma conta acadêmica após login Firebase.
        await SessionService().logout();
        // Espera essa tarefa terminar para seguir para a próxima etapa.
        await favoritos.carregar();
      } else if (_service.usuarioAtual == null && mounted) {
        // Ajuda a tela a usar os dados ou verificar o formulário.
        final favoritos = context.read<FavoritosController>();
        favoritos.limpar();
        // Espera essa tarefa terminar para seguir para a próxima etapa.
        await favoritos.carregar();
      }
    } catch (erro) {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) setState(() => _erro = FirebaseAuthService.mensagemDoErro(erro));
    } finally {
      // Só mexe na tela se ela ainda estiver aberta.
      if (mounted) setState(() => _carregando = false);
    }
  }

  // A função _entrarEmail confere o formulário para entrar ou cadastrar.
  Future<void> _entrarEmail() async {
    // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
    if (!_formKey.currentState!.validate()) return;
    // Espera essa tarefa terminar para seguir para a próxima etapa.
    await _executar(() async {
      // Aqui o aplicativo escolhe o que fazer dependendo desta condição.
      if (_criarConta) {
        // Espera essa tarefa terminar para seguir para a próxima etapa.
        await _service.criarContaComEmail(_email.text, _senha.text);
      } else {
        // Espera essa tarefa terminar para seguir para a próxima etapa.
        await _service.entrarComEmail(_email.text, _senha.text);
      }
    }, iniciarSessaoFirebase: true);
  }

  @override
  // A função build monta o que aparece na tela.
  Widget build(BuildContext context) {
    // Aqui é montada a estrutura principal desta tela.
    return Scaffold(
      // Este texto aparece na tela para orientar quem está usando o app.
      appBar: AppBar(title: const Text('Autenticação Firebase')),
      body: StreamBuilder<User?>(
        stream: _service.mudancasDeUsuario,
        initialData: _service.usuarioAtual,
        builder: (context, snapshot) {
          // Essa variável guarda uma informação usada mais adiante.
          final usuario = snapshot.data;
          // Organiza os elementos na tela para que fiquem na ordem certa.
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.verified_user_outlined, size: 60),
              const SizedBox(height: 12),
              Text(
                usuario == null ? 'Login com Firebase' : 'Usuário autenticado',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Exercício de Firebase Authentication. O cadastro de lugares '
                'continua exigindo o login separado na API da faculdade.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Confere se faltam informações ou se há algum erro.
              if (usuario != null) ...[
                // Confere se faltam informações ou se há algum erro.
                if (usuario.photoURL != null)
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(usuario.photoURL!),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  usuario.displayName ?? 'Sem nome',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(usuario.email ?? 'Sem e-mail', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                  onPressed: _carregando
                      ? null
                      : () => _executar(_service.sair),
                  icon: const Icon(Icons.logout),
                  // Este texto aparece na tela para orientar quem está usando o app.
                  label: const Text('Sair do Firebase'),
                ),
              ] else ...[
                Form(
                  key: _formKey,
                  // Organiza os elementos na tela para que fiquem na ordem certa.
                  child: Column(
                    children: [
                      // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        // Este texto aparece na tela para orientar quem está usando o app.
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (valor) =>
                            valor == null || !valor.contains('@')
                            ? 'Informe um e-mail válido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                      TextFormField(
                        controller: _senha,
                        obscureText: true,
                        // Este texto aparece na tela para orientar quem está usando o app.
                        decoration: const InputDecoration(labelText: 'Senha'),
                        validator: (valor) =>
                            valor == null || valor.length < 6
                            ? 'A senha deve ter pelo menos seis caracteres'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Esse componente permite que a pessoa digite, escolha ou toque em alguma opção.
                FilledButton(
                  // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                  onPressed: _carregando ? null : _entrarEmail,
                  child: Text(_criarConta ? 'Cadastrar no Firebase' : 'Entrar com e-mail'),
                ),
                TextButton(
                  // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                  onPressed: _carregando
                      ? null
                      // Avisa ao Flutter que precisa mostrar uma informação atualizada.
                      : () => setState(() => _criarConta = !_criarConta),
                  child: Text(_criarConta ? 'Já tenho conta' : 'Criar conta Firebase'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  // Aqui dizemos o que acontece quando a pessoa toca nesse botão ou item.
                  onPressed: _carregando
                      ? null
                      : () => _executar(() async {
                          // Espera essa tarefa terminar para seguir para a próxima etapa.
                          await _service.entrarComGoogle();
                        }, iniciarSessaoFirebase: true),
                  icon: const Icon(Icons.login),
                  // Este texto aparece na tela para orientar quem está usando o app.
                  label: const Text('Entrar com o Google'),
                ),
              ],
              // Evita começar uma segunda tarefa enquanto a primeira ainda acontece.
              if (_carregando) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              // Confere se faltam informações ou se há algum erro.
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  _erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
