# Segunda entrega — Mobile II — Explore Turismo

Branch de desenvolvimento: `feat/mapa-localizacao`. Destino do Pull Request:
`main`. Revisão realizada em **04/11/2026**.

## Objetivos da atividade

Ampliar o aplicativo da primeira entrega com mapa dos destinos cadastrados e
busca de localização durante o cadastro. Preservar login, câmera/galeria,
listagem, filtros, detalhes, cadastro autenticado e identidade verde-azulada.
Manter a arquitetura Flutter com Provider, ChangeNotifier, controllers, models,
services e screens, sem migrar as funcionalidades existentes.

## Tecnologias utilizadas

- Flutter/Dart, Material 3 e temas derivados de `ColorScheme`.
- Provider e ChangeNotifier para compartilhar e atualizar o estado.
- `flutter_map` 8.3.2 e `latlong2` 0.10.1.
- `http` para API de lugares e Nominatim; `http_parser` para datas HTTP.
- `shared_preferences` para a sessão existente e cache local de geocodificação.
- OpenStreetMap para tiles; Nominatim para endereço/CEP.
- `flutter_test`, `MockClient` e tiles em memória para testes sem gravações reais.
- `image_picker` permanece responsável pela câmera/galeria da primeira entrega.

## Mapa e marcadores

A aba **Mapa** foi acrescentada ao HomeScreen, preservando os índices de Início,
Câmera e Lugares. `MapaScreen` observa o `LugaresController` existente e utiliza
`LugaresModel`. O serviço consulta `GET https://guia.liliaborges.com.br/lugares`
com `pagina` e `limite=30`.

São consultadas até dez páginas, com prazo total de 60 segundos e timeout de
até 20 segundos por requisição. IDs repetidos são removidos. Páginas repetidas,
respostas com mais itens que o solicitado e o limite de páginas interrompem a
consulta e geram aviso de exibição parcial. São mantidos no máximo 300 lugares.
Respostas fora do contrato esperado geram erro controlado, sem assumir sucesso.

Cada lugar com latitude e longitude finitas nos intervalos [-90, 90] e
[-180, 180] recebe um marcador. Coordenadas ausentes, texto inválido, NaN,
infinito ou valores fora dos intervalos não são plotados; o restante da lista
continua disponível. O enquadramento inicial considera os pontos carregados.

Ao tocar em um marcador, o app mostra nome e categoria e oferece **Ver detalhes**,
abrindo `DetalheLugarScreen` com o objeto já carregado. Há estados de carregamento,
lista vazia, ausência de coordenadas válidas, erro da API e falha dos tiles.

## Busca por endereço ou CEP

No formulário **Lugares > Novo lugar**, a busca é opcional. O usuário informa um
endereço ou CEP e toca em **Buscar localização**. Digitar não dispara chamadas;
não existe autocomplete. Até cinco resultados são exibidos para escolha.

Endereços usam o parâmetro `q`; CEPs brasileiros de oito dígitos, com ou sem
hífen, usam `postalcode` e `countrycodes=br`. A resposta é solicitada em JSONv2
e português. Consultas vazias/muito curtas, buscas sem resultados, coordenadas
inválidas, JSON inesperado, erro HTTP e falha de conexão possuem tratamento.

Escolher um resultado abre `SelecionarLocalizacaoScreen`. O usuário visualiza o
ponto, toca no mapa para ajustar o marcador e confirma com **Usar estas
coordenadas**. Somente a confirmação transfere latitude e longitude ao formulário;
voltar cancela a seleção e preserva os valores anteriores. Os campos continuam
editáveis manualmente e aceitam vírgula decimal.

## Envio das coordenadas à API

O mapa não cadastra lugares. O cadastro continua dependendo do botão **Salvar**
e da validação do formulário. `LugaresController` obtém o token da sessão atual
e chama `LugaresServices.cadastrarLugar`.

O POST usa `Content-Type: application/json` e `Authorization: Bearer <token da
sessão>`. O corpo contém somente `nome`, `descricao`, `latitude`, `longitude` e
`categoriaId`. As coordenadas são números JSON. O serviço também bloqueia
coordenadas inválidas e token vazio antes de acessar a rede. O sucesso esperado
é HTTP 201; após a confirmação, o controller atualiza a lista.

Nenhuma credencial real é incluída nos exemplos ou testes. O teste de POST usa
credencial explicitamente fictícia e intercepta a requisição com `MockClient`.

## Identidade visual e preservação da primeira entrega

Os componentes novos utilizam as cores do tema atual, inclusive superfícies,
textos, botões e marcadores. A identidade verde-azulada existente é mantida.
A cartografia padrão do OpenStreetMap continua clara em ambos os temas.

Login, sessão, câmera, galeria, arquivos de tema e detalhes foram preservados.
A busca local por nome, filtro de categoria e atualização da lista permanecem
disponíveis. A navegação inferior usa quatro abas fixas com seus rótulos visíveis.

## Políticas do OpenStreetMap e Nominatim

