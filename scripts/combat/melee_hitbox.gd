class_name MeleeHitbox extends Area2D
## Активная атака скаута: живёт только во время swing-окна (godot-combat-system).
## Внутри окна мониторит hurtbox-ы врагов (слой Enemy), урон отдаёт через Hurtbox.

var damage: int = 10
var knockback: Vector2 = Vector2.ZERO
var window_left: float = 0.0
var owner_entity: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)
	owner_entity = get_parent()

func activate(attack_damage: int, attack_knockback: Vector2) -> void:
	damage = attack_damage
	knockback = attack_knockback
	window_left = 0.14
	monitoring = true

func _process(delta: float) -> void:
	if window_left <= 0.0:
		return
	window_left -= delta
	if window_left <= 0.0:
		window_left = 0.0
		set_deferred("monitoring", false)

func build_attack() -> DamageData:
	return DamageData.new(damage, owner_entity.get_instance_id(), knockback, DamageData.AttackType.MELEE)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.get_parent() != owner_entity:
		area.take_attack(self)
