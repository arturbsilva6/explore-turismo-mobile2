# CLAUDE.md — Explore Turismo (Mobile II)

> Contexto operacional para Claude Code. Atualizado em 18/11/2026.  
> **Modo inicial: somente revisão/auditoria, sem alterações no código ou no Git.**
> Este arquivo deve ser lido em conjunto com `docs/CODEX_CONTEXTO_REVISAO_ENTREGA_FINAL.md`, que contém o contexto histórico e técnico ampliado e também serve para Claude.

## Missão imediata

Revisar tecnicamente a versão da **entrega final** do aplicativo Flutter/Dart Explore Turismo, especialmente as mudanças do **PR #3** (`feat/entrega-final-mobile2` → `main`). O objetivo é verificar aderência ao enunciado da disciplina, qualidade, bugs, integrações, segurança, regressões e testes que faltam, **antes** do teste manual do desenvolvedor no Samsung Galaxy S23.

**Não codificar ou corrigir nesta primeira etapa.** Primeiro entregar um relatório fundamentado, com arquivo/linha, gravidade e evidência. Não fazer commit, push, merge, alteração de branch destrutiva, chamadas reais de escrita à API nem mudanças no Firebase sem autorização.

## Identificação

- Projeto: **Explore Turismo**, pacote Flutter: `guia_turismo`.
- Disciplina: **Mobile II**, curso de Sistemas para Internet.
- Repositório: https://github.com/arturbsilva6/explore-turismo-mobile2
- Diretório local habitual: `C:\ProjetosFlutter\explore_turismo` (Windows/PowerShell).
- Stack: Flutter 3.47.7 (referência de CI), Dart, Provider/ChangeNotifier, HTTP REST, SharedPreferences, image_picker, flutter_map/OpenStreetMap, latlong2, Nominatim, Firebase Authentication/Google, geolocator e url_launcher.
- API acadêmica: https://guia.liliaborges.com.br ; docs https://guia.liliaborges.com.br/api-docs/
- Firebase de aula: projeto `explore-turismo`; Android app id/package `com.example.guia_turismo`.
- Android: aparelho real já usado na validação do PR #2; **novas funções do PR #3 ainda exigem teste físico**.

## Branches, PRs e contexto Git

| Ref | Finalidade | Estado confirmado em 18/11/2026 |
| --- | --- | --- |
| `main` | Versão principal com entregas anteriores e Firebase da aula | Não contém código novo da entrega final |
| `feat/mapa-localizacao` | Entrega 2: mapa, marcadores, CEP/endereço via Nominatim | PR #1 integrado na `main` |
| `feat/firebase-auth-aula` | Entrega 3: Google/Firebase, e-mail/senha, logout | PR #2 integrado na `main` |
| `feat/entrega-final-mobile2` | Entrega final: fotos, GPS, favoritos, rotas, filtro, login e revisão | **PR #3 aberto como draft; não integrar sem autorização** |

Links:
- PR #1 https://github.com/arturbsilva6/explore-turismo-mobile2/pull/1
- PR #2 https://github.com/arturbsilva6/explore-turismo-mobile2/pull/2
- PR #3 https://github.com/arturbsilva6/explore-turismo-mobile2/pull/3

Referência de comparação: `main` no início do PR #3 era `6020ba7c31b8d4eb20b9d0f85ae963ead309bca3`. Antes dos documentos de contexto, o código do PR #3 estava em `19208fdfe8a8c34e9d6f0deba680b01af8467ca6`. Depois foi adicionado o documento para Codex em `85d0c6cc8d44258f1085d8691fdbb4aa574aec8f`. **Não supor que estes são o HEAD atual: validar o histórico ao iniciar a auditoria.**

**Regra:** não revisar apenas `main`; auditar a branch da entrega final e seu diff contra `main`. Se houver alterações locais não commitadas, não sobrescrever.

## Enunciado oficial da entrega final

1. Entrega 1: **cadastro de lugares com foto**.
2. Entrega 2: **geolocalização**.
3. Entrega 3: **login com Google**.
4. Entrega final: **aplicativo funcional**.

