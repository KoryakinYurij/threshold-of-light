# AGENTS.md

## Обзор

Godot 4.7.1 stable, GDScript, 2D. Ветка `прототип-дипсик` — одноразовый прототип: в `master` возвращаются только выводы, не код.

## Сборка и тесты

- `tools\test.cmd` — тесты. Ждать `ЗЕЛЕНО` и `RC=0`.
- `godot --headless --path . res://tests/combat_smoke.tscn` — смоук боя.
- `godot --headless --path . --import` — обязательно после добавления скрипта с `class_name`.
- Сборка exe — `docs/prototype/BUILD.md`. Работа с Windows-машиной — `docs/windows-development.md`.

## Документация

**Один журнал вместо отчётов.** После задачи дописывай запись **снизу** в `docs/prototype/JOURNAL.md`, не длиннее 20 строк, формат — как у соседних записей.

Запрещено:
- Создавать `REPORT-*.md`, `LESSONS-*.md`, `REVIEW-*.md`, `HANDOFF.md`. Всё идёт в журнал.
- Дублировать текстом то, что видно в коде, в `git log` или в тестах.
- Описывать то, чего ещё нет в коде.

Живые документы — правь их, новых не заводи:
`docs/prototype/PLAN-v0.1-deepseek.md` (план и статус) · `docs/prototype/ANSWERS-v0.1.md` (ответы на дизайн-вопросы) · `docs/prototype/BUILD.md` (сборка) · `CONTEXT.md` (термины) · `README.md` (для человека).

Устаревшее удаляй, а не архивируй: история лежит в `git`.

## Скиллы и справочники — рекомендация, не контракт

Обязательны только `docs/adr/*` и `CONTEXT.md`. Всё остальное — совет.

- `.agents/skills/` — общая библиотека скиллов по Godot, написана не под эту игру. Читай точечно, когда задача прямо совпадает со скиллом. Отклонение от скилла обоснования не требует.
- `docs/research/*` и `docs/prompt_hub_expeditions_professional.md` — справочники, а не источник требований.
- **Запрещено** объявлять блокером то, что требует скилл или справочник. Блокер — это упавший тест, сломанная сборка или нарушение ADR.

## Границы

- Ветки `master` и `proto/v0.1` не трогать. Работа только в `прототип-дипсик`.
- В `master` из этой ветки ничего не мержить.
- Дизайнерские развилки не решай сам: записывай в `docs/design/OPEN-QUESTIONS.md` и ставь метку `ready-for-human`.

## Agent skills

### Issue tracker

GitHub Issues in this repository. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Design questions

Owner-level design forks (mechanics, risk, game feel) live in `docs/design/OPEN-QUESTIONS.md`. Agents do not settle them: record the fork there and apply `ready-for-human` instead of choosing.

### Domain docs

Single-context layout. `CONTEXT.md` + `docs/adr/` for ADRs. See `docs/agents/domain.md`.

### Development handbook

Comprehensive guide for game development with AI assistants. See `docs/research/game-dev-handbook.md`.

### Godot 4.7 + genre supplement

Godot 4.7 / GDScript specifics, roguelite run structure, and project-technical details. See `docs/research/godot-47-supplement.md`.

### Design & release supplement

Game-design and production companion: extraction risk/reward math, economy faucet/sink design, StS-style graph generation invariants, game feel, 2D lighting in Compatibility renderer, localization, playtesting, and Steam/itch.io release path. See `docs/research/design-and-release-supplement.md`.

### Production & AI-workflow supplement

Production pipeline (prototype vs vertical slice, phase mapping), solo tool stack with licenses, CI/CD reference (gdtoolkit + GUT + Godot CI + Butler), production-grade SaveManager reference, anti-patterns, and the project's AI prompt library. See `docs/research/production-and-ai-workflow-supplement.md`.

### Required MCP Server: godot-mcp
**CRITICAL FOR ALL AGENTS:** Working in this repository requires the **`godot-mcp`** server ([Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)). It bridges the AI agent with Godot 4.7, allowing process execution, scene launching, and real-time debug log capture.
- Root configuration file: `.mcp.json`
- Command: `npx -y @coding-solo/godot-mcp`
- Skill reference: `.agents/skills/godot-mcp-setup/SKILL.md`

### Godot 4 Agentic Skills (thedivergentai/gd-agentic-skills)

Библиотека из ~50 скиллов по Godot 4.5+ лежит в `.agents/skills/`. Список — командой `dir .agents/skills`. Это рекомендации, см. раздел «Скиллы и справочники».

### Engineering workflow skills (mattpocock/skills)

Лежат в `.agents/skills/`, лицензия MIT. Список — `dir .agents/skills`. Рекомендации.
Скилл `/handoff` в этом проекте **не использовать** — вместо handoff-документа пиши запись в журнал.
