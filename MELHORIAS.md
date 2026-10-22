# Melhorias para a primeira entrega

Este documento serve para auxiliar a explicação do projeto na apresentação.

## 1. Busca de lugares (`lib/screens/cadastro_lugar.dart`)

- O `TextField` atualiza `_termoBusca` usando `setState`.
- A lista usa `.where()` para pesquisar o nome sem diferenciar maiúsculas e minúsculas.
- A busca não chama a API outra vez: filtra apenas os registros carregados.

## 2. Filtro por categoria (`lib/screens/cadastro_lugar.dart`)

- Um `DropdownButton` define `_categoriaFiltro`.
- O filtro combina nome e `categoriaId`; as duas condições precisam ser verdadeiras.
- A opção *Todas* remove o filtro por categoria.

## 3. Detalhes (`lib/screens/detalhe_lugar_screen.dart`)

- Tocar em um lugar abre uma nova tela com `Navigator.push`.
- A tela recebe um objeto `LugaresModel` no construtor.
- O botão *Copiar coordenadas* usa o `Clipboard` do Flutter.

## 4. Início (`lib/screens/home_screen.dart`)

- A aba inicial deixou de ser uma tela vazia.
- Os cards acionam callbacks que mudam a aba atual, sem duplicar telas.
- A paleta da aplicação usa verde-azulado em `theme_controller.dart`.

## 5. Integração com a API (preservada)

- `LugaresController` solicita os dados para `LugaresServices`.
- O `POST /lugares` envia os 5 campos aceitos pela documentação.
- O token JWT é recuperado de `SessionService`.
- Após salvar, o controller recarrega a lista de lugares.

**Observação:** não afirme que um recurso foi executado/testado se você ainda não
conferiu no emulador. Dê crédito à base fornecida em aula e ao trabalho do grupo.
