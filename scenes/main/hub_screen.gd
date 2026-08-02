extends Control
## Заглушка хаба (T-02, план: «заглушка вместо сцены — норма»).
## Настоящий хаб с маяком и сокетами — T-05.

func _ready() -> void:
	%HubLabel.text = "Хаб — заглушка (T-05)\n\nМатериалы: %d\nНестабильная добыча: %d" % [GameState.hub.materials, GameState.hub.unstable_loot]
