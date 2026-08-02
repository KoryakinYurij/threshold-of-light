class_name SaveSchema extends RefCounted
## DTO-слой (ADR-003, SPEC-01 §7). Правило без исключений: после разбора JSON
## ни одно число не используется напрямую — каждое проходит через int()/float().
##
## Касты живут здесь и только здесь. Забыть их нельзя: присваивание float
## в статически типизированное int-поле не скомпилируется.

# --- Запись ---

static func envelope_to_dict(env: SaveEnvelope) -> Dictionary:
	var d: Dictionary = {
		"save_version": env.save_version,
		"profile": profile_to_dict(env.profile),
		"hub_state": hub_state_to_dict(env.hub_state),
		"run_state": null,
	}
	if env.run_state != null:
		d["run_state"] = run_state_to_dict(env.run_state)
	return d


static func profile_to_dict(s: ProfileState) -> Dictionary:
	return {
		"unlocked_modules": Array(s.unlocked_modules),
		"memories": s.memories,
		"runs_completed": s.runs_completed,
		"runs_died": s.runs_died,
	}


static func hub_state_to_dict(s: HubState) -> Dictionary:
	return {
		"materials": s.materials,
		"unstable_loot": s.unstable_loot,
		"modules": s.modules.duplicate(),
	}


static func run_state_to_dict(s: RunState) -> Dictionary:
	return {
		"master_seed": s.master_seed,
		"current_node_index": s.current_node_index,
		"visited_nodes": Array(s.visited_nodes),
		"pending_materials": s.pending_materials,
		"pending_unstable_loot": s.pending_unstable_loot,
		"pending_memories": s.pending_memories,
		"scout_hp": s.scout_hp,
	}


# --- Чтение ---

static func envelope_from_dict(d: Dictionary) -> SaveEnvelope:
	var env := SaveEnvelope.new()
	env.save_version = int(d.get("save_version", 0))
	env.profile = profile_from_dict(_dict_at(d, "profile"))
	env.hub_state = hub_state_from_dict(_dict_at(d, "hub_state"))
	var raw_run: Variant = d.get("run_state", null)
	if raw_run is Dictionary:
		env.run_state = run_state_from_dict(raw_run)
	else:
		env.run_state = null
	return env


static func profile_from_dict(d: Dictionary) -> ProfileState:
	var s := ProfileState.new()
	var modules := PackedStringArray()
	for m: Variant in _array_at(d, "unlocked_modules"):
		modules.append(String(m))
	s.unlocked_modules = modules
	s.memories = int(d.get("memories", 0))
	s.runs_completed = int(d.get("runs_completed", 0))
	s.runs_died = int(d.get("runs_died", 0))
	return s


static func hub_state_from_dict(d: Dictionary) -> HubState:
	var s := HubState.new()
	s.materials = int(d.get("materials", 0))
	s.unstable_loot = int(d.get("unstable_loot", 0))
	var raw_modules: Dictionary = _dict_at(d, "modules")
	for id: Variant in raw_modules:
		# без int() уровень модуля приедет из JSON как float
		s.modules[String(id)] = int(raw_modules[id])
	return s


static func run_state_from_dict(d: Dictionary) -> RunState:
	var s := RunState.new()
	s.master_seed = int(d.get("master_seed", 0))
	s.current_node_index = int(d.get("current_node_index", 0))
	var visited := PackedInt32Array()
	for n: Variant in _array_at(d, "visited_nodes"):
		visited.append(int(n))
	s.visited_nodes = visited
	s.pending_materials = int(d.get("pending_materials", 0))
	s.pending_unstable_loot = int(d.get("pending_unstable_loot", 0))
	s.pending_memories = int(d.get("pending_memories", 0))
	s.scout_hp = int(d.get("scout_hp", 0))
	return s


# --- Мелочи ---

static func _dict_at(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key, null)
	return v if v is Dictionary else {}


static func _array_at(d: Dictionary, key: String) -> Array:
	var v: Variant = d.get(key, null)
	return v if v is Array else []
