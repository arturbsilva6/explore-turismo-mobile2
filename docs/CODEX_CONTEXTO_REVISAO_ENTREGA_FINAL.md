# Explore Turismo — Contexto completo e roteiro de revisão para o Codex

> **Atualização de referência:** 18/11/2026 (horário de Brasília).  
> **Fonte:** repositório GitHub, código e documentação das branches `main` e `feat/entrega-final-mobile2`, histórico dos PRs e execuções de CI.  
> **Objetivo:** fornecer contexto suficiente para uma revisão técnica da entrega final de Mobile II. **Este arquivo não certifica o funcionamento no celular.**

## 1. Identificação do projeto e objetivo da revisão

- **Aplicação:** Explore Turismo; nome do pacote Flutter `guia_turismo`.
- **Disciplina:** Mobile II, curso de Sistemas para Internet; projeto acadêmico desenvolvido a partir da base das aulas e ampliado para as entregas.
- **Repositório:** https://github.com/arturbsilva6/explore-turismo-mobile2
- **Pasta local usual (Windows):** `C:\ProjetosFlutter\explore_turismo`.
- **Tecnologia principal:** Flutter/Dart; Flutter 3.47.7 usado no desenvolvimento/CI; SDK Dart no `pubspec.yaml`: `^3.12.1`.
- **Plataforma de demonstração:** Android, com testes anteriores em aparelho físico Samsung Galaxy S23. Não presumir que todos os novos recursos da entrega final já foram testados no aparelho.
- **Objetivo desta solicitação ao Codex:** revisar integralmente o código e principalmente o diff do PR #3, localizar bugs, riscos, integrações incompletas, conflitos arquiteturais, pontos de segurança e lacunas de testes. **Primeiro gerar um relatório; não modificar código, fazer push, criar dados reais nem integrar branches sem autorização.**

## 2. Enunciado oficial da disciplina

**Etapas:** Entrega 1 — Cadastro de lugares com foto; Entrega 2 — Geolocalização; Entrega 3 — Login com Google; Entrega Final — App funcional.

**Obrigatórios:** login Google com persistência de sessão e logout; mapa interativo OpenStreetMap com marcadores dos lugares e respectivas fotos e localização atual por GPS; geolocalização dos lugares cadastrados; favoritos; tratamento de erros; estrutura `lib/screens`, `lib/controllers`, `lib/services`, `lib/models` e `lib/widgets`.

**Pelo menos um extra:** rota “Como Chegar”; compartilhamento nativo; filtros de categoria no mapa; sensores. A branch atual propõe **Como Chegar** e **filtro no mapa**. Ao auditar, separar “código implementado”, “teste automatizado” e “comportamento comprovado em dispositivo”.

## 3. Branches e Pull Requests — estado confirmado em 18/11/2026

| Branch | Papel | Situação conhecida |
| --- | --- | --- |
| `main` | Versão principal estável; contém entregas anteriores + Firebase da aula | PR #1 e #2 integrados; **não contém o PR #3** |
| `feat/mapa-localizacao` | Segunda entrega: mapa, marcadores, geocodificação Nominatim | PR #1 **merged** na `main` |
| `feat/firebase-auth-aula` | Terceira entrega/aula: Firebase Authentication, Google e e-mail/senha | PR #2 **merged** na `main` |
| `feat/entrega-final-mobile2` | Fotos, GPS, favoritos, rotas, filtro de mapa, novo fluxo de login e ajustes | PR #3 **aberto, draft, não integrado** |

Links:
- PR #1: https://github.com/arturbsilva6/explore-turismo-mobile2/pull/1
- PR #2: https://github.com/arturbsilva6/explore-turismo-mobile2/pull/2
- PR #3 (alvo da revisão): https://github.com/arturbsilva6/explore-turismo-mobile2/pull/3

Referências da revisão:
- `main` no início do PR #3: `6020ba7c31b8d4eb20b9d0f85ae963ead309bca3` (merge do PR #2).
- HEAD verificado do PR #3 **antes da criação deste documento**: `19208fdfe8a8c34e9d6f0deba680b01af8467ca6`.
- O PR #3 estava `mergeable=true`, mas isso **não substitui aprovação funcional**. Este arquivo de documentação acrescenta um novo commit à branch; Codex deve conferir o HEAD atualizado ao começar.
- Não apagar branches antigas nem fazer merge do PR #3 antes de o desenvolvedor testar o Android e aprovar.

## 4. Histórico das entregas e últimas alterações

