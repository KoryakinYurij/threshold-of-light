class_name CombatArena extends Node2D
## Арена T-03b: владелец параметров тюнинга, единый менеджер времени
## (хит-стоп + slow-mo), screenshake, HUD. Без T-04 (карта экспедиции,
## extraction, death-loss) — только тестовый бой.
##
## Блок 1 (ощущение удара): отдача попадания игрока = хит-стоп + число урона +
## частицы; смерть врага = slow-mo + тряска. Враги пока лежат в сцене
## (PursuerA/B); волны и новые типы — Блок 3.

signal tuning_changed(values: Dictionary)

const DEFAULTS: Dictionary = {
	"iframes": 0.18,
	"dash_cooldown": 0.8,
	"telegraph": 0.5,
	"enemy_damage": 25.0,
	"scout_hp": 100.0,
	"speed": 220.0,
	"enemy_speed": 140.0,
	"hit_stop": 0.06,
	"slow_mo": 0.2,
	"swarm_hp": 10.0,
	"swarm_damage": 10.0,
	"swarm_speed": 260.0,
	"shooter_hp": 20.0,
	"shooter_damage": 10.0,
	"shooter_range": 180.0,
	"projectile_speed": 340.0,
}
const RANGES: Dictionary = {
	"iframes": Vector2(0.05, 0.5),
	"dash_cooldown": Vector2(0.2, 2.0),
	"telegraph": Vector2(0.1, 1.0),
	"enemy_damage": Vector2(5.0, 50.0),
	"scout_hp": Vector2(25.0, 200.0),
	"speed": Vector2(100.0, 400.0),
	"hit_stop": Vector2(0.0, 0.15),
	"slow_mo": Vector2(0.1, 0.5),
	"swarm_hp": Vector2(4.0, 30.0),
	"swarm_damage": Vector2(3.0, 25.0),
	"swarm_speed": Vector2(160.0, 420.0),
	"shooter_hp": Vector2(8.0, 60.0),
	"shooter_damage": Vector2(3.0, 25.0),
	"shooter_range": Vector2(100.0, 320.0),
	"projectile_speed": Vector2(180.0, 560.0),
}

## Единый менеджер времени (T-03b Блок 1): хит-стоп (0.05) и slow-mo (0.2)
## пишут в один Engine.time_scale, поэтому не дерутся.
enum TimeMode { NONE = 0, HIT_STOP = 1, SLOW_MO = 2 }

var parameters: Dictionary = {}
var trauma: float = 0.0
var time_mode: int = TimeMode.NONE
var time_left: float = 0.0
var defeated_enemies: int = 0
var scout_dead: bool = false
## Материалы за сессию боя (T-03b Блок 2): без сейва/персистентности (ADR-003,
## сейв — T-04; тогда переедет в run_state.pending_materials).
var materials: int = 0
## Сидированный RNG боя (ADR-004): ВСЯ геймплейная случайность арены (дроп,
## составы волн, элита) идёт через этот генератор, randi()/randf() запрещены.
var _combat_rng: RandomNumberGenerator
## Волны (T-03b Блок 3): индекс текущей волны (0-based), живые враги волны.
var current_wave: int = 0
var wave_enemies_alive: int = 0
var _wave_in_progress: bool = false

@onready var scout: Node = $Scout
@onready var camera: Camera2D = $Camera2D
@onready var status_label: Label = $HUD/Status
@onready var death_label: Label = $HUD/DeathLabel
@onready var materials_label: Label = $HUD/Materials

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key: String in DEFAULTS:
		var limits: Vector2 = RANGES.get(key, Vector2(-INF, INF))
		parameters[key] = clampf(float(SettingsStore.get_value("combat", key, DEFAULTS[key])), limits.x, limits.y)
	## Семя боя: из активного забега, если он есть (T-04), иначе свой сид.
	var master: int = GameState.current_run.master_seed if GameState.has_run() else SeedService.new_master_seed()
	_combat_rng = SeedService.rng_for(SeedService.combat_seed(master))
	death_label.visible = false
	materials_label.text = "Материалы: 0"
	_start_wave(0)
	queue_redraw()

func _process(delta: float) -> void:
	var unscaled_delta: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	if time_mode != TimeMode.NONE:
		time_left -= unscaled_delta
		if time_left <= 0.0:
			time_left = 0.0
			time_mode = TimeMode.NONE
			Engine.time_scale = 1.0
	trauma = maxf(0.0, trauma - unscaled_delta * 2.8)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * trauma * 14.0

