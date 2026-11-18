# Aula de Firebase — aplicação no Explore Turismo

## Resumo visual da gravação da aula (04/11/2026)

A gravação foi analisada pelas **etapas mostradas na tela**. A fala não foi
integralmente transcrita, portanto o roteiro abaixo não pretende ser uma citação
literal da professora.

- **0–10 min:** edição de um projeto Flutter didático denominado `login`,
  com uma tela `Login com Google`; preparação de terminal e bibliotecas.
- **10–20 min:** criação/acesso a um projeto no Firebase Console;
  Authentication e ativação dos provedores **E-mail/senha** e **Google**;
  apresentação dos modelos de mensagens de autenticação.
- **20–45 min:** registro de um app Flutter no Firebase, Firebase CLI,
  FlutterFire CLI, login na CLI, ajustes de ambiente/PATH no Windows.
- **45–83 min:** execução de `flutterfire configure` e geração de arquivos
  de configuração; parte desse período mostra o terminal em espera.
- **83–92 min:** código demonstrado no `main.dart`:
  `WidgetsFlutterBinding.ensureInitialized()` e
  `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
- **92–101 min:** tentativa de executar o aplicativo Android com dificuldades
  de Gradle/JDK no computador apresentado. As imagens não confirmam a conclusão
  bem-sucedida de um login no final da gravação.

## Decisão de integração ao Explore Turismo

O Explore Turismo já autentica na API
`https://guia.liliaborges.com.br/login`, recebendo o token exigido para
`POST /lugares`.

**Firebase Authentication não substitui esse token automaticamente.**
Foi acrescentada uma tela demonstrativa, independente, que permite:
- criar conta e entrar por E-mail/senha no Firebase;
- entrar com uma conta Google via Firebase;
- exibir nome, e-mail, foto (se houver) e sair.

O login atual e os recursos da primeira e da segunda entrega continuam
inalterados. **Não usamos o projeto Firebase da professora mostrado no vídeo.**
A autenticação Firebase permanece inativa por padrão.

## Configurar seu próprio projeto Firebase (Windows / Android)

1. Abra https://console.firebase.google.com/ e crie um projeto Firebase seu
   (ou selecione um projeto já administrado por você).
2. Em **Authentication > Método de login**, ative **E-mail/senha** e **Google**.
   Escolha o e-mail de suporte do provedor Google, se solicitado.
3. Abra o terminal na pasta `C:\ProjetosFlutter\explore_turismo`.
4. Confira Flutter e Node:
   `flutter doctor`, `node -v`, `npm -v`.
5. Instale/configure as ferramentas seguindo a documentação do Firebase:
   
   ```powershell
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

6. Execute `flutter pub get` e `flutterfire configure --platforms=android`,
   selecionando **seu** projeto no assistente. Se `flutterfire` não estiver no
   PATH, consulte as instruções exibidas pelo Dart para habilitar o diretório
   de executáveis globais.
7. O arquivo `lib/firebase_options.dart` agora contém **opções Android
   montadas a partir do `google-services.json` do seu próprio projeto**.
   Não foi gerado pelo FlutterFire CLI. Execute `flutterfire configure`
   para conferir/regenerar oficialmente a configuração, inclusive alterações
   de Gradle. O plugin Google Services já está declarado nos arquivos
   `android/settings.gradle.kts` e `android/app/build.gradle.kts`.
8. Cadastre no Firebase os hashes de assinatura do aplicativo Android
   (SHA-1 e, quando necessário, SHA-256). Para a chave de debug:

   ```powershell
   cd android
   .\gradlew.bat signingReport
   cd ..
   ```

   Copie as impressões digitais da variante `debug` para as configurações
   do aplicativo Android no Firebase Console; então execute novamente
   `flutterfire configure --platforms=android` se necessário. Para login
   Google, verifique se o `google-services.json` está atualizado.
9. Execute:

   ```powershell
   flutter pub get
   flutter analyze
   flutter test
   flutter run -d emulator-5554 --dart-define=FIREBASE_ENABLED=true
   ```

   Substitua `emulator-5554` pelo identificador obtido em `flutter devices`.
   A flag só deve ser ativada **após configurar** o Firebase.

10. Abra a tela **Login** do aplicativo, toque em
    **Experimentar Firebase Authentication** e faça os testes de e-mail/senha,
    Google, exibição de usuário e sair. Teste também o **login da API** e o
    cadastro de lugares para comprovar que nada regrediu.

## O que foi implementado nesta branch

- `lib/firebase_options.dart`: opções Android preenchidas do arquivo oficial do Firebase (pendente regeneração/validação com FlutterFire CLI);
- `lib/main.dart`: inicialização opcional usando a classe gerada pelo FlutterFire;
- `lib/services/firebase_auth_service.dart`: autenticação Firebase isolada;
- `lib/screens/firebase_login_screen.dart`: tela demonstrativa;
- `lib/screens/login_screen.dart`: atalho sem substituir o login anterior;
- `pubspec.yaml`: dependências de Firebase e Google;
- `android/app/google-services.json`: configuração cliente do próprio Firebase;
- Gradle: plugin Google Services aplicado para gerar recursos Android;
- `test/firebase_auth_service_test.dart`: testes unitários das mensagens de erro.

**Avanços confirmados:** Google e E-mail/senha foram ativados no Console;
o `android/app/google-services.json` do projeto foi incluído nesta branch,
as opções Android foram preenchidas e o plugin Google Services foi configurado.
  
**Pendências reais:** registrar SHA-1 da chave de assinatura utilizada no seu
computador, baixar novamente o `google-services.json` após o registro da SHA,
validar/regenerar opções com FlutterFire CLI, atualizar `pubspec.lock` com
`flutter pub get`, validar Gradle/Android e testar login Google no emulador.
Ainda não foi executado `flutter analyze` nem `flutter test` nesta branch.

## Cuidados

- A configuração cliente gerada pelo FlutterFire contém identificadores
  públicos do projeto, **não credenciais de administrador**. Mesmo assim,
  nunca publique uma chave privada do Firebase Admin SDK, tokens de sessão
  nem senhas de usuário.
- Configure regras de segurança adequadas se adicionar Firestore/Storage
  futuramente. **Esses serviços não foram introduzidos nesta etapa**, pois o
  exercício visível trata principalmente de Authentication.
- Não envie o ID token do Firebase como Bearer à API da faculdade. Para
  unificar logins, seria necessária uma integração própria no backend.
- Não faça merge na `main` antes de validar Flutter, Google Sign-In,
  autenticação existente e o cadastro pela API.

Referências oficiais:
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/start
- https://firebase.google.com/docs/auth/flutter/federated-auth
