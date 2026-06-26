# CLAUDE.md — nutrinitro

Instruções e contexto para agentes (Claude Code ou outros) trabalhando neste repositório.

---

## Stack

- Flutter / Dart ^3.10.1
- State management: **Riverpod 3** com code generation (`riverpod_annotation`, `riverpod_generator`)
- Persistência local: **SQLite** via `sqflite` (versão atual: 4)
- Imagem / visão computacional: `opencv_dart`, `image`, `image_cropper`, `exif`
- Mapa: `flutter_map` + `latlong2` (tiles OpenStreetMap)
- Drone: interface `IDroneService` → `MockDroneService` ou `DjiDroneService`
- Config: `envied` + arquivo `.env` (nunca commitar)
- HTTP: `dio` (ainda pouco usado — sem API REST no momento)

---

## Arquitetura

Clean Architecture em camadas. Fluxo de dados sempre unidirecional:

```
UI (pages + view models)
  └── repositories (Result<T>)
        └── services (câmera, análise, drone, storage)
              └── database (sqflite singleton via Riverpod)
```

### Estrutura de pastas

```
lib/src/
  core/
    config/         # Env vars (envied) — env.dart + env.g.dart
    const/          # Enums globais e de domínio (drone/, analysis_status, etc.)
    database/       # database_client.dart — singleton keepAlive, migrations, seed
    exceptions/     # Exceções tipadas
    helpers/        # Utilitários pontuais
    interfaces/     # Result<T>, Nil
    themes/         # AppColors, AppText, AppTheme
    widgets/        # Widgets reutilizáveis globais (AppLoading, AppSkeleton)
    utils/          # PDF exporter, validações, debug exporter
  data/
    models/         # Modelos imutáveis com toMap / fromMap / copyWith
      analysis/     # AnalysisModel, ImageModel, AnalysisRecipe, AnalysisPayload
      drone/        # MissionModel, DroneWaypointModel, DroneImageModel, TelemetryData
    repositories/   # Acesso ao banco — retornam Result<T>
      repositories_provider.dart   # Todos os providers de repositório
    services/       # Lógica de negócio e integrações externas
      analysis/     # Engine de análise (isolate, pipeline de receitas, OpenCV)
      camera/       # CameraService, ExifService, ImageCropperService
      drone/        # IDroneService, MockDroneService, DjiDroneService
      storage/      # StorageService (salva arquivos no documents directory)
      services_provider.dart       # Todos os providers de serviço
  ui/
    splash/
    tabs/
      tabs_page.dart               # Bottom tabs (Dashboard | Analysis | Drone)
      screens/
        dashboard/
        analysis/   # list / create / details
        drone/      # panel / missions (create + details) / media
```

Cada tela segue o padrão: `*_page.dart` + `*_state.dart` + `*_view_model.dart` + `*_view_model.g.dart`

---

## Padrão Result

Toda operação assíncrona nos repositórios retorna `Result<T>` — nunca lança exceção até a UI:

```dart
sealed class Result<T> {}

class Success<T> extends Result<T> { final T value; }
class Failure<T> extends Result<T> { final Exception error; final Object? value; }

// Para operações sem retorno útil:
Result<Nil> successOfNil() => Success(Nil());
```

Use pattern matching com switch exhaustivo na UI / ViewModel:

```dart
switch (result) {
  case Success(value: final data):
    // ...
  case Failure(:final error):
    // ...
}
```

`Failure` aceita um segundo parâmetro `value` opcional — útil para devolver dados parciais junto ao erro, mas raramente necessário.

---

## Riverpod

- Todos os providers usam `@riverpod` / `@Riverpod(keepAlive: true)` com code generation
- Arquivos `*.g.dart` são gerados — **nunca editar à mão**
- **O agente NUNCA deve rodar `build_runner`** — o desenvolvedor cuida disso manualmente. Apenas indicar quando é necessário rodar após alterações em providers.

**Providers keepAlive (globais):** `databaseClientProvider`, `droneServiceProvider`

**Providers autoDispose (padrão):** todos os repositórios e view models de tela

Os providers de repositório são `async` porque dependem do `databaseClientProvider` (Future):

