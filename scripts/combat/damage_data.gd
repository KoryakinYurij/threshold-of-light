class_name DamageData extends RefCounted
## Паспорт атаки (godot-combat-system): урон всегда приходит как объект.
## Урон: число, источник, отброс, тип. Без строковых типов урона.

enum AttackType { MELEE = 1, RANGED = 2 }

var amount: int
var source_id: int
var knockback: Vector2
var attack_type: AttackType

func _init(p_amount: int, p_source_id: int = 0, p_knockback: Vector2 = Vector2.ZERO, p_attack_type: AttackType = AttackType.MELEE) -> void:
	amount = p_amount
	source_id = p_source_id
	knockback = p_knockback
	attack_type = p_attack_type