Requisitos obrigatórios da entrega final:
- Google Sign-In, persistência da sessão e logout.
- Mapa OpenStreetMap interativo com pins dos lugares e fotos quando disponíveis e **localização atual do usuário via GPS**.
- Sistema de favoritos.
- Erros tratados sem travamentos; organização `lib/screens`, `lib/controllers`, `lib/services`, `lib/models` e `lib/widgets`.
- Ao menos uma funcionalidade extra: **Como Chegar**, compartilhamento nativo, filtros por categoria no mapa ou sensores. A implementação inclui **Como Chegar** e **filtro no mapa**.
- Atualizar link do GitHub e demonstrar o aplicativo funcionando.

**Crítico:** geocodificação por CEP/endereço **não é** o GPS físico. Foto capturada mas não enviada ao backend **não satisfaz integralmente** cadastro com foto. Teste automatizado passando **não garante** que GPS, login Google e deep links funcionem em dispositivo.

## Histórico funcional resumido

### Base/Entrega 1
- Login com JWT da API acadêmica; GET/POST de lugares; listagem/detalhes; câmera e galeria.
- Câmera mostrava placeholder externo `placehold.co/150x150.png`, sem vínculo persistente das fotos ao cadastro.
- Categorias fixas de cinco IDs; tema claro/escuro; Provider.

### Entrega 2 / PR #1
- `flutter_map` + OpenStreetMap: mapa com pinos de lugares de coordenadas válidas.
- Busca Nominatim por CEP/endereço, ajuste de ponto, retorno para formulário e campos manuais.
- Até dez páginas com trinta lugares (máximo de 300) e aviso de paginação parcial.
- Cache/fila para Nominatim; tratamento de falhas HTTP, coordenadas inválidas e tiles.

### Entrega 3 / PR #2
- Firebase Core/Auth e Google Sign-In 7.x; e-mail/senha; cadastro e logout.
- `flutterfire configure` executado para Android; SHA-1/SHA-256 da assinatura debug cadastrados.
- Fase anterior: 36 testes locais aprovados, análise sem problemas, Google/email/senha e login API testados em aparelho físico.
- Inicialmente Firebase era opt-in com `FIREBASE_ENABLED=true`.

### Entrega final / PR #3 — alterações propostas
- Remove placeholder remoto e introduz estado vazio da câmera com seleção de imagem real.
- Captura/seleção opcional de foto no formulário; upload autenticado multipart para galeria depois de cadastrar o lugar.
- Exibe foto real do backend em detalhes/lista/marcador, quando existir; fallback em caso contrário.
- GPS de primeiro plano: permissão explícita, botão “Minha localização GPS”, pin azul e distância aproximada.
- Favoritos remotos com JWT da API; locais por SharedPreferences para sessão só Google/visitante; filtro “Somente favoritos”.
- Filtro por categoria na tela do mapa; “Como chegar” com Google Maps externo.
- Google direto na tela principal de login; tentativa de restaurar sessão ao iniciar; logout na Home.
- Controladores em `lib/controllers`; `lib/controller` mantém reexports temporários para compatibilidade.
- Testes adicionais de câmera vazia, fotos, rotas, favoritos, upload multipart e distância.

## Mapa de arquivos

| Componente | Arquivos |
| --- | --- |
| Inicialização/rotas/providers | `lib/main.dart`; `lib/screens/home_screen.dart` |
| Tela login API/Google | `lib/screens/login_screen.dart` |
| Login Firebase | `lib/screens/firebase_login_screen.dart`; `lib/services/firebase_auth_service.dart` |
| Login acadêmico/JWT | `lib/controllers/auth_controller.dart`; `lib/services/auth_service.dart`; `lib/services/session_service.dart` |
| Lista/cadastro/detalhes | `lib/screens/cadastro_lugar.dart`; `lib/screens/detalhe_lugar_screen.dart` |
| Serviço/estado de lugares | `lib/services/lugares_services.dart`; `lib/controllers/lugares_controller.dart` |
| Modelo/fotos | `lib/models/lugares_model.dart`; `lib/widgets/lugar_foto.dart` |
| Câmera/upload | `lib/screens/camera_screen.dart`; `lib/controllers/camera_controller.dart`; `lib/services/galeria_service.dart` |
| Mapa/GPS/rota | `lib/screens/mapa_screen.dart`; `lib/services/localizacao_atual_service.dart`; `lib/services/rotas_service.dart` |
| Favoritos | `lib/controllers/favoritos_controller.dart`; `lib/services/favoritos_service.dart` |
| Endereço/CEP | `lib/widgets/busca_localizacao.dart`; `lib/screens/selecionar_localizacao_screen.dart`; `lib/services/geocodificacao_service.dart` e Nominatim |
| Permissões/dependências | `android/app/src/main/AndroidManifest.xml`; `ios/Runner/Info.plist`; `pubspec.yaml`; `pubspec.lock` |
| Qualidade | `test/`; `.github/workflows/flutter-checks.yml` |
| Contexto ampliado | `docs/CODEX_CONTEXTO_REVISAO_ENTREGA_FINAL.md`; `ENTREGA_FINAL.md`; `README.md`; `SEGUNDA_ENTREGA.md`; `FIREBASE_AULA.md`; `docs/geocodificacao.md` |

