extends Node
## T-03 combat smoke test (scene-based, ASCII only).
## Verifies: melee damage pipeline, enemy absolute HP (30), enemy attack on
## scout (25), 3-hit kill, hit feedback (number + particles), F1 panel sliders,
## defaults, drop (materials + heal), seeded RNG (Блок 2), волны по типам,
## стрелок-снаряд, элита, фаза отчаяния (Блок 3).
## Run: godot --headless --path . res://tests/combat_smoke.tscn

func _ready() -> void:
	var arena_scene: PackedScene = load("res://scenes/combat/combat_arena.tscn")
	var arena: Node2D = arena_scene.instantiate()
	add_child(arena)
	# Дай физике кадры, чтобы areas зарегистрировались (иначе первый удар флакает)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var scout: Node = arena.get_node("Scout")
	var scout_health: Node = scout.get_node("HealthComponent")
	var panel: Node = arena.get_node("TuningLayer/TuningPanel")
	var checks: int = 0
	var failed: int = 0

	# Волна 1 заспавнена: 1 Преследователь + 2 Роя, статус «Волна 1/3» (Блок 3)
	var pursuer: Node = _find_enemy(arena, "Pursuer")
	var swarms: Array = _find_enemies(arena, "Swarm")
	if pursuer != null and swarms.size() == 2:
		checks += 1
		print("OK wave1 composition: pursuer + ", swarms.size(), " swarms")
	else:
		failed += 1
		print("FAIL wave1 composition: pursuer=", pursuer != null, " swarms=", swarms.size())
	if arena.status_label.text.begins_with("Волна 1/3"):
		checks += 1
		print("OK wave status: ", arena.status_label.text)
	else:
		failed += 1
		print("FAIL wave status: ", arena.status_label.text)

	# Элита выбирается сидированным RNG случайно — для регресса «3 удара = смерть»
	# нужен детерминированный НЕэлитный преследователь (30 HP, SPEC-04).
	# Волна 1 остаётся как есть (проверка состава выше); тест спавнит своего.
	var test_enemy: Node = arena._spawn_enemy(&"Pursuer", false)
	var enemy_health: Node = _get_health(test_enemy)

	# Enemy absolute HP from defaults (30, SPEC-04)
	if enemy_health.maximum == 30 and enemy_health.current == 30:
		checks += 1
		print("OK enemy hp: ", enemy_health.current, "/", enemy_health.maximum)
	else:
		failed += 1
		print("FAIL enemy hp: ", enemy_health.current, "/", enemy_health.maximum)

	# Melee damage pipeline: 10 damage -> 30 -> 20 + отдача попадания (T-03b)
	test_enemy.position = scout.position + Vector2(50, 0)
	scout.last_direction = Vector2.RIGHT
	var before: int = enemy_health.current
	scout._attack()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var after: int = enemy_health.current
	if after == before - 10:
		checks += 1
		print("OK melee damage: ", before, " -> ", after)
	else:
		failed += 1
		print("FAIL melee damage: ", before, " -> ", after)

	# Отдача попадания: число урона и частицы появились у арены (Блок 1)
	var number_seen := false
	var particles_seen := false
	for child: Node in arena.get_children():
		if child is DamageNumber:
			number_seen = true
		if child is HitParticles:
			particles_seen = true
	if number_seen:
		checks += 1
		print("OK damage number spawned on player hit")
	else:
		failed += 1
		print("FAIL damage number missing on player hit")
	if particles_seen:
		checks += 1
		print("OK hit particles spawned on player hit")
	else:
		failed += 1
		print("FAIL hit particles missing on player hit")

	# Enemy attack on scout: 25 damage -> 100 -> 75
	var scout_before: int = scout_health.current
	var data: DamageData = DamageData.new(25, test_enemy.get_instance_id(), Vector2.ZERO)
	scout_health.take_damage(data)
	await get_tree().process_frame
	if scout_health.current == scout_before - 25:
		checks += 1
		print("OK enemy damage on scout: ", scout_before, " -> ", scout_health.current)
	else:
		failed += 1
		print("FAIL enemy damage on scout: ", scout_before, " -> ", scout_health.current)

	# 3 melee hits kill the enemy (30 HP / 10 dmg) - regression for user report
	enemy_health.invincible = false
	enemy_health.invincibility_left = 0.0
	enemy_health.current = enemy_health.maximum
	test_enemy.position = scout.position + Vector2(50, 0)
	scout.last_direction = Vector2.RIGHT
	await get_tree().physics_frame
	scout._attack()
	await _wait_ms(250)
	scout._attack()
	await _wait_ms(250)
	scout._attack()
	await _wait_ms(250)
	await get_tree().physics_frame
	if test_enemy.dead or not is_instance_valid(test_enemy):
		checks += 1
		print("OK enemy dies in 3 melee hits")
	else:
		failed += 1
		print("FAIL enemy survives 3 melee hits: cur=", enemy_health.current)

	# Дроп при убийстве (Блок 2): осколки летят к игроку и собираются.
	await _wait_ms(800)
	var shards_seen: int = 0
	for child: Node in arena.get_children():
		if child is MaterialShard:
			shards_seen += 1
	if arena.materials >= 1 or shards_seen > 0:
		checks += 1
		print("OK drop on kill: materials=", arena.materials, " shards=", shards_seen)
	else:
		failed += 1
		print("FAIL no drop on kill: materials=", arena.materials, " shards=", shards_seen)

	# HUD-счётчик виден сразу после подхвата (Блок 2)
	var hud_label: Label = arena.get_node("HUD/Materials")
	if hud_label != null and hud_label.text.begins_with("Материалы:"):
		checks += 1
		print("OK HUD materials label: ", hud_label.text)
	else:
		failed += 1
		print("FAIL HUD materials label missing")

	# Лечение +10 HP при подхвате лечебного осколка (Блок 2)
	var hp_before_heal: int = scout_health.current
	arena.collect_heal(arena.get_node("Scout"))
	if scout_health.current == mini(scout_health.maximum, hp_before_heal + 10):
		checks += 1
		print("OK heal drop +10 HP: ", hp_before_heal, " -> ", scout_health.current)
	else:
		failed += 1
		print("FAIL heal drop: ", hp_before_heal, " -> ", scout_health.current)

	# Сидированный RNG (ADR-004): один и тот же сид даёт тот же дроп.
	var rng_a: RandomNumberGenerator = SeedService.rng_for(SeedService.combat_seed(42))
	var rng_b: RandomNumberGenerator = SeedService.rng_for(SeedService.combat_seed(42))
	if rng_a.randf() == rng_b.randf() and rng_a.randi_range(1, 3) == rng_b.randi_range(1, 3):
		checks += 1
		print("OK seeded RNG deterministic for same seed")
	else:
		failed += 1
		print("FAIL seeded RNG not deterministic")

	# Стрелок: держит дистанцию и выпускает снаряд (Блок 3).
	# Спавним стрелка вручную и ставим на дистанцию стрельбы (180px), чтобы
	# не зависеть от случайной позиции спавна. Телеграф 0.6с → снаряд.
	var shooter: Node = arena._spawn_enemy(&"Shooter", false)
	shooter.position = scout.position + Vector2(180, 0)
	await get_tree().physics_frame
	var projectile_seen := false
	for i: int in 80:
		for child: Node in arena.get_children():
			if child is Projectile:
				projectile_seen = true
		if projectile_seen:
			break
		await _wait_ms(50)
	if projectile_seen:
		checks += 1
		print("OK shooter fired a projectile")
	else:
		failed += 1
		print("FAIL shooter never fired")

	# Элитный аффикс: HP ×2.5, урон ×1.6, скорость ×1.5 (Блок 3)
	var elite: Node = arena._spawn_enemy(&"Swarm", true)
	await get_tree().physics_frame
	var base_swarm_hp: int = maxi(1, roundi(arena.get_parameter("swarm_hp", 10.0)))
	if elite.health.maximum == roundi(base_swarm_hp * 2.5):
		checks += 1
		print("OK elite hp x2.5: ", elite.health.maximum)
	else:
		failed += 1
		print("FAIL elite hp: ", elite.health.maximum, " expected ~", roundi(base_swarm_hp * 2.5))
	if is_equal_approx(elite.eff_speed(100.0), 150.0):
		checks += 1
		print("OK elite speed x1.5")
	else:
		failed += 1
		print("FAIL elite speed: ", elite.eff_speed(100.0))
	if elite.eff_damage(10.0) == 16.0:
		checks += 1
		print("OK elite damage x1.6")
	else:
		failed += 1
		print("FAIL elite damage: ", elite.eff_damage(10.0))

	# Фаза отчаяния: <25% HP -> скорость ×1.4, кулдаун ×0.7 (Блок 3)
	elite.health.current = 1
	if elite.in_despair():
		checks += 1
		print("OK despair triggers below 25% hp")
	else:
		failed += 1
		print("FAIL despair not triggered at 1 hp")
	if is_equal_approx(elite.eff_speed(100.0), 150.0 * 1.4):
		checks += 1
		print("OK despair speed x1.4: ", elite.eff_speed(100.0))
	else:
		failed += 1
		print("FAIL despair speed: ", elite.eff_speed(100.0))
	if is_equal_approx(elite.eff_cooldown(1.0), 0.7):
		checks += 1
		print("OK despair cooldown x0.7")
	else:
		failed += 1
		print("FAIL despair cooldown: ", elite.eff_cooldown(1.0))

	if panel.sliders.size() == 15:
		checks += 1
		print("OK tuning panel sliders: ", panel.sliders.size())
	else:
		failed += 1
		print("FAIL tuning panel sliders: ", panel.sliders.size())

	if arena.get_parameter("iframes") == 0.18:
		checks += 1
		print("OK default iframes: ", arena.get_parameter("iframes"))
	else:
		failed += 1
		print("FAIL iframes default: ", arena.get_parameter("iframes"))

	if is_equal_approx(arena.get_parameter("hit_stop"), 0.06):
		checks += 1
		print("OK default hit_stop: ", arena.get_parameter("hit_stop"))
	else:
		failed += 1
		print("FAIL hit_stop default: ", arena.get_parameter("hit_stop"))

	if is_equal_approx(arena.get_parameter("slow_mo"), 0.2):
		checks += 1
		print("OK default slow_mo: ", arena.get_parameter("slow_mo"))
	else:
		failed += 1
		print("FAIL slow_mo default: ", arena.get_parameter("slow_mo"))

	if is_equal_approx(arena.get_parameter("shooter_range"), 180.0):
		checks += 1
		print("OK default shooter_range: ", arena.get_parameter("shooter_range"))
	else:
		failed += 1
		print("FAIL shooter_range default: ", arena.get_parameter("shooter_range"))

	# Хит-стоп и slow-mo не «утекли» в другие сцены
	if is_equal_approx(Engine.time_scale, 1.0):
		checks += 1
		print("OK time_scale вернулся в 1.0")
	else:
		failed += 1
		print("FAIL time_scale не вернулся в 1.0: ", Engine.time_scale)

	print("SMOKE checks=", checks, " failed=", failed)
	get_tree().quit(0 if failed == 0 else 1)


## Runtime-враги создаются кодом, их имена уникальны (@Node@68 и т.п.),
## поэтому ищем по class_name скрипта, а не по имени узла (ТЗ: «по типам»).
func _find_enemies(arena: Node, type_name: String) -> Array:
	var found: Array = []
	for child: Node in arena.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == type_name:
			found.append(child)
	return found


func _find_enemy(arena: Node, type_name: String) -> Node:
	var list: Array = _find_enemies(arena, type_name)
	return list[0] if not list.is_empty() else null

## У runtime-врага HealthComponent создан кодом и назван уникально (@Node@68).
func _get_health(enemy: Node) -> Node:
	for child: Node in enemy.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == "HealthComponent":
			return child
	return enemy.get_node_or_null("HealthComponent")


func _wait_ms(ms: int) -> void:
	var start: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < ms:
		await get_tree().process_frame
