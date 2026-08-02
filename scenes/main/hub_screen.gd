extends Control
## Заглушка хаба для T-02. Ни экономики, ни модулей — только кнопки,
## которыми владелец руками проверяет, что каркас работает:
## состояние меняется, пишется на диск и переживает перезапуск .exe.
##
## T-05 заменит эту сцену настоящим хабом.

@onready var _status: Label = %StatusLabel


func _ready() -> void:
	%AddMaterialsButton.pressed.connect(_on_add_materials)
	%NewRunButton.pressed.connect(_on_new_run)
	%SaveButton.pressed.connect(_on_save)
	%ReloadButton.pressed.connect(_on_reload)
	%MenuButton.pressed.connect(_on_menu)
	EventBus.save_completed.connect(_on_save_completed)
	_refresh()


func _refresh() -> void:
	var run_line := "нет"
	if GameState.has_run():
		var r := GameState.current_run
		run_line = "сид %d · узел %d" % [r.master_seed, r.current_node_index]
	_status.text = "\n".join([
		"Слот: %d" % SaveManager.current_slot,
		"Материалы: %d" % GameState.hub.materials,
		"Память: %d" % GameState.profile.memories,
		"Забегов: %d завершено / %d смертей" % [
			GameState.profile.runs_completed, GameState.profile.runs_died
		],
		"Текущий забег: %s" % run_line,
	])


func _on_add_materials() -> void:
	GameState.hub.materials += 10
	GameState.profile.memories += 1
	_refresh()


func _on_new_run() -> void:
	var run := GameState.begin_run()
	run.current_node_index = 1
	run.visited_nodes = PackedInt32Array([0, 1])
	run.scout_hp = 100
	_refresh()


func _on_save() -> void:
	EventBus.save_requested.emit("hub")


func _on_reload() -> void:
	SaveManager.load_from_slot(SaveManager.current_slot)
	_refresh()


func _on_save_completed(slot: int, ok: bool) -> void:
	_status.text += "\n\n%s слот %d" % ["Сохранено в" if ok else "ОШИБКА записи в", slot]


func _on_menu() -> void:
	SceneRouter.go_to_main_menu()
