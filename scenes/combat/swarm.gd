class_name Swarm extends EnemyBase
## Рой (T-03b Блок 3): быстрый, 10 HP, урон 10, мелкий, стаи по 2–3.
## Дёшево: перекраска/масштаб. Контактная атака с коротким телеграфом
## (покраснение перед ударом) — телеграф-иерархию чтения не ломаем.

enum State { IDLE, SEEK, TELEGRAPH, ATTACK, RECOVER }

const BASE_HP: int = 10
const BASE_DAMAGE: int = 10
const BASE_SPEED: float = 260.0
const CONTACT_RANGE: float = 26.0
const TELEGRAPH_SECONDS: float = 0.22

var state: State = State.IDLE
var state_elapsed: float = 0.0
var attack_done: bool = false
var attack_cooldown_left: float = 0.0

func _ready() -> void:
	arena = get_parent()
	# HP из параметра арены (ползунок swarm_hp), дефолт BASE_HP.
	health.set_maximum(maxi(1, roundi(arena.get_parameter("swarm_hp", BASE_HP))))
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
			_change_state(State.SEEK)
		State.SEEK:
			# Быстрый, но с рандомизированным жужжанием — сидированный RNG арены
			# (геймплейная случайность, контракт ADR-004). Скорость — ползунок.
			var wobble: Vector2 = arena.combat_wobble()
			velocity = (global_position.direction_to(target.global_position) + wobble) * eff_speed(arena.get_parameter("swarm_speed", BASE_SPEED))
			move_and_slide()
			if distance <= CONTACT_RANGE:
				_change_state(State.TELEGRAPH)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			if state_elapsed >= eff_cooldown(TELEGRAPH_SECONDS):
				_change_state(State.ATTACK)
		State.ATTACK:
			velocity = Vector2.ZERO
			if not attack_done:
				attack_done = true
				var target_health: Node = find_health(target)
				if distance <= CONTACT_RANGE + 6.0 and target_health != null:
					var data := DamageData.new(roundi(eff_damage(arena.get_parameter("swarm_damage", BASE_DAMAGE))), get_instance_id(), Vector2.ZERO)
					target_health.take_damage(data)
					arena.emit_feedback(target.global_position, 0.5, 0.04)
				_change_state(State.RECOVER)
		State.RECOVER:
			velocity = Vector2.ZERO
			if state_elapsed >= eff_cooldown(0.4):
				_change_state(State.SEEK)
	queue_redraw()

func _change_state(next: State) -> void:
	state = next
	state_elapsed = 0.0
	attack_done = false
	queue_redraw()

func _fx_radius() -> float:
	return 10.0

func _draw() -> void:
	var alpha: float = 1.0
	if death_fade > 0.0:
		alpha = clampf(death_fade / DEATH_FADE, 0.0, 1.0)
	var body: Color = Color("#d8576b") if state == State.TELEGRAPH else Color("#8f4fd8")
	draw_circle(Vector2.ZERO, 10.0, Color(body, alpha))
	draw_circle(Vector2.ZERO, 10.0, Color("#2a1233", alpha), false, 2.0)
	draw_rect(Rect2(-10, -19, 20, 3), Color("#2a1233", alpha))
	draw_rect(Rect2(-10, -19, 20.0 * float(health.current) / float(maxi(1, health.maximum)), 3), Color("#ffcf87", alpha))
	if death_fade > 0.0:
		var p: float = 1.0 - death_fade / DEATH_FADE
		draw_circle(Vector2.ZERO, 10.0 + p * 10.0, Color(1.0, 0.95, 0.8, (1.0 - p) * 0.7), false, 3.0)
		return
	if state == State.TELEGRAPH:
		draw_circle(Vector2.ZERO, 16.0 + sin(state_elapsed * 24.0) * 2.0, Color("#ff6b6b", 0.35), false, 3.0)
	draw_fx()
