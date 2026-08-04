class_name Hurtbox extends Area2D
## Принимающая сторона: MeleeHitbox вызывает take_attack => DamageData => HealthComponent.
## Скоуп попадания — физические слои (godot-2d-physics), а не группы.
## Hurtbox monitorable=true: иначе MeleeHitbox (monitoring) его не увидит.

func _ready() -> void:
	monitoring = false
	monitorable = true
	area_entered.connect(_on_area_entered)

func _on_area_entered(hitbox: Area2D) -> void:
	take_attack(hitbox)

## True — урон списан (не съеден i-frames). По нему MeleeHitbox даёт отдачу
## попадания (T-03b Блок 1).
## HealthComponent у runtime-врагов (Блок 3) назван уникально (@Node@68), поэтому
## ищем по типу скрипта, а не по имени узла.
func take_attack(hitbox: Area2D) -> bool:
	if not hitbox.has_method(&"build_attack"):
		return false
	var health: Node = _find_health(get_parent())
	if health != null and health.has_method(&"take_damage"):
		return health.take_damage(hitbox.build_attack())
	return false

func _find_health(entity: Node) -> Node:
	for child: Node in entity.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == "HealthComponent":
			return child
	return entity.get_node_or_null(NodePath("HealthComponent"))
