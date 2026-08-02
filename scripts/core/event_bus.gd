extends Node
## Шина событий. Автолоад №1: ноль зависимостей, на неё подписываются все.
## Без class_name (ADR-005) — имя даёт только регистрация автолоада.
##
## Правило (CONTEXT.md): UI не мутирует состояние. UI эмитит `*_requested`,
## владеющая система отвечает past-tense событием.
##
## Набор сигналов — SPEC-01 §2. Дополнительно `game_started` (решение
## SPEC-01 §3: меню эмитит в EventBus; слот забирает SaveManager и SceneRouter).

# --- Навигация ---
## Меню запустило игру. Слот, с которого играем (0..2).
signal game_started(slot: int)
signal expedition_requested()
signal node_entered(node_index: int, node_type: int)
signal node_cleared(node_index: int, rewards: Dictionary)
signal extraction_completed(rewards: Dictionary)
signal scout_died(node_index: int)
signal returned_to_hub()

# --- Хаб ---
signal module_built(module_id: String, level: int)
signal module_upgrade_requested(module_id: String)

# --- Персистентность ---
## reason: "hub" | "node_cleared" | "extraction" | "death" (SPEC-01 §6).
signal save_requested(reason: String)
signal save_completed(slot: int, ok: bool)