## Contratos e restrições que não devem ser quebrados

**Autenticação dupla:** Firebase/Google **não substitui** JWT da API acadêmica. Usuário só Google pode navegar pela listagem pública, mas não deve enviar POST de lugar, foto ou favorito remoto sem credencial válida da API. Confirmar logout, alternância de contas, identidade dos favoritos e restauração de sessão.

**Cadastro:** `POST /lugares` envia JSON com `nome`, `descricao`, `latitude`, `longitude`, `categoriaId` e JWT da API, aguardando HTTP 201. Upload de foto é **uma segunda operação**: `POST /lugares/{id}/galeria` com campo multipart `foto` e JWT. Caso o POST não devolva o ID, o controller tenta encontrar **apenas um** lugar recém-criado compatível com nome/coordenadas. Se não houver correspondência única, não associar a foto a um lugar incerto; permitir envio posterior pela tela de detalhes.

**Favoritos:** `GET /favoritos`; `POST/DELETE /favoritos/{id}` (conferir esquema real do Swagger). Local/offline via SharedPreferences quando apropriado; testar isolamento de conta e sincronização após erro.

**GPS/mapa:** pedir localização somente sob ação do usuário, sem background. Marcar posição atual separadamente dos lugares. Usar coordenadas válidas, tratar permissão negada/permanente, GPS desligado/timeout e ausência de lugares. “Como chegar” abre rota externa, exige fallback se não houver handler.

**Fotos:** não usar placeholder remoto 150×150; não inventar URLs ou fotos. Ler imagens retornadas pela API com fallback, validar URL segura e uploads até o limite implementado (8 MB). Revisar o contrato real da galeria.

**Serviços públicos:** respeitar atribuição e política de tiles do OpenStreetMap e limites do Nominatim. A fila/cache do Nominatim é por instalação, não global. Não disparar chamadas automáticas massivas.

## Focos obrigatórios de revisão

1. **Possíveis bugs críticos:** crash ou tela bloqueada após iniciar sem Firebase, sessão antiga restaurada indevidamente, contas Google/API alternadas, favoritos de uma conta aparecendo para outra.
2. **Foto e cadastro:** dois passos, acesso ao JWT, parsing do ID, coincidência ambígua, erro parcial de upload, conteúdo da resposta, refresh dos detalhes, arquivo temporário inexistente, API offline.
3. **UI e ciclo de vida:** context/setState após dispose, snackbar após navegação, `MapController.move` antes de estar anexado, loading/desabilitação de botões, duplicação de requisições, overflow em telas pequenas.
4. **GPS:** políticas/permissões Android, estados de recusa, distância exibida, localização atual não persistida indevidamente.
5. **Firebase:** inicialização Android padrão na branch final (constante `FIREBASE_ENABLED` está com `defaultValue: true`), credenciais e SHA debug, persistência, logout, estados de erro e teste em dispositivo.
6. **Arquitetura:** imports com `lib/controller` e `lib/controllers`, Provider instanciado corretamente, acoplamento para testes, nomenclatura, duplicações e dívida técnica.
7. **Segurança:** `SessionService` guarda JWT em `SharedPreferences` e `logout()` remove token, mas pode deixar e-mail/nome. Verificar exposição intercontas sem afirmar automaticamente que é bug explorável. Validar URLs/arquivos/logs; não exibir tokens.
8. **Testes:** mocks podem não replicar API real. Verificar cobertura dos cenários ruins, testes de widgets, autorização e CI.
9. **Documentação desatualizada:** comentários do `main.dart` ainda sugerem Firebase desativado por padrão, porém branch final o liga por padrão no Android; `README.md` ainda pode citar `lib/controller` como estrutura principal.

