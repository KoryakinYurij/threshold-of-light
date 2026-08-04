class_name DamageNumber extends Node2D
## Всплывающий текст урона (T-03b Блок 1): подъём 30px, fade 0.6с.
## Живёт в реальном времени (PROCESS_MODE_ALWAYS + unscaled delta), чтобы не
## замирать на хит-стопе. Визуал — не геймплейный RNG, шум не используется.

const RISE: float = 30.0
const LIFETIME: float = 0.6

var _elapsed: float = 0.0

## Цвет по умолчанию — жёлтый (урон); лечение (Блок 2) передаёт зелёный.
func setup(text_value: String, at: Vector2, text_color: Color = Color(1.0, 0.92, 0.55)) -> void:
	global_position = at
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.03))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-24, -14)
	label.size = Vector2(48, 28)
	add_child(label)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 60

func _process(delta: float) -> void:
	var unscaled: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	_elapsed += unscaled
	if _elapsed >= LIFETIME:
		queue_free()
		return
	position.y -= RISE * (unscaled / LIFETIME)
	modulate.a = 1.0 - _elapsed / LIFETIME
