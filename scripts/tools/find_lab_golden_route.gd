extends SceneTree

const SEARCH_SCRIPT := preload("res://scripts/lab_engine/tools/lab_route_search.gd")

func _init() -> void:
	var result: Dictionary = SEARCH_SCRIPT.new().search(240731)
	var serializable: Dictionary = {
		"found": bool(result.found),
		"schedule": result.schedule,
	}
	if bool(result.found):
		serializable.path = result.path
		serializable.state = result.state
	elif not result.best.is_empty():
		serializable.best_path = result.best.path
		serializable.best_state = result.best.state.snapshot()
	var file: FileAccess = FileAccess.open("res://.temp/lab_route_search.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(serializable, "\t"))
	file.close()
	quit(0)
