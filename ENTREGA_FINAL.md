# Entrega final — Mobile II — Explore Turismo

Este documento descreve a implementação proposta no PR #3, sem confundir execução de testes automatizados com a validação no dispositivo.

## Requisitos e implementação

| Requisito | Implementação |
| --- | --- |
| Cadastro de lugares com foto | Formulário com captura de câmera/galeria; lugar é criado na API e foto enviada como `multipart/form-data` (`foto`) para `POST /lugares/{id}/galeria`, utilizando o JWT da API |
| Mapa OpenStreetMap | `flutter_map` com marcadores dos lugares cadastrados e miniatura real quando `GET /lugares` devolve `galeria[].urlFoto` |
| GPS do aparelho | Botão **Minha localização GPS** no mapa solicita permissão apenas em primeiro plano; pin azul e distância aproximada ao lugar na ficha do marcador |
| Favoritos | Botões de coração na lista e nos detalhes; com JWT da API usam `GET/POST/DELETE /favoritos`; sem JWT há armazenamento local via `SharedPreferences` |
| Google + sessão | Firebase é inicializado por padrão no Android, login Google direto na entrada, sessão anterior restaurada no início e logout acessível na Home |
| Funcionalidade extra | Botão **Como chegar** no mapa e nos detalhes abre rota externa do Google Maps |
| Filtros extras | Mapa possui filtro por categoria; lista já tinha filtro por categoria e nome |
| Câmera | Removido placeholder remoto `placehold.co/150x150.png`; agora há estado vazio visual, imagem real selecionada, tratamento de erros/cancelamento |
| Erros | Mensagens para GPS desativado, permissão negada, falha de rotas, rede/galeria, API de favoritos e identificação ambígua do lugar |

## Considerações técnicas importantes

1. O **Firebase** e a **API acadêmica** têm sessões diferentes. Logar com Google permite navegar e visualizar lugares públicos, mas cadastrar lugares e enviar fotos exige JWT da API acadêmica. O aplicativo não transmite ID token Firebase como se fosse token da API.
2. A galeria remota só pode receber a foto após o cadastro do lugar. Quando `POST /lugares` não devolve ID, o aplicativo tenta identificar **um único** registro novo com nome e coordenadas compatíveis. Caso haja ambiguidade ou a paginação não contenha o novo lugar, o lugar fica cadastrado e a tela informa que **a foto não foi enviada**; a pessoa pode anexá-la depois em **Detalhes → Adicionar foto à galeria**. Nenhuma foto deve ser apresentada como salva se a API recusar o upload.
3. Fotos aparecem em marcadores quando a API disponibiliza uma URL HTTPS em `galeria` ou campos equivalentes. Lugares sem foto usam ícone ilustrativo. Imagens remotas inválidas recebem fallback.
4. GPS só é solicitado após o usuário tocar em **Minha localização GPS**. Não há localização em segundo plano.
5. A localização por CEP via Nominatim continua independente do GPS real do aparelho.
6. As duas autenticações foram mantidas deliberadamente separadas para não romper o cadastro da atividade anterior.
7. A pasta legada `lib/controller` segue existente para compatibilidade com as entregas 1 e 2. Os componentes novos serão gradualmente migrados para `lib/controllers`.
8. Os testes de Flutter no GitHub Actions não substituem teste de permissão GPS, câmera, galeria, navegação externa e autenticação no aparelho real.

## Como testar no Galaxy S23

No PC (com Java/Flutter/SDK Android já configurados):

```powershell
cd C:\ProjetosFlutter\explore_turismo
git fetch origin
git switch --track origin/feat/entrega-final-mobile2
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d RQCX9053YDD
```

Se a branch já existir localmente: `git switch feat/entrega-final-mobile2` e `git pull`.
Depois do `flutter pub get`, atualize `pubspec.lock` na branch se houver mudança de versão.

### Roteiro manual de validação

1. Verifique o estado vazio na câmera: **não deve existir imagem 150×150 baixada da internet**. Capture e selecione foto real.
2. Faça login com Google, feche completamente o app, abra novamente e confira a sessão persistente; depois teste **Sair da conta**.
3. Faça login na API da faculdade. Na tela **Lugares**, cadastre um lugar **real ou claramente identificado como teste** com coordenadas válidas e uma foto. Confira se o app informa se a foto foi enviada e se aparece na galeria na API. Evite duplicar registros desnecessários.
4. Na lista, marque um lugar como favorito; ative **Somente favoritos**; feche e reabra o aplicativo para conferir persistência.
5. No **Mapa**, toque **Minha localização GPS**, aceite a permissão e confira pin azul distinto dos lugares; teste também negar permissão e reabilitar.
6. Filtre o mapa por categoria, abra marcador e confira foto (se a API tiver foto), distância aproximada em km e **Como chegar**.
7. Confira se **Como chegar** abre o Google Maps/navegador com o destino correto.
8. Teste o estado sem internet: mensagens e botão **Tentar novamente**, sem travamentos.
9. Confirme que **Lugares**, mapa, busca CEP e cadastro original continuam operando.

## Execução e integração

Este PR é **rascunho**. O responsável deve executar as verificações no Android e conferir o GitHub Actions antes de autorizar o merge.
