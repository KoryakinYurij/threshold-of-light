class_name HitStop extends Node
## Микропауза на попадании: `Engine.time_scale = 0` на несколько кадров.
## Практика жанра — удар без остановки читается как «прошёл сквозь».
## Длительности держим в 2–7 кадрах при 60 fps: длиннее начинает походить на лаг.
##
## Таймер обязан игнорировать time_scale, иначе он не дотикает никогда:
## при нулевом масштабе игровое время стоит.

const HIT_ENEMY: float = 0.035
const KILL_ENEMY: float = 0.09
const SCOUT_HURT: float = 0.12

var _frozen_until_pending: int = 0


func freeze(seconds: float) -> void:
	if seconds <= 0.0 or not CombatTuning.b("hit_stop"):
		return
	_frozen_until_pending += 1
	Engine.time_scale = 0.0
	var timer := get_tree().create_timer(seconds, true, false, true)
	await timer.timeout
	_frozen_until_pending -= 1
	# Восстанавливаем только когда отработала последняя из наложившихся пауз.
	if _frozen_until_pending <= 0:
		_frozen_until_pending = 0
		Engine.time_scale = 1.0


## Сцена может умереть посреди паузы — время должно вернуться в любом случае.
func _exit_tree() -> void:
	_frozen_until_pending = 0
	Engine.time_scale = 1.0
