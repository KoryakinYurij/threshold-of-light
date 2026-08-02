class_name HubState extends RefCounted
## Забанкованное состояние хаба (SPEC-01 §4). Добыча переносится сюда только
## при успешной эвакуации или победе над стражем (ADR-002), нигде больше.

var materials: int = 0
var unstable_loot: int = 0
var modules: Dictionary = {}  # module_id: String -> level: int
