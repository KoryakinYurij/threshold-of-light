class_name Shooter extends EnemyBase
## Стрелок (T-03b Блок 3): держит дистанцию ~180px, телеграф 0.6с → снаряд.
## Телеграф виден заранее (одобрен владельцем) — не ломаем: жёлтая линия цели
## и пульс до выстрела.

enum State { IDLE, POSITION, TELEGRAPH, FIRE, RECOVER }

const BASE_HP: int = 20
const BASE_DAMAGE: int = 10
const PREFERRED_RANGE: float = 180.0
const RANGE_BAND: float = 30.0
const TELEGRAPH_SECONDS: float = 0.6

var state: State = State.IDLE
var state_elapsed: float = 0.0
var attack_done: bool = false
var attack_cooldown_left: float = 0.0
var aim_direction: Vector2 = Vector2.UP

func _ready() -> void:
	arena = get_parent()
	health.set_maximum(maxi(1, roundi(arena.get_parameter("shooter_hp", BASE_HP))))
	queue_redraw()

func _physics_process(delta: float) -> void:
	tick_fx(delta)
	if dead:
		velocity = Vector2.ZERO
		return
	if target == null or not is_instance_valid(target) or target.get("dead") == true:
		velocity = Vector2.ZERO
		return
	state_elapsed += delta
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	var distance: float = global_position.distance_to(target.global_position)
	match state:
		State.IDLE:
			_change_state(State.POSITION)
		State.POSITION:
			# Держит дистанцию: подходит/отходит в пределах preferred ± band.
			# Дистанция — ползунок shooter_range.
			var preferred: float = arena.get_parameter("shooter_range", PREFERRED_RANGE)
			var dir: Vector2 = global_position.direction_to(target.global_position)
			if distance > preferred + RANGE_BAND:
				velocity = dir * eff_speed(120.0)
			elif distance < preferred - RANGE_BAND:
				velocity = -dir * eff_speed(120.0)
			else:
				velocity = Vector2.ZERO
			move_and_slide()
			if distance > preferred - RANGE_BAND and distance < preferred + RANGE_BAND and attack_cooldown_left <= 0.0:
				_change_state(State.TELEGRAPH)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			aim_direction = global_position.direction_to(target.global_position)
			if state_elapsed >= eff_cooldown(TELEGRAPH_SECONDS):
				_change_state(State.FIRE)
		State.FIRE:
			velocity = Vector2.ZERO
			if not attack_done:
				attack_done = true
				arena.spawn_projectile(global_position, aim_direction, roundi(eff_damage(arena.get_parameter("shooter_damage", BASE_DAMAGE))))
				_change_state(State.RECOVER)
		State.RECOVER:
			velocity = Vector2.ZERO
			if state_elapsed >= eff_cooldown(0.5):
				attack_cooldown_left = 0.8
				_change_state(State.POSITION)
	queue_redraw()

func _change_state(next: State) -> void:
	state = next
	state_elapsed = 0.0
	attack_done = false
	queue_redraw()

func _fx_radius() -> float:
	return 13.0

func _draw() -> void:
	var alpha: float = 1.0
	if death_fade > 0.0:
		alpha = clampf(death_fade / DEATH_FADE, 0.0, 1.0)
	var body: Color = Color("#e8b13c") if state == State.TELEGRAPH else Color("#3c8fd8")
	draw_circle(Vector2.ZERO, 13.0, Color(body, alpha))
	draw_circle(Vector2.ZERO, 13.0, Color("#14314a", alpha), false, 2.0)
	draw_line(Vector2.ZERO, Vector2(0, -20), Color("#bfe8ff", alpha), 3.0)
	draw_rect(Rect2(-13, -24, 26, 3), Color("#14314a", alpha))
	draw_rect(Rect2(-13, -24, 26.0 * float(health.current) / float(maxi(1, health.maximum)), 3), Color("#ffcf87", alpha))
	if death_fade > 0.0:
		var p: float = 1.0 - death_fade / DEATH_FADE
		draw_circle(Vector2.ZERO, 13.0 + p * 13.0, Color(1.0, 0.95, 0.8, (1.0 - p) * 0.7), false, 3.0)
		return
	if state == State.TELEGRAPH:
		var pulse: float = 1.0 + sin(state_elapsed * 16.0) * 0.1
		draw_circle(Vector2.ZERO, 24.0 * pulse, Color("#ffb347", 0.25), false, 4.0)
		draw_line(Vector2.ZERO, aim_direction * 60.0, Color("#ffb347"), 4.0)
	draw_fx()
