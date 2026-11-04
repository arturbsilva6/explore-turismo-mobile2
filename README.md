# Explore Turismo — aplicativo Flutter

Projeto acadêmico da disciplina **Mobile II**. A base foi desenvolvida a partir
dos exemplos utilizados em aula, com trabalho em equipe, e foi ampliada com
melhorias na navegação, pesquisa de lugares, detalhes e interface visual.

## Tecnologias

- Flutter e Dart
- Provider / ChangeNotifier para gerenciamento de estado
- HTTP para consumir a API do Guia de Turismo
- `shared_preferences` para armazenar a sessão do usuário
- `image_picker` para câmera e galeria
- `flutter_map` 8.3.2 e `latlong2` 0.10.1 para mapas e coordenadas
- OpenStreetMap para tiles e Nominatim para geocodificação
- `http_parser` para interpretar o cabeçalho HTTP `Retry-After`

## Funcionalidades

- Login e integração com a API `https://guia.liliaborges.com.br`
- Consulta de lugares (`GET /lugares`)
- Cadastro de lugares (`POST /lugares`) autenticado com Bearer token
- Validação de nome, latitude e longitude antes do envio
- **Busca local por nome** entre os lugares carregados
- **Filtro local por categoria** entre os lugares carregados
- **Detalhes do lugar** com descrição e coordenadas copiáveis
- **Atualização da lista** com gesto de puxar para baixo e botão de atualizar
- **Página inicial própria** com atalhos para os recursos existentes
- Tema claro/escuro e acesso à câmera/galeria (sem upload de imagens ainda)
- **Mapa interativo** com marcadores dos lugares com coordenadas válidas,
  nome/categoria e acesso aos detalhes
- **Paginação da API** com até dez páginas de 30 lugares, remoção de IDs
  repetidos e aviso quando o resultado for parcial
- **Busca opcional por endereço ou CEP no cadastro**, somente pelo botão
  **Buscar localização**, com seleção entre até cinco resultados
- **Ajuste do marcador por toque no mapa** e confirmação para preencher latitude
  e longitude; os campos continuam editáveis manualmente
- Tratamento de carregamento, vazio, coordenadas inválidas e falhas de rede

Consulte [SEGUNDA_ENTREGA.md](SEGUNDA_ENTREGA.md) para os objetivos, funcionamento,
resultados das verificações e evidências relatadas no Android.

## Executar no computador

```bash
flutter pub get
flutter devices
flutter run
```

Entre com uma conta válida da API. Acesse **Lugares > Novo lugar** para cadastrar.
Os campos enviados são `nome`, `descricao`, `latitude`, `longitude` e
`categoriaId`. O app espera resposta HTTP **201** ao cadastrar.

Para conferir a localização sem gravar dados: abra **Lugares > Novo lugar**,
pesquise endereço/CEP, escolha um resultado, ajuste o marcador e confirme.
Confira latitude/longitude e feche o formulário com **Cancelar**.

## Verificações automatizadas

```bash
flutter analyze
flutter test
git diff --check
git status
```

Os testes usam HTTP simulado e tiles em memória. O teste de cadastro confere
o Bearer token e o corpo do POST sem enviar requisições à API real.

## OpenStreetMap e Nominatim

A busca não usa autocomplete, identifica o aplicativo e mantém cache local
por sete dias, com até 50 consultas. A fila compartilhada no processo limita
as chamadas a uma requisição por segundo. Ambos os mapas exibem atribuição
OpenStreetMap e usam tiles HTTPS, cache nativo e nenhum download antecipado.

**O limite do Nominatim é agregado por aplicação, somando todos os usuários.**
O acesso direto desta entrega é destinado à avaliação acadêmica em uma
instalação. Antes de distribuir a vários usuários, é necessário configurar
proxy com cache e limite global ou contratar outro provedor. A abstração do
serviço permite a troca; configuração remota e proxy ainda não foram implantados.

Leia a [política do Nominatim](https://operations.osmfoundation.org/policies/nominatim/),
a [política de tiles](https://operations.osmfoundation.org/policies/tiles/) e os
[detalhes de configuração](docs/geocodificacao.md). Não envie dados pessoais ou
confidenciais nas buscas.

## Limitações conhecidas

- A busca por nome e os filtros são locais, sobre os lugares carregados
  (até 300). Se o servidor repetir páginas, ignorar o tamanho solicitado ou a
  consulta atingir o limite seguro, a interface informa que o resultado é parcial.
- A precisão de endereço/CEP depende da cobertura do OpenStreetMap. O resultado
  pode indicar uma região; o usuário deve conferir e ajustar o marcador.
- A interface acompanha o tema claro/escuro. Os tiles padrão do OpenStreetMap
  mantêm o estilo cartográfico claro, inclusive quando o app usa tema escuro.
- As opções de categoria do formulário e do filtro refletem as cinco categorias
  existentes na API na data de desenvolvimento. Carregamento dinâmico de
  categorias é uma melhoria futura.
- A câmera seleciona fotos, mas o envio para a galeria da API ainda não está
  implementado.
- O usuário relatou teste do mapa, marcadores e acesso aos detalhes no emulador
  Android. A busca e o ajuste de coordenadas possuem testes automatizados; a
  validação manual completa desta etapa e das correções finais continua recomendada.

## Organização

- `lib/models` — dados e conversão JSON
- `lib/services` — chamadas HTTP e persistência de sessão
- `lib/controller` — estado e integração entre serviços e telas
- `lib/screens` — interface, formulário, lista e detalhes
- `lib/themes` — tema e cores
- `lib/widgets` — busca de localização reutilizável no formulário
- `test` — testes de serviços, validação e interface

## Próximos passos

1. Conferir o fluxo completo de localização no emulador após a revisão final.
2. Implementar categorias diretamente pelo endpoint `GET /categorias`.
3. Configurar proxy/configuração remota antes de uso simultâneo por vários usuários.

## Créditos acadêmicos

A estrutura inicial é derivada de exercícios e exemplos da disciplina Mobile II.
As contribuições de cada integrante devem ser informadas de forma verdadeira
na entrega e no histórico de commits.
