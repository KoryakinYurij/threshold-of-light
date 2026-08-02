extends Control
## Заглушка хаба (T-02, план: «заглушка вместо сцены — норма»).
## Настоящий хаб с маяком и сокетами — T-05.
## T-03: кнопка «Тестовый бой» ведёт на арену через EventBus.combat_requested.

func _ready() -> void:
	%HubLabel.text = "Хаб — заглушка (T-05)\n\nМатериалы: %d\nНестабильная добыча: %d" % [GameState.hub.materials, GameState.hub.unstable_loot]
	%CombatButton.pressed.connect(_on_combat_pressed)


func _on_combat_pressed() -> void:
	EventBus.combat_requested.emit()
