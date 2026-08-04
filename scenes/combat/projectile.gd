class_name Projectile extends Area2D
## Снаряд стрелка (T-03b Блок 3): летит по прямой, попадает по хёртбоксу
## скаута (слой Player). Живёт в реальном времени (не замирает на хит-стопе).
## Урон через DamageData.AttackType.RANGED.

const LIFE: float = 2.2
const RADIUS: float = 6.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var speed: float = 340.0
var source_id: int = 0
var _elapsed: float = 0.0
var _hit: bool = false

func setup(origin: Vector2, dir: Vector2, amount: int, sid: int, shot_speed: float = 340.0) -> void:
	global_position = origin
	direction = dir.normalized()
	damage = amount
	source_id = sid
	speed = shot_speed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # Player (Hurtbox скаута)
	area_entered.connect(_on_area_entered)
	z_index = 40

func _physics_process(delta: float) -> void:
	var unscaled: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	_elapsed += unscaled
	if _elapsed >= LIFE:
		queue_free()
		return
	global_position += direction * speed * unscaled
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if _hit or not (area is Hurtbox):
		return
	_hit = true
	if area.take_attack(self):
		var arena_node: Node = get_parent()
		if arena_node != null and arena_node.has_method("on_projectile_hit"):
			arena_node.on_projectile_hit(area.global_position, damage)
	queue_free()

func build_attack() -> DamageData:
	return DamageData.new(damage, source_id, direction * 60.0, DamageData.AttackType.RANGED)

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color("#ffd76a"))
	draw_circle(Vector2.ZERO, RADIUS, Color("#6b4a00"), false, 1.5)
	draw_line(Vector2.ZERO, -direction * 12.0, Color("#fff3c4"), 3.0)
