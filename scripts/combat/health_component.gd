class_name HealthComponent extends Node
## Компонент здоровья: весь урон входит через take_damage (godot-combat-system).
## i-frames принадлежат компоненту: после попадания короткое окно неуязвимости.
## HUD слушает health_changed/died — lifebar не живёт в сущности.

signal health_changed(current: int, maximum: int)
signal died

const I_FRAME_WINDOW: float = 0.12

@export var maximum: int = 100
@export var current: int = 100
var invincible: bool = false
var invincibility_left: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current = clampi(current, 0, maximum)
	health_changed.emit(current, maximum)

func _process(delta: float) -> void:
	if invincibility_left <= 0.0:
		return
	var unscaled: float = delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	invincibility_left -= unscaled
	if invincibility_left <= 0.0:
		invincibility_left = 0.0
		invincible = false

func set_maximum(new_maximum: int) -> void:
	maximum = maxi(1, new_maximum)
	current = mini(current, maximum)
	health_changed.emit(current, maximum)

func take_damage(data: DamageData) -> void:
	if invincible or current <= 0:
		return
	current = maxi(0, current - data.amount)
	invincible = true
	invincibility_left = I_FRAME_WINDOW
	health_changed.emit(current, maximum)
	if current <= 0:
		died.emit()

func begin_invincibility(duration: float) -> void:
	invincible = true
	invincibility_left = maxf(invincibility_left, duration)