```dart
@riverpod
Future<MissionRepository> missionRepository(Ref ref) async {
  final db = await ref.watch(databaseClientProvider.future);
  final waypoints = await ref.watch(waypointRepositoryProvider.future);
  return MissionRepository(db, waypoints);
}
```

---

## Banco de dados (SQLite)

Versão atual: **4**. Migrations em `database_client.dart` via `onUpgrade`.

Tabelas: `crops`, `analyses`, `images`, `analysis_recipes`, `crop_recipe_bindings`, `missions`, `waypoints`, `drone_images`

**Seed automático:** ao abrir o banco, `RecipeSeedService.seedFromAssets()` carrega receitas de `assets/recipes/` e `seedCropBindings()` associa receitas a culturas. Só insere se ainda não existir.

Ao incrementar a versão do banco:
1. Adicionar o bloco `if (oldVersion < N)` em `_onUpgrade`
2. Nunca usar `DROP TABLE` — usar `ALTER TABLE` ou criar nova tabela

---

## Drone — IDroneService

A flag `Env.useMockDrone` no `.env` alterna a implementação em runtime:

```dart
@Riverpod(keepAlive: true)
IDroneService droneService(Ref ref) {
  final service = Env.useMockDrone ? MockDroneService() : DjiDroneService();
  ref.onDispose(service.dispose);
  return service;
}
```

**`MockDroneService`** — completamente implementado: telemetria simulada com streams, bateria drenando, decolar/pousar, execução de missão ponto a ponto.

**`DjiDroneService`** — scaffoldado com TODOs. Requer integração real com DJI Mobile SDK Flutter plugin. Os métodos da interface estão declarados mas não implementados.

A interface `IDroneService` define os contratos:

```
connect / disconnect / connectionStream
telemetryStream / lastTelemetry
takeoff / land / returnToHome / pauseFlight / resumeFlight / emergencyStop
uploadMission / startMission / abortMission / missionProgressStream
capturePhoto / startIntervalShooting / setCameraParameters / setGimbalPitch
listMediaFiles / downloadFile / deleteFile
videoStream / startVideoStream / stopVideoStream
dispose
```

Nunca acessar `MockDroneService` ou `DjiDroneService` diretamente na UI — sempre usar `IDroneService` via `droneServiceProvider`.

---

## Analysis Engine

Processamento pesado roda em **Isolate** com `ReceivePort` para enviar atualizações de progresso à UI sem bloquear a thread principal.

Pipeline baseado em **receitas JSON** (`assets/recipes/`): cada receita define operações modulares (normalização, segmentação HSV, detecção de contornos via OpenCV, predição de déficit).

Implementações disponíveis em `analysis_registry.dart`:
- `StandardAgronomicAnalysis`
- `NitrogenAnalysis`

Ao adicionar nova análise: implementar a interface base, registrar no registry, criar a receita JSON correspondente.

---

## Navegação

Rotas nomeadas definidas em `app_widget.dart`:

```
/                         → SplashPage
/tabs                     → TabsPage (arg: int — índice da aba; 0=Dashboard, 1=Analysis, 2=Drone)
/analysis/create          → AnalysisCreatePage
/analysis/details         → AnalysisDetailsPage (arg: int analysisId)
/drone/mission/create     → MissionCreatePage (arg opcional: MissionModel — modo edição)
/drone/mission/details    → MissionDetailsPage (arg: int missionId)
```

Argumentos são passados via `ModalRoute.of(context)?.settings.arguments`. Para navegação programática fora do contexto de widget, usar `appNavigatorKey` (definido em `app_widget.dart`).

**Padrão criar/editar com a mesma página:** `MissionCreatePage` aceita `MissionModel? initialMission`. Quando fornecido, pré-popula campos e chama `updateWithWaypoints` no submit em vez de `create`. O VM expõe `initFromMission(mission)` chamado via `addPostFrameCallback` no `initState`. Após retornar da edição, a página de detalhes recarrega com `load(missionId)` no `.then` do `pushNamed`.

---

## Enums e constantes

Todos os enums de domínio ficam em `lib/src/core/const/`. Cada um tem getter `.label` em português para exibição na UI.

Enums principais:
- `MissionStatus` — `planned`, `executing`, `completed`, `aborted`
- `DroneConnectionState` — `disconnected`, `connecting`, `connected`
- `DroneGpsSignal` — `none`, `poor`, `ok`, `good`, `excellent`
- `AnalysisStatus` — `pending`, `processing`, `completed`, `error`

