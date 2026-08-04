class_name MeleeHitbox extends Area2D
## Активная атака скаута: живёт только во время swing-окна (godot-combat-system).
## Внутри окна каждый физический кадр опрашивает пересечения с hurtbox-ами
## врагов (слой Enemy). Не edge-triggered area_entered: тот пропускает врага,
## уже стоящего в зоне с прошлого замаха (T-03b Блок 1, регресс «3 удара = смерть»).

var damage: int = 10
var knockback: Vector2 = Vector2.ZERO
var window_left: float = 0.0
var owner_entity: Node
var _hit_this_swing: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	monitoring = false
	monitorable = false
	owner_entity = get_parent()

func activate(attack_damage: int, attack_knockback: Vector2) -> void:
	damage = attack_damage
	knockback = attack_knockback
	window_left = 0.14
	_hit_this_swing.clear()
	monitoring = true

func _physics_process(_delta: float) -> void:
	if window_left <= 0.0:
		return
	for area: Area2D in get_overlapping_areas():
		if not (area is Hurtbox) or area.get_parent() == owner_entity:
			continue
		var id: int = area.get_instance_id()
		if _hit_this_swing.has(id):
			continue
		_hit_this_swing[id] = true
		# «При удаче» = урон реально списан (take_attack вернул true), иначе
		# контакт с поглощённым i-frames тоже давал бы отдачу (T-03b Блок 1).
		if area.take_attack(self):
			var arena_node: Node = owner_entity.get("arena")
			if arena_node != null and arena_node.has_method("on_player_hit"):
				arena_node.on_player_hit(area.global_position, damage)

func _process(delta: float) -> void:
	if window_left <= 0.0:
		return
	# Swing-окно в НЕмасштабированном времени (T-03b Блок 1): иначе хит-стоп
	# растягивает окно, и следующий удар «склеивается» с прошлым.
	var unscaled: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	window_left -= unscaled
	if window_left <= 0.0:
		window_left = 0.0
		set_deferred("monitoring", false)

func build_attack() -> DamageData:
	return DamageData.new(damage, owner_entity.get_instance_id(), knockback, DamageData.AttackType.MELEE)
