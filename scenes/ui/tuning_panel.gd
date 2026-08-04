class_name TuningPanel extends Control
## F1-панель: ползунки тюнинга, применяются сразу и сохраняются в SettingsStore.
## T-03b Блок 1: добавлены hit_stop (хит-стоп попадания игрока) и slow_mo.

var arena: Node
var sliders: Dictionary = {}
var value_labels: Dictionary = {}
var definitions: Array[Dictionary] = [
	{"key": "iframes", "label": "Дэш i-frames", "min": 0.05, "max": 0.5, "step": 0.01, "suffix": " s"},
	{"key": "dash_cooldown", "label": "Кулдаун дэша", "min": 0.2, "max": 2.0, "step": 0.05, "suffix": " s"},
	{"key": "telegraph", "label": "Телеграф врага", "min": 0.1, "max": 1.0, "step": 0.05, "suffix": " s"},
	{"key": "enemy_damage", "label": "Урон врага", "min": 5.0, "max": 50.0, "step": 1.0, "suffix": ""},
	{"key": "scout_hp", "label": "HP скаута", "min": 25.0, "max": 200.0, "step": 5.0, "suffix": ""},
	{"key": "speed", "label": "Скорость скаута", "min": 100.0, "max": 400.0, "step": 5.0, "suffix": " px/s"},
	{"key": "hit_stop", "label": "Хит-стоп попадания", "min": 0.0, "max": 0.15, "step": 0.005, "suffix": " s"},
	{"key": "slow_mo", "label": "Slow-mo на смерть", "min": 0.1, "max": 0.5, "step": 0.01, "suffix": ""},
	{"key": "swarm_hp", "label": "HP роя", "min": 4.0, "max": 30.0, "step": 1.0, "suffix": ""},
	{"key": "swarm_damage", "label": "Урон роя", "min": 3.0, "max": 25.0, "step": 1.0, "suffix": ""},
	{"key": "swarm_speed", "label": "Скорость роя", "min": 160.0, "max": 420.0, "step": 5.0, "suffix": " px/s"},
	{"key": "shooter_hp", "label": "HP стрелка", "min": 8.0, "max": 60.0, "step": 1.0, "suffix": ""},
	{"key": "shooter_damage", "label": "Урон стрелка", "min": 3.0, "max": 25.0, "step": 1.0, "suffix": ""},
	{"key": "shooter_range", "label": "Дистанция стрелка", "min": 100.0, "max": 320.0, "step": 5.0, "suffix": " px"},
	{"key": "projectile_speed", "label": "Скорость снаряда", "min": 180.0, "max": 560.0, "step": 10.0, "suffix": " px/s"},
]

func _ready() -> void:
	arena = get_parent().get_parent()
	_build_panel()
	visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		visible = not visible
		get_viewport().set_input_as_handled()
		if visible:
			_refresh()

func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 102)
	panel.custom_minimum_size = Vector2(420, 0)
	add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var title := Label.new()
	title.text = "F1  TUNING LAB"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	var hint := Label.new()
	hint.text = "Изменения применяются сразу и сохраняются."
	hint.modulate = Color("#9fb8c5")
	column.add_child(hint)
	for definition: Dictionary in definitions:
		var header := HBoxContainer.new()
		var label := Label.new()
		label.text = str(definition["label"])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(label)
		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		header.add_child(value_label)
		column.add_child(header)
		var slider := HSlider.new()
		slider.min_value = float(definition["min"])
		slider.max_value = float(definition["max"])
		slider.step = float(definition["step"])
		slider.custom_minimum_size = Vector2(0, 24)
		var key: String = str(definition["key"])
		var suffix: String = str(definition["suffix"])
		slider.value_changed.connect(func(value: float) -> void:
			arena.set_parameter(key, value)
			value_label.text = _format(value, suffix)
		)
		column.add_child(slider)
		sliders[key] = slider
		value_labels[key] = value_label
	var footer := Label.new()
	footer.text = "F1 — скрыть   Esc — в хаб"
	footer.modulate = Color("#9fb8c5")
	column.add_child(footer)
	_refresh()

func _refresh() -> void:
	if arena == null:
		return
	for definition: Dictionary in definitions:
		var key: String = str(definition["key"])
		var value: float = arena.get_parameter(key)
		sliders[key].set_value_no_signal(value)
		value_labels[key].text = _format(value, str(definition["suffix"]))

func _format(value: float, suffix: String) -> String:
	if suffix == "":
		return str(roundi(value))
	return "%.2f" % value + suffix
