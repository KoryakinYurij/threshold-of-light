class_name CombatArena extends Node2D
## Арена T-03: владелец параметров тюнинга, hit-stop, screenshake, HUD.
## Без T-04 (карта экспедиции, extraction, death-loss) — только тестовый бой.

signal tuning_changed(values: Dictionary)

const DEFAULTS: Dictionary = {
	"iframes": 0.18,
	"dash_cooldown": 0.8,
	"telegraph": 0.5,
	"enemy_damage": 25.0,
	"scout_hp": 100.0,
	"speed": 220.0,
	"enemy_speed": 140.0,
}
const RANGES: Dictionary = {
	"iframes": Vector2(0.05, 0.5),
	"dash_cooldown": Vector2(0.2, 2.0),
	"telegraph": Vector2(0.1, 1.0),
	"enemy_damage": Vector2(5.0, 50.0),
	"scout_hp": Vector2(25.0, 200.0),
	"speed": Vector2(100.0, 400.0),
}

var parameters: Dictionary = {}
var trauma: float = 0.0
var hit_stop_left: float = 0.0
var defeated_enemies: int = 0
var scout_dead: bool = false

@onready var scout: Node = $Scout
@onready var camera: Camera2D = $Camera2D
@onready var status_label: Label = $HUD/Status
@onready var death_label: Label = $HUD/DeathLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key: String in DEFAULTS:
		var limits: Vector2 = RANGES.get(key, Vector2(-INF, INF))
		parameters[key] = clampf(float(SettingsStore.get_value("combat", key, DEFAULTS[key])), limits.x, limits.y)
	death_label.visible = false
	status_label.text = "Бой: 2 преследователя | F1 — настройка"
	queue_redraw()

func _process(delta: float) -> void:
	var unscaled_delta: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	if hit_stop_left > 0.0:
		hit_stop_left -= unscaled_delta
		if hit_stop_left <= 0.0:
			hit_stop_left = 0.0
			Engine.time_scale = 1.0
	trauma = maxf(0.0, trauma - unscaled_delta * 2.8)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * trauma * 14.0

func _exit_tree() -> void:
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

func emit_feedback(_at: Vector2, shake: float, stop_seconds: float) -> void:
	trauma = maxf(trauma, shake)
	if stop_seconds > 0.0:
		Engine.time_scale = 0.05
		hit_stop_left = maxf(hit_stop_left, stop_seconds)

func notify_scout_hp(current: int, maximum: int) -> void:
	$HUD/HP.text = "SCOUT  HP %d / %d" % [current, maximum]

func notify_enemy_died(_enemy: Node) -> void:
	defeated_enemies += 1
	if defeated_enemies >= 2:
		status_label.text = "Арена зачищена — можно продолжать тестировать ползунки"

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
