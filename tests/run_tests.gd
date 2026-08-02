extends Node
## Прогон проверок каркаса T-02. Запуск:
##   godot --headless --path . res://tests/run_tests.tscn
## Ненулевой код возврата = красный тест.
##
## Сцена, а не `--script`: только запуск сцены гарантирует, что автолоады
## подняты — а проверять надо именно их.
##
## Покрывает Definition of Done из SPEC-01 §8, кроме «все 4 точки сохранения»:
## эвакуация и смерть появятся в T-04, проверять там пока нечего.

const EXPECTED_AUTOLOADS: Array[String] = [
	"EventBus", "SeedService", "GameState", "SaveManager", "SceneRouter", "CombatLog"
]
const TEST_SLOT: int = 2
const BACKUP_SLOT: int = 1

## Дефолты из ANSWERS-v0.1.md §Q-14. Проверяются числом, а не «примерно»:
## T-03 обязан стартовать именно с них, иначе замеры T-06 не с чем сводить.
const Q14_DEFAULTS: Dictionary = {
	"scout_speed": 220.0,
	"scout_max_hp": 100.0,
	"dash_duration": 0.30,
	"dash_iframes": 0.30,
	"dash_cooldown": 0.55,
	"dash_distance": 200.0,
	"shot_cooldown": 0.35,
	"shot_damage": 10.0,
	"enemy_hp_base": 50.0,
	"enemy_speed": 140.0,
	"enemy_damage": 10.0,
	"telegraph_time": 0.45,
	"enemy_attack_cd": 1.20,
}

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame

	_suite_autoloads()
	_suite_seed_service()
	_suite_save_roundtrip()
	_suite_seed_boundaries()
	_suite_atomicity_and_backup()
	_suite_settings()
	_suite_combat_tuning()
	_suite_combat_stats()
	_suite_combat_log()
	await _suite_combat_scene()

	SaveManager.delete_slot(TEST_SLOT)
	SaveManager.delete_slot(BACKUP_SLOT)

	print("")
	if _failures.is_empty():
		print("ЗЕЛЁНО: %d проверок пройдено" % _checks)
		get_tree().quit(0)
	else:
		print("КРАСНО: %d из %d проверок упало" % [_failures.size(), _checks])
		for f: String in _failures:
			print("  - %s" % f)
		get_tree().quit(1)


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

	# Точка сохранения «в хабе»: run_state обязан лечь как null.
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


func _suite_settings() -> void:
	print("[настройки: ConfigFile]")
	_check(SettingsStore.set_value("combat", "dash_iframes", 0.30), "запись настройки")
	_check(SettingsStore.set_value("debug", "panel_open", true), "запись булевой настройки")
	_check(is_equal_approx(float(SettingsStore.get_value("combat", "dash_iframes", 0.0)), 0.30), "float пережил ConfigFile")
	_check(bool(SettingsStore.get_value("debug", "panel_open", false)) == true, "bool пережил ConfigFile")
	_check(SettingsStore.get_value("нет", "такого", "по умолчанию") == "по умолчанию", "значение по умолчанию отдаётся")
	DirAccess.remove_absolute(SettingsStore.PATH)


func _suite_combat_tuning() -> void:
	print("[бой: ползунки]")
	DirAccess.remove_absolute(SettingsStore.PATH)
	CombatTuning.reset_to_defaults()

	for key: String in Q14_DEFAULTS:
		_check(
			is_equal_approx(CombatTuning.f(key), float(Q14_DEFAULTS[key])),
			"дефолт %s == %s (Q-14), получено %s" % [key, Q14_DEFAULTS[key], CombatTuning.f(key)]
		)
	_check(CombatTuning.SPECS.size() == Q14_DEFAULTS.size(),
		"ползунков ровно столько, сколько дефолтов Q-14 (%d)" % CombatTuning.SPECS.size())

	# Q-03: i-frames покрывают дэш целиком. Разъехались — сломан замер, а не число.
	_check(is_equal_approx(CombatTuning.f("dash_iframes"), CombatTuning.f("dash_duration")),
		"i-frames == длительность дэша (Q-03)")

	var seen := {}
	for spec: Dictionary in CombatTuning.SPECS:
		var key := String(spec["key"])
		_check(not seen.has(key), "ключ %s не дублируется" % key)
		seen[key] = true
		var d := float(spec["default"])
		_check(d >= float(spec["min"]) and d <= float(spec["max"]),
			"дефолт %s внутри границ ползунка" % key)
		_check(String(spec["src"]) != "", "у %s указан вопрос-источник" % key)

	# Границы обязаны пускать значения, которыми Q-02 велит ставить эксперимент.
	var tele := CombatTuning.spec_of("telegraph_time")
	_check(float(tele["min"]) <= 0.15 and float(tele["max"]) >= 0.45,
		"телеграф крутится и на 0.15, и на 0.45 (эксперимент Q-02)")
	_check(float(CombatTuning.spec_of("dash_iframes")["min"]) <= 0.0,
		"i-frames крутятся в ноль (эксперимент Q-03)")

	# K(d) = 1.15^d (Q-11) и бюджет HP узла из Q-14: 6 × 50 × K(1) = 345.
	# Ровного числа тут не будет: 1.15 в double — 1.1499999…, и 50 × K(1) даёт
	# 57.4999…, то есть край округления. Проверяем бюджет, а не последний бит.
	_check(is_equal_approx(CombatTuning.k_depth(0), 1.0), "K(0) == 1.0")
	_check(is_equal_approx(CombatTuning.k_depth(1), 1.15), "K(1) == 1.15")
	var hp_d1 := CombatTuning.enemy_hp_at(1)
	_check(hp_d1 == 57 or hp_d1 == 58, "HP врага на d=1 == 57–58 (50 × 1.15 = 57.5), получено %d" % hp_d1)
	_check(absf(float(hp_d1 * 6) - 345.0) <= 3.0,
		"бюджет боевого узла на d=1 ≈ 345 HP (Q-14), получено %d" % (hp_d1 * 6))

	# Состояние панели переживает перезапуск .exe: пишем, роняем кэш, читаем.
	CombatTuning.set_value("telegraph_time", 0.15)
	CombatTuning.set_value("hit_stop", false)
	_check(CombatTuning.flush(), "панель сброшена на диск")
	CombatTuning._loaded = false
	CombatTuning._values = {}
	_check(is_equal_approx(CombatTuning.f("telegraph_time"), 0.15), "телеграф 0.15 пережил перезапуск")
	_check(CombatTuning.b("hit_stop") == false, "флажок hit-stop пережил перезапуск")
	_check(is_equal_approx(CombatTuning.f("dash_iframes"), 0.30), "нетронутый ползунок остался дефолтным")

	CombatTuning.reset_to_defaults()
	_check(is_equal_approx(CombatTuning.f("telegraph_time"), 0.45), "сброс вернул телеграф к 0.45")
	_check(CombatTuning.b("hit_stop") == true, "сброс вернул флажок hit-stop")
	CombatTuning.flush()
	DirAccess.remove_absolute(SettingsStore.PATH)


