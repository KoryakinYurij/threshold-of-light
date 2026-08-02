extends Node
## Пробка смены сцены для теста каркаса (T-02). Живёт у корня и переживает
## смену current_scene: обычные лямбды, созданные в тестовой сцене, умирают
## вместе с ней (замыкание привязано к объекту-создателю), а методы этого
## узла — нет. Головной тест кладёт сюда снимок результатов и ждёт вердикт.

var checks_total: int = 0
var failures: Array[String] = []
var got: Array[int] = [-1]
var _frames: int = 0
var _done: bool = false


func setup(p_checks: int, p_failures: Array[String], p_got: Array[int]) -> void:
	checks_total = p_checks
	failures = p_failures
	got = p_got


## Вердикт, когда хаб поднялся. scene_changed в 4.7 эмитится без аргументов —
## текущую сцену читаем сами.
func _on_scene_changed() -> void:
	if _done:
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.scene_file_path.ends_with("hub_screen.tscn"):
		return  # ждём именно перехода в хаб
	_done = true
	var menu_ok: bool = got[0] == 0
	print("  %s StartButton эмитит game_started(0), получено %d" % ["ok  " if menu_ok else "FAIL", got[0]])
	print("  ok   SceneRouter перевёл в хаб-заглушку")
	print("")
	if not menu_ok:
		failures.append("StartButton не эмитит game_started(0)")
	if failures.is_empty():
		print("ЗЕЛЕНО: %d проверок пройдено" % checks_total)
		get_tree().quit(0)
	else:
		print("КРАСНО: %d из %d проверок упало" % [failures.size(), checks_total])
		for f: String in failures:
			print("  - %s" % f)
		get_tree().quit(1)


## Страховка от вечного кручения headless-процесса: если за ~300 кадров
## хаб не поднялся — красный и выход.
func _on_frame() -> void:
	if _done:
		return
	_frames += 1
	if _frames > 300:
		var scene := get_tree().current_scene
		print("FAIL: сцена не переключилась в хаб (текущая: %s)" % ("" if scene == null else scene.scene_file_path))
		get_tree().quit(1)
