class_name CombatTuning extends RefCounted
## Боевые числа одной кучей. Стартовые значения — `ANSWERS-v0.1.md` §Q-14,
## не `SPEC-04`: T-03 это оговаривает прямо.
##
## Не автолоад и не ресурс: числа нужны сущностям, панели и тестам, а состояния
## сцены здесь нет — статические поля дают доступ без узла. ADR-005 запрещает
## `class_name` автолоадам, обычных классов это не касается.
##
## Панель F1 пишет сюда на лету, а на отпускание ползунка один раз роняет всё
## на диск через SettingsStore: состояние панели обязано пережить перезапуск .exe.

const SECTION: String = "combat"

## Порядок массива = порядок строк в панели.
## `src` — вопрос из ANSWERS-v0.1.md, который обосновывает и число, и сам ползунок.
const SPECS: Array[Dictionary] = [
	{"key": "scout_speed", "label": "Скорость разведчика", "unit": "px/c", "min": 60.0, "max": 500.0, "step": 5.0, "default": 220.0, "src": "Q-14"},
	{"key": "scout_max_hp", "label": "HP разведчика", "unit": "", "min": 20.0, "max": 300.0, "step": 5.0, "default": 100.0, "src": "Q-14"},
	{"key": "dash_duration", "label": "Длительность дэша", "unit": "c", "min": 0.05, "max": 0.80, "step": 0.01, "default": 0.30, "src": "Q-03"},
	{"key": "dash_iframes", "label": "i-frames дэша", "unit": "c", "min": 0.00, "max": 0.80, "step": 0.01, "default": 0.30, "src": "Q-03"},
	{"key": "dash_cooldown", "label": "Кулдаун дэша", "unit": "c", "min": 0.10, "max": 1.50, "step": 0.01, "default": 0.55, "src": "Q-03"},
	{"key": "dash_distance", "label": "Дистанция дэша", "unit": "px", "min": 40.0, "max": 400.0, "step": 5.0, "default": 200.0, "src": "Q-03"},
	{"key": "shot_cooldown", "label": "Кулдаун выстрела", "unit": "c", "min": 0.10, "max": 1.00, "step": 0.01, "default": 0.35, "src": "Q-07"},
	{"key": "shot_damage", "label": "Урон снаряда", "unit": "", "min": 1.0, "max": 40.0, "step": 1.0, "default": 10.0, "src": "Q-14"},
	{"key": "enemy_hp_base", "label": "HP врага (база, d=0)", "unit": "", "min": 10.0, "max": 200.0, "step": 1.0, "default": 50.0, "src": "Q-14"},
	{"key": "enemy_speed", "label": "Скорость врага", "unit": "px/c", "min": 40.0, "max": 400.0, "step": 5.0, "default": 140.0, "src": "Q-14"},
	{"key": "enemy_damage", "label": "Урон атаки врага", "unit": "", "min": 1.0, "max": 40.0, "step": 1.0, "default": 10.0, "src": "Q-14"},
	{"key": "telegraph_time", "label": "Телеграф атаки", "unit": "c", "min": 0.05, "max": 1.20, "step": 0.01, "default": 0.45, "src": "Q-02"},
	{"key": "enemy_attack_cd", "label": "Кулдаун атаки врага", "unit": "c", "min": 0.30, "max": 3.00, "step": 0.05, "default": 1.20, "src": "Q-14"},
]

## Переключатели game feel. Нужны не ради красоты: без них нельзя отличить
## «ползунок изменил бой» от «ощущение даёт тряска камеры».
const TOGGLES: Array[Dictionary] = [
	{"key": "hit_stop", "label": "Hit-stop", "default": true},
	{"key": "screen_shake", "label": "Тряска камеры", "default": true},
]

## Числа, которые ползунками не правятся: их разброс ничего не отвечает
## ни в Q-02, ни в Q-03, а лишний ползунок — лишний способ запутаться.
const ENEMY_ATTACK_RADIUS: float = 40.0
const ENEMY_ATTACK_WINDOW: float = 0.12
const ENEMY_RECOVER_TIME: float = 0.35
const SHOT_SPEED: float = 600.0
const SHOT_LIFETIME: float = 1.5
const SCOUT_RADIUS: float = 12.0
const ENEMY_RADIUS: float = 16.0

static var _values: Dictionary = {}
static var _loaded: bool = false


## Число по ключу. Первое обращение поднимает сохранённое состояние панели с диска.
static func f(key: String) -> float:
	_ensure_loaded()
	return float(_values.get(key, _default_of(key)))


static func b(key: String) -> bool:
	_ensure_loaded()
	return bool(_values.get(key, _toggle_default_of(key)))


## Правка на лету: в память, без диска. Диск — отдельно, во `flush`,
## иначе перетаскивание ползунка пишет файл каждый кадр.
static func set_value(key: String, value: Variant) -> void:
	_ensure_loaded()
	_values[key] = value


## Сброс на диск. Зовётся на отпускание ползунка и на закрытие панели.
static func flush() -> bool:
	_ensure_loaded()
	var cfg := SettingsStore.load_config()
	for key: String in _values:
		cfg.set_value(SECTION, key, _values[key])
	return SettingsStore.save_config(cfg)


static func reset_to_defaults() -> void:
	_values = _defaults()
	_loaded = true


## Все ключи, которыми оперирует панель. Порядок: сначала ползунки, потом флажки.
static func keys() -> PackedStringArray:
	var out := PackedStringArray()
	for spec: Dictionary in SPECS:
		out.append(String(spec["key"]))
	for spec: Dictionary in TOGGLES:
		out.append(String(spec["key"]))
	return out


static func spec_of(key: String) -> Dictionary:
	for spec: Dictionary in SPECS:
		if spec["key"] == key:
			return spec
	return {}


## Множитель сложности по глубине, `K(d) = 1.15^d` (Q-11).
static func k_depth(depth: int) -> float:
	return pow(1.15, float(depth))


## HP врага на глубине. Единственное место, где база и K(d) встречаются.
static func enemy_hp_at(depth: int) -> int:
	return int(round(f("enemy_hp_base") * k_depth(depth)))


# --- Внутреннее ---

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_values = _defaults()
	var cfg := SettingsStore.load_config()
	if not cfg.has_section(SECTION):
		return
	for key: String in _values:
		if cfg.has_section_key(SECTION, key):
			_values[key] = cfg.get_value(SECTION, key, _values[key])


static func _defaults() -> Dictionary:
	var out := {}
	for spec: Dictionary in SPECS:
		out[String(spec["key"])] = float(spec["default"])
	for spec: Dictionary in TOGGLES:
		out[String(spec["key"])] = bool(spec["default"])
	return out


static func _default_of(key: String) -> float:
	var spec := spec_of(key)
	if spec.is_empty():
		push_error("CombatTuning: нет ползунка с ключом %s" % key)
		return 0.0
	return float(spec["default"])


static func _toggle_default_of(key: String) -> bool:
	for spec: Dictionary in TOGGLES:
		if spec["key"] == key:
			return bool(spec["default"])
	push_error("CombatTuning: нет флажка с ключом %s" % key)
	return false
