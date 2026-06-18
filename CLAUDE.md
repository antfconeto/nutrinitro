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
- Rodar o gerador após qualquer alteração em providers ou `.env`:

```bash
dart run build_runner build --delete-conflicting-outputs
# ou em modo watch durante o desenvolvimento:
dart run build_runner watch --delete-conflicting-outputs
```

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
/drone/mission/create     → MissionCreatePage
/drone/mission/details    → MissionDetailsPage (arg: int missionId)
```

Argumentos são passados via `ModalRoute.of(context)?.settings.arguments`. Para navegação programática fora do contexto de widget, usar `appNavigatorKey` (definido em `app_widget.dart`).

---

## Enums e constantes

Todos os enums de domínio ficam em `lib/src/core/const/`. Cada um tem getter `.label` em português para exibição na UI.

Enums principais:
- `MissionStatus` — `planned`, `executing`, `completed`, `aborted`
- `DroneConnectionState` — `disconnected`, `connecting`, `connected`
- `DroneGpsSignal` — `none`, `poor`, `ok`, `good`, `excellent`
- `AnalysisStatus` — `pending`, `processing`, `completed`, `error`

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

Widgets `TileLayer` (flutter_map) sempre incluem `userAgentPackageName`:

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'nutrinitro.com.nutrinitro',
),
```

---

## Comandos úteis

```bash
# Analisar o projeto
dart analyze lib/

# Code generation (Riverpod + envied)
dart run build_runner build --delete-conflicting-outputs

# Mode watch durante desenvolvimento
dart run build_runner watch --delete-conflicting-outputs

# Rodar o app
flutter run

# Testes
flutter test
```

---

## Branch atual — `feat/drone-integration`

**Pronto:**
- Repositórios: `MissionRepository`, `WaypointRepository`, `DroneImageRepository`
- Serviços: `MockDroneService` (completo), `DjiDroneService` (scaffoldado)
- Telas: Painel do drone, lista de missões, criar missão, detalhes da missão, mídia

**Pendente:**
- Integração real com SDK DJI (autenticação, conexão, upload de waypoints, telemetria real)
- Stream de vídeo ao vivo
- Download de mídia do armazenamento do drone
