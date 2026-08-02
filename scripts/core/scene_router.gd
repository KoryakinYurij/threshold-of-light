extends Node
## Переключение сцен. Автолоад №5: зависит только от EventBus.
## Без class_name (ADR-005).
##
## Единственное место в проекте, где вызывается change_scene_to_file.
## Сцены друг о друге не знают (SPEC-01 §3).

const SCENE_MAIN_MENU: String = "res://scenes/main/main_menu.tscn"
const SCENE_HUB: String = "res://scenes/main/hub_screen.tscn"


func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.returned_to_hub.connect(_on_returned_to_hub)


func go_to_main_menu() -> void:
	_switch(SCENE_MAIN_MENU)


func _on_game_started(_slot: int) -> void:
	_switch(SCENE_HUB)


func _on_returned_to_hub() -> void:
	_switch(SCENE_HUB)


func _switch(path: String) -> void:
	# Отложенно: переключение прямо из обработчика сигнала сносит узел,
	# который этот сигнал ещё обрабатывает.
	_do_switch.call_deferred(path)


func _do_switch(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: не переключиться на %s (код %d)" % [path, err])
