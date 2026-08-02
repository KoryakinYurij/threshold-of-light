extends Node
## Сиды. Автолоад №2: чистая функция от мастер-сида, о состоянии не знает.
## Без class_name (ADR-005).
##
## Контракт ADR-004:
##  - мастер-сид лежит в 0..2^53-1 — граница точности double, переживает JSON;
##  - под-сиды выводятся детерминированно и НИКОГДА не сохраняются;
##  - деривация только целочисленная, ни одного float на пути сида;
##  - три потока независимы: бой не может сдвинуть генерацию графа.

const MAX_SEED: int = 9007199254740991  # 2^53-1 — предел точного double
const SEED_SPACE: int = 9007199254740992  # MAX_SEED + 1

const _MASK_63: int = 0x7FFFFFFFFFFFFFFF
const _MASK_31: int = 0x7FFFFFFF

# Различители потоков. Нечётные константы, взяты из общеупотребимых наборов
# для целочисленного перемешивания; конкретные значения роли не играют,
# важна только их различность и постоянство.
const _STREAM_GRAPH: int = 0x517CC1B7
const _STREAM_LOOT: int = 0x27220A95
const _STREAM_COMBAT: int = 0x2545F491


## Новый мастер-сид. Гарантированно <= MAX_SEED (53 бита: 21 + 32).
func new_master_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var high: int = int(rng.randi()) & 0x1FFFFF
	var low: int = int(rng.randi()) & 0xFFFFFFFF
	return ((high << 32) | low) & MAX_SEED


## Кэп для сида, введённого игроком (daily / debug). Применяется при вводе,
## а не при использовании (ADR-004 §4). Значения уже в диапазоне не меняются.
func normalize(raw: int) -> int:
	return (raw & _MASK_63) % SEED_SPACE


func graph_seed(master: int) -> int:
	return _mix(master, _STREAM_GRAPH)


func loot_seed(master: int) -> int:
	return _mix(master, _STREAM_LOOT)


func combat_seed(master: int) -> int:
	return _mix(master, _STREAM_COMBAT)


## Готовый генератор для потока. Удобнее, чем вручную присваивать seed.
func rng_for(sub_seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = sub_seed
	return rng


## Целочисленное перемешивание в духе splitmix64, урезанное так, чтобы
## ни одно умножение не вылезло за int64: перед каждым умножением операнд
## сжимается до 31 бита, множитель — 32-битный. Старшие биты не теряются:
## они подмешиваются сдвигом вправо до маскирования.
func _mix(value: int, stream: int) -> int:
	var x: int = (value ^ stream) & _MASK_63
	x = ((x ^ (x >> 30)) & _MASK_31) * 0xBF58476D
	x = ((x ^ (x >> 27)) & _MASK_31) * 0x94D049BB
	return (x ^ (x >> 31)) & _MASK_63
