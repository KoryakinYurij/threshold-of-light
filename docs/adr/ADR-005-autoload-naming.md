# ADR-005: Именование автолоадов против `class_name`

## Status

Accepted (2026-08-03 — реализовано в T-02: автолоады без `class_name`, проверка в `tests/run_tests.gd`)

## Context

Два действующих правила проекта по отдельности корректны, а вместе не собираются.

**Правило 1** — `CONTEXT.md`, раздел «Naming»:

> Scene and script files: snake_case … `class_name` и node names stay PascalCase (e.g., `HubScreen`)

**Правило 2** — `README.md` (структура + план Phase 1) и `godot-47-supplement.md` §6: автолоады называются `GameState`, `EventBus`, `SeedService`, `SimulationClock`, `SaveManager`.

Godot запрещает совпадение имени автолоада и `class_name`: оба пишутся в один глобальный реестр имён. Попытка даёт ошибку парсера:

```
Class "GameState" hides an autoload singleton.
```

Подтверждено официальным трекером — [godot-proposals#8441](https://github.com/godotengine/godot-proposals/issues/8441): *«Option 1: Allow a singleton to have class_name that is the same as its autoload name. This currently throws error: "Class XXXX hides an autoload singleton"»*. Симметричный случай (сначала `class_name`, потом автолоад того же имени) даёт «hides a global script class».

### Почему это стоит решить сейчас

Тикет №1 плана Phase 1 — буквально «GameState + EventBus + SeedService». Агент напишет `class_name GameState` в `scripts/core/game_state.gd` (правило 1 велит), затем зарегистрирует автолоад `GameState` (правило 2 велит) — и упрётся в ошибку на первом же шаге. Разрешается это методом тыка за 15 минут, но результат будет разным у разных агентов в разных файлах, и проект получит непоследовательный нейминг ядра ещё до первой рабочей сцены.

## Decision

**Автолоад-синглтоны не объявляют `class_name`.** Имя автолоада — единственная точка входа.

```gdscript
# scripts/core/game_state.gd
extends Node
# НЕТ class_name — имя даёт регистрация автолоада "GameState"

var current_run: RunState = null
```

```ini
# project.godot
[autoload]
GameState="*res://scripts/core/game_state.gd"
EventBus="*res://scripts/core/event_bus.gd"
SeedService="*res://scripts/core/seed_service.gd"
```

Обращение из кода — `GameState.current_run`, как и предполагает `godot-47-supplement.md` §6.

**Обычные (не-автолоад) классы правило 1 сохраняют без изменений:** `RunState`, `HubState`, `ProfileState`, `HubScreen`, `EnemyDefinition` объявляют `class_name` в PascalCase, потому что автолоадами они не являются. Разделение проходит ровно по признаку «зарегистрирован ли скрипт в `[autoload]`».

**Следствие для типизации:** у автолоада без `class_name` нет типа для аннотаций. Если где-то нужен типизированный доступ (например, в тестах, где автолоад мокается), скрипт получает `class_name` с суффиксом — `GameStateSingleton` — а автолоад остаётся `GameState`. Это исключение, а не норма; по умолчанию `class_name` у автолоадов отсутствует.

`CONTEXT.md` дополняется одной строкой в разделе «Naming» со ссылкой на этот ADR.

## Consequences

### Positive

- Ошибка парсера, гарантированно ожидавшая агента на тикете №1, снята заранее.
- Нейминг ядра фиксирован до написания кода — не будет расхождений между файлами, написанными в разных сессиях.
- Совпадает с рекомендацией `godot-47-supplement.md` §6 (лимит 5–10 автолоадов, доступ по имени) без правок этого документа.

### Negative

- Автолоады теряют возможность быть типом в аннотациях (`var gs: GameState` невозможно). На практике не мешает: обращение к автолоаду идёт по глобальному имени, а не через переменную.
- Правило именования становится условным («зависит от того, автолоад ли это»), то есть чуть сложнее для запоминания, чем прежнее безусловное.

## Alternatives considered

- **Суффикс в имени автолоада** (`GameStateAutoload`, `class_name GameState`) — снимает конфликт, но делает обращения шумными (`GameStateAutoload.current_run`) и расходится с §6 и README, где автолоады названы коротко.
- **Суффикс в `class_name`** (`class_name GameStateSingleton` + автолоад `GameState`) — работает, но заводит бесполезный тип для каждого автолоада. Оставлено как точечное исключение для тестируемых случаев.
- **Отказ от автолоадов в пользу явного DI** — архитектурно чище, но противоречит §6 и промту, и заметно дороже для greybox-фазы.