func _exit_tree() -> void:
	# Slow-mo/хит-стоп не должны «утекать» в другие сцены и тесты.
	Engine.time_scale = 1.0

func get_parameter(key: String, fallback: float = 0.0) -> float:
	return float(parameters.get(key, fallback))

func set_parameter(key: String, value: float) -> void:
	if not RANGES.has(key):
		return
	var limits: Vector2 = RANGES[key]
	parameters[key] = clampf(value, limits.x, limits.y)
	SettingsStore.set_value("combat", key, parameters[key])
	tuning_changed.emit(parameters.duplicate())

## Тряска + необязательный хит-стоп. Позиция — первый аргумент (сигнатура
## emit_feedback(_at, shake, stop_seconds) из T-03b).
func emit_feedback(_at: Vector2, shake: float, stop_seconds: float) -> void:
	trauma = maxf(trauma, shake)
	if stop_seconds > 0.0:
		_apply_time(TimeMode.HIT_STOP, stop_seconds, 0.05)

## Slow-mo на смерть врага (T-03b Блок 1): time_scale на 0.25с + тряска 0.7.
func slow_mo(seconds: float, target_scale: float = 0.2) -> void:
	trauma = maxf(trauma, 0.7)
	_apply_time(TimeMode.SLOW_MO, seconds, target_scale)

## Slow-mo на смерть не перебивается хит-стопом от того же удара.
func _apply_time(mode: int, seconds: float, target_scale: float) -> void:
	if time_mode == TimeMode.SLOW_MO and mode == TimeMode.HIT_STOP:
		return
	time_mode = mode
	time_left = maxf(time_left, seconds) if time_mode == mode else seconds
	Engine.time_scale = target_scale

## Попадание игрока по врагу (T-03b Блок 1): отдача = хит-стоп + число урона +
## частицы. Вызывается из MeleeHitbox при списанном уроне.
func on_player_hit(at: Vector2, amount: int) -> void:
	emit_feedback(at, 0.4, get_parameter("hit_stop", 0.06))
	_spawn_damage_number(at, str(amount))
	_spawn_hit_particles(at)

func _spawn_damage_number(at: Vector2, text_value: String, text_color: Color = Color(1.0, 0.92, 0.55)) -> void:
	var number := DamageNumber.new()
	add_child(number)
	number.setup(text_value, at, text_color)

func _spawn_hit_particles(at: Vector2) -> void:
	var particles := HitParticles.new()
	add_child(particles)
	particles.setup(at)

func notify_scout_hp(current: int, maximum: int) -> void:
	$HUD/HP.text = "SCOUT  HP %d / %d" % [current, maximum]

func notify_enemy_died(enemy: Node) -> void:
	defeated_enemies += 1
	slow_mo(0.25, get_parameter("slow_mo", 0.2))
	_spawn_drops(enemy.global_position, enemy.get("is_elite") == true)
	wave_enemies_alive -= 1
	if _wave_in_progress and wave_enemies_alive <= 0:
		_wave_in_progress = false
		if current_wave + 1 >= WAVE_COMPOSITIONS.size():
			status_label.text = "Все волны зачищены — бой пройден | F1 — настройка"
		else:
			# Переход на следующую волну с короткой паузой (сбор дропа).
			status_label.text = "Волна зачищена — следующая через мгновение…"
			_apply_time(TimeMode.NONE, 0.0, 1.0)
			_start_wave(current_wave + 1)

## Волны: 1) Преследователь + 2 Роя · 2) Преследователь + Стрелок · 3) 2 Стрелка.
## Один враг в волне — элитный (HP×2.5/скорость×1.5/урон×1.6, дроп ×2).
const WAVE_COMPOSITIONS: Array[Array] = [
	[&"Pursuer", &"Swarm", &"Swarm"],
	[&"Pursuer", &"Shooter"],
	[&"Shooter", &"Shooter"],
]

## Спавн состава волны через сидированный RNG (элита, позиции, стаи).
func _start_wave(index: int) -> void:
	current_wave = index
	wave_enemies_alive = 0
	_wave_in_progress = true
	var composition: Array = WAVE_COMPOSITIONS[index]
	var elite_index: int = _combat_rng.randi_range(0, composition.size() - 1)
	for i: int in composition.size():
		var type_name: StringName = composition[i]
		_spawn_enemy(type_name, i == elite_index)
	status_label.text = "Волна %d/%d | F1 — настройка" % [current_wave + 1, WAVE_COMPOSITIONS.size()]

