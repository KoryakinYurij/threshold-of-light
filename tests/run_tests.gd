extends Node
## Прогон проверок каркаса T-02 (SPEC-01 DoD + план T-02). Запуск:
##   godot --headless --path . res://tests/run_tests.tscn
## Ненулевой код возврата = красный тест.
##
## Сцена, а не `--script`: только запуск сцены гарантирует, что автолоады
## подняты — а проверять надо именно их.

const EXPECTED_AUTOLOADS: Array[String] = [
	"EventBus", "SeedService", "GameState", "SaveManager", "SceneRouter"
]
const TEST_SLOT: int = 2
const BACKUP_SLOT: int = 1

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame

	_suite_autoloads()
	_suite_seed_service()
	_suite_save_roundtrip()
	_suite_seed_boundaries()
	_suite_atomicity_and_backup()
	_suite_backup_failure()
	_suite_settings()

	SaveManager.delete_slot(TEST_SLOT)
	SaveManager.delete_slot(BACKUP_SLOT)
	DirAccess.remove_absolute(SettingsStore.PATH)

	# В headless на VPS Godot 4.7 не возвращается после change_scene_to_file
	# даже в минимальном проекте. Это не save/load-контракт T-02; scene-flow
	# проверяется на Windows в оконном запуске. Не оставляем headless-процесс висеть.
	if OS.has_feature("headless"):
		print("[сцена: меню -> хаб через EventBus]")
		print("  SKIP  headless VPS: scene-flow проверяется на Windows (см. docs/prototype/JOURNAL.md, запись T-02)")
		_finish_and_quit()
		return

	# Последняя: смена сцены освобождает этот узел.
	_suite_scene_flow()


# --- Наборы ---

func _suite_autoloads() -> void:
	print("[автолоады]")
	var root := get_tree().root
	for name: String in EXPECTED_AUTOLOADS:
		_check(root.get_node_or_null(NodePath(name)) != null, "автолоад %s зарегистрирован" % name)

	# Порядок инициализации = порядок в [autoload]; автолоады идут первыми детьми root.
	var actual: Array[String] = []
	for i: int in mini(EXPECTED_AUTOLOADS.size(), root.get_child_count()):
		actual.append(root.get_child(i).name)
	_check(actual == EXPECTED_AUTOLOADS, "порядок автолоадов %s == %s" % [actual, EXPECTED_AUTOLOADS])

	# ADR-005: ни один автолоад не объявляет class_name.
	for name: String in EXPECTED_AUTOLOADS:
		var node := root.get_node_or_null(NodePath(name))
		if node == null:
			continue
		var script: Script = node.get_script()
		_check(script != null and script.get_global_name() == &"", "%s без class_name (ADR-005)" % name)


func _suite_seed_service() -> void:
	print("[сиды]")
	_check(SeedService.MAX_SEED == 9007199254740991, "MAX_SEED == 2^53-1 (ADR-004)")

	var out_of_range := 0
	var seen := {}
	for i: int in 2000:
		var s := SeedService.new_master_seed()
		if s < 0 or s > SeedService.MAX_SEED:
			out_of_range += 1
		seen[s] = true
	_check(out_of_range == 0, "2000 мастер-сидов в диапазоне 0..MAX_SEED")
	_check(seen.size() > 1900, "мастер-сиды не вырождены (%d уникальных из 2000)" % seen.size())

	_check(SeedService.normalize(SeedService.MAX_SEED) == SeedService.MAX_SEED, "normalize не трогает MAX_SEED")
	_check(SeedService.normalize(0) == 0, "normalize(0) == 0")
	var big := SeedService.normalize(9223372036854775807)
	_check(big >= 0 and big <= SeedService.MAX_SEED, "normalize кэпит int64-максимум -> %d" % big)
	var neg := SeedService.normalize(-1)
	_check(neg >= 0 and neg <= SeedService.MAX_SEED, "normalize кэпит отрицательное -> %d" % neg)

	# Детерминизм и независимость трёх потоков.
	var collisions := 0
	var negatives := 0
	for i: int in 500:
		var m: int = i * 7919 + 13
		var g := SeedService.graph_seed(m)
		var l := SeedService.loot_seed(m)
		var c := SeedService.combat_seed(m)
		if g == l or l == c or g == c:
			collisions += 1
		if g < 0 or l < 0 or c < 0:
			negatives += 1
		if SeedService.graph_seed(m) != g:
			_check(false, "graph_seed недетерминирован на %d" % m)
	_check(collisions == 0, "потоки graph/loot/combat не совпадают на 500 мастер-сидах")
	_check(negatives == 0, "под-сиды неотрицательны")

	# Разные мастер-сиды -> разные графовые сиды (грубая проверка на вырождение).
	var graph_seeds := {}
	for i: int in 1000:
		graph_seeds[SeedService.graph_seed(i)] = true
	_check(graph_seeds.size() == 1000, "1000 соседних мастер-сидов дают 1000 разных graph_seed (получено %d)" % graph_seeds.size())


