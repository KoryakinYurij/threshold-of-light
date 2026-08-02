class_name Scout extends CharacterBody2D
## Скаут: движение, дэш с i-frames, мели-атака. HP живёт в HealthComponent.

const DASH_DISTANCE: float = 160.0
const DASH_DURATION: float = 0.18
const INPUT_BUFFER: float = 0.18
const ATTACK_DAMAGE: int = 10
const ATTACK_COOLDOWN: float = 0.25
const MELEE_OFFSET: float = 34.0
const MELEE_RANGE: float = 38.0

var arena: Node
var last_direction: Vector2 = Vector2.RIGHT
var dash_direction: Vector2 = Vector2.RIGHT
var dash_elapsed: float = 0.0
var dash_cooldown_left: float = 0.0
var attack_cooldown_left: float = 0.0
var is_dashing: bool = false
var dead: bool = false
var attack_flash: float = 0.0
var input_buffer: Array[Dictionary] = []

@onready var health: HealthComponent = $HealthComponent
@onready var melee: MeleeHitbox = $MeleeHitbox

func _ready() -> void:
	arena = get_parent()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	health.set_maximum(maxi(1, roundi(arena.get_parameter("scout_hp", 100.0))))
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event.is_action_pressed("dash") or event.is_action_pressed("attack"):
		var action: String = "dash" if event.is_action_pressed("dash") else "attack"
		input_buffer.append({"action": action, "at": Time.get_ticks_msec() / 1000.0})
		if input_buffer.size() > 8:
			input_buffer.pop_front()

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	_expire_buffer()
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.0:
		last_direction = direction.normalized()
	if not is_dashing and _consume("dash") and dash_cooldown_left <= 0.0:
		is_dashing = true
		dash_elapsed = 0.0
		dash_direction = last_direction
		dash_cooldown_left = arena.get_parameter("dash_cooldown", 0.8)
		health.begin_invincibility(arena.get_parameter("iframes", 0.18))
		arena.emit_feedback(global_position, 0.35, 0.0)
	if not is_dashing and _consume("attack") and attack_cooldown_left <= 0.0:
		_attack()
	if is_dashing:
		dash_elapsed += delta
		velocity = dash_direction * (DASH_DISTANCE / DASH_DURATION)
		if dash_elapsed >= DASH_DURATION:
			is_dashing = false
	else:
		velocity = direction.normalized() * arena.get_parameter("speed", 220.0)
	move_and_slide()
	melee.position = last_direction * MELEE_OFFSET
	melee.rotation = last_direction.angle()
	global_position.x = clampf(global_position.x, 40.0, 1240.0)
	global_position.y = clampf(global_position.y, 100.0, 680.0)
	queue_redraw()

func _attack() -> void:
	attack_cooldown_left = ATTACK_COOLDOWN
	attack_flash = 0.12
	melee.activate(ATTACK_DAMAGE, last_direction * 80.0)
	arena.emit_feedback(global_position, 0.25, 0.0)
	queue_redraw()

func _on_health_changed(current: int, maximum: int) -> void:
	arena.notify_scout_hp(current, maximum)

func _on_died() -> void:
	if dead:
		return
	dead = true
	arena.notify_scout_died()
	queue_redraw()

func _consume(action: String) -> bool:
	for index: int in input_buffer.size():
		if input_buffer[index]["action"] == action:
			input_buffer.remove_at(index)
			return true
	return false

func _expire_buffer() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	while not input_buffer.is_empty() and now - float(input_buffer[0]["at"]) > INPUT_BUFFER:
		input_buffer.pop_front()

func _draw() -> void:
	var color: Color = Color("#fff2a8") if is_dashing else Color("#d8f3ff")
	if dead:
		color = Color("#4d5966")
	draw_circle(Vector2.ZERO, 14.0, color)
	draw_circle(Vector2.ZERO, 14.0, Color("#16202b"), false, 2.0)
	draw_line(Vector2.ZERO, last_direction * 22.0, Color("#71d8ff"), 3.0)
	if attack_flash > 0.0:
		draw_arc(last_direction * 34.0, 34.0, -1.0, 1.0, 16, Color("#fff4bf"), 5.0)
