# 🧭 Аудит готовности Phase 1 (Greybox) — 31.07.2026

> **Статус документа:** research-артефакт (resolved `wayfinder:research`-тикет в терминах `.agents/skills/wayfinder`). Линкуется по имени; выводы распределены по адресам: правила → `CONTEXT.md`, контракты → `docs/adr/`, работа → GitHub Issues.
>
> **Метод:** полное чтение проектных документов (`README.md`, `CONTEXT.md`, `docs/prompt_hub_expeditions_professional.md`, 4 research-документа `docs/research/`, `docs/adr/`, `.agents/skills/`) + независимая интернет-верификация ключевых фактов (см. раздел 4).
>
> **Вердикт:** стартовать с Phase 1 — правильно (соответствует LTPF-пайплайну Исмаила, промт-контракту §17 и production-supplement §2.2). Стратегический уровень (зачем/что/риски) покрыт отлично. Исполнительский уровень («чтобы агенту не приходилось думать») — не полный: найдены 2 runtime-бага, 12 противоречий между документами и ряд пробелов спецификаций. Раздел 6 фиксирует, что уже исправлено этим аудитом; раздел 7 — что отложено на спеки/тикеты.

---

## 1. Critical: баги текущего состояния (найдены и исправлены 31.07.2026)

### 1.1. Главная сцена падала на старте

`scenes/main/main_menu.gd` обращается к `%StartButton` / `%QuitButton`, но в `scenes/main/main_menu.tscn` у узлов не было флага `unique_name_in_owner = true`. Синтаксис `%` резолвит только узлы с «Access as Unique Name» ([Godot docs: Scene Unique Nodes](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_unique_nodes.html)) — без флага `_ready()` падал. **Исправлено:** флаги добавлены.

Замечание (не баг, а пробел): сигнал `start_pressed` никем не слушается — bootstrap-переход MainMenu → HubScreen не спроектирован нигде. Это задача для будущей спеки «Bootstrap & State» (раздел 7).

### 1.2. Битый путь иконки

`project.godot` ссылался на `res://assets/icon.svg`, реальный файл — `res://assets/icon/icon.svg`. **Исправлено.**

---

## 2. Противоречия документов: реестр и разрешение

Легенда статуса: ✅ исправлено 31.07.2026 · 📌 зафиксировано решением, требует отражения при работе.

