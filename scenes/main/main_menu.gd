extends Control

signal quit_pressed

func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	# SPEC-01 §3: меню эмитит в EventBus, локальный start_pressed удалён.
	# Слот 0 — дефолтный; выбор слота появится с меню в T-07.
	EventBus.game_started.emit(0)

func _on_quit_pressed() -> void:
	quit_pressed.emit()
	get_tree().quit()