### Base / primeira entrega
- Login pela API acadêmica, listagem e cadastro `GET/POST /lugares` com JWT da própria API.
- Câmera/galeria via `image_picker` e telas de listagem/cadastro/detalhes.
- A câmera antiga mostrava placeholder remoto `https://placehold.co/150x150.png`; o upload de foto não estava completo.

### Segunda entrega — PR #1 (merged)
- Mapa OpenStreetMap via `flutter_map` e `latlong2`, marcadores por latitude/longitude, toque para detalhes.
- Consulta paginada: até 10 páginas de 30 registros, máximo de 300 carregados, deduplicação de IDs, aviso de listagem parcial.
- Busca opcional de endereço/CEP via Nominatim, resultado selecionável, ajuste de ponto no mapa e preenchimento manual de latitude/longitude.
- Temas claro/escuro, validações de coordenadas, tratamentos para erros de API, tiles e consulta, testes.
- **Importante:** pesquisa de endereço/CEP não é GPS do aparelho.

### Terceira entrega / Firebase — PR #2 (merged)
- `firebase_core`, `firebase_auth`, `google_sign_in` 7.x.
- Projeto Firebase `explore-turismo`, app Android `com.example.guia_turismo`, `google-services.json` e `firebase_options.dart` gerado por FlutterFire CLI; SHA-1/SHA-256 de debug registrados para Google Sign-In.
- Fluxo Google, cadastro/login por e-mail e senha, exibição de perfil, logout. Verificações anteriores: `flutter analyze` sem problemas, **36 testes locais aprovados** na fase do PR #2; uso real Google e e-mail/senha testado no aparelho.
- Firebase e API acadêmica **não compartilham tokens**. Na `main` original do PR #2, Firebase era opt-in por `--dart-define=FIREBASE_ENABLED=true`.

### Entrega final — PR #3 (draft, pendente de teste físico)
O código atual da branch propõe:
1. Remoção do placeholder da câmera e estado vazio “Nenhuma foto selecionada”, captura/seleção real, mensagens de erro/cancelamento.
2. Foto no formulário de cadastro. Primeiro cadastra o lugar na API, depois tenta enviar imagem multipart para a galeria. A foto também pode ser anexada posteriormente na tela de detalhes.
3. Miniaturas nos detalhes, lista e marcadores quando o backend fornece imagem; ícone/fallback para lugar sem foto.
4. GPS de primeiro plano sob permissão do usuário, botão “Minha localização GPS”, pin azul e distância em quilômetros.
5. Favoritos pela API acadêmica quando há JWT; armazenamento local `SharedPreferences` para usuário Google/visitante; filtro “Somente favoritos”.
6. Filtro de categorias na tela do mapa.
7. Extra obrigatório “Como chegar” via navegador/app externo do Google Maps.
8. Login Google direto na entrada, tentativa de restaurar sessão Firebase no início e logout na Home.
9. Organização `lib/controllers`; a pasta `lib/controller` permanece como camada de reexportação para imports legados.
10. Testes novos em `test/entrega_final_test.dart` e `test/galeria_gps_test.dart`.

**Não declarar a entrega final concluída apenas com base nos testes de CI.** Falta confirmação manual no dispositivo físico dos novos fluxos.

## 5. Arquitetura e arquivos para leitura prioritária

A aplicação usa Flutter + `Provider/ChangeNotifier`; não confundir “controller” do app com endpoints HTTP.

