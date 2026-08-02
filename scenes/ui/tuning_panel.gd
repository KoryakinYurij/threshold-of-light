class_name TuningPanel extends PanelContainer
## Панель ползунков, F1. Строки собираются из `CombatTuning.SPECS`, а не
## руками: добавить ползунок должно значить «добавить строку в SPECS».
##
## Правки уходят в память сразу (бой меняется под пальцами), на диск —
## на отпускание ползунка: писать файл каждый кадр перетаскивания незачем.

signal restart_requested()

@onready var _rows: VBoxContainer = %Rows
@onready var _toggles: VBoxContainer = %Toggles

var _value_labels: Dictionary = {}


func _ready() -> void:
	visible = false
	%ResetButton.pressed.connect(_on_reset)
	%RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	_build()


func toggle() -> void:
	visible = not visible
	if not visible:
		CombatTuning.flush()


func _build() -> void:
	for spec: Dictionary in CombatTuning.SPECS:
		_rows.add_child(_make_slider_row(spec))
	for spec: Dictionary in CombatTuning.TOGGLES:
		_toggles.add_child(_make_toggle(spec))


func _make_slider_row(spec: Dictionary) -> Control:
	var key := String(spec["key"])
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 0)

	var head := HBoxContainer.new()
	var caption := Label.new()
	caption.text = "%s  ·  %s" % [spec["label"], spec["src"]]
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(caption)

	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(110, 0)
	head.add_child(value)
	_value_labels[key] = value
	row.add_child(head)

	var slider := HSlider.new()
	slider.min_value = float(spec["min"])
	slider.max_value = float(spec["max"])
	slider.step = float(spec["step"])
	slider.value = CombatTuning.f(key)
	slider.value_changed.connect(_on_slider_changed.bind(key))
	slider.drag_ended.connect(_on_drag_ended)
	row.add_child(slider)

	_refresh_value_label(key, slider.value)
	return row


func _make_toggle(spec: Dictionary) -> Control:
	var key := String(spec["key"])
	var box := CheckBox.new()
	box.text = String(spec["label"])
	box.button_pressed = CombatTuning.b(key)
	box.toggled.connect(func(on: bool) -> void:
		CombatTuning.set_value(key, on)
		CombatTuning.flush()
		EventBus.tuning_changed.emit()
	)
	return box


func _on_slider_changed(value: float, key: String) -> void:
	CombatTuning.set_value(key, value)
	_refresh_value_label(key, value)
	EventBus.tuning_changed.emit()


func _on_drag_ended(value_changed: bool) -> void:
	if value_changed:
		CombatTuning.flush()


func _refresh_value_label(key: String, value: float) -> void:
	if not _value_labels.has(key):
		return
	var spec := CombatTuning.spec_of(key)
	var label: Label = _value_labels[key]
	var shown := "%.2f" % value if float(spec["step"]) < 1.0 else "%d" % int(round(value))
	label.text = "%s %s" % [shown, spec["unit"]]


func _on_reset() -> void:
	CombatTuning.reset_to_defaults()
	CombatTuning.flush()
	EventBus.tuning_changed.emit()
	# Перестроить проще, чем разыскивать каждый ползунок и гасить его сигнал.
	for child: Node in _rows.get_children():
		child.queue_free()
	for child: Node in _toggles.get_children():
		child.queue_free()
	_value_labels.clear()
	await get_tree().process_frame
	_build()