func _suite_save_roundtrip() -> void:
	print("[сейв: round-trip]")
	SaveManager.delete_slot(TEST_SLOT)
	GameState.reset()
	GameState.hub.materials = 42
	GameState.hub.unstable_loot = 3
	GameState.hub.modules["forge_of_form"] = 2
	GameState.profile.memories = 7
	GameState.profile.runs_completed = 3
	GameState.profile.runs_died = 1
	GameState.profile.unlocked_modules = PackedStringArray(["forge_of_form", "beacon"])
	var run := GameState.begin_run(123456789)
	run.current_node_index = 4
	run.visited_nodes = PackedInt32Array([0, 1, 4])
	run.pending_materials = 5
	run.pending_unstable_loot = 9
	run.pending_memories = 2
	run.scout_hp = 77

	_check(SaveManager.save_to_slot(TEST_SLOT), "запись в слот %d" % TEST_SLOT)
	_check(SaveManager.has_slot(TEST_SLOT), "файл слота %d на диске" % TEST_SLOT)

	GameState.reset()  # затираем память, чтобы читать действительно с диска
	var env := SaveManager.load_from_slot(TEST_SLOT)
	_check(env != null, "слот %d прочитан" % TEST_SLOT)
	if env == null:
		return

	_check(env.save_version == SaveEnvelope.VERSION, "save_version == %d" % SaveEnvelope.VERSION)
	_check(env.hub_state.materials == 42, "hub.materials == 42")
	_check(env.hub_state.unstable_loot == 3, "hub.unstable_loot == 3")
	_check(env.profile.memories == 7, "profile.memories == 7")
	_check(env.profile.runs_completed == 3, "profile.runs_completed == 3")
	_check(env.profile.runs_died == 1, "profile.runs_died == 1")
	_check(Array(env.profile.unlocked_modules) == ["forge_of_form", "beacon"], "profile.unlocked_modules сохранён")
	_check(env.run_state != null, "run_state непустой")
	_check(env.run_state.master_seed == 123456789, "run_state.master_seed сохранён")
	_check(env.run_state.current_node_index == 4, "run_state.current_node_index == 4")
	_check(Array(env.run_state.visited_nodes) == [0, 1, 4], "run_state.visited_nodes сохранён")
	_check(env.run_state.scout_hp == 77, "run_state.scout_hp == 77")

	# Главное в ADR-003: типы, а не значения. 2 == 2.0 истинно, тест значений это пропустит.
	_check(typeof(env.hub_state.modules["forge_of_form"]) == TYPE_INT, "modules[\"forge_of_form\"] это TYPE_INT, а не TYPE_FLOAT")
	_check(typeof(env.profile.memories) == TYPE_INT, "profile.memories это TYPE_INT")
	_check(typeof(env.run_state.master_seed) == TYPE_INT, "run_state.master_seed это TYPE_INT")
	_check(typeof(env.run_state.visited_nodes) == TYPE_PACKED_INT32_ARRAY, "visited_nodes это PackedInt32Array")
	_check(typeof(env.profile.unlocked_modules) == TYPE_PACKED_STRING_ARRAY, "unlocked_modules это PackedStringArray")

	# Состояние GameState после загрузки — то же самое.
	_check(GameState.hub.materials == 42, "GameState.hub подхватил загруженное")
	_check(GameState.current_run != null and GameState.current_run.master_seed == 123456789, "GameState.current_run подхватил загруженное")

	# Точка сохранения «в хабе» (SPEC-01 §6): run_state обязан лечь как null.
	GameState.end_run()
	_check(SaveManager.save_to_slot(TEST_SLOT), "перезапись слота из хаба")
	GameState.reset()
	var hub_env := SaveManager.load_from_slot(TEST_SLOT)
	_check(hub_env != null and hub_env.run_state == null, "run_state == null, когда игрок в хабе")