| Área | Arquivos de referência e responsabilidades |
| --- | --- |
| Bootstrap e dependências | `lib/main.dart`, `pubspec.yaml`, `lib/firebase_options.dart` |
| Autenticação acadêmica | `lib/screens/login_screen.dart`, `lib/controllers/auth_controller.dart`, `lib/services/auth_service.dart`, `lib/services/session_service.dart` |
| Autenticação Firebase | `lib/services/firebase_auth_service.dart`, `lib/screens/firebase_login_screen.dart` |
| Estado e navegação | `lib/screens/home_screen.dart`, `lib/controllers/theme_controller.dart`, `lib/themes/` |
| Lista/cadastro e API | `lib/screens/cadastro_lugar.dart`, `lib/controllers/lugares_controller.dart`, `lib/services/lugares_services.dart` |
| Modelo e imagens | `lib/models/lugares_model.dart`, `lib/widgets/lugar_foto.dart` |
| Upload de foto | `lib/services/galeria_service.dart`, `lib/screens/detalhe_lugar_screen.dart` |
| Câmera | `lib/screens/camera_screen.dart`, `lib/controllers/camera_controller.dart` |
| Mapa/GPS/rota | `lib/screens/mapa_screen.dart`, `lib/services/localizacao_atual_service.dart`, `lib/services/rotas_service.dart` |
| Busca de endereço/CEP | `lib/widgets/busca_localizacao.dart`, `lib/services/geocodificacao_service.dart` e implementação Nominatim, `lib/screens/selecionar_localizacao_screen.dart` |
| Favoritos | `lib/controllers/favoritos_controller.dart`, `lib/services/favoritos_service.dart` |
| Android/iOS | `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `android/settings.gradle.kts`, `ios/Runner/Info.plist` |
| Testes/automação | `test/`, `.github/workflows/flutter-checks.yml` |
| Documentação existente | `README.md`, `SEGUNDA_ENTREGA.md`, `FIREBASE_AULA.md`, `ENTREGA_FINAL.md`, `docs/geocodificacao.md` |

Dependências relevantes no PR #3: `http`, `http_parser`, `provider`, `shared_preferences`, `image_picker`, `flutter_map` 8.3.2, `latlong2` 0.10.1, `firebase_core`, `firebase_auth`, `google_sign_in`, `geolocator` 14.1.2 e `url_launcher` 6.3.3. Verificar versões efetivas no `pubspec.lock`.

## 6. Integrações e contratos externos

### API acadêmica

- Base: `https://guia.liliaborges.com.br`; documentação Swagger: `https://guia.liliaborges.com.br/api-docs/`.
- `GET /lugares`: consulta paginada; os filtros por nome/categoria são locais sobre o subconjunto carregado, até 300 lugares.
- `POST /lugares`: requer `Authorization: Bearer <JWT da API>`; corpo JSON com `nome`, `descricao`, `latitude`, `longitude` e `categoriaId`; sucesso esperado HTTP 201.
- `POST /lugares/{id}/galeria`: upload multipart, campo `foto`, JWT da API; verificar o contrato real e os formatos de resposta no Swagger/servidor de teste.
- `GET /favoritos` e `POST/DELETE /favoritos/{id}`: sincronização de favoritos com JWT da API; conferir a estrutura de JSON/IDs com o contrato efetivo, não só com mocks.
- Cadastro e foto são duas operações distintas. Se `POST /lugares` não devolver o ID, o controller procura um **único** item novo de mesmo nome e coordenadas compatíveis. Caso não encontre correspondência inequívoca, **não envia imagem a outro registro**; orienta anexar a foto depois.
- Evitar POSTs de teste na API real durante revisão automatizada; usar `MockClient`/serviços falsos, a menos que o desenvolvedor autorize um ambiente de testes.

### Firebase e Google

- Firebase autentica usuário Google/e-mail/senha; o **ID token Firebase não é JWT da API acadêmica**.
- Na branch de entrega final, `main.dart` define `FIREBASE_ENABLED` com `defaultValue: true` e inicializa Firebase por padrão **somente no Android**; falhas de inicialização caem para a API acadêmica.
- A tela de entrada oferece Google diretamente; após login Firebase sem credencial da API, pode visualizar locais públicos, mas **não deve cadastrar lugar, foto nem usar JWT inexistente**.
- O app também mantém o fluxo de login da API e troca de sessão entre os provedores. Verificar consistência ao alternar contas, sair, fechar/abrir, perder conectividade e passar de “visitante” para autenticado.
- Google Sign-In real depende de configuração OAuth e do SHA correspondente à assinatura do APK. **APK debug do CI usa assinatura diferente** daquela registrada no computador do desenvolvedor.
- Não expor credenciais, tokens, arquivos locais com segredos nem logs sensíveis no relatório.

### Mapa, GPS, Nominatim e rotas

- Mapa com tiles HTTPS e atribuição OpenStreetMap; verificar licenças e política dos serviços.
- Geocodificação Nominatim somente por ação explícita, sem autocomplete; cache previsto de sete dias/50 consultas e fila local de uma requisição por segundo. Isto **não fornece limite agregado entre múltiplos usuários**.
- GPS: `geolocator`; permissão somente em primeiro plano; sem tracking em background. O manifesto Android inclui `ACCESS_COARSE_LOCATION` e `ACCESS_FINE_LOCATION`.
- Rotas: `RotasService` constrói URL HTTPS Google Maps `/maps/dir/?api=1&destination=...` e usa `url_launcher`; tratar quando não houver app/handler.
- Miniaturas: `LugaresModel.extrairFotoUrl` tenta campos de imagem ou `galeria` e admite HTTPS ou caminho relativo resolvido sob a API. Verificar dados reais, sanitização/host e falhas de rede.
- Categorias cadastradas no app estão atualmente fixadas em cinco IDs; a opção de consultar `GET /categorias` dinamicamente permanece melhoria proposta.

