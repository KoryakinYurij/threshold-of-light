class_name Pursuer extends EnemyBase
## Преследователь: плоский FSM IDLE->SEEK->TELEGRAPH->ATTACK->RECOVER (спека T-03).
## T-03b Блок 1: белая вспышка при попадании. Блок 3: элитный аффикс и фаза
## отчаяния (< 25% HP: скорость ×1.4, кулдаун −30%, телеграф остаётся).

enum State { IDLE, SEEK, TELEGRAPH, ATTACK, RECOVER }

const BASE_HP: int = 30  # SPEC-04: преследователь 3 удара скаута (урон 10)
const BASE_SPEED: float = 140.0
const BASE_DAMAGE: float = 25.0

var state: State = State.IDLE
var state_elapsed: float = 0.0
var attack_done: bool = false
var attack_cooldown_left: float = 0.0
var telegraph_direction: Vector2 = Vector2.UP
var attack_flash: float = 0.0

## Спавн — только через арену (setup_enemy, Блок 3), поэтому здесь просто
## базовая инициализация; сигналы здоровья вешаются в setup_enemy.
func _ready() -> void:
	arena = get_parent()
	health.set_maximum(BASE_HP)
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
	attack_flash = maxf(0.0, attack_flash - delta)
	var distance: float = global_position.distance_to(target.global_position)
	match state:
		State.IDLE:
			_change_state(State.SEEK)
		State.SEEK:
			velocity = global_position.direction_to(target.global_position) * eff_speed(arena.get_parameter("enemy_speed", BASE_SPEED))
			move_and_slide()
			if distance <= 40.0:
				_change_state(State.TELEGRAPH)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			telegraph_direction = global_position.direction_to(target.global_position)
			if state_elapsed >= eff_cooldown(arena.get_parameter("telegraph", 0.5)):
				_change_state(State.ATTACK)
		State.ATTACK:
			velocity = Vector2.ZERO
			if not attack_done:
				attack_done = true
				attack_flash = 0.16
				var target_health: Node = find_health(target)
				if distance <= 48.0 and target_health != null:
					var data := DamageData.new(roundi(eff_damage(arena.get_parameter("enemy_damage", BASE_DAMAGE))), get_instance_id(), global_position.direction_to(target.global_position) * 100.0)
					target_health.take_damage(data)
					arena.emit_feedback(target.global_position, 0.9, 0.09)
				_change_state(State.RECOVER)
		State.RECOVER:
			velocity = Vector2.ZERO
			if state_elapsed >= eff_cooldown(0.28):
				_change_state(State.SEEK)
	queue_redraw()

func _change_state(next: State) -> void:
	state = next
	state_elapsed = 0.0
	attack_done = false
	queue_redraw()

func _draw() -> void:
	var alpha: float = 1.0
	if death_fade > 0.0:
		alpha = clampf(death_fade / DEATH_FADE, 0.0, 1.0)
	draw_circle(Vector2.ZERO, 16.0, Color("#ff6b6b", alpha))
	draw_circle(Vector2.ZERO, 16.0, Color("#30151b", alpha), false, 2.0)
	draw_line(Vector2.ZERO, Vector2(0, -24), Color("#ffb0a8", alpha), 3.0)
	draw_rect(Rect2(-18, -31, 36, 4), Color("#30151b", alpha))
	draw_rect(Rect2(-18, -31, 36.0 * float(health.current) / float(maxi(1, health.maximum)), 4), Color("#ffcf87", alpha))
	if death_fade > 0.0:
		var p: float = 1.0 - death_fade / DEATH_FADE
		draw_circle(Vector2.ZERO, 16.0 + p * 16.0, Color(1.0, 0.95, 0.8, (1.0 - p) * 0.7), false, 4.0)
		return
	if state == State.TELEGRAPH:
		var pulse: float = 1.0 + sin(state_elapsed * 18.0) * 0.12
		draw_circle(Vector2.ZERO, 28.0 * pulse, Color("#ffb347", 0.22), false, 4.0)
		draw_line(Vector2.ZERO, telegraph_direction * 54.0, Color("#ffb347"), 5.0)
	elif state == State.ATTACK or attack_flash > 0.0:
		draw_circle(Vector2.ZERO, 34.0, Color("#ff4757", 0.45), false, 5.0)
	draw_fx()