Considere esses itens **hipóteses de revisão**, não falhas confirmadas.

## Verificações e limites de evidência

- PR #3 tem workflow “Flutter - análise e testes”, com `flutter pub get`, `flutter analyze`, `flutter test` e `flutter build apk --debug --dart-define=FIREBASE_ENABLED=true`.
- A execução `44221130632` associada ao código antes do arquivo de contexto foi relatada pelo GitHub como concluída com sucesso.
- O commit posterior de documentação iniciou outra execução de CI; **reconsultar o status atual**, não assumir sucesso.
- A compilação debug na nuvem **não comprova** Google Sign-In funcional no Galaxy S23: assinatura debug de CI pode diferir da cadastrada no Firebase.
- Não afirmar que fotos, GPS, favoritos ou rotas foram validados no celular antes de evidência do usuário.

## Fluxo de trabalho do Claude nesta sessão

1. Conferir `pwd`, `git status --short --branch`, `git log -5 --oneline` e `git remote -v`.
2. Revisar a branch `feat/entrega-final-mobile2`, evitando perder alterações locais. Fazer `git fetch origin` apenas se permitido pelo ambiente e sem modificar conteúdo do usuário; pedir instrução se checkout não for seguro.
3. Ler **todo** `docs/CODEX_CONTEXTO_REVISAO_ENTREGA_FINAL.md` e documentação complementar. Comparar `git diff main...HEAD` e investigar os arquivos alterados do PR #3.
4. Reconstituir fluxos ponta a ponta antes de concluir que funcionalidades estão implementadas: Google/API → Home → Cadastro + Foto → Favoritos → GPS/Mapa → Como Chegar → Logout.
5. Se houver Flutter/SDK disponíveis, executar `flutter analyze`, `flutter test`, `git diff --check` e opcionalmente build APK; distinguir resultados próprios dos checks remotos.
6. Sem tocar na API real com POST/DELETE nem usar credenciais privadas; preferir `MockClient`, dependências injetadas e evidência do Swagger.
7. Entregar relatório **em português** com achados ordenados por gravidade; incluir arquivo:linha, cenário, impacto, evidência e correção sugerida. Juntar matriz de requisitos, lacunas de cobertura, verificações executadas e roteiro de teste real.
8. **Encerrar após a auditoria.** Só implementar soluções em nova etapa com aprovação explícita do usuário. Não efetuar merge do PR #3 ou push na `main`.

Comandos locais de referência (PowerShell):

```powershell
cd C:\ProjetosFlutter\explore_turismo
git status --short --branch
git fetch origin
git switch feat/entrega-final-mobile2
git pull --ff-only origin feat/entrega-final-mobile2
git diff main...HEAD --stat
flutter pub get
flutter analyze
flutter test
git diff --check
```

Se a branch ainda não existir localmente, usar `git switch --track origin/feat/entrega-final-mobile2`. **Não executar checkout/pull se existirem alterações locais que possam ser perdidas.**

## Formato esperado da resposta final

1. **Situação:** pronto para teste / pronto para entrega / bloqueado, com critérios observáveis.
2. **Achados concretos:** severidade, arquivo:linha, falha/cenário, evidências e correção recomendada.
3. **Requisitos da professora:** um por linha; implementação, teste existente, teste faltante.
4. **Testes efetivamente executados** e limitações do ambiente.
5. **Plano de correções** priorizado, sem alterar o repositório nesta etapa.
6. **Roteiro de validação no Galaxy S23** de Google, API acadêmica, câmera, upload, favoritos, mapa/GPS, pin com foto, filtros, rotas e logout.

**Última orientação:** o arquivo de contexto do Codex serve também como referência técnica para Claude, mas as afirmações históricas devem ser checadas contra o HEAD atual. Nenhum teste automatizado substitui a apresentação do aplicativo funcionando no celular.
