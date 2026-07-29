extends Node
class_name VisionRunState

const DEFAULT_SEED := 240731
const VALID_INCLINATION_IDS := [&"literature", &"experiment", &"sprint"]

var run_seed: int = DEFAULT_SEED
var inclination_id: StringName = &""
var legacy_id: StringName = &""
var has_active_run: bool = false


func begin_run(selected_inclination_id: StringName, selected_seed: int) -> bool:
	if not VALID_INCLINATION_IDS.has(selected_inclination_id):
		push_error("VisionRunState: unknown inclination '%s'." % selected_inclination_id)
		return false
	inclination_id = selected_inclination_id
	run_seed = max(1, selected_seed)
	has_active_run = true
	return true


func clear_run() -> void:
	run_seed = DEFAULT_SEED
	inclination_id = &""
	has_active_run = false


func get_debug_snapshot() -> Dictionary:
	return {
		"run_seed": run_seed,
		"inclination_id": String(inclination_id),
		"legacy_id": String(legacy_id),
		"has_active_run": has_active_run,
	}