## 7. Evidências de validação e o que continua pendente

- PR #2: 36 testes Flutter locais aprovados e `flutter analyze` limpo; login Google e e-mail/senha testados no Android físico; fluxo de API original revalidado pelo desenvolvedor.
- PR #3: último workflow encontrado para o HEAD `19208fd...`: **“Flutter - análise e testes” concluído com sucesso** (run `44221130632`); inclui `flutter pub get`, `flutter analyze`, `flutter test` e `flutter build apk --debug --dart-define=FIREBASE_ENABLED=true`.
- URL para CI: https://github.com/arturbsilva6/explore-turismo-mobile2/actions/runs/44221130632
- **Esses checks são anteriores ao commit que adiciona este documento**; verificar checks do novo HEAD se houver mudança de status.
- Novos testes cobrem URI/validação de rotas, leitura/filtro de URLs de imagens, API de favoritos simulada, favoritos locais, captura de ID do cadastro, estado vazio da câmera, upload multipart mockado, falha HTTP e cálculo de distância.
- Pendente: execução manual completa da entrega final no Galaxy S23, incluindo GPS/permissões, foto+cadastro+upload real autorizado, miniaturas, Google pós-reinício, logout/troca de contas, favoritos persistidos, mapa, filtros e rotas.
- Pendente: confirmar se `flutter test` na máquina do desenvolvedor e se o build instalado no dispositivo reproduzem os checks do CI após este conjunto de alterações.

## 8. Pontos críticos para revisão do Codex (hipóteses, não defeitos confirmados)

**P0/P1 — comportamento e dados**
1. **Separação de autenticações:** verificar se a restauração de sessão Firebase, logout da API, troca de contas e sessão persistente podem expor favoritos/dados de outra conta ou levar a telas protegidas indevidamente. Inspecionar `SessionService`: o JWT fica em `SharedPreferences` e `logout()` remove apenas `token`; avaliar riscos, limpeza de dados de perfil e storage seguro sem quebrar a atividade.
2. **Persistência Firebase:** confirmar que `initialRoute` é decidido após inicialização e restauração de sessão; verificar comportamento se Firebase falhar/desabilitado, logins Google e API coexistirem e Google sign-out falhar.
3. **Fluxo cadastro + foto:** verificar duas etapas, identificação de ID em respostas variadas, lista incompleta/paginada, concorrência, foto selecionada e caminho temporário, falha parcial do upload e mensagens de sucesso. Evitar vincular a imagem ao lugar errado.
4. **Contrato remoto:** conferir `GET/POST/DELETE /favoritos`, `POST /lugares/{id}/galeria` e JSON de `GET /lugares` com o Swagger. Testes atuais usam mocks; não supor que o servidor real responde igual.
5. **Favoritos e múltiplas contas:** validar chave por identidade, sincronização remota/local, erros offline, mudanças de conta, IDs removidos e estado consistente quando API falha.
6. **GPS:** verificar permissões negadas/permanentes, GPS desligado, timeout, coordenadas válidas, chamadas de `MapController.move` somente quando anexado, filtros ativos e telas de mapa sem lugares.
7. **Imagens:** verificar origem/segurança de URLs, falha de download, placeholders locais, uso real das miniaturas no mapa, tamanho/performance, arquivo da câmera/galeria e política de 8 MB.
8. **Tratamento de erros e UI:** assegurar que operações assíncronas não disparem `setState`/`context` após dispose, que loading/erro/vazio estejam corretos e que não haja ações duplicadas.

**P2 — qualidade, arquitetura e manutenção**
9. Verificar estrutura `lib/controllers` e compatibilidade dos reexports `lib/controller`; imports, acoplamento, dependências injetáveis para testes e descarte de `ChangeNotifier`.
10. Verificar acessibilidade, temas, navegação (incluindo retorno do mapa e back), semântica de ícones, overflow em tela pequena e funcionamento offline.
11. Eliminar comentários/documentação desatualizados com cautela: `main.dart` ainda possui comentário de Firebase “desativado por padrão”, porém a constante da branch final usa `defaultValue: true`; `README.md` também mantém seção antiga de organização em `lib/controller`.
12. Verificar segurança e privacidade: localização solicitada só após ação explícita, autenticações distintas, nenhuma credencial em Git, armazenamento de JWT, logs, validação de URLs e permissões mínimas. Distinguir requisitos acadêmicos de hardening de produção.
13. Rever política de tiles OSM e Nominatim para uso acadêmico. Não transformar isso em bloqueador da entrega sem evidência de violação no cenário de demonstração.

