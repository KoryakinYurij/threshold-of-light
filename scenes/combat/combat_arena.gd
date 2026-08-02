extends Node2D
## Боевой узел. Три волны по два врага, на экране одновременно не больше двух
## (Q-04/Q-14: длина узла набирается волнами, а не запасом HP одного врага).
##
## Узел одиночный: экспедиция появится в T-04, поэтому глубина здесь
## зафиксирована на d=1 — том значении, для которого Q-14 считает
## целевые 25 c и бюджет 6 × 50 × K(1) = 345 HP.
##
## Сцена ничего не знает о хабе: выход наружу — только через EventBus,
## переключением занимается SceneRouter (SPEC-01 §3).

const DEPTH: int = 1
const WAVES: int = 3
const ENEMIES_PER_WAVE: int = 2
const ARENA_SIZE: Vector2 = Vector2(1280, 720)
const WALL_THICKNESS: float = 40.0
const SPAWN_MARGIN: float = 120.0
## Спавн не ближе этого к разведчику: волна, появившаяся вплотную, читается
## как нечестность, а не как сложность.
const MIN_SPAWN_DISTANCE: float = 260.0

const SCOUT_SCENE: PackedScene = preload("res://scenes/combat/scout.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/combat/enemy.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")

@onready var _camera: ShakeCamera = %Camera
@onready var _hit_stop: HitStop = %HitStop
@onready var _hud: Label = %HudLabel
@onready var _hint: Label = %HintLabel
@onready var _panel: TuningPanel = %TuningPanel
@onready var _overlay: Control = %Overlay
@onready var _overlay_label: Label = %OverlayLabel

var _stats: CombatStats = CombatStats.new()
var _scout: Scout = null
var _alive_enemies: Array[Node] = []
var _wave: int = 0
var _rng: RandomNumberGenerator = null
var _running: bool = false
var _node_index: int = 1


func _ready() -> void:
	if not GameState.has_run():
		GameState.begin_run()
	_node_index = GameState.current_run.current_node_index
	_rng = SeedService.rng_for(SeedService.combat_seed(GameState.current_run.master_seed))

	_build_walls()
	_camera.global_position = ARENA_SIZE * 0.5
	_camera.make_current()
	_panel.restart_requested.connect(_restart)
	%RetryButton.pressed.connect(_restart)
	%HubButton.pressed.connect(_on_hub)
	_hint.text = "WASD — движение · ЛКМ — выстрел · Space/Shift — дэш · F1 — ползунки"
	_start_node()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_panel"):
		_panel.toggle()
		_sync_scout_input()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _running:
		_stats.node_seconds += delta
	_refresh_hud()


# --- Узел ---

func _start_node() -> void:
	_stats = CombatStats.new()
	_wave = 0
	_running = true
	_overlay.visible = false

	_scout = SCOUT_SCENE.instantiate()
	_scout.global_position = ARENA_SIZE * 0.5
	_scout.shot_fired.connect(_on_shot_fired)
	_scout.dashed.connect(func() -> void: _stats.dashes += 1)
	_scout.died.connect(_on_scout_died)
	add_child(_scout)
	_sync_scout_input()

	# `node_entered` здесь не эмитится намеренно: его шлёт тот, кто навигирует
	# (в T-04 — контроллер экспедиции), и на него подписан SceneRouter.
	# Эмит отсюда завёл бы переключение сцены в петлю.
	_spawn_wave()


func _spawn_wave() -> void:
	_wave += 1
	var hp := CombatTuning.enemy_hp_at(DEPTH)
	for i: int in ENEMIES_PER_WAVE:
		var enemy: CharacterBody2D = ENEMY_SCENE.instantiate()
		enemy.global_position = _pick_spawn()
		enemy.setup(_scout, hp)
		enemy.died.connect(_on_enemy_died)
		enemy.attack_resolved.connect(_on_attack_resolved)
		add_child(enemy)
		_alive_enemies.append(enemy)


func _pick_spawn() -> Vector2:
	var inner_min := Vector2(SPAWN_MARGIN, SPAWN_MARGIN)
	var inner_max := ARENA_SIZE - inner_min
	# Десяти попыток хватает: запретный круг занимает малую долю арены,
	# а fallback в угол лучше бесконечного цикла.
	for _attempt: int in 10:
		var p := Vector2(
			_rng.randf_range(inner_min.x, inner_max.x),
			_rng.randf_range(inner_min.y, inner_max.y)
		)
		if _scout == null or p.distance_to(_scout.global_position) >= MIN_SPAWN_DISTANCE:
			return p
	return inner_min


