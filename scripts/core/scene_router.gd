extends Node
## Смена сцен по сигналам шины (SPEC-01 §1, автолоад №5). Единственное место,
## где вызывается change_scene_to_file — сцены друг о друге не знают.
## Без class_name (ADR-005).
##
## Маршруты — SPEC-01 §3. Сцены экспедиции (expedition_map, combat_arena)
## появятся в T-03/T-04: пока их нет, маршрут логирует ошибку и не переключает.

const HUB_SCENE: String = "res://scenes/main/hub_screen.tscn"
const EXPEDITION_MAP_SCENE: String = "res://scenes/expedition/expedition_map.tscn"
const COMBAT_ARENA_SCENE: String = "res://scenes/combat/combat_arena.tscn"


func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.expedition_requested.connect(func() -> void: _goto(EXPEDITION_MAP_SCENE))
	EventBus.node_entered.connect(_on_node_entered)
	EventBus.node_cleared.connect(func(_index: int, _rewards: Dictionary) -> void: _goto(EXPEDITION_MAP_SCENE))
	EventBus.extraction_completed.connect(func(_rewards: Dictionary) -> void: _goto(HUB_SCENE))
	EventBus.scout_died.connect(func(_index: int) -> void: _goto(HUB_SCENE))
	EventBus.returned_to_hub.connect(func() -> void: _goto(HUB_SCENE))


func _on_game_started(_slot: int) -> void:
	_goto(HUB_SCENE)


## Боевой узел ведёт на арену; остальные типы остаются на карте (T-04 уточнит).
func _on_node_entered(node_index: int, node_type: int) -> void:
	if node_type == 0:  # COMBAT — см. T-04, там появится enum типов узлов
		_goto(COMBAT_ARENA_SCENE)
	else:
		_goto(EXPEDITION_MAP_SCENE)


func _goto(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: %s не существует (появится в T-03/T-04), сцена не переключена" % path)
		return
	get_tree().change_scene_to_file(path)
