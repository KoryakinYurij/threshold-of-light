class_name RunState extends RefCounted
## Состояние текущего забега (SPEC-01 §4). Всё, что в `pending_*`, — под риском
## (ADR-002): переносится в HubState только при эвакуации/победе над стражем,
## при смерти нестабильная добыча обнуляется.
## В сейв едет `master_seed` + `current_node_index`; под-сиды не хранятся (ADR-004).

var master_seed: int = 0
var current_node_index: int = 0
var visited_nodes: PackedInt32Array = PackedInt32Array()
var pending_materials: int = 0  # не забанковано
var pending_unstable_loot: int = 0  # теряется при смерти (ADR-002)
var pending_memories: int = 0
var scout_hp: int = 0