## 9. Procedimento recomendado ao Codex

1. Localizar o repositório; rodar `git status --short --branch` e `git remote -v`. Se estiver em `main`, trocar explicitamente para `feat/entrega-final-mobile2` **sem descartar alterações locais não commitadas**. Se não houver branch local, usar `git fetch origin` e `git switch --track origin/feat/entrega-final-mobile2`.
2. Confirmar `git log -5 --oneline`, `git diff main...feat/entrega-final-mobile2 --stat` e depois o diff completo. Distinguir código herdado na `main` de mudanças introduzidas no PR #3.
3. Ler este arquivo, `ENTREGA_FINAL.md`, `README.md`, `SEGUNDA_ENTREGA.md`, `FIREBASE_AULA.md`, `pubspec.yaml` e o workflow.
4. Mapear fluxos ponta a ponta (Login Google/API → Home → Lista/Cadastro → Foto → Favoritos → Mapa/GPS → Rota → Logout). Verificar contratos de dados antes de sugerir correções.
5. Se as ferramentas estiverem disponíveis, executar `flutter pub get`, `flutter analyze`, `flutter test`, `git diff --check`; opcionalmente `flutter build apk --debug`. Não alegar execução se a ferramenta não estiver disponível. Registrar versão do Flutter e saída dos comandos.
6. Priorizar testes que faltam; adicionar recomendações de testes unitários/widget/integrados, inclusive erros, login/troca de contas, upload parcial e geolocalização. Não efetuar chamadas com efeitos colaterais na API real.
7. Fazer **revisão somente de leitura** nesta primeira passagem. Se forem necessárias correções, propor patches e uma ordem segura, pedindo autorização antes de editar, fazer commit, push, publicar PR ou merge.
8. Não atualizar `main`, não fazer force-push, não apagar branches, não alterar Firebase Console e não inserir credenciais em arquivos ou logs.

Comandos base (PowerShell, a partir do repositório; confirmar branch antes):

```powershell
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

Se ainda não existir branch local, usar `git switch --track origin/feat/entrega-final-mobile2` no lugar de `git switch feat/entrega-final-mobile2`.

## 10. Formato solicitado para o relatório de revisão

Retornar o relatório em português, **não apenas “os testes passaram”**:

1. **Resumo executivo:** prontidão real para a entrega final; o que foi comprovado versus o que depende de teste físico.
2. **Tabela de achados:** severidade (bloqueante/alta/média/baixa), arquivo:linha, descrição concreta, cenário de reprodução, impacto e correção sugerida. Não classificar como bug algo sem evidência.
3. **Matriz de requisitos:** para cada exigência da professora, indicar código relevante, evidências/testes e pendência.
4. **Fluxos críticos:** Google/JWT, upload após cadastro, GPS, favoritos, rotas, marcadores com fotos, sessão e logout.
5. **Testes executados:** comandos e resultados reais; testes adicionais recomendados.
6. **Plano priorizado de correções:** ordem, dependências, esforço qualitativo e risco de regressão; preservar API acadêmica e as entregas anteriores.
7. **Checklist final para Galaxy S23:** passos reproduzíveis para verificar tudo em dispositivo real.
8. **Conclusão:** “pronto para teste”, “pronto para entrega” ou “bloqueado”, com justificativa técnica.

## 11. Critérios para considerar pronto para entrega

- Entrar com Google, restaurar sessão após reiniciar e sair de forma consistente.
- Preservar login/API acadêmica, listagem e cadastro com JWT válido.
- Tirar/selecionar foto sem placeholder remoto; salvar e recuperar foto de lugar com resultado confiável; falhas de upload devem ser comunicadas honestamente.
- Mapa OSM mostra pinos e fotos quando realmente disponíveis; localização GPS atual tem pin distinto e solicita permissão corretamente.
- Favoritos funcionam, persistem e não vazam entre contas.
- Extra “Como chegar” ou filtro no mapa funcionando em aparelho real.
- Erros comuns não provocam encerramentos inesperados.
- Estrutura requerida de pastas e testes/CI coerentes com o código.
- GitHub atualizado **somente após aprovação do desenvolvedor** e demonstração do app funcionando.

---

**Importante para Codex:** este documento é um mapa do projeto, **não uma substituição à leitura do código e das respostas reais da API**. Confirme afirmações técnicas no HEAD atual antes de emitir um parecer.