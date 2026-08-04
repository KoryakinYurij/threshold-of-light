class_name MaterialShard extends Node2D
## Осколок дропа (T-03b Блок 2): спавнится у трупа, притягивается к скауту,
## подхват = +1 материал или +10 HP (лечебный, 15% шанс). Реальное время
## (PROCESS_MODE_ALWAYS + unscaled delta) — не замирает на slow-mo/хит-стопе.
## Визуал — только цвет; движение детерминировано от сидированного RNG арены.

enum Kind { MATERIAL, HEAL }

const PICKUP_DISTANCE: float = 30.0
const SEEK_SPEED: float = 280.0

var kind: Kind = Kind.MATERIAL
var _arena: Node
var _vel: Vector2 = Vector2.ZERO

func setup(arena: Node, shard_kind: Kind, at: Vector2, scatter: Vector2) -> void:
	_arena = arena
	kind = shard_kind
	global_position = at
	_vel = scatter

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 50

func _physics_process(delta: float) -> void:
	var unscaled: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	var scout: Node = _arena.scout
	if not is_instance_valid(scout) or scout.get("dead") == true:
		queue_free()
		return
	var to_scout: Vector2 = scout.global_position - global_position
	if to_scout.length() <= PICKUP_DISTANCE:
		if kind == Kind.HEAL:
			_arena.collect_heal(self)
		else:
			_arena.collect_material(self)
		queue_free()
		return
	_vel = _vel.lerp(to_scout.normalized() * SEEK_SPEED, unscaled * 6.0)
	global_position += _vel * unscaled
	queue_redraw()

func _draw() -> void:
	if kind == Kind.HEAL:
		draw_circle(Vector2.ZERO, 6.0, Color("#7dffb0"))
		draw_circle(Vector2.ZERO, 6.0, Color("#143a28"), false, 1.5)
	else:
		draw_circle(Vector2.ZERO, 5.0, Color("#ffd76a"))
		draw_circle(Vector2.ZERO, 5.0, Color("#4a3a14"), false, 1.5)
