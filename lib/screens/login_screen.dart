import 'package:flutter/material.dart';
import 'package:guia_turismo/controller/auth_controller.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      //Consumer vai ler/ouvir o controller de Autenticação
      body: Consumer<AuthController>(
        builder: (context, controleAuth, _) => Padding(
          padding: EdgeInsets.all(16),
          child: Column(
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
                    //pushNamed -> cria uma "setinha" que te permite voltar a tela anterior
                    Navigator.pushNamed(context, 'home');
                  }
                },
                child: Text("Entrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}