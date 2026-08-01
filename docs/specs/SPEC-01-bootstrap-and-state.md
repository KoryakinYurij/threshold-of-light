# SPEC-01: Bootstrap & State

**Статус:** draft · **Фаза:** 1 (Greybox) · **Закрывает пункты плана:** 1 (GameState + EventBus + SeedService), 2 (SaveManager), 11 (RunState + ProfileState)
**Закрывает acceptance:** №6 (полный цикл без ручного редактирования состояния), №8 (сохранение в хабе и после эвакуации, профиль после смерти)

Основания: `godot-47-supplement.md` §6, §11 · `production-and-ai-workflow-supplement.md` §6 · ADR-003, ADR-004, ADR-005.

---

## 1. Реестр автолоадов

Порядок в `[autoload]` = порядок инициализации (сверху вниз, `godot-47-supplement` §6, правило 5). Зависимость может смотреть только **вверх** по списку.

```ini
[autoload]
EventBus="*res://scripts/core/event_bus.gd"
SeedService="*res://scripts/core/seed_service.gd"
GameState="*res://scripts/core/game_state.gd"
SaveManager="*res://scripts/persistence/save_manager.gd"
SceneRouter="*res://scripts/core/scene_router.gd"
```

| Автолоад | Зависит от | Обоснование позиции |
|---|---|---|
| `EventBus` | — | Чистые сигналы, ноль зависимостей. Обязан быть первым: на него подписываются все. |
| `SeedService` | — | Чистая функция от мастер-сида. Не знает про состояние. |
| `GameState` | `EventBus`, `SeedService` | Держит текущий `RunState`/`HubState`/`ProfileState`. |
| `SaveManager` | `GameState` | Читает состояние для записи. **`GameState` не вызывает `SaveManager` напрямую** — только через `EventBus` (ADR-005 / §6 правило 2: запрет циклов). |
| `SceneRouter` | `EventBus` | Меняет сцены по сигналам. |

**Жёсткие правила (нарушение = баг, а не стиль):**
- Ни один автолоад **не объявляет `class_name`** (ADR-005). Имя даёт только регистрация.
- Обращение к автолоаду **запрещено в `_init()`** — только `_ready()`/`_enter_tree()`.
- `SaveManager` **не читает** `GameState` по своей инициативе в момент старта — только по вызову.
- Автолоад **не хранит состояние конкретной сцены**. `GameState.current_run` обнуляется через явный `reset()`.

Итого 5 автолоадов — в пределах лимита 5–10 (§6 правило 4). `SimulationClock` из README в Phase 1 **не вводится**: фиксированный тик экономики нужен только для пассивной генерации Света, которой в Phase 1 нет (Свет не тратится — см. SPEC-02 §4). Вводится в Phase 2.

## 2. EventBus — сигналы Phase 1

Имена — past-tense события (`CONTEXT.md`, Architecture rules). Типизированные.

```gdscript
# scripts/core/event_bus.gd
extends Node

# Навигация
signal expedition_requested            # HubScreen -> ExpeditionController
signal expedition_started(master_seed: int)
signal node_entered(node_index: int, node_type: int)
signal node_cleared(node_index: int, rewards: Dictionary)
signal extraction_completed(rewards: Dictionary)
signal scout_died(node_index: int)
signal returned_to_hub()

# Хаб
signal module_built(module_id: String, level: int)
signal module_upgrade_requested(module_id: String)

# Персистентность
signal save_requested(reason: String)   # "hub" | "node_cleared" | "extraction" | "death"
signal save_completed(slot: int, ok: bool)
```

Правило: **UI не мутирует состояние** — эмитит `*_requested`, владеющая система отвечает `*_completed`/past-tense событием.

## 3. Поток сцен

```
main_menu.tscn  --start_pressed-->  hub_screen.tscn
hub_screen      --expedition_requested-->  expedition_map.tscn
expedition_map  --node_entered(combat)-->  combat_arena.tscn
combat_arena    --node_cleared-->          expedition_map.tscn
expedition_map  --extraction_completed-->  hub_screen.tscn
combat_arena    --scout_died-->            hub_screen.tscn
```

`SceneRouter` — единственное место, где вызывается `get_tree().change_scene_to_file()`. Сцены друг о друге не знают.

**Известный пробел, закрываемый этой спекой:** сигнал `start_pressed` в `scenes/main/main_menu.gd` сейчас никем не слушается (аудит §1.1). `SceneRouter` подписывается на него в `_ready()` через поиск текущей сцены — либо `main_menu.gd` переписывается на эмит в `EventBus`. **Решение: второе** — меню эмитит `EventBus`, локальный сигнал `start_pressed` удаляется. Это убирает необходимость `SceneRouter` знать про конкретный узел.

## 4. Состояния

Все три — обычные классы с `class_name` (ADR-005), не автолоады.

