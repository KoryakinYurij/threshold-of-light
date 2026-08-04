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

## Применил ли урон. False — i-frames или уже мёртв: фидбэк «попадания»
## вешается на true, иначе удар ощущается даже на поглощённом i-frames
## (T-03b Блок 1).
func take_damage(data: DamageData) -> bool:
	if invincible or current <= 0:
		return false
	current = maxi(0, current - data.amount)
	invincible = true
	invincibility_left = I_FRAME_WINDOW
	health_changed.emit(current, maximum)
	if current <= 0:
		died.emit()
	return true

## Лечение (T-03b Блок 2: дроп +10 HP). Не воскрешает.
func heal(amount: int) -> void:
	if current <= 0:
		return
	current = mini(maximum, current + amount)
	health_changed.emit(current, maximum)

func begin_invincibility(duration: float) -> void:
	invincible = true
	invincibility_left = maxf(invincibility_left, duration)