func _suite_combat_stats() -> void:
	print("[бой: счётчики]")
	var s := CombatStats.new()
	_check(is_equal_approx(s.hit_rate(), 0.0), "hit_rate пустого узла == 0, а не деление на ноль")
	_check(is_equal_approx(s.dodge_rate(), 0.0), "dodge_rate пустого узла == 0")

	s.shots_fired = 20
	s.shots_hit = 9
	_check(is_equal_approx(s.hit_rate(), 0.45), "hit_rate 9/20 == 0.45 (гипотеза Q-14)")

	s.enemy_attacks = 10
	s.attacks_dodged_iframes = 4
	s.attacks_evaded_range = 2
	s.attacks_hit = 4
	_check(is_equal_approx(s.dodge_rate(), 0.6), "dodge_rate считает i-frames и уход шагом вместе")

	var d := s.to_dict()
	_check(typeof(d["shots_fired"]) == TYPE_INT, "shots_fired это TYPE_INT (ADR-003)")
	_check(typeof(d["hit_rate"]) == TYPE_FLOAT, "hit_rate это TYPE_FLOAT")
	_check(d.has("attacks_dodged_iframes") and d.has("attacks_evaded_range"),
		"i-frames и уход шагом разведены в логе (замер Q-03)")


func _suite_combat_log() -> void:
	print("[бой: телеметрия]")
	CombatLog.clear()
	_check(CombatLog.read_all().is_empty(), "пустой лог читается как пустой массив")

	EventBus.combat_recorded.emit({"hit_rate": 0.45, "shots_fired": 20, "cleared": true})
	EventBus.combat_recorded.emit({"hit_rate": 0.5, "shots_fired": 10, "cleared": false})
	var rows := CombatLog.read_all()
	_check(rows.size() == 2, "две записи дописаны, а не перезаписаны (получено %d)" % rows.size())
	if rows.size() == 2:
		_check(is_equal_approx(float(rows[0]["hit_rate"]), 0.45), "первая запись цела после второй")
		_check(bool(rows[1]["cleared"]) == false, "смерть тоже попадает в лог")
	CombatLog.clear()
	_check(CombatLog.read_all().is_empty(), "лог очищается")


func _suite_combat_scene() -> void:
	print("[бой: сцена]")
	CombatTuning.reset_to_defaults()
	for path: String in [
		"res://scenes/combat/scout.tscn",
		"res://scenes/combat/enemy.tscn",
		"res://scenes/combat/projectile.tscn",
		"res://scenes/ui/tuning_panel.tscn",
		"res://scenes/combat/combat_arena.tscn",
	]:
		var packed: PackedScene = load(path)
		_check(packed != null and packed.can_instantiate(), "%s грузится и инстанцируется" % path)

	# Дым: арена поднимается целиком и разводит первую волну. Ловит ошибки
	# .tscn и preload, которых headless-импорт не видит.
	GameState.reset()
	GameState.begin_run(424242)
	var arena: Node2D = load("res://scenes/combat/combat_arena.tscn").instantiate()
	add_child(arena)
	await get_tree().process_frame
	await get_tree().physics_frame

	var scout: Scout = arena.get_node_or_null("Scout") as Scout
	_check(scout != null, "разведчик появился на арене")
	var enemies := 0
	for child: Node in arena.get_children():
		if child is Enemy:
			enemies += 1
	_check(enemies == 2, "первая волна — ровно 2 врага на арене (получено %d)" % enemies)
	if scout != null:
		_check(scout.hp == 100 and scout.max_hp == 100, "HP разведчика поднялось из ползунка")
		_check(scout.is_invulnerable() == false, "вне дэша разведчик уязвим")
	_check(arena.get_node_or_null("Walls") != null, "стены арены собраны")

	arena.queue_free()
	await get_tree().process_frame
	_check(is_equal_approx(Engine.time_scale, 1.0), "time_scale вернулся в 1.0 после сноса арены")
	CombatLog.clear()
	GameState.reset()


# --- Мелочи ---

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  ok   %s" % label)
	else:
		print("  FAIL %s" % label)
		_failures.append(label)
