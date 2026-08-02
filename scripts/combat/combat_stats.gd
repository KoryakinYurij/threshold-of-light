class_name CombatStats extends RefCounted
## Счётчики одного боевого узла. Пишутся в лог по закрытию узла, оттуда T-06
## берёт `hit_rate` — единственную ручку калибровки пакета Q-14.
##
## Отдельные счётчики на «увернулся i-frames» и «вышел из радиуса» — не роскошь:
## Q-03 меряет именно долю атак, съеденных дэшем, а уход шагом её бы завысил.

var shots_fired: int = 0
var shots_hit: int = 0
var damage_dealt: int = 0
var damage_taken: int = 0
var enemies_killed: int = 0
var dashes: int = 0
## Атаки врага, дошедшие до удара (телеграф отыгран целиком).
var enemy_attacks: int = 0
var attacks_hit: int = 0
## Разведчик был в радиусе, но неуязвим — засчитано дэшу.
var attacks_dodged_iframes: int = 0
## Разведчик успел выйти из радиуса — засчитано шагу или смещению дэша.
var attacks_evaded_range: int = 0
var node_seconds: float = 0.0


## Доля попаданий. T-06 подставляет её в `hp_врага_база = ... × hit_rate / ...`.
func hit_rate() -> float:
	if shots_fired <= 0:
		return 0.0
	return float(shots_hit) / float(shots_fired)


## Доля атак врага, от которых разведчик ушёл. Рамка Q-03: > 0.9 — окно щедрое,
## < 0.4 — узкое.
func dodge_rate() -> float:
	if enemy_attacks <= 0:
		return 0.0
	return float(attacks_dodged_iframes + attacks_evaded_range) / float(enemy_attacks)


## Плоский словарь под JSON. Только int/float/bool/String — ADR-003.
func to_dict() -> Dictionary:
	return {
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"hit_rate": hit_rate(),
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"enemies_killed": enemies_killed,
		"dashes": dashes,
		"enemy_attacks": enemy_attacks,
		"attacks_hit": attacks_hit,
		"attacks_dodged_iframes": attacks_dodged_iframes,
		"attacks_evaded_range": attacks_evaded_range,
		"dodge_rate": dodge_rate(),
		"node_seconds": node_seconds,
	}