```gdscript
# scripts/core/profile_state.gd
class_name ProfileState extends RefCounted
var unlocked_modules: PackedStringArray = ["forge_of_form"]
var memories: int = 0
var runs_completed: int = 0
var runs_died: int = 0

# scripts/core/hub_state.gd
class_name HubState extends RefCounted
var materials: int = 0
var unstable_loot: int = 0
var modules: Dictionary = {}      # module_id: String -> level: int

# scripts/core/run_state.gd
class_name RunState extends RefCounted
var master_seed: int = 0
var current_node_index: int = 0
var visited_nodes: PackedInt32Array = []
var pending_materials: int = 0        # не забанковано
var pending_unstable_loot: int = 0    # теряется при смерти (ADR-002)
var pending_memories: int = 0
var scout_hp: int = 0
```

**Разделение по риску (ADR-002):** всё, что в `RunState.pending_*`, — под риском. Перенос в `HubState` происходит **только** в `ExtractionSystem` при успешной эвакуации или победе над guardian. При смерти: `pending_materials` и `pending_memories` переносятся по таблице ADR-002 (100% / ~50%), `pending_unstable_loot` **обнуляется**.

## 5. SeedService

```gdscript
# scripts/core/seed_service.gd
extends Node
const MAX_SEED: int = 9007199254740991   # 2^53-1 (ADR-004)

func new_master_seed() -> int              # результат гарантированно <= MAX_SEED
func normalize(raw: int) -> int            # кэп для сида, введённого игроком
func graph_seed(master: int) -> int
func loot_seed(master: int) -> int
func combat_seed(master: int) -> int
```

**Контракт (ADR-004 + §11):**
- Под-сиды **выводятся** из мастер-сида детерминированно и **никогда не сохраняются**.
- В сейв едет **только** `master_seed` + `current_node_index`.
- Три потока RNG независимы: боёвка не может сдвинуть последовательность генерации графа.
- Деривация — **только целочисленная** (§11 правило 5); никакого float в пути сида.

## 6. SaveEnvelope v1

Формат — JSON через `FileAccess` (ADR-001). Настройки — отдельно, `ConfigFile`, в этой спеке не рассматриваются.

```json
{
  "save_version": 1,
  "profile": { "unlocked_modules": ["forge_of_form"], "memories": 0, "runs_completed": 0, "runs_died": 0 },
  "hub_state": { "materials": 0, "unstable_loot": 0, "modules": { "forge_of_form": 1 } },
  "run_state": null
}
```

`run_state` = `null`, когда игрок в хабе. Непустой — только при сохранении внутри экспедиции.

**Слоты и запись:** 3 слота, атомарная запись (`tmp` → `rename_absolute`), 1 бэкап на слот. Реализация — по референсу `production-and-ai-workflow-supplement.md` §6.1–6.2, **с поправкой ADR-003**: каст одного `save_version` там — недостаточный образец.

### Точки сохранения (acceptance №8)

| Момент | Что пишется |
|---|---|
| Вход в хаб / изменение хаба | `profile` + `hub_state`, `run_state: null` |
| Узел завершён | `profile` + `hub_state` + `run_state` |
| Эвакуация завершена | `profile` + `hub_state` (после переноса наград), `run_state: null` |
| Смерть разведчика | `profile` + `hub_state` (после списания по ADR-002), `run_state: null` |

## 7. DTO-слой (ADR-003)

**Правило без исключений:** после `JSON.parse_string` ни одно число не используется напрямую. Каждая секция получает `from_dict`/`to_dict` с явными кастами.

```gdscript
# scripts/persistence/save_schema.gd
class_name SaveSchema extends RefCounted

static func hub_state_from_dict(d: Dictionary) -> HubState:
    var s := HubState.new()
    s.materials = int(d.get("materials", 0))
    s.unstable_loot = int(d.get("unstable_loot", 0))
    for id in d.get("modules", {}):
        s.modules[String(id)] = int(d["modules"][id])   # без int() ключ уровня станет float
    return s
```

Забыть каст нельзя: присваивание `float` в статически типизированное `int`-поле не пройдёт.

## 8. Definition of Done

- [ ] Проект стартует: `godot --headless --path . --quit-after 30` — ноль ошибок в stderr.
- [ ] 5 автолоадов зарегистрированы, порядок как в §1; ни один не объявляет `class_name`.
- [ ] `MainMenu → HubScreen` работает через `EventBus`, локальный `start_pressed` удалён.
- [ ] Roundtrip-тест сейва проверяет **типы**, а не только значения:
      `assert(typeof(loaded.hub_state.modules["forge_of_form"]) == TYPE_INT)`.
- [ ] Сид переживает JSON-роундтрип на граничных кейсах `0`, `1`, `MAX_SEED-1`, `MAX_SEED`
      (ADR-004 §5), и `RouteGraph.generate(restored) == RouteGraph.generate(s)`.
- [ ] Атомарность: убийство процесса между `tmp` и `rename` не портит существующий слот.
- [ ] Все 4 точки сохранения из §6 покрыты тестом.

## 9. Явные не-цели Phase 1

- Миграции схемы (`SaveMigrations`) — каркас есть, правил нет: схема одна, v1.
- `SimulationClock` и пассивная генерация Света.
- Настройки через `ConfigFile`.
- Облачные сейвы, шифрование, античит.