---

## Filtros e ordenação

Padrão aplicado em `AnalysisListPage`, `DroneMissionsPage` e `DroneMediaPage`.

**UI:** filtro inline (nunca no AppBar) — row com `SingleChildScrollView` de chips ativos + botão de filtro com badge de contagem. Sheet de filtros abre via `showModalBottomSheet`.

**Ordem das seções no sheet:** Status → Cultura (se aplicável) → Período → Ordenar por.

**Período (date range):** campos `dateFrom` e `dateTo` opcionais. Sem `dateFrom` pega tudo antes de `dateTo`; sem `dateTo` pega tudo depois de `dateFrom`. Chips ativos mostram a data formatada; toque remove o filtro.

**Análises:** filtros aplicados em SQL no repositório (`allPaginated`). `dateFrom` usa `>= inicio_do_dia`, `dateTo` usa `<= 23:59:59.999` do dia.

**Missões / Mídia:** carregados de uma vez; filtros e ordenação aplicados in-memory em getters no state (`missions`, `entries`).

**Sentinel para nullable em `copyWith`:** campos opcionais que precisam ser setados para `null` usam `const Object _sentinel = Object()` para distinguir "não fornecido" de "explicitamente null".

**`StatefulBuilder` em bottom sheets:** usar quando há estado local no sheet (ex: switch de toggle). Nunca chamar o VM dentro do `setSheetState` — apenas atualizar a variável local; chamar o VM só no botão de salvar.

---

## Convenções de código

### Sem comentários desnecessários
Não comentar o QUE o código faz — nomes bem escolhidos já fazem isso. Comentar apenas quando o PORQUÊ é não-óbvio (workaround, invariante oculta, bug específico).

### Sem tratamento de erro para cenários impossíveis
Não adicionar fallbacks para casos que não podem acontecer. Confiar nas garantias do framework e do código interno. Validar apenas nas bordas do sistema (input do usuário, leitura de arquivos externos).

### Sem abstrações prematuras
Três linhas similares é melhor do que uma abstração prematura. Não criar helpers genéricos para um caso que existe uma única vez.

### Sem código morto
Se algo foi removido, deletar completamente. Não deixar comentários `// removed` ou variáveis `_unused`.

### Idioma
Código em **inglês**. UI (textos exibidos ao usuário) em **português (Brasil)**.

---

## Mapas

Versão: `flutter_map: ^8.3.0` + `latlong2: ^0.9.1`.

Widgets `TileLayer` sempre incluem `userAgentPackageName`:

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'nutrinitro.com.nutrinitro',
),
```

**URLs de tile:**
- OSM (padrão): `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- Satélite (Google Maps): `https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}`

**Fit automático nos waypoints:**
```dart
CameraFit.bounds(
  bounds: LatLngBounds.fromPoints(points),
  padding: const EdgeInsets.all(36),
)
// Passe em MapOptions.initialCameraFit ou mapController.fitCamera(...)
```

**Converter posição de tela → LatLng** (para marcadores arrastáveis):
```dart
final box = _mapContainerKey.currentContext!.findRenderObject() as RenderBox;
final local = box.globalToLocal(globalPosition);
final latLng = _mapController.camera.offsetToCrs(local);
// offsetToCrs recebe Offset relativo ao canto superior-esquerdo do widget FlutterMap
```

**Mapa não-interativo em cards de lista:** envolver `FlutterMap` em `IgnorePointer` — gestos passam para o `InkWell` do card pai.

**Padrão de toggle satélite:** `FloatingActionButton.small` posicionado em `Positioned(bottom: 12, right: 12)` dentro de um `Stack` sobre o mapa. `heroTag` único obrigatório. Cor do ícone alterna entre `AppColors.green` (ativo) e `AppColors.grayMedium` (inativo).

**Padrão de card de mapa interativo** (ver `_MissionMapCard`, `AnalysisMapCard`):
- `StatefulWidget` com `late final MapController _mapController` (dispose no `dispose`)
- `bool _isSatellite = false` e `int? _selectedIndex` gerenciados localmente
- Layout: `Container` com header (ícone + título + contagem) → `SizedBox(height: N)` com `ClipRRect` → `Stack` com `FlutterMap` + FABs (`Column` satélite + recenter) + painel de info selecionado
- FABs sobem (`bottom: 72`) quando painel de info está visível

