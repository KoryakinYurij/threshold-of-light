class_name HitParticles extends Node2D
## Частицы попадания (T-03b Блок 1): 6 точек, разлёт ~150px/s, жизнь 0.35с.
## Реальное время (не замирают на хит-стопе). Случайность только визуальная
## (направления/скорость разлёта) — не геймплейный RNG.

const COUNT: int = 6
const SPEED: float = 150.0
const LIFE: float = 0.35

var _angles: Array[float] = []
var _speeds: Array[float] = []
var _offsets: Array[Vector2] = []
var _elapsed: float = 0.0

func setup(at: Vector2) -> void:
	global_position = at
	var visual := RandomNumberGenerator.new()
	visual.randomize()
	for i: int in COUNT:
		_angles.append(TAU * float(i) / float(COUNT) + visual.randf_range(-0.35, 0.35))
		_speeds.append(visual.randf_range(0.7, 1.3) * SPEED)
		_offsets.append(Vector2.ZERO)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 55

func _process(delta: float) -> void:
	var unscaled: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	_elapsed += unscaled
	if _elapsed >= LIFE:
		queue_free()
		return
	for i: int in COUNT:
		_offsets[i] += Vector2.from_angle(_angles[i]) * _speeds[i] * unscaled
	queue_redraw()

func _draw() -> void:
	var alpha: float = clampf(1.0 - _elapsed / LIFE, 0.0, 1.0)
	for i: int in COUNT:
		draw_circle(_offsets[i], 3.0, Color(1.0, 0.88, 0.5, alpha))
