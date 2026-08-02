extends Node
## Держатель состояния. Автолоад №3: зависит от EventBus и SeedService.
## Без class_name (ADR-005).
##
## Не God object (CONTEXT.md): три состояния живут отдельными объектами и
## ничего не знают друг о друге. GameState их только держит и обнуляет.
##
## GameState НЕ вызывает SaveManager напрямую (запрет циклов, SPEC-01 §1) —
## запрос на запись идёт через EventBus.save_requested.

var profile: ProfileState = null
var hub: HubState = null
var current_run: RunState = null


func _ready() -> void:
	reset()


## Чистый профиль без сейва. Точка входа для «новой игры».
func reset() -> void:
	profile = ProfileState.new()
	hub = HubState.new()
	current_run = null


## Заводит новый забег. Единственное место, где мастер-сид попадает в состояние.
## Без аргумента (или с sentinel -1) создаётся новый сид; внешний daily/debug
## сид передаётся неотрицательным числом и нормализуется через SeedService.
func begin_run(master_seed: int = -1) -> RunState:
	var chosen: int = master_seed
	if chosen < 0:
		chosen = SeedService.new_master_seed()
	else:
		chosen = SeedService.normalize(chosen)
	current_run = RunState.new()
	current_run.master_seed = chosen
	return current_run


func end_run() -> void:
	current_run = null


func has_run() -> bool:
	return current_run != null