**Marcadores arrastáveis (drag-to-move):**
```dart
// 1. GlobalKey no container do mapa
final GlobalKey _mapContainerKey = GlobalKey();
Container(key: _mapContainerKey, ...)

// 2. int? _draggingIndex no estado do widget

// 3. Desabilitar interação do mapa durante drag
interactionOptions: InteractionOptions(
  flags: _draggingIndex != null
      ? InteractiveFlag.none
      : InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
),

// 4. GestureDetector no marcador
onLongPressStart: (_) => setState(() => _draggingIndex = index),
onLongPressMoveUpdate: (details) {
  final box = _mapContainerKey.currentContext!.findRenderObject() as RenderBox;
  final latLng = _mapController.camera.offsetToCrs(box.globalToLocal(details.globalPosition));
  viewModel.moveWaypoint(index, latLng);
},
onLongPressEnd: (_) => setState(() => _draggingIndex = null),
```

**Inserir ponto entre dois waypoints:** renderizar `MarkerLayer` com marcadores de midpoint `(a+b)/2`, ocultos durante drag. Tap chama `insertWaypoint(afterIndex, midLatLng)` no VM.

---

## Comandos úteis

```bash
# Analisar o projeto
dart analyze lib/

# Rodar o app
flutter run

# Testes
flutter test
```

> **Nota:** `build_runner` é rodado manualmente pelo desenvolvedor — o agente não deve executá-lo.

---

## Branch atual — `feat/drone-integration`

### Concluído

**Repositórios e dados**
- `MissionRepository`, `WaypointRepository`, `DroneImageRepository`
  - `updateWithWaypoints(...)` — atualiza metadados + substitui waypoints atomicamente
  - `findByStatus(MissionStatus)` — busca missões por status sem carregar waypoints
  - `findActive()` em `AnalysisRepository` — retorna análises com `status = 'processing'` sem joins

**Serviços**
- `MockDroneService` — completamente implementado: telemetria simulada, bateria drenando, missão ponto a ponto, pausa de 400ms em cada waypoint
- `DjiDroneService` — scaffoldado com TODOs (ver seção de integração abaixo)

**Fluxo missão → análise**
- `DroneAnalysisPreset` passado como argumento de rota para `/analysis/create`
- `initFromPreset()` no VM pré-preenche título, data, notas, cultura (`cropId`) e imagens
- Botão "Fazer Análise" visível para missões `completed` independentemente de ter imagens

**Download com progresso**
- `downloadWithProgress()` em `core/widgets/download_progress_dialog.dart`
- `LinearProgressIndicator` com contador "X de N fotos" — usado em `MissionDetailsPage` e `DroneMediaPage`

**Resiliência de tarefas longas**
- `lib/src/data/services/active_tasks/active_tasks_state.dart` — `ActiveTasksState` com `executingMissions`, `interruptedAnalyses`, `totalCount`
- `lib/src/data/services/active_tasks/active_tasks_provider.dart` — `class ActiveTasks extends _$ActiveTasks` (`keepAlive: true`), provider gerado: `activeTasksProvider`; chama `refresh()` a cada volta do app ao foreground
- `TabsPage` com `WidgetsBindingObserver`: chama `activeTasksProvider.notifier.refresh()` no `initState` e em cada `AppLifecycleState.resumed`
- `DashboardPage`: sino de notificação com `Badge` (Material 3, laranja) mostra contagem de tarefas ativas; abre `active_tasks_bottom_sheet`
- `active_tasks_bottom_sheet.dart`: lista missões em execução (navega para detalhes) e análises interrompidas (navega para detalhes)
- `analysis_header_card.dart`: botão de análise aparece também para `isProcessing`; label "Processar novamente"
- `analysis_details_view_model.dart`: guard `if (state.isAnalyzing) return;` — permite reprocessar análise com status `processing` no banco (deixada assim por kill do app)

> **build_runner pendente:** `active_tasks_provider.dart` usa `@Riverpod(keepAlive: true)`. Rodar `dart run build_runner build` para gerar `active_tasks_provider.g.dart`.

