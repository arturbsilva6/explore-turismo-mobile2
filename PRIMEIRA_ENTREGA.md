# Primeira entrega — Cadastro de lugares (Mobile II)

## Requisito
Cadastro de lugares funcional e integrado à API da disciplina.
Swagger: https://guia.liliaborges.com.br/api-docs/

## Fluxo implementado
1. Fazer login no aplicativo (necessário obter token Bearer).
2. Abrir **Locais** na barra inferior e tocar no botão **+**.
3. Preencher nome, descrição, categoria, latitude e longitude.
4. Validar campos (nome, número e intervalo das coordenadas).
5. Enviar `POST https://guia.liliaborges.com.br/lugares` com `Authorization: Bearer <token>`.
6. Em HTTP 201, mostrar mensagem e recarregar `GET /lugares?pagina=1&limite=10`.

## Corpo enviado na requisição POST
```json
{
  "nome": "Exemplo de lugar",
  "descricao": "Descrição da atração",
  "latitude": -23.4699,
  "longitude": -45.0617,
  "categoriaId": 1
}
```

> Não enviar `id` ou `categoria`: esses campos não fazem parte do exemplo de criação documentado.

## Como testar no seu computador
```bash
flutter pub get
flutter run
```
Faça login e cadastre um lugar real de teste autorizado pela turma/professora.
Cheque se o aplicativo exibe confirmação e se o lugar aparece na lista.
Para conferir o backend, consulte `GET /lugares` (paginado); o cadastro pode aparecer na página 1 se a ordenação for do mais recente para o mais antigo.

## Testes manuais sugeridos
- Nome em branco: deve bloquear.
- Latitude vazia ou com letras: deve bloquear.
- Latitude fora do intervalo -90 a 90: deve bloquear.
- Longitude fora de -180 a 180: deve bloquear.
- Valores com vírgula decimal: devem ser aceitos.
- Categoria escolhida: deve usar o ID correspondente.
- Login válido: cadastro deve mostrar sucesso HTTP 201 e atualizar a lista.
- Token ausente/expirado: deve mostrar erro sem fechar o cadastro.
- API indisponível: deve exibir erro e permitir nova tentativa.

## Observações
- Os IDs de categorias 1..5 conferiam com `GET /categorias` em 22/10/2026; se a API for alterada, deve-se buscar as categorias dinamicamente.
- Esta versão foi revisada estaticamente; não foi possível executar Flutter neste ambiente. Teste no emulador ou celular antes da entrega.
- A câmera, o cadastro de regiões e outras melhorias não foram alterados, pois não fazem parte do requisito informado.