| # | Конфликт | Где было | Разрешение | Статус |
|---|----------|----------|------------|--------|
| 1 | **Версия движка** | Промт-док «Godot 4.6.stable» vs CONTEXT/ADR-001/README — 4.7.x | Godot 4.7 stable вышла 18.06.2026, 4.7.1 (78 фиксов) — 15.07.2026 → пин **4.7.1**. Промт-док обновлён по его же правилу «изменить строку явно»; CONTEXT.md и ADR-001 — пин 4.7.1 | ✅ |
| 2 | **Сохранения в Phase 1** | README Phase 1 (SaveManager + сериализация RunState/ProfileState + acceptance №8) vs промт §17 (сохранения — «Фаза 2») | Решено: **сейвы в Phase 1** — приоритет промта №3 «стабильность сохранений» + acceptance-требование полного цикла | 📌 аннотировано в промт-доке (Фаза 1) |
| 3 | **Нестабильная добыча** | CONTEXT.md «lost on death/evacuation» vs промт §9 и design-supplement §2.3 (только при смерти) | ✅ *Теряется только при смерти; эвакуация банкует 100%.* Иначе push-your-luck разваливается: «остановиться» ничего не сохраняет. Контракт — **ADR-002**; CONTEXT.md исправлен | ✅ |
| 4 | **«JSON via ConfigFile»** | ADR-001, CONTEXT.md | ConfigFile — INI-формат ([class ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html)). Решено: **JSON (FileAccess) для сейв-слотов; ConfigFile (INI) только для настроек** — как в промт-доке §14 | ✅ |
| 5 | **Нумерация фаз** | godot-47-supplement §16 («Фаза 0» = 1 узел, «Фаза 1» = граф 7 узлов) vs README/промт/design-supp §11 («Phase 1 Greybox» = 7 узлов сразу) | Каноническая таблица — **README «Phase 1 — Greybox» + design-supplement §11**. §16 помечен как superseded | ✅ |
| 6 | **100 vs 10 000 сидов в тестах графа** | design-supplement §4.3 vs промт «Definition of Done» | CI-гейт: **≥1000 сидов на инвариант**; полный прогон **10 000** — перед этапными релизами (не на каждый коммит) | 📌 аннотировано в §4.3 |
| 7 | **Доступность в Phase 1** | design-supplement §6.4 «начинается в Phase 1» vs план Phase 1 (settings-экрана нет) | Дешёвый минимум живёт в Phase 1 как **глобальный флаг** (`SettingsState.reduced_motion/shake_enabled` — выключатель тряски камеры, см. design-supp §6.3); полноценный экран настроек — Phase 2 | 📌 оставлено для спеки Combat/Bootstrap |
| 8 | **Gamepad** | One-screen UI contract (промт) требует gamepad для важных действий vs input-map без joypad-событий | Phase 1 — клавиатура+мышь; gamepad-маппинг — Phase 2 (дешёво добавить, но не блокер greybox) | 📌 отложено в Phase 2 |
| 9 | **GUT без пина версии** | godot-47-supplement §14, production-supplement §4.1 | Для Godot 4.7.x — **GUT 9.7.1** (ветка `godot_4_7`; таблица версий [bitwes/Gut](https://github.com/bitwes/Gut)). Пин внесён в оба документа | ✅ |
| 10 | **CI-образ `:4.7`** | production-supplement §5.2 | Проверенный тег — **`barichello/godot-ci:4.7.1`** ([Docker Hub](https://hub.docker.com/r/barichello/godot-ci), [Marketplace](https://github.com/marketplace/actions/godot-ci)) | ✅ |
| 11 | **«74 audited skills»** | AGENTS.md | Фактически в `.agents/skills/` — **50 godot-*** каталогов (68 всего). Исправлено на «50 curated Godot 4.5+ skills» | ✅ |
| 12 | Опечатка | README п.7 «скaut» | Исправлено на «scout» | ✅ |

---

## 3. Пробелы исполнительских спецификаций (НЕ исправляются аудитом — уходят в спеки Phase 1)

База знаний для этих спецификаций в репо **есть и точна** (см. раздел 5), но до состояния «агенту не приходится думать» каждый пункт Phase 1 должен получить спеку через `/to-spec` и тикеты через `/to-tickets` (GitHub Issues, `ready-for-agent`). Рекомендуемая нарезка спек (по естественным швам):

1. **Bootstrap & State** — autoload-реестр с порядком инициализации (требование godot-47-supplement §6), смена сцен (MainMenu → HubScreen → ExpeditionMap → CombatArena), поля `GameState/RunState/HubState/ProfileState/SaveEnvelope v1`, сейвы (референс production-supplement §6).
2. **Hub & Module #1** — выбор единственного модуля (рекомендация: **Кузница Формы ур.1** — зримо меняет правило боя → закрывает acceptance №5), поля `ModuleDefinition`, карточка по шаблону design-supplement §3.4, позиции сокетов.
3. **Expedition** — `RouteGraph` по инвариантам **G1–G8** (design-supplement §4.2) + тесты §4.3 (седа-контракт из таблицы выше), `ExpeditionController`, экстракция, UI-контракт карты (как игрок выбирает из 2–3 вариантов).
4. **Combat** — baseline-числа (скорость/HP разведчика, урон и кД снаряда, длительность и i-frames дэша, статы Преследователя, размер арены, 2–3 врага на узел, награды за узлы), матрица коллизий по слоям (World/Player/Enemy/Projectile/Pickup уже заданы в project.godot), контракт `AttackData`.

До запуска агента также нужна разовая инициализация workflow (сама по себе, см. `AGENTS.md`): метки GitHub (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, + `wayfinder:map/research/prototype/grilling/task`), секция «Wayfinding operations» в `docs/agents/issue-tracker.md`, `docs/status.md` (требуется промтами №1/№9 production-supplement §10), скелет `scripts/`, `data/`, `tests/` + GUT 9.7.1 + gdtoolkit.

---

## 4. Интернет-верификация фактов (31.07.2026)

| Утверждение в docs | Вердикт | Источник |
|---|---|---|
| Godot 4.7 «Lights, Camera, Action!» stable — 18.06.2026; HDR-вывод, Control offset transforms, DrawableTexture2D | ✅ Верно | [Wikipedia: Godot](https://en.wikipedia.org/wiki/Godot_(game_engine)); [vagon.io — What's new in Godot 4.7](https://vagon.io/blog/what-s-new-in-godot-4-7) |
| Godot 4.7.1 — maintenance-релиз | ✅ Верно (15.07.2026, 78 фиксов) | [anons 4.7.1](https://www.warp2search.net/story/godot-471-released-quick-stability-patch-fixes-rendering-and-platform-bugs) |
| «HDR-вывод ≠ glow в Compatibility; glow в Compatibility не поддержан» → рекомендация additive-фейка (design-supp §7.3) | ✅ Верно | [godot#62110](https://github.com/godotengine/godot/issues/62110); [r/godot](https://www.reddit.com/r/godot/comments/1b6iar6/need_help_with_glow_not_working_godot_4/) |
| SaveManager-референс: `DirAccess.copy_absolute` / `rename_absolute` — существуют, rename перезаписывает файлы | ✅ API валидно (перезапись проблемна только для каталогов) | [class DirAccess](https://docs.godotengine.org/en/stable/classes/class_diraccess.html); [godot#114267](https://github.com/godotengine/godot/issues/114267) |
| `%` unique node names требуют флага | ✅ Верно (основание бага 1.1) | [docs: Scene Unique Nodes](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_unique_nodes.html) |
| StS-генерация: 7×15, 6 путей, ≥2 входа, вёдра 5/12/22/8%, запреты подряд/у родителя | ✅ Верно | [r/slaythespire reverse-engineering](https://www.reddit.com/r/slaythespire/comments/ndqweh/) |
| Loop Hero 100/60/30% | ✅ Верно | [PCGamesN review](https://www.pcgamesn.com/loop-hero/review) |
| gdtoolkit `pip install "gdtoolkit==4.*"` | ✅ Верно (актуальная 4.5.0) | [PyPI](https://pypi.org/project/gdtoolkit/) |
| GUT для Godot 4.7.x | ⚠️ Уточнено: нужен GUT 9.7.1 (`godot_4_7`) | [bitwes/Gut version table](https://github.com/bitwes/Gut) |
| `@coding-solo/godot-mcp` (`.mcp.json`) | ✅ Пакет существует (0.1.1, MIT); оригинал обновляется редко — запасной вариант: форк `tugcantopaloglu/godot-mcp` (тестирован на 4.7) | [mcp.so](https://mcp.so/server/godot-mcp/Coding-Solo); npm registry |
| `barichello/godot-ci` | ⚠️ Уточнён тег: `4.7.1` / `4.7.1-stable` | [Docker Hub](https://hub.docker.com/r/barichello/godot-ci) |

---

## 5. Что прописано точно и проверено — НЕ трогать

- **Инварианты графа G1–G8 + sample-GUT-тесты** — design-supplement §4.2–4.3 (готовый контракт).
- **Production SaveManager** — production-supplement §6 (API валидирован, атомарность .tmp→rename корректна для файлов).
- **Autoload-жёсткие правила** — godot-47-supplement §6; hitbox/hurtbox + композиция §3/§7; DTO-посредник «модули↔экспедиции» §10; RNG-потоки §11.
- **Экономика §3.3, бюджет забега §5.1, push-your-luck математика §2.2** — design-supplement (стартовые гипотезы).
- **Промты №1–№9** — production-supplement §10 (workflow остаётся как есть).

---

## 6. Изменения, внесённые аудитом (31.07.2026)

- `project.godot` — путь иконки → `res://assets/icon/icon.svg`.
- `scenes/main/main_menu.tscn` — `unique_name_in_owner = true` у StartButton/QuitButton.
- `CONTEXT.md` — правило нестабильной добычи (→ ADR-002), формат сейвов (JSON/ConfigFile), пин Godot 4.7.1, ссылки на этот аудит.
- `docs/adr/ADR-001` — уточнены версия движка и формат сейвов.
- `docs/adr/ADR-002` — **новый**: контракт нестабильной добычи (таблица исходов).
- `docs/prompt_hub_expeditions_professional.md` — «Зафиксированная техническая база» обновлена до Godot 4.7.1 (+ отметка о сейвах в Phase 1).
- `README.md` — опечатка «скaut» → «scout».
- `docs/research/godot-47-supplement.md` — пин GUT 9.7.1 (§14); §16 помечен superseded (каноничен README).
- `docs/research/production-and-ai-workflow-supplement.md` — пин GUT 9.7.1 (§4.1); CI-образ `barichello/godot-ci:4.7.1` (§5.2).
- `docs/research/design-and-release-supplement.md` — §2.3: ссылка на ADR-002; §4.3: седа-контракт CI/full.
- `AGENTS.md` — «74 audited skills» → «50 curated Godot 4.5+ skills».

## 7. Отложено (следующий шаг — по выбору владельца)

- Инициализация workflow: метки GitHub, секция «Wayfinding operations» в `docs/agents/issue-tracker.md`, `docs/status.md`.
- 4 спеки (`/to-spec`) + тикеты (`/to-tickets`) по разделу 3 → GitHub Issues с `ready-for-agent`.
- Baseline-числа боя и матрица коллизий → `docs/specs/phase-1/` (файлами, линкуются из ишью).
- GUT 9.7.1 в `addons/` + gdtoolkit-конфиг + `.gitattributes` (LFS до первых ассетов).
</content>
