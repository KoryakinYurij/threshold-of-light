extends Area2D
## Снаряд разведчика. Area2D, а не тело: снаряду нужно узнать о враге,
## а не оттолкнуть его.
##
## Слой 4 (Projectile), маска 3 (Enemy) — со стенами снаряд не сталкивается,
## его убивает время жизни. Так проще и так не нужен второй набор форм.

signal hit_enemy(enemy: Node, damage: int)

var damage: int = 10
var _velocity: Vector2 = Vector2.ZERO
var _life_left: float = CombatTuning.SHOT_LIFETIME


func launch(from: Vector2, direction: Vector2, dmg: int) -> void:
	global_position = from
	_velocity = direction.normalized() * CombatTuning.SHOT_SPEED
	damage = dmg


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return
	global_position += _velocity * delta
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.93, 0.6))
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.93, 0.6, 0.25))


func _on_body_entered(body: Node2D) -> void:
	_resolve(body)


func _on_area_entered(area: Area2D) -> void:
	_resolve(area)


func _resolve(target: Node) -> void:
	if not target.has_method("take_damage"):
		return
	hit_enemy.emit(target, damage)
	target.take_damage(damage)
	queue_free()