Referências: [política do Nominatim](https://operations.osmfoundation.org/policies/nominatim/)
e [política de tiles](https://operations.osmfoundation.org/policies/tiles/).

- Tiles: URL HTTPS oficial, `userAgentPackageName=br.exploreturismo.mobileii`,
  cache nativo do flutter_map e `panBuffer=0`. Sem downloads em lote, prefetch,
  uso offline ou cabeçalhos para ignorar o cache. Atribuição visível nos dois
  mapas, com acesso ao texto de licença e endereço de copyright.
- Geocodificação: `User-Agent: ExploreTurismo-MobileII/1.0 (Flutter Android)`,
  clique explícito, sem autocomplete nem repetição automática. Cache persistente
  de sete dias com até 50 consultas, incluindo buscas vazias.
- Fila estática compartilhada entre instâncias no processo com intervalo mínimo
  de um segundo. HTTP 429/503 aplica pausa de acordo com `Retry-After` em segundos
  ou data HTTP, com fallback de 60 segundos. Timeout de 15 segundos.
- Atribuição Nominatim/OpenStreetMap/ODbL no formulário. A interface não solicita
  localização do aparelho nem permissão de GPS. Não envie informações pessoais
  ou confidenciais nas consultas.

**Limitação para múltiplos usuários:** o limite público de uma requisição por
segundo soma o tráfego de toda a aplicação. A fila Flutter limita somente uma
instalação/processo; não coordena outros aparelhos nem reinícios do aplicativo.
O acesso direto desta entrega destina-se à avaliação acadêmica em uma instalação.
Antes de uso simultâneo por vários usuários, é necessário proxy com cache e fila
global ou outro provedor que permita esse volume.

`GeocodificacaoService` separa o contrato do provedor. `NominatimService` aceita
`resolverEndpoint` e a preferência `geocodificacao_endpoint`, lida a cada busca,
para apontar a um endpoint HTTPS compatível. O proxy e a configuração remota
hospedada ainda não foram implantados. Essa configuração operacional deve existir
antes da distribuição para permitir a troca do serviço sem atualizar o app.
Mais detalhes em [docs/geocodificacao.md](docs/geocodificacao.md).

## Executar e testar

Pré-requisitos: Flutter compatível com o SDK Dart `^3.12.1`, Android SDK,
emulador/dispositivo disponível e conexão com a internet para o teste manual.

```bash
git switch feat/mapa-localizacao
flutter pub get
flutter devices
flutter run -d <identificador-do-dispositivo-android>
```

Use uma conta válida da API, sem registrar credenciais no repositório. Para
conferir esta entrega sem alterar o backend:

1. Abra **Mapa**, toque em um marcador e acesse os detalhes.
2. Alterne o tema e confira contraste e atribuição.
3. Abra **Lugares > Novo lugar** e pesquise um endereço/CEP público conhecido.
4. Selecione o resultado, ajuste o ponto no mapa e confirme.
5. Confira latitude/longitude e edite manualmente para verificar que continuam livres.
6. Confira entradas inválidas, ausência de resultados e falha de conexão.
7. Feche com **Cancelar**; não envie um cadastro real para testar esta revisão.

```bash
flutter pub get
flutter analyze
flutter test
git diff --check
git status
```

Os testes automatizados não consultam Nominatim, não baixam tiles públicos e
não criam nem alteram registros na API real.

## Resultados reais da revisão

| Verificação | Resultado |
| --- | --- |
| Branch | `feat/mapa-localizacao`, sem checkout ou merge em `main` |
| `flutter pub get` | Executado com sucesso; 14 dependências têm versões mais recentes fora das restrições atuais, sem impedir a resolução |
| `flutter analyze` | Executado com sucesso: `No issues found!` |
| `flutter test` | 33 testes aprovados, incluindo cadastro autenticado simulado |
| `git diff --check` | Executado com sucesso, sem erros de whitespace; avisos de conversão LF/CRLF esperados no Windows |
| `git status` | Conferido antes dos commits: somente código, testes, dependências, registros de plugins e documentação da entrega; sem temporários ou credenciais reais |

A primeira execução de análise durante esta revisão apontou um getter incorreto
no novo teste de tiles e um aviso de estilo; ambos foram corrigidos antes dos
commits. Os testes passaram após as correções. Os avisos informativos do
flutter_map sobre políticas de tiles são esperados e não representam falha.

Cobertura: paginação, limites, duplicatas, resposta inesperada, coordenadas,
cache, endereço, CEP, identificação HTTP, pausa por excesso de uso, ausência de
autocomplete, estados da interface, temas, navegação dos marcadores, ajuste no
mapa, cancelamento, transferência ao formulário e POST autenticado simulado.

### Evidência no Android

O usuário relatou que **a tela de mapa, os marcadores e a navegação para detalhes
foram implementados e testados no emulador Android**. Esse relato não equivale
a uma nova execução manual pelo agente após a revisão final. Não foram fornecidas
capturas, logs ou confirmação manual do fluxo completo de geocodificação.
Os testes de widgets validam seleção, ajuste, cancelamento e preenchimento;
recomenda-se conferir o fluxo completo no emulador após as últimas correções.

## Limitações e pendências

- Proxy global e configuração remota pendentes para múltiplos usuários.
- Disponibilidade dos serviços públicos sem garantia; o cache não implementa
  modo offline e a precisão de endereço/CEP depende da cobertura cartográfica.
- Máximo de 300 lugares por consulta; filtros locais não pesquisam todo o backend.
- Categorias continuam com os cinco IDs da base; carregamento dinâmico é futuro.
- Fotos da câmera/galeria continuam sem upload para a API, como na primeira entrega.
- A sessão mantém o armazenamento em SharedPreferences da base. Armazenamento
  seguro de credenciais em produção permanece uma melhoria futura.
- Validação manual completa de geocodificação e das correções finais no Android
  ainda não foi relatada pelo usuário.
- Integração do Pull Request à `main` depende de aprovação do usuário. Não fazer
  merge automático, force push ou exclusão de branches.

## Créditos acadêmicos

A estrutura inicial é derivada de exercícios e exemplos da disciplina Mobile II,
com trabalho em equipe, conforme os créditos preservados no README e na primeira
entrega. As contribuições de cada integrante devem ser informadas de forma
verdadeira na entrega e no histórico de commits.
