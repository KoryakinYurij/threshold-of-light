class_name SaveEnvelope extends RefCounted
## Конверт сейва v1 (SPEC-01 §6). Типизированный: после чтения из JSON
## наружу выходит он, а не сырой Dictionary.

const VERSION: int = 1

var save_version: int = VERSION
var profile: ProfileState = null
var hub_state: HubState = null
var run_state: RunState = null  # null, когда игрок в хабе
