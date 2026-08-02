class_name Scout extends CharacterBody2D
## Разведчик. Один защитный инструмент — дэш (Q-03), поэтому пост-хит
## неуязвимости здесь нет намеренно: она бы смазала ровно тот замер,
## ради которого прототип и собирается.
##
## i-frames заведены отдельным числом от длительности дэша. По Q-03 они равны,
## но развести их ползунками — единственный способ проверить, что владелец
## чувствует именно окно неуязвимости, а не смещение тела.

signal hp_changed(hp: int, max_hp: int)
signal died()
signal dashed()
signal shot_fired(from: Vector2, direction: Vector2, damage: int)

const COLOR_BODY: Color = Color(0.42, 0.72, 1.0)
const COLOR_DASH: Color = Color(0.85, 0.97, 1.0)
const COLOR_HURT: Color = Color(1.0, 0.45, 0.45)

var max_hp: int = 100
var hp: int = 100
var alive: bool = true
## Снимается, пока открыта панель F1: "attack" висит на кнопке мыши, и без этого
## перетаскивание ползунка стреляло бы.
var input_enabled: bool = true

var _dash_left: float = 0.0
var _iframes_left: float = 0.0
var _dash_cd_left: float = 0.0
var _shot_cd_left: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _aim: Vector2 = Vector2.RIGHT
var _hurt_flash: float = 0.0
var _dash_buffer: InputBuffer = InputBuffer.new()
var _shot_buffer: InputBuffer = InputBuffer.new()


func _ready() -> void:
	max_hp = int(CombatTuning.f("scout_max_hp"))
	hp = max_hp
	EventBus.tuning_changed.connect(_on_tuning_changed)
	hp_changed.emit(hp, max_hp)


func is_invulnerable() -> bool:
	return _iframes_left > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not alive or not input_enabled:
		return
	if event.is_action_pressed("dash"):
		_dash_buffer.press()
	if event.is_action_pressed("attack"):
		_shot_buffer.press()


func _physics_process(delta: float) -> void:
	if not alive or not input_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		_tick_timers(delta)
		queue_redraw()
		return

	_dash_buffer.tick(delta)
	_shot_buffer.tick(delta)
	_tick_timers(delta)
	_aim = (get_global_mouse_position() - global_position).normalized()

	if _dash_left > 0.0:
		velocity = _dash_dir * (CombatTuning.f("dash_distance") / maxf(CombatTuning.f("dash_duration"), 0.01))
	else:
		velocity = _move_input() * CombatTuning.f("scout_speed")
		if _dash_cd_left <= 0.0 and _dash_buffer.consume():
			_start_dash()

	# Огонь очередью: кнопка удерживается, буфер ловит нажатие в мёртвый кадр.
	if _shot_cd_left <= 0.0:
		if Input.is_action_pressed("attack") or _shot_buffer.consume():
			_fire()

	move_and_slide()
	queue_redraw()


func take_damage(amount: int) -> void:
	if not alive or is_invulnerable():
		return
	hp = maxi(hp - amount, 0)
	_hurt_flash = 0.18
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		alive = false
		died.emit()


func _draw() -> void:
	var color := COLOR_BODY
	if _hurt_flash > 0.0:
		color = COLOR_HURT
	elif is_invulnerable():
		color = COLOR_DASH
	if not alive:
		color = Color(0.35, 0.35, 0.4)

	draw_circle(Vector2.ZERO, CombatTuning.SCOUT_RADIUS, color)
	# Кольцо неуязвимости: без него i-frames невидимы, и ползунок нечем читать.
	if is_invulnerable():
		draw_arc(Vector2.ZERO, CombatTuning.SCOUT_RADIUS + 6.0, 0.0, TAU, 28, Color(1, 1, 1, 0.9), 2.0)
	if alive:
		draw_line(Vector2.ZERO, _aim * (CombatTuning.SCOUT_RADIUS + 10.0), Color(1, 1, 1, 0.75), 2.0)


func _tick_timers(delta: float) -> void:
	_dash_left = maxf(_dash_left - delta, 0.0)
	_iframes_left = maxf(_iframes_left - delta, 0.0)
	_dash_cd_left = maxf(_dash_cd_left - delta, 0.0)
	_shot_cd_left = maxf(_shot_cd_left - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)


func _move_input() -> Vector2:
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).limit_length(1.0)


func _start_dash() -> void:
	var dir := _move_input()
	if dir.is_zero_approx():
		dir = _aim
	_dash_dir = dir.normalized()
	_dash_left = CombatTuning.f("dash_duration")
	_iframes_left = CombatTuning.f("dash_iframes")
	# Кулдаун считается от старта дэша, а не от конца: Q-03 закладывает
	# ~2 дэша на цикл атаки врага (1.2 c), а это верно только так.
	_dash_cd_left = CombatTuning.f("dash_cooldown")
	dashed.emit()


func _fire() -> void:
	_shot_cd_left = CombatTuning.f("shot_cooldown")
	shot_fired.emit(
		global_position + _aim * (CombatTuning.SCOUT_RADIUS + 6.0),
		_aim,
		int(CombatTuning.f("shot_damage"))
	)


func _on_tuning_changed() -> void:
	var new_max := int(CombatTuning.f("scout_max_hp"))
	if new_max == max_hp:
		return
	max_hp = new_max
	hp = mini(hp, max_hp)
	hp_changed.emit(hp, max_hp)
