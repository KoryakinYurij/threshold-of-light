class_name ShakeCamera extends Camera2D
## Тряска камеры по модели «травмы» (Squirrel Eiserloh, GDC 2016 «Juicing Your
## Cameras With Math»): накапливается `trauma`, смещение считается как `trauma²`,
## травма гаснет линейно. Квадрат нужен, чтобы слабые попадания почти не трясли,
## а сильные читались отдельно.
##
## Смещение берётся из шума, а не из `randf`: белый шум даёт дрожь, шум Перлина —
## рывок, который глаз читает как удар.
##
## Поворот не трогаем: в top-down он сбивает прицел мышью, а мышью тут целятся.

const MAX_OFFSET: float = 14.0
const DECAY: float = 1.8
const NOISE_SPEED: float = 42.0

const TRAUMA_SHOT_HIT: float = 0.12
const TRAUMA_KILL: float = 0.35
const TRAUMA_SCOUT_HURT: float = 0.55

var _trauma: float = 0.0
var _noise_t: float = 0.0
var _noise: FastNoiseLite = null


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = 20260802
	_noise.frequency = 0.5
	set_process(true)


func add_trauma(amount: float) -> void:
	if not CombatTuning.b("screen_shake"):
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - DECAY * delta, 0.0)
	_noise_t += delta * NOISE_SPEED
	var shake := _trauma * _trauma
	offset = Vector2(
		_noise.get_noise_2d(_noise_t, 0.0),
		_noise.get_noise_2d(0.0, _noise_t)
	) * MAX_OFFSET * shake
