import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:guia_turismo/screens/firebase_login_screen.dart';
import 'package:guia_turismo/controller/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/services/firebase_auth_service.dart';
import 'package:guia_turismo/controller/favoritos_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _entrandoGoogle = false;
  String? _erroGoogle;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _loginGoogle() async {
    if (_entrandoGoogle) return;
    setState(() {
      _entrandoGoogle = true;
      _erroGoogle = null;
    });
    try {
      await FirebaseAuthService().entrarComGoogle();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('home', (r) => false);
    } catch (e) {
      if (mounted) setState(() => _erroGoogle = FirebaseAuthService.mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _entrandoGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      //Consumer vai ler/ouvir o controller de Autenticação
      body: Consumer<AuthController>(
        builder: (context, controleAuth, _) => Padding(
          padding: EdgeInsets.all(16),
          child: ListView(
            children: [const SizedBox(height: 60),
              Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _email,
                decoration: InputDecoration(labelText: "E-mail"),
              ),
              TextField(
                controller: _senha,
                obscureText: true, //Esconde a senha
                decoration: InputDecoration(labelText: "Senha"),
              ),
              SizedBox(height: 16),
              //Fica vazio se não tiver erro
              Text(controleAuth.erro), 
              ElevatedButton(
                onPressed: () async {
                  //Tentar logar
                  final logou = await controleAuth.autenticarUsuario(_email.text, _senha.text);
                  if (logou && context.mounted) {
                    try { await context.read<FavoritosController>().carregar(); }
                    on ProviderNotFoundException { /* testes legados */ }
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, 'home', (r) => false);
                    }
                  }
                },
                child: Text("Entrar"),
              ),
              if (Firebase.apps.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _entrandoGoogle ? null : _loginGoogle,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(_entrandoGoogle ? 'Conectando ao Google...' : 'Entrar com Google'),
                ),
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
                label: const Text('Experimentar Firebase Authentication'),
                onPressed: () {
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