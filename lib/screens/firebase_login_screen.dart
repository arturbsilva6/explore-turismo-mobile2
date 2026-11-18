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

class _FirebaseLoginScreenState extends State<FirebaseLoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseAuthService();
  bool _carregando = false;
  bool _criarConta = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao,
      {bool iniciarSessaoFirebase = false}) async {
    if (_carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await acao();
      if (iniciarSessaoFirebase) {
        if (!mounted) return;
        final favoritos = context.read<FavoritosController>();
        favoritos.limpar();
        // Nunca herdar JWT de uma conta acadêmica após login Firebase.
        await SessionService().logout();
        await favoritos.carregar();
      } else if (_service.usuarioAtual == null && mounted) {
        final favoritos = context.read<FavoritosController>();
        favoritos.limpar();
        await favoritos.carregar();
      }
    } catch (erro) {
      if (mounted) setState(() => _erro = FirebaseAuthService.mensagemDoErro(erro));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _entrarEmail() async {
    if (!_formKey.currentState!.validate()) return;
    await _executar(() async {
      if (_criarConta) {
        await _service.criarContaComEmail(_email.text, _senha.text);
      } else {
        await _service.entrarComEmail(_email.text, _senha.text);
      }
    }, iniciarSessaoFirebase: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autenticação Firebase')),
      body: StreamBuilder<User?>(
        stream: _service.mudancasDeUsuario,
        initialData: _service.usuarioAtual,
        builder: (context, snapshot) {
          final usuario = snapshot.data;
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
              if (usuario != null) ...[
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
                  onPressed: _carregando
                      ? null
                      : () => _executar(_service.sair),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair do Firebase'),
                ),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (valor) =>
                            valor == null || !valor.contains('@')
                            ? 'Informe um e-mail válido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _senha,
                        obscureText: true,
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
                FilledButton(
                  onPressed: _carregando ? null : _entrarEmail,
                  child: Text(_criarConta ? 'Cadastrar no Firebase' : 'Entrar com e-mail'),
                ),
                TextButton(
                  onPressed: _carregando
                      ? null
                      : () => setState(() => _criarConta = !_criarConta),
                  child: Text(_criarConta ? 'Já tenho conta' : 'Criar conta Firebase'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _carregando
                      ? null
                      : () => _executar(() async {
                          await _service.entrarComGoogle();
                        }, iniciarSessaoFirebase: true),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar com o Google'),
                ),
              ],
              if (_carregando) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
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
