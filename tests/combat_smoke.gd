extends Node
## T-03 combat smoke test (scene-based, ASCII only).
## Verifies: melee damage pipeline, enemy absolute HP (30), enemy attack on
## scout (25), F1 panel sliders, defaults.
## Run: godot --headless --path . res://tests/combat_smoke.tscn

func _ready() -> void:
	var arena_scene: PackedScene = load("res://scenes/combat/combat_arena.tscn")
	var arena: Node2D = arena_scene.instantiate()
	add_child(arena)
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

	# Melee damage pipeline: 10 damage -> 30 -> 20
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

	if panel.sliders.size() == 6:
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

	print("SMOKE checks=", checks, " failed=", failed)
	get_tree().quit(0 if failed == 0 else 1)
