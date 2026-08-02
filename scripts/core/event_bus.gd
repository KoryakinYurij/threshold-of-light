extends Node
## Шина событий. Автолоад №1: ноль зависимостей, на неё подписываются все.
## Без class_name (ADR-005) — имя даёт только регистрация автолоада.
##
## Правило: UI не мутирует состояние. UI эмитит `*_requested`,
## владеющая система отвечает past-tense событием.

# --- Навигация ---
## Меню запросило вход в игру. Слот, с которого играем.
signal game_started(slot: int)
signal expedition_requested()
signal expedition_started(master_seed: int)
signal node_entered(node_index: int, node_type: int)
signal node_cleared(node_index: int, rewards: Dictionary)
signal extraction_completed(rewards: Dictionary)
signal scout_died(node_index: int)
signal returned_to_hub()

# --- Хаб ---
signal module_built(module_id: String, level: int)
signal module_upgrade_requested(module_id: String)

# --- Персистентность ---
## reason: "hub" | "node_cleared" | "extraction" | "death"
signal save_requested(reason: String)
signal save_completed(slot: int, ok: bool)
