class_name Pursuer extends CharacterBody2D
## Преследователь: плоский FSM IDLE->SEEK->TELEGRAPH->ATTACK->RECOVER (спека T-03).

enum State { IDLE, SEEK, TELEGRAPH, ATTACK, RECOVER }

var arena: Node
var target: Node
var state: State = State.IDLE
var state_elapsed: float = 0.0
var attack_done: bool = false
var attack_cooldown_left: float = 0.0
var dead: bool = false
var telegraph_direction: Vector2 = Vector2.UP
var attack_flash: float = 0.0

@export var target_path: NodePath
@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
	arena = get_parent()
	target = get_node_or_null(target_path)
	health.died.connect(_on_died)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead or target == null or not is_instance_valid(target) or target.get("dead") == true:
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
			velocity = global_position.direction_to(target.global_position) * arena.get_parameter("enemy_speed", 140.0)
			move_and_slide()
			if distance <= 40.0:
				_change_state(State.TELEGRAPH)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			telegraph_direction = global_position.direction_to(target.global_position)
			if state_elapsed >= arena.get_parameter("telegraph", 0.5):
				_change_state(State.ATTACK)
		State.ATTACK:
			velocity = Vector2.ZERO
			if not attack_done:
				attack_done = true
				attack_flash = 0.16
				if distance <= 48.0 and target.has_node("HealthComponent"):
					var data := DamageData.new(roundi(arena.get_parameter("enemy_damage", 25.0)), get_instance_id(), global_position.direction_to(target.global_position) * 100.0)
					target.get_node("HealthComponent").take_damage(data)
					arena.emit_feedback(target.global_position, 0.9, 0.09)
				_change_state(State.RECOVER)
		State.RECOVER:
			velocity = Vector2.ZERO
			if state_elapsed >= 0.28:
				_change_state(State.SEEK)
	queue_redraw()

func _change_state(next: State) -> void:
	state = next
	state_elapsed = 0.0
	attack_done = false
	queue_redraw()

func _on_died() -> void:
	if dead:
		return
	dead = true
	arena.notify_enemy_died(self)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color("#ff6b6b"))
	draw_circle(Vector2.ZERO, 16.0, Color("#30151b"), false, 2.0)
	draw_line(Vector2.ZERO, Vector2(0, -24), Color("#ffb0a8"), 3.0)
	draw_rect(Rect2(-18, -31, 36, 4), Color("#30151b"))
	draw_rect(Rect2(-18, -31, 36.0 * float(health.current) / float(maxi(1, health.maximum)), 4), Color("#ffcf87"))
	if state == State.TELEGRAPH:
		var pulse: float = 1.0 + sin(state_elapsed * 18.0) * 0.12
		draw_circle(Vector2.ZERO, 28.0 * pulse, Color("#ffb347", 0.22), false, 4.0)
		draw_line(Vector2.ZERO, telegraph_direction * 54.0, Color("#ffb347"), 5.0)
	elif state == State.ATTACK or attack_flash > 0.0:
		draw_circle(Vector2.ZERO, 34.0, Color("#ff4757", 0.45), false, 5.0)
