class_name Enemy extends CharacterBody2D
## Преследователь. FSM из пяти состояний по Q-02:
## `IDLE → SEEK → TELEGRAPH → ATTACK → RECOVER → SEEK`.
##
## Телеграф — единственное, что делает дэш реакцией, а не ставкой, поэтому
## во время замаха враг останавливается и меняет силуэт: по источникам Q-02
## именно смена силуэта, а не таймер, работает уведомлением игроку.
##
## Урон снимается одним мгновением на входе в ATTACK — так же, как в играх,
## на которые ссылается Q-03. Это и есть кадр, который обязан покрыть дэш.

signal died(enemy: Node)
signal attack_resolved(outcome: int)

enum State { IDLE, SEEK, TELEGRAPH, ATTACK, RECOVER }
## Исход атаки: пришёл урон · съеден i-frames · разведчик вышел из радиуса.
enum Outcome { HIT, DODGED_IFRAMES, EVADED_RANGE }

const SPAWN_DELAY: float = 0.4
const COLOR_IDLE: Color = Color(0.85, 0.4, 0.35)
const COLOR_TELEGRAPH: Color = Color(1.0, 0.92, 0.3)
const COLOR_ATTACK: Color = Color(1.0, 0.25, 0.2)
const COLOR_HURT: Color = Color(1.0, 1.0, 1.0)

var max_hp: int = 58
var hp: int = 58

var _target: Node2D = null
var _state: State = State.IDLE
var _state_left: float = SPAWN_DELAY
var _attack_cd_left: float = 0.0
var _hurt_flash: float = 0.0
var _dying: bool = false


func setup(target: Node2D, hp_value: int) -> void:
	_target = target
	max_hp = maxi(hp_value, 1)
	hp = max_hp


## Текущее состояние FSM. Наружу — только на чтение: проверка Q-02 обязана
## видеть, что все пять состояний действительно проходятся.
func state() -> State:
	return _state


func _physics_process(delta: float) -> void:
	if _dying:
		return
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_attack_cd_left = maxf(_attack_cd_left - delta, 0.0)
	_state_left = maxf(_state_left - delta, 0.0)

	match _state:
		State.IDLE:
			if _state_left <= 0.0:
				_enter(State.SEEK)
		State.SEEK:
			_seek()
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			if _state_left <= 0.0:
				_enter(State.ATTACK)
		State.ATTACK:
			velocity = Vector2.ZERO
			if _state_left <= 0.0:
				_enter(State.RECOVER)
		State.RECOVER:
			velocity = Vector2.ZERO
			if _state_left <= 0.0:
				_enter(State.SEEK)

	move_and_slide()
	queue_redraw()


func take_damage(amount: int) -> void:
	if _dying:
		return
	hp = maxi(hp - amount, 0)
	_hurt_flash = 0.09
	if hp <= 0:
		_dying = true
		died.emit(self)
		queue_free()


func _seek() -> void:
	if _target == null or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	var to_target := _target.global_position - global_position
	var reach := CombatTuning.ENEMY_ATTACK_RADIUS + CombatTuning.SCOUT_RADIUS
	if to_target.length() <= reach and _attack_cd_left <= 0.0:
		_enter(State.TELEGRAPH)
		return
	velocity = to_target.normalized() * CombatTuning.f("enemy_speed")


func _enter(next: State) -> void:
	_state = next
	match next:
		State.SEEK:
			_state_left = 0.0
		State.TELEGRAPH:
			_state_left = CombatTuning.f("telegraph_time")
		State.ATTACK:
			_state_left = CombatTuning.ENEMY_ATTACK_WINDOW
			_attack_cd_left = CombatTuning.f("enemy_attack_cd")
			_resolve_attack()
		State.RECOVER:
			_state_left = CombatTuning.ENEMY_RECOVER_TIME
		State.IDLE:
			_state_left = SPAWN_DELAY


## Один кадр удара. Порядок проверок задан Q-03: сначала «был ли в радиусе»,
## потом «был ли неуязвим» — иначе уход шагом засчитается дэшу и завысит замер.
func _resolve_attack() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var reach := CombatTuning.ENEMY_ATTACK_RADIUS + CombatTuning.SCOUT_RADIUS
	var in_range: bool = global_position.distance_to(_target.global_position) <= reach
	if not in_range:
		attack_resolved.emit(Outcome.EVADED_RANGE)
		return
	if _target.has_method("is_invulnerable") and _target.is_invulnerable():
		attack_resolved.emit(Outcome.DODGED_IFRAMES)
		return
	attack_resolved.emit(Outcome.HIT)
	if _target.has_method("take_damage"):
		_target.take_damage(int(CombatTuning.f("enemy_damage")))


func _draw() -> void:
	var radius := CombatTuning.ENEMY_RADIUS
	var color := COLOR_IDLE
	match _state:
		State.TELEGRAPH:
			# Замах читается тремя сигналами сразу: цвет, раздувание силуэта
			# и кольцо, дорисовывающееся к моменту удара.
			var total: float = maxf(CombatTuning.f("telegraph_time"), 0.001)
			var progress: float = clampf(1.0 - _state_left / total, 0.0, 1.0)
			color = COLOR_IDLE.lerp(COLOR_TELEGRAPH, progress)
			radius += 5.0 * progress
			var reach := CombatTuning.ENEMY_ATTACK_RADIUS + CombatTuning.SCOUT_RADIUS
			draw_arc(Vector2.ZERO, reach, 0.0, TAU, 48, Color(1, 0.85, 0.25, 0.22), 2.0)
			draw_arc(Vector2.ZERO, reach, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, Color(1, 0.85, 0.25, 0.9), 3.0)
		State.ATTACK:
			color = COLOR_ATTACK
			radius += 7.0
			draw_circle(Vector2.ZERO, CombatTuning.ENEMY_ATTACK_RADIUS + CombatTuning.SCOUT_RADIUS, Color(1, 0.25, 0.2, 0.18))
		State.RECOVER:
			color = COLOR_IDLE.darkened(0.35)
	if _hurt_flash > 0.0:
		color = COLOR_HURT

	draw_circle(Vector2.ZERO, radius, color)
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	if hp >= max_hp:
		return
	var width := 34.0
	var top := -CombatTuning.ENEMY_RADIUS - 12.0
	var frac := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(-width / 2.0, top, width, 4.0), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-width / 2.0, top, width * frac, 4.0), Color(0.95, 0.35, 0.3))