func _finish(cleared: bool) -> void:
	if not _running:
		return
	_running = false
	if _scout != null and is_instance_valid(_scout):
		_scout.input_enabled = false
		GameState.current_run.scout_hp = _scout.hp

	var payload := _stats.to_dict()
	payload["cleared"] = cleared
	payload["depth"] = DEPTH
	payload["node_index"] = _node_index
	payload["master_seed"] = GameState.current_run.master_seed
	payload["waves"] = WAVES
	payload["enemies_total"] = WAVES * ENEMIES_PER_WAVE
	payload["enemy_hp"] = CombatTuning.enemy_hp_at(DEPTH)
	for spec: Dictionary in CombatTuning.SPECS:
		payload["tuning_" + String(spec["key"])] = CombatTuning.f(String(spec["key"]))

	if cleared:
		EventBus.node_cleared.emit(_node_index, {})
	else:
		EventBus.scout_died.emit(_node_index)
	EventBus.combat_recorded.emit(payload)
	EventBus.save_requested.emit("node_cleared" if cleared else "death")

	_overlay_label.text = "\n".join([
		"Узел зачищен" if cleared else "Разведчик погиб",
		"",
		"Время узла: %.1f c" % _stats.node_seconds,
		"Попаданий: %d из %d  ·  hit_rate %.2f" % [
			_stats.shots_hit, _stats.shots_fired, _stats.hit_rate()
		],
		"Атак врага: %d  ·  ушёл от %d (i-frames %d, шагом %d)  ·  dodge_rate %.2f" % [
			_stats.enemy_attacks,
			_stats.attacks_dodged_iframes + _stats.attacks_evaded_range,
			_stats.attacks_dodged_iframes,
			_stats.attacks_evaded_range,
			_stats.dodge_rate(),
		],
		"Получено урона: %d  ·  нанесено: %d" % [_stats.damage_taken, _stats.damage_dealt],
	])
	_overlay.visible = true


func _restart() -> void:
	for enemy: Node in _alive_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_alive_enemies.clear()
	if _scout != null and is_instance_valid(_scout):
		_scout.queue_free()
		_scout = null
	if _panel.visible:
		_panel.toggle()
	_start_node()


func _on_hub() -> void:
	EventBus.returned_to_hub.emit()


# --- Обработчики ---

func _on_shot_fired(from: Vector2, direction: Vector2, damage: int) -> void:
	var shot: Area2D = PROJECTILE_SCENE.instantiate()
	shot.launch(from, direction, damage)
	shot.hit_enemy.connect(_on_shot_hit)
	add_child(shot)
	_stats.shots_fired += 1


func _on_shot_hit(_enemy: Node, damage: int) -> void:
	_stats.shots_hit += 1
	_stats.damage_dealt += damage
	_camera.add_trauma(ShakeCamera.TRAUMA_SHOT_HIT)
	_hit_stop.freeze(HitStop.HIT_ENEMY)


func _on_enemy_died(enemy: Node) -> void:
	_alive_enemies.erase(enemy)
	_stats.enemies_killed += 1
	_camera.add_trauma(ShakeCamera.TRAUMA_KILL)
	_hit_stop.freeze(HitStop.KILL_ENEMY)
	if not _running:
		return
	if not _alive_enemies.is_empty():
		return
	if _wave >= WAVES:
		_finish(true)
	else:
		_spawn_wave()


func _on_attack_resolved(outcome: int) -> void:
	_stats.enemy_attacks += 1
	match outcome:
		Enemy.Outcome.HIT:
			_stats.attacks_hit += 1
			_stats.damage_taken += int(CombatTuning.f("enemy_damage"))
			_camera.add_trauma(ShakeCamera.TRAUMA_SCOUT_HURT)
			_hit_stop.freeze(HitStop.SCOUT_HURT)
		Enemy.Outcome.DODGED_IFRAMES:
			_stats.attacks_dodged_iframes += 1
		Enemy.Outcome.EVADED_RANGE:
			_stats.attacks_evaded_range += 1


func _on_scout_died() -> void:
	_finish(false)


func _sync_scout_input() -> void:
	if _scout != null and is_instance_valid(_scout):
		_scout.input_enabled = _running and not _panel.visible


# --- Обстановка ---

func _build_walls() -> void:
	# Четыре прямоугольника в коде, а не в .tscn: редактора у агента нет,
	# а руками сведённые формы — источник ошибок, которых не видно до запуска.
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	var half := WALL_THICKNESS * 0.5
	var rects: Array[Rect2] = [
		Rect2(Vector2(ARENA_SIZE.x * 0.5, -half), Vector2(ARENA_SIZE.x + WALL_THICKNESS, WALL_THICKNESS)),
		Rect2(Vector2(ARENA_SIZE.x * 0.5, ARENA_SIZE.y + half), Vector2(ARENA_SIZE.x + WALL_THICKNESS, WALL_THICKNESS)),
		Rect2(Vector2(-half, ARENA_SIZE.y * 0.5), Vector2(WALL_THICKNESS, ARENA_SIZE.y + WALL_THICKNESS)),
		Rect2(Vector2(ARENA_SIZE.x + half, ARENA_SIZE.y * 0.5), Vector2(WALL_THICKNESS, ARENA_SIZE.y + WALL_THICKNESS)),
	]
	for r: Rect2 in rects:
		var shape := RectangleShape2D.new()
		shape.size = r.size
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = r.position
		body.add_child(cs)
	add_child(body)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), Color(0.09, 0.10, 0.13))
	draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), Color(0.28, 0.30, 0.38), false, 3.0)


func _refresh_hud() -> void:
	var hp_line := "—"
	if _scout != null and is_instance_valid(_scout):
		hp_line = "%d / %d" % [_scout.hp, _scout.max_hp]
	_hud.text = "\n".join([
		"HP разведчика: %s" % hp_line,
		"Волна %d из %d  ·  врагов на арене: %d" % [_wave, WAVES, _alive_enemies.size()],
		"Время: %.1f c" % _stats.node_seconds,
		"Выстрелов: %d  ·  попало: %d  ·  hit_rate %.2f" % [
			_stats.shots_fired, _stats.shots_hit, _stats.hit_rate()
		],
		"Атак врага: %d  ·  i-frames %d  ·  шагом %d  ·  урон получен %d" % [
			_stats.enemy_attacks,
			_stats.attacks_dodged_iframes,
			_stats.attacks_evaded_range,
			_stats.damage_taken,
		],
	])
