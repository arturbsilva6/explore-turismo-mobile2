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

## Executar no computador

```bash
flutter pub get
flutter run
```

Entre com uma conta válida da API. Acesse **Lugares > Novo lugar** para cadastrar.
Os campos enviados são `nome`, `descricao`, `latitude`, `longitude` e
`categoriaId`. O app espera resposta HTTP **201** ao cadastrar.

## Limitações conhecidas

- A busca e os filtros são feitos sobre a página carregada da API (atualmente
  até 30 lugares), não em todos os registros do servidor.
- As opções de categoria do formulário e do filtro refletem as cinco categorias
  existentes na API na data de desenvolvimento. Carregamento dinâmico de
  categorias é uma melhoria futura.
- A câmera seleciona fotos, mas o envio para a galeria da API ainda não está
  implementado.
- A aplicação foi preparada a partir de código de aula; os ajustes e as
  funcionalidades adicionais devem ser revisados e testados no emulador.

## Organização

- `lib/models` — dados e conversão JSON
- `lib/services` — chamadas HTTP e persistência de sessão
- `lib/controller` — estado e integração entre serviços e telas
- `lib/screens` — interface, formulário, lista e detalhes
- `lib/themes` — tema e cores

## Próximos passos

1. Validar o fluxo de login/cadastro/listagem no emulador.
2. Implementar categorias diretamente pelo endpoint `GET /categorias`.
3. Implementar paginação e pesquisa no servidor, se necessário.

## Créditos acadêmicos

A estrutura inicial é derivada de exercícios e exemplos da disciplina Mobile II.
As contribuições de cada integrante devem ser informadas de forma verdadeira
na entrega e no histórico de commits.
