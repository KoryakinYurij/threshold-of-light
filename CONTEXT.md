# CONTEXT.md

## Project

**Threshold of Light / Порог Света** — 2D hub-builder + extraction-lite + action-roguelite.

- Working title: `threshold-of-light`
- Engine: Godot 4.7.x stable
- Renderer: Compatibility (Windows first)
- Language: GDScript 2.0 with static typing
- Target: PC first, potential Web export later

## Domain language

- **Hub** — single persistent screen with central Lighthouse and modular sockets around it.
- **Module** — buildable/upgradeable structure in the Hub that changes expedition rules.
- **Expedition** — short (5–12 min) run through a 7-node graph of encounters.
- **Node** — one encounter on the expedition graph: combat, resource, event, safe camp, extraction, elite, guardian.
- **Scout** — player character sent into expeditions. Human silhouette (greybox: simple geometry).
- **Route** — ordered path through the expedition graph, chosen sequentially (2–3 options per step).
- **Extraction** — voluntary end of expedition at an extraction node; preserves stable loot, loses unstable loot on death.
- **Light** — passive hub resource, powers modules.
- **Materials** — expedition resource, spent on hub modules.
- **Memories** — expedition reward, unlocks rules, modifiers, new enemies/events.
- **Unstable Loot** — high-value expedition resource, lost on death/evacuation.
- **Modifier** — temporary run upgrade chosen after encounters; changes gameplay style, not just numbers.
- **RunState** — mutable state during a single expedition.
- **HubState** — persistent hub layout, module levels, unlocked content.
- **ProfileState** — permanent unlocks, discoveries, settings.

## Architecture rules

- UI never mutates resources directly; it emits signals to the owning system.
- Systems cache node references; no `get_node()` inside loops.
- No God object; split into `GameState`, `RunState`, `HubState`, `ProfileState`.
- Visual Nodes are reconstructed from state after load; no Node references in save data.
- Stable runtime IDs for entities; signals named as past-tense events (`item_collected`, `enemy_defeated`, `module_built`).
- Fixed simulation tick for economy; physics tick for movement/collisions.
- Seed-controlled reproducible expeditions.
- Custom Resources for static definitions in `res://data/`; edit in Inspector.

## Naming

- Scenes: PascalCase (e.g., `HubScreen.tscn`)
- Scripts: PascalCase matching attached node (e.g., `hub_screen.gd`)
- Groups: snake_case (e.g., `enemies`, `interactables`)
- Data Resources: PascalCase + `Definition` suffix (e.g., `EnemyDefinition.tres`)

## Version

Godot 4.7.x stable.

## MVP scope

See `README.md` for full design doc.

## Key decisions

- See `docs/adr/` for architecture decision records.
- See `docs/research/game-dev-handbook.md` for the comprehensive development guide.
- No external dependencies for MVP core loop.
- Save format: JSON via `ConfigFile` for MVP, atomic write, 3 slots, backup.
- Hub layout: fixed socket positions around lighthouse (no free drag-and-drop in MVP).
- Expedition navigation: sequential choice (2–3 visible options per step).
- Audio: deferred to Phase 2.
- Scout visual: human silhouette; greybox uses simple geometry first.