func _suite_seed_boundaries() -> void:
	print("[сиды: граница JSON]")
	var boundaries: Array[int] = [0, 1, SeedService.MAX_SEED - 1, SeedService.MAX_SEED]
	for s: int in boundaries:
		SaveManager.delete_slot(TEST_SLOT)
		GameState.reset()
		GameState.begin_run(s)
		SaveManager.save_to_slot(TEST_SLOT)
		GameState.reset()
		var env := SaveManager.load_from_slot(TEST_SLOT)
		var restored: int = -1 if env == null or env.run_state == null else env.run_state.master_seed
		_check(restored == s, "сид %d пережил JSON-роундтрип (получено %d)" % [s, restored])
		_check(SeedService.graph_seed(restored) == SeedService.graph_seed(s), "graph_seed(restored) == graph_seed(%d)" % s)
		_check(SeedService.loot_seed(restored) == SeedService.loot_seed(s), "loot_seed(restored) == loot_seed(%d)" % s)
		_check(SeedService.combat_seed(restored) == SeedService.combat_seed(s), "combat_seed(restored) == combat_seed(%d)" % s)
	SaveManager.delete_slot(TEST_SLOT)


func _suite_atomicity_and_backup() -> void:
	print("[сейв: атомарность и бэкап]")
	SaveManager.delete_slot(BACKUP_SLOT)

	GameState.reset()
	GameState.hub.materials = 11
	_check(SaveManager.save_to_slot(BACKUP_SLOT), "первая запись слота %d" % BACKUP_SLOT)
	GameState.hub.materials = 22
	_check(SaveManager.save_to_slot(BACKUP_SLOT), "вторая запись слота %d" % BACKUP_SLOT)
	_check(FileAccess.file_exists(SaveManager.backup_path(BACKUP_SLOT)), "бэкап создан при перезаписи")

	# Оборванная запись: .tmp остался, слот целый.
	var tmp := "%s/slot_%d.tmp" % [SaveManager.SAVE_DIR, BACKUP_SLOT]
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string("{ оборвано на середине")
	f.close()
	GameState.reset()
	var env := SaveManager.load_from_slot(BACKUP_SLOT)
	_check(env != null and env.hub_state.materials == 22, "мусорный .tmp не портит слот (materials == 22)")
	DirAccess.remove_absolute(tmp)

	# Битый основной файл: читается бэкап предыдущей записи (materials == 11).
	var broken := FileAccess.open(SaveManager.slot_path(BACKUP_SLOT), FileAccess.WRITE)
	broken.store_string("{ это не json")
	broken.close()
	GameState.reset()
	var from_backup := SaveManager.load_from_slot(BACKUP_SLOT)
	_check(from_backup != null, "битый слот прочитан из бэкапа")
	_check(from_backup != null and from_backup.hub_state.materials == 11, "из бэкапа приехало предыдущее состояние (materials == 11)")

	SaveManager.delete_slot(BACKUP_SLOT)


