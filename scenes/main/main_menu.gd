extends Control
## Главное меню. Локальные сигналы удалены (SPEC-01 §3): меню эмитит в EventBus,
## иначе SceneRouter пришлось бы знать про конкретный узел сцены.

func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	# UI не мутирует состояние: слот грузит SaveManager, сцену меняет SceneRouter.
	EventBus.game_started.emit(SaveManager.DEFAULT_SLOT)


func _on_quit_pressed() -> void:
	get_tree().quit()
