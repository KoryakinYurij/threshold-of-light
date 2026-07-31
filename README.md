# Порог Света / Threshold of Light

2D hub-builder + extraction-lite + action-roguelite.

- **Engine:** Godot 4.7.x
- **Language:** GDScript 2.0 (static typing)
- **Renderer:** Compatibility
- **License:** MIT
- **Status:** Pre-production, documentation phase

## Quick summary

Игрок управляет живым маяком на границе тёмного мира. На постоянном экране хаба строит модули вокруг центрального маяка. Отправляет разведчика в короткие (5–12 мин) процедурные экспедиции по графу из 7 узлов, сражается, добывает ресурсы и решает: рисковать дальше или эвакуироваться. После возвращения добыча идёт на строительство. Ключевая мета-идея: модули меняют правила экспедиции, а экспедиции меняют хаб.

## Documentation

- `docs/prompt_hub_expeditions_professional.md` — исходный продуктовый и технический промт
- `docs/adr/` — архитектурные решения
- `CONTEXT.md` — доменный язык и архитектурные правила проекта

## Architecture

```
res://
  scenes/
    main/           → Main меню, bootstrap
    hub/            → HubScreen, HubModuleView, ModuleSlot
    expedition/     → ExpeditionMap, RouteNode, ExtractionZone
    combat/         → CombatArena, Player, Enemy, Projectile
    entities/       → Shared entity components
    ui/             → HUD, resource bar, modifier picker
  scripts/
    core/           → GameState, EventBus, SeedService, SimulationClock
    hub/            → HubSystem, ModuleSystem, PlacementSystem
    expedition/     → ExpeditionController, RouteGraph, ExtractionSystem
    combat/         → CombatDirector, DamageSystem, Hitbox/Hurtbox, FSM
    progression/    → ModifierSystem, UnlockSystem, BuildSystem
    persistence/    → SaveManager, SaveSchema, SaveMigrations
  data/
    hub_modules/    → ModuleDefinition ресурсы
    enemies/        → EnemyDefinition ресурсы
    encounters/     → EncounterDefinition ресурсы
    modifiers/      → ModifierDefinition ресурсы
    loot_tables/    → LootTable ресурсы
  tests/            → Unit/integration тесты
  assets/           → Аудио, шрифты, текстуры (позже)
```

## MVP constraints

- 2D only.
- Хаб — один постоянный экран.
- Экспедиция — 7 узлов, seed-воспроизводимый граф.
- 4 ресурса: Свет, Материалы, Воспоминания, Нестабильная добыча.
- 3 врага, 1 стартовое оружие, 1 способность, 1 уклонение.
- 5 модулей хаба, каждый с 3 уровнями и trade-off.
- Сохранения: JSON, atomic write, 3 слота, backup.
- Без внешних зависимостей в MVP.

## Phase 1 — Greybox (goal: полный цикл без placeholder-меню)

1. GameState + EventBus + SeedService
2. SaveManager
3. HubScreen с центральным маяком и 1 модулем
4. ModuleDefinition (Custom Resource)
5. ExpeditionMap — 7 узлов, seed-генератор с инвариантами
6. ExpeditionController — переход между узлами
7. Player (scout) — движение, projectile, dash
8. Enemy (Преследователь) — FSM: IDLE → SEEK → ATTACK → RECOVER
9. CombatDirector — урон, death, награда
10. ExtractionSystem — эвакуация, возврат в хаб
11. RunState + ProfileState — сериализация

## Acceptance criteria for Phase 1

- [ ] Хаб отображается с маяком и 1 модулем.
- [ ] Запуск экспедиции → карта из 7 узлов.
- [ ] Прохождение минимум 2 узлов → эвакуация → возврат в хаб.
- [ ] Добытые ресурсы тратятся на улучшение модуля.
- [ ] Улучшение модуля меняет хотя бы одно правило экспедиции.
- [ ] Полный цикл работает без ручного редактирования состояния.
- [ ] Тот же seed даёт тот же граф.
- [ ] Сохранение в хабе и после эвакуации работает; после смерти сохраняется профиль.

## Development

Требуется Godot 4.7.x stable. Откройте `project.godot` в редакторе и запустите основную сцену.

### ⚠️ Первый запуск: проект ещё ни разу не открывали в редакторе

Все файлы (`project.godot`, `.tscn`) написаны текстом вручную. Признаки: нет `.godot/`, нет
`*.import`-сайдкаров у ассетов, нет `*.uid`-сайдкаров у скриптов, а `main_menu.tscn` ссылается
на скрипт через `path=` без `uid=`.

Отсюда следствие, которое важно знать до первого коммита сцен: **UID в `main_menu.tscn`
недействителен**. Там стоит `uid="uid://bq6v0xmainmenu"` — 14 символов после `uid://`, тогда как
движок (`core/io/resource_uid.cpp`) допускает максимум 13:

```cpp
static constexpr uint8_t max_uuid_number_length = 13;
// Max 0x7FFFFFFFFFFFFFFF (uid://d4n4ub6itg400) size is 13 characters.
```

Строка переполняет uint64 при парсинге, и редактор молча заменит её при первом сохранении сцены
(прогон алгоритма `text_to_id` даёт `uid://xlpavb8by0sw` — round-trip не сохраняется).

**Правильный порядок действий, а не ручная правка UID:**

1. Открыть проект в Godot 4.7.x — редактор создаст `.godot/`, сгенерирует `*.import` и `*.uid`.
2. Пересохранить `main_menu.tscn` (Ctrl+S) — движок перепишет UID на валидный и добавит `uid=`
   в ссылку на скрипт.
3. **Закоммитить** появившиеся `*.uid` и `*.import` — они часть состояния проекта, не артефакты
   сборки ([Godot: UID changes in 4.4](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)).
4. При перемещении скриптов через `git mv` двигать `.gd.uid` вместе с `.gd`, иначе ссылки рвутся.

Писать UID руками не нужно ни здесь, ни в новых сценах — их выдаёт редактор.

## License

MIT

## Windows Development

See docs/windows-development.md for the verified local Godot setup and daily workflow.
