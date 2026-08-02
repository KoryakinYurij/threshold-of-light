class_name ProfileState extends RefCounted
## Профиль игрока (SPEC-01 §4): переживает всё, включая смерть разведчика.

var unlocked_modules: PackedStringArray = PackedStringArray(["forge_of_form"])
var memories: int = 0
var runs_completed: int = 0
var runs_died: int = 0
