# Busca de localização no cadastro

Na branch `feat/mapa-localizacao`, abra **Lugares > Novo lugar** e informe um
endereço com cidade/estado ou um CEP brasileiro. Toque em **Buscar localização**,
escolha um dos resultados e toque no mapa para posicionar o marcador. Somente
**Usar estas coordenadas** altera latitude e longitude no formulário. Voltar
cancela a seleção. Os dois campos continuam editáveis; o botão **Salvar** mantém
o fluxo original de `POST /lugares` com Bearer token.

A precisão de endereços e CEPs depende dos dados do OpenStreetMap. Um resultado
pode representar uma rua ou região, sem indicar a entrada exata do local.
Confira o marcador antes de confirmar. Não envie informações confidenciais.

## Serviço e políticas

Consulte a [política do Nominatim público](https://operations.osmfoundation.org/policies/nominatim/)
e a [política de tiles](https://operations.osmfoundation.org/policies/tiles/).

- Busca somente mediante clique, sem autocomplete, busca em segundo plano ou
  repetição automática. Até cinco resultados em português.
- Endereços usam `q`; CEPs de oito dígitos usam `postalcode` e `countrycodes=br`.
- HTTP identifica o app como `ExploreTurismo-MobileII/1.0 (Flutter Android)`.
- Fila estática compartilhada entre instâncias serializa as requisições e
  impõe intervalo mínimo de um segundo no processo. Timeout de 15 segundos.
- HTTP 429/503 bloqueia novas chamadas de rede temporariamente, respeitando
  `Retry-After` em segundos ou data HTTP; na ausência de um valor válido,
  usa uma pausa de 60 segundos.
- Cache persistente em SharedPreferences, incluindo buscas vazias: validade
  de sete dias e no máximo 50 consultas. Cache vencido/corrompido é reconstruído.
  Chaves incluem o endpoint para não misturar respostas de provedores distintos.
- Atribuição OpenStreetMap/ODbL na busca e no mapa. Tiles HTTPS com identificação
  própria, cache nativo do flutter_map e sem prefetch ou download offline.

**O limite público de 1 requisição/segundo é agregado por aplicação, somando
todos os usuários. O cliente Flutter controla apenas seu próprio processo.**
O acesso direto é destinado aos testes acadêmicos em uma instalação. Antes de
distribuir o app a vários usuários, configure um proxy com cache e fila global,
ou um provedor que autorize esse volume. Nenhum proxy foi implantado nesta etapa.

## Troca de provedor

`GeocodificacaoService` define o contrato independente da API. A interface recebe
essa dependência e o estado fica em `GeocodificacaoController` com ChangeNotifier
e Provider. Outro provedor pode implementar o mesmo contrato.

`NominatimService.resolverEndpoint` aceita uma função assíncrona para configuração
remota. Sem essa função, o serviço lê a preferência `geocodificacao_endpoint` em
cada busca; o fallback é `https://nominatim.openstreetmap.org/search`.
Um endpoint alternativo deve usar HTTPS e aceitar o contrato de busca Nominatim.
Não há tela administrativa nem configuração remota hospedada nesta entrega;
essas entradas precisam ser alimentadas pela configuração da implantação.

## Validação

Execute `flutter analyze` e `flutter test`. Os testes usam HTTP simulado e tiles
em memória, sem consultar Nominatim nem cadastrar/alterar lugares na API.
Cobrem cache, endereço, CEP, erros, limite de frequência, validação, estados da
interface, ajuste no mapa, cancelamento e transferência ao formulário real.

No emulador, valide endereço/CEP, ausência de resultados, falha de conexão,
ajuste do marcador, edição manual e temas claro/escuro. Para testar apenas esta
etapa, feche o cadastro com **Cancelar** após conferir os campos preenchidos.