**Telas**
- Painel do drone, lista de missões, criar/editar missão, detalhes da missão, mídia
- Filtros com date range e ordenação em todas as listas (análises, missões, mídia)
- `_MissionMapCard`: marcadores numerados, painel de info, toggle satélite, recenter
- Mapa satélite não-interativo de 160px nos cards da lista de missões
- `MissionCreatePage`: drag-to-move em marcadores; inserir waypoint via midpoint "+"

---

### Pendente — Integração DJI SDK

#### Visão geral
Toda a lógica de UI e persistência está pronta. O único passo restante é preencher `DjiDroneService` com chamadas reais ao SDK.

**Arquivo:** `lib/src/data/services/drone/dji_drone_service.dart`
**Toggle:** `Env.useMockDrone` no `.env` — setar `USE_MOCK_DRONE=false` para ativar

#### Passo 1 — Adicionar o package ao pubspec.yaml

Verificar o package disponível para DJI Mobile SDK no Flutter (geralmente `dji_flutter_plugin` ou wrapper customizado). Adicionar em `dependencies:` e rodar `flutter pub get`.

```yaml
dependencies:
  dji_flutter_plugin: ^x.x.x  # confirmar versão atual
```

#### Passo 2 — Configuração nativa

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<!-- Adicionar app key do DJI Developer Center -->
<meta-data android:name="com.dji.sdk.API_KEY" android:value="SUA_APP_KEY"/>
```

**iOS** (`ios/Runner/Info.plist`): adicionar permissões de câmera, localização, bluetooth e a app key DJI.

#### Passo 3 — Implementar DjiDroneService

A interface `IDroneService` define todos os contratos. Prioridade de implementação:

1. **`connect()` / `disconnect()` / `connectionStream`** — autenticar app key + conectar ao drone via Wi-Fi/OcuSync. Emitir `DroneConnectionState` no stream.

2. **`telemetryStream`** — mapear dados de voo DJI (altitude, velocidade, GPS, bateria, heading) para `TelemetryData`. Emitir a cada ~500ms.

3. **`takeoff()` / `land()` / `returnToHome()`** — chamadas diretas ao SDK.

4. **`uploadMission()` / `startMission()` / `abortMission()` / `missionProgressStream`** — converter `List<DroneWaypointModel>` para waypoints DJI (lat/lng/altitude/speed/action); monitorar progresso via listener do SDK e emitir índice atual.

5. **`capturePhoto()` / `startIntervalShooting()`** — comandos de câmera via `DJICameraKey`.

6. **`videoStream`** — decodificar stream H.264 do DJI para `Uint8List` de frames; expor como `Stream<Uint8List>`.

7. **`listMediaFiles()` / `downloadFile()` / `deleteFile()`** — acesso ao cartão SD via `DJIMediaManager`.

#### Passo 4 — Stream de vídeo ao vivo

A `DronePage` já tem um painel de vídeo. Conectar ao `IDroneService.videoStream`:

```dart
// No widget de vídeo, assinar o stream
ref.watch(droneServiceProvider).videoStream.listen((frame) {
  // Renderizar com RawImage ou Texture
});
```

O `MockDroneService.videoStream` emite `Stream.empty()` — sem impacto no mock.

#### Passo 5 — Salvar imagens capturadas em voo

Quando `capturePhoto()` é chamado durante missão, o `MockDroneService` já cria um `DroneImageModel` e salva via `DroneImageRepository`. O `DjiDroneService` deve seguir o mesmo padrão: após captura, baixar a imagem do drone via `DJIMediaManager`, salvar no documents directory com `StorageService`, persistir com `DroneImageRepository`.

#### Passo 6 — Reconexão após foreground

Quando o app volta ao foreground (`TabsPage.didChangeAppLifecycleState`), além do `activeTasksProvider.refresh()` já implementado, considerar chamar `droneService.connect()` se o estado anterior era `connected`. O `DroneConnectionState` atual é exibido no painel — a UI já reage ao stream.

---

### Pendente — Outros

- Tela de monitor de missão em tempo real (rota no mapa com posição atual do drone)
- Download de mídia em lote do armazenamento interno do drone (não da galeria local)