func _suite_backup_failure() -> void:
	print("[сейв: ошибка backup]")
	var slot := 0
	SaveManager.delete_slot(slot)
	GameState.reset()
	GameState.hub.materials = 31
	_check(SaveManager.save_to_slot(slot), "исходная запись для теста ошибки backup")

	# Каталог на месте .bak заставляет copy_absolute вернуть ошибку.
	var backup := SaveManager.backup_path(slot)
	DirAccess.make_dir_absolute(backup)
	GameState.hub.materials = 99
	_check(not SaveManager.save_to_slot(slot), "ошибка создания backup отклоняет запись")
	var restored := SaveManager.load_from_slot(slot)
	_check(restored != null and restored.hub_state.materials == 31, "основной слот не заменён после ошибки backup")
	DirAccess.remove_absolute(backup)
	SaveManager.delete_slot(slot)


func _suite_settings() -> void:
	print("[настройки: ConfigFile]")
	_check(SettingsStore.set_value("combat", "dash_iframes", 0.30), "запись настройки")
	_check(SettingsStore.set_value("debug", "panel_open", true), "запись булевой настройки")
	_check(is_equal_approx(float(SettingsStore.get_value("combat", "dash_iframes", 0.0)), 0.30), "float пережил ConfigFile")
	_check(bool(SettingsStore.get_value("debug", "panel_open", false)) == true, "bool пережил ConfigFile")
	_check(SettingsStore.get_value("нет", "такого", "по умолчанию") == "по умолчанию", "значение по умолчанию отдаётся")
	DirAccess.remove_absolute(SettingsStore.PATH)


func _suite_scene_flow() -> void:
	## Последняя сюита: клик по кнопке меню уже триггерит полный маршрут
	## game_started -> SceneRouter -> hub, и смена сцены освобождает этот узел.
	## Поэтому вердикт выносит «бессмертный» узел-пробка у корня, а результаты
	## прошлых сюит снимаем в локальные переменные ДО первого эмита.
	print("[сцена: меню -> хаб через EventBus]")
	var checks_total := _checks
	var failures_total: Array[String] = _failures.duplicate()

	# Кнопка меню эмитит game_started(0) (SPEC-01 §3: локальный start_pressed удалён).
	# Массив вместо int: лямбды захватывают внешние локальные по значению.
	var got: Array[int] = [-1]
	EventBus.game_started.connect(func(slot: int) -> void: got[0] = slot, CONNECT_ONE_SHOT)

	# Вердикт выносит пробка у корня: смена current_scene освобождает этот узел
	# вместе с его лямбдами, а методы пробки переживают смену сцены.
	var probe: Node = (load("res://tests/scene_flow_probe.gd") as GDScript).new()
	probe.name = "SceneFlowProbe"
	get_tree().root.add_child(probe)
	probe.call("setup", checks_total, failures_total, got)
	get_tree().scene_changed.connect(Callable(probe, "_on_scene_changed"))
	get_tree().process_frame.connect(Callable(probe, "_on_frame"))

	# Меню вешаем в root (не в current_scene): переживёт смену сцены.
	var menu: Control = load("res://scenes/main/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	menu.get_node("%StartButton").pressed.emit()
	# Дальше — вердикт пробки; этот узел будет освобождён в конце кадра.


func _finish_and_quit() -> void:
	print("")
	if _failures.is_empty():
		print("ЗЕЛЕНО: %d проверок пройдено" % _checks)
		get_tree().quit(0)
	else:
		print("КРАСНО: %d из %d проверок упало" % [_failures.size(), _checks])
		for failure: String in _failures:
			print("  - %s" % failure)
		get_tree().quit(1)


# --- Мелочи ---

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  ok   %s" % label)
	else:
		print("  FAIL %s" % label)
		_failures.append(label)
