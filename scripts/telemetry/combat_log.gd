extends Node
## Лог боевой телеметрии. Автолоад №6: зависит только от EventBus.
## Без class_name (ADR-005).
##
## Строка JSON на закрытый узел, дописыванием. JSONL, а не один JSON-массив:
## файл дописывается посреди сессии и не должен ломаться от того, что игру
## закрыли на середине.
##
## Отсюда T-06 берёт `hit_rate` — единственную ручку калибровки пакета Q-14.
## Вместе со счётчиками кладём и значения ползунков: замер без чисел, при
## которых он снят, для калибровки бесполезен.

const DIR: String = "user://telemetry"
const PATH: String = "user://telemetry/combat.jsonl"

var last_entry: Dictionary = {}


func _ready() -> void:
	EventBus.combat_recorded.connect(_on_combat_recorded)


func read_all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(PATH):
		return out
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_warning("CombatLog: %s не открыт (код %d)" % [PATH, FileAccess.get_open_error()])
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary:
			out.append(parsed)
		else:
			push_warning("CombatLog: строка не разобралась, пропущена")
	f.close()
	return out


func clear() -> void:
	last_entry = {}
	DirAccess.remove_absolute(PATH)


func _on_combat_recorded(stats: Dictionary) -> void:
	last_entry = stats
	if not DirAccess.dir_exists_absolute(DIR):
		var err := DirAccess.make_dir_recursive_absolute(DIR)
		if err != OK:
			push_error("CombatLog: не создать %s (код %d)" % [DIR, err])
			return
	# READ_WRITE, а не WRITE: WRITE обрезает файл, и предыдущие узлы пропадут.
	var f := FileAccess.open(PATH, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("CombatLog: не записать %s (код %d)" % [PATH, FileAccess.get_open_error()])
		return
	f.seek_end()
	f.store_line(JSON.stringify(stats))
	f.close()
