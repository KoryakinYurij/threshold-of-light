extends Node
## Сейвы. Автолоад №4: зависит от GameState (читает его для записи).
## Без class_name (ADR-005).
##
## Формат — JSON через FileAccess (ADR-001). Настройки живут отдельно,
## в ConfigFile — см. SettingsStore.
##
## Запись атомарная: полный файл кладётся в .tmp, существующий слот
## копируется в .bak, и только потом .tmp переименовывается в слот.
## Убийство процесса до переименования оставляет слот нетронутым (SPEC-01 §6).
##
## SaveManager не читает GameState по своей инициативе при старте —
## только по вызову или по EventBus.save_requested.

const SLOT_COUNT: int = 3
const DEFAULT_SLOT: int = 0
const SAVE_DIR: String = "user://saves"

var current_slot: int = DEFAULT_SLOT


func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.save_requested.connect(_on_save_requested)


# --- Пути ---

func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func backup_path(slot: int) -> String:
	return "%s/slot_%d.bak.json" % [SAVE_DIR, slot]


func _tmp_path(slot: int) -> String:
	return "%s/slot_%d.tmp" % [SAVE_DIR, slot]


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


# --- Запись ---

## Пишет текущее состояние GameState в слот. Возвращает успех.
func save_to_slot(slot: int) -> bool:
	if not _valid_slot(slot):
		push_error("SaveManager: слот %d вне диапазона 0..%d" % [slot, SLOT_COUNT - 1])
		return false

	var env := SaveEnvelope.new()
	env.profile = GameState.profile
	env.hub_state = GameState.hub
	env.run_state = GameState.current_run

	var ok := _write_envelope(slot, env)
	current_slot = slot
	EventBus.save_completed.emit(slot, ok)
	return ok


func _write_envelope(slot: int, env: SaveEnvelope) -> bool:
	if DirAccess.make_dir_recursive_absolute(SAVE_DIR) != OK and not DirAccess.dir_exists_absolute(SAVE_DIR):
		push_error("SaveManager: не создать %s" % SAVE_DIR)
		return false

	var text := JSON.stringify(SaveSchema.envelope_to_dict(env), "\t")

	# 1. Полный файл во временный.
	var tmp := _tmp_path(slot)
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: не открыть %s (код %d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(text)
	f.close()

	# 2. Временный файл должен читаться. Если нет — слот не трогаем.
	if _parse_object(FileAccess.get_file_as_string(tmp)).is_empty():
		push_error("SaveManager: временный файл слота %d нечитаем, слот не тронут" % slot)
		DirAccess.remove_absolute(tmp)
		return false

	# 3. Бэкап существующего слота. Копией, а не переносом: слот должен
	#    оставаться на месте до самого переименования.
	var final := slot_path(slot)
	if FileAccess.file_exists(final):
		DirAccess.copy_absolute(final, backup_path(slot))

	# 4. Подмена.
	if DirAccess.rename_absolute(tmp, final) != OK:
		push_error("SaveManager: не переименовать %s -> %s" % [tmp, final])
		return false
	return true


# --- Чтение ---

## Читает слот. При битом основном файле молча падает на бэкап.
## Возвращает null, если нечего читать.
func load_from_slot(slot: int) -> SaveEnvelope:
	if not _valid_slot(slot):
		push_error("SaveManager: слот %d вне диапазона 0..%d" % [slot, SLOT_COUNT - 1])
		return null

	var env := _read_file(slot_path(slot))
	if env == null:
		env = _read_file(backup_path(slot))
		if env != null:
			push_warning("SaveManager: слот %d прочитан из бэкапа" % slot)
	if env == null:
		return null

	current_slot = slot
	GameState.profile = env.profile
	GameState.hub = env.hub_state
	GameState.current_run = env.run_state
	return env


func _read_file(path: String) -> SaveEnvelope:
	if not FileAccess.file_exists(path):
		return null
	var parsed := _parse_object(FileAccess.get_file_as_string(path))
	if parsed.is_empty():
		push_warning("SaveManager: %s не разобрался как JSON-объект" % path)
		return null
	var env := SaveSchema.envelope_from_dict(parsed)
	if env.save_version != SaveEnvelope.VERSION:
		# Миграций в Phase 1 нет: схема одна, v1 (SPEC-01 §9).
		push_warning("SaveManager: %s версии %d, ожидалась %d" % [path, env.save_version, SaveEnvelope.VERSION])
	return env


## Разбор JSON-объекта. Пустой словарь = не разобралось.
## Через JSON.new(), а не JSON.parse_string: битый сейв — штатная ситуация,
## её отрабатывает бэкап, и в лог она не должна падать движковой ошибкой.
func _parse_object(raw: String) -> Dictionary:
	if raw.is_empty():
		return {}
	var json := JSON.new()
	if json.parse(raw) != OK:
		return {}
	var data: Variant = json.data
	return data if data is Dictionary else {}


## Загружает слот, а если его нет — заводит чистое состояние и пишет слот.
func load_or_create(slot: int) -> SaveEnvelope:
	var env := load_from_slot(slot)
	if env != null:
		return env
	GameState.reset()
	save_to_slot(slot)
	return load_from_slot(slot)


func delete_slot(slot: int) -> void:
	for p: String in [slot_path(slot), backup_path(slot), _tmp_path(slot)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


# --- Реакции на шину ---

func _on_game_started(slot: int) -> void:
	load_or_create(slot)


func _on_save_requested(reason: String) -> void:
	var ok := save_to_slot(current_slot)
	if not ok:
		push_error("SaveManager: запись по причине '%s' не удалась" % reason)


func _valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT
