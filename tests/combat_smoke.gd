extends Node
## T-03 combat smoke test (scene-based, ASCII only).
## Verifies: melee damage pipeline, enemy absolute HP (30), enemy attack on
## scout (25), 3-hit kill, hit feedback (number + particles), F1 panel sliders,
## defaults (включая hit_stop/slow_mo из T-03b Блок 1), drop (materials + heal)
## и сидированный RNG (T-03b Блок 2).
## Run: godot --headless --path . res://tests/combat_smoke.tscn

func _ready() -> void:
	var arena_scene: PackedScene = load("res://scenes/combat/combat_arena.tscn")
	var arena: Node2D = arena_scene.instantiate()
	add_child(arena)
	# Дай физике кадры, чтобы areas зарегистрировались (иначе первый удар флакает)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var scout: Node = arena.get_node("Scout")
	var enemy: Node = arena.get_node("PursuerA")
	var enemy_health: Node = enemy.get_node("HealthComponent")
	var scout_health: Node = scout.get_node("HealthComponent")
	var panel: Node = arena.get_node("TuningLayer/TuningPanel")
	var checks: int = 0
	var failed: int = 0

	# Enemy absolute HP from scene (30, SPEC-04)
	if enemy_health.maximum == 30 and enemy_health.current == 30:
		checks += 1
		print("OK enemy hp: ", enemy_health.current, "/", enemy_health.maximum)
	else:
		failed += 1
		print("FAIL enemy hp: ", enemy_health.current, "/", enemy_health.maximum)

	# Melee damage pipeline: 10 damage -> 30 -> 20 + отдача попадания (T-03b)
	enemy.position = scout.position + Vector2(50, 0)
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
	var data: DamageData = DamageData.new(25, enemy.get_instance_id(), Vector2.ZERO)
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
	enemy.position = scout.position + Vector2(50, 0)
	scout.last_direction = Vector2.RIGHT
	await get_tree().physics_frame
	scout._attack()
	await _wait_ms(250)
	scout._attack()
	await _wait_ms(250)
	scout._attack()
	await _wait_ms(250)
	await get_tree().physics_frame
	if enemy.dead or not is_instance_valid(enemy):
		checks += 1
		print("OK enemy dies in 3 melee hits")
	else:
		failed += 1
		print("FAIL enemy survives 3 melee hits: cur=", enemy_health.current)

	# Дроп при убийстве (Блок 2): осколки летят к игроку и собираются.
	# Ждём реальные секунды (осколки живут в реальном времени, slow-mo не мешает).
	await _wait_ms(800)
	var drop_ok: bool = false
	var shards_seen: int = 0
	for child: Node in arena.get_children():
		if child is MaterialShard:
			shards_seen += 1
	# 1..3 осколка спавнятся у трупа; часть могла уже подобраться.
	drop_ok = arena.materials >= 1 or shards_seen > 0
	if drop_ok:
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
	# Разные сиды дают разные потоки (статистически)
	var rng_c: RandomNumberGenerator = SeedService.rng_for(SeedService.combat_seed(43))
	if rng_a.randf() != rng_c.randf():
		checks += 1
		print("OK seeded RNG differs across seeds")
	else:
		failed += 1
		print("FAIL seeded RNG same across seeds")

	if panel.sliders.size() == 8:
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

	# Хит-стоп и slow-mo не «утекли» в другие сцены
	if is_equal_approx(Engine.time_scale, 1.0):
		checks += 1
		print("OK time_scale вернулся в 1.0")
	else:
		failed += 1
		print("FAIL time_scale не вернулся в 1.0: ", Engine.time_scale)

	print("SMOKE checks=", checks, " failed=", failed)
	get_tree().quit(0 if failed == 0 else 1)


func _wait_ms(ms: int) -> void:
	var start: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < ms:
		await get_tree().process_frame