## Создаёт врага нужного класса. Позиция — в стороне от скаута, сидированный
## RNG (контракт ADR-004). Слой Enemy выставляется, чтобы мели-хёртбокс и
## снаряды находили цели.
func _spawn_enemy(type_name: StringName, is_elite: bool) -> Node:
	var enemy: EnemyBase
	match type_name:
		&"Pursuer":
			enemy = Pursuer.new()
		&"Swarm":
			enemy = Swarm.new()
		&"Shooter":
			enemy = Shooter.new()
		_:
			return null
	add_child(enemy)
	enemy.global_position = _spawn_position()
	enemy.setup_enemy(self, scout, is_elite)
	wave_enemies_alive += 1
	return enemy

## Позиция спавна: на краю арены, не ближе 240px к скауту (сидированный RNG).
func _spawn_position() -> Vector2:
	for attempt: int in 12:
		var pos: Vector2 = Vector2(_combat_rng.randf_range(80.0, 1200.0), _combat_rng.randf_range(140.0, 640.0))
		if scout != null and pos.distance_to(scout.global_position) > 240.0:
			return pos
	return Vector2(_combat_rng.randf_range(80.0, 1200.0), _combat_rng.randf_range(140.0, 640.0))

## Жужжание роя: маленькое сидированное отклонение направления (Блок 3).
func combat_wobble() -> Vector2:
	return Vector2(_combat_rng.randf_range(-0.12, 0.12), _combat_rng.randf_range(-0.12, 0.12))

## Снаряд стрелка: спавнится в дереве арены, летит на скаута.
func spawn_projectile(origin: Vector2, dir: Vector2, amount: int) -> void:
	var projectile := Projectile.new()
	add_child(projectile)
	projectile.setup(origin, dir, amount, 0, get_parameter("projectile_speed", 340.0))

## Отдача от попадания снаряда (Блок 3): лёгкий хит-стоп + число урона.
func on_projectile_hit(at: Vector2, amount: int) -> void:
	_spawn_damage_number(at, str(amount))
	emit_feedback(at, 0.3, 0.03)

## Дроп при убийстве (T-03b Блок 2): 1–3 осколка + 15% шанс лечения +10 HP.
## Весь RNG — сидированный (_combat_rng), контракт ADR-004.
func _spawn_drops(at: Vector2, is_elite: bool = false) -> void:
	# Элитный враг даёт дроп ×2.
	var count: int = _combat_rng.randi_range(1, 3) * (2 if is_elite else 1)
	for i: int in count:
		_spawn_shard(at, MaterialShard.Kind.MATERIAL)
	if _combat_rng.randf() < 0.15:
		_spawn_shard(at, MaterialShard.Kind.HEAL)

func _spawn_shard(at: Vector2, shard_kind: int) -> void:
	var shard := MaterialShard.new()
	add_child(shard)
	# Разброс спавна и начальный импульс — геймплейный RNG: сидированный.
	var scatter: Vector2 = Vector2(_combat_rng.randf_range(-120.0, 120.0), _combat_rng.randf_range(-80.0, 80.0))
	shard.setup(self, shard_kind, at, scatter)

## Подхват осколка: счётчик + эффект, виден сразу.
func collect_material(_shard: Node) -> void:
	materials += 1
	materials_label.text = "Материалы: %d" % materials
	_spawn_hit_particles(_shard.global_position)

## Подхват лечения: +10 HP, эффект.
func collect_heal(shard: Node) -> void:
	if scout.has_node("HealthComponent"):
		scout.get_node("HealthComponent").heal(10)
	_spawn_damage_number(shard.global_position, "+10", Color(0.49, 1.0, 0.69))
	_spawn_hit_particles(shard.global_position)

func notify_scout_died() -> void:
	if scout_dead:
		return
	scout_dead = true
	death_label.visible = true
	status_label.text = "Скаут погиб — R перезапускает бой (без T-04 death-loss)"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R and scout_dead:
		get_tree().reload_current_scene()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/main/hub_screen.tscn")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#09131c"))
	draw_rect(Rect2(24, 82, 1232, 614), Color("#102635"))
	draw_rect(Rect2(24, 82, 1232, 614), Color("#284b5d"), false, 3.0)
	for x: int in range(64, 1240, 64):
		draw_line(Vector2(x, 100), Vector2(x, 680), Color(0.12, 0.26, 0.32, 0.3), 1.0)
	for y: int in range(120, 680, 64):
		draw_line(Vector2(44, y), Vector2(1236, y), Color(0.12, 0.26, 0.32, 0.3), 1.0)
