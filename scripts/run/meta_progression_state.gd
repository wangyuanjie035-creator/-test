@tool
extends RefCounted
class_name MetaProgressionState

const SAVE_PATH := "user://meta_progression_v1.json"
const SAVE_VERSION := 1
const RESOURCE_IDS := [
	"experience_lessons",
	"methodology_notes",
	"psychological_resilience",
	"paper_fragments",
	"black_history_archive",
]
const UNLOCK_SELF_CARE_SEED := &"self_care_seed"
const UNLOCK_REVISION_STRATEGY_SEED := &"revision_strategy_seed"
const UNLOCK_REVISION_MATRIX_SEED := &"revision_matrix_seed"

var version: int = SAVE_VERSION
var runs_completed: int = 0
var resources: Dictionary = {}
var unlocks: Array[StringName] = []
var last_outcome_id: String = ""
var last_error: String = ""


func _init() -> void:
	reset()


func reset() -> void:
	version = SAVE_VERSION
	runs_completed = 0
	resources.clear()
	unlocks.clear()
	last_outcome_id = ""
	last_error = ""
	for resource_id: String in RESOURCE_IDS:
		resources[resource_id] = 0


func load_from_disk(path: String = SAVE_PATH) -> bool:
	reset()
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "open_failed:%d" % FileAccess.get_open_error()
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "invalid_json"
		return false

	_load_from_dict(parsed)
	return true


func save_to_disk(path: String = SAVE_PATH) -> int:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error := FileAccess.get_open_error()
		last_error = "open_failed:%d" % open_error
		return open_error

	file.store_string(JSON.stringify(to_dict(), "\t"))
	last_error = ""
	return OK


func clear_save(path: String = SAVE_PATH, allow_default_path: bool = false) -> Dictionary:
	if path == SAVE_PATH and not allow_default_path:
		last_error = "refuse_default_path"
		return {
			"clear_error": ERR_UNAUTHORIZED,
			"existed": FileAccess.file_exists(path),
			"cleared": false,
			"summary_text": "正式局外存档未清空。清空按钮只用于测试路径。",
		}

	var existed := FileAccess.file_exists(path)
	var clear_error := OK
	if existed:
		clear_error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	if clear_error == OK:
		reset()
		last_error = ""
	else:
		last_error = "remove_failed:%d" % clear_error

	return {
		"clear_error": clear_error,
		"existed": existed,
		"cleared": clear_error == OK,
		"summary_text": "测试局外存档已清空。" if clear_error == OK else "测试局外存档清空失败：%s。" % error_string(clear_error),
	}


func apply_settlement(settlement: Dictionary, path: String = SAVE_PATH) -> Dictionary:
	var loaded_existing := load_from_disk(path)
	var settlement_resources: Dictionary = settlement.get("resources", {})
	var applied_resources: Dictionary = {}

	for resource_id: String in RESOURCE_IDS:
		var amount := int(settlement_resources.get(resource_id, 0))
		if amount <= 0:
			continue
		resources[resource_id] = int(resources.get(resource_id, 0)) + amount
		applied_resources[resource_id] = amount

	runs_completed += 1
	last_outcome_id = String(settlement.get("outcome_id", ""))
	var new_unlocks := _refresh_unlocks()
	var save_error := save_to_disk(path)
	return {
		"loaded_existing": loaded_existing,
		"save_error": save_error,
		"runs_completed": runs_completed,
		"last_outcome_id": last_outcome_id,
		"applied_resources": applied_resources,
		"resources": resources.duplicate(true),
		"new_unlocks": _stringify_ids(new_unlocks),
		"unlocks": to_unlock_strings(),
		"summary_text": _format_progression_summary(new_unlocks),
	}


func get_resource(resource_id: String) -> int:
	return int(resources.get(resource_id, 0))


func has_unlock(unlock_id: StringName) -> bool:
	return unlocks.has(unlock_id)


func get_unlock_display_names() -> Array[String]:
	var names: Array[String] = []
	for unlock_id: StringName in unlocks:
		names.append(get_unlock_display_name(unlock_id))
	return names


static func get_unlock_display_name(unlock_id: StringName) -> String:
	match unlock_id:
		UNLOCK_SELF_CARE_SEED:
			return "自我照护种子"
		UNLOCK_REVISION_STRATEGY_SEED:
			return "返修策略种子"
		UNLOCK_REVISION_MATRIX_SEED:
			return "返修矩阵种子"
		_:
			return String(unlock_id)


func to_unlock_strings() -> Array[String]:
	return _stringify_ids(unlocks)


func to_dict() -> Dictionary:
	return {
		"version": version,
		"runs_completed": runs_completed,
		"resources": resources.duplicate(true),
		"unlocks": to_unlock_strings(),
		"last_outcome_id": last_outcome_id,
	}


func to_debug_dict() -> Dictionary:
	var data := to_dict()
	data["last_error"] = last_error
	return data


func _load_from_dict(data: Dictionary) -> void:
	version = int(data.get("version", SAVE_VERSION))
	runs_completed = int(data.get("runs_completed", 0))
	last_outcome_id = String(data.get("last_outcome_id", ""))

	var raw_resources: Dictionary = data.get("resources", {})
	for resource_id: String in RESOURCE_IDS:
		resources[resource_id] = int(raw_resources.get(resource_id, 0))

	unlocks.clear()
	var raw_unlocks: Array = data.get("unlocks", [])
	for raw_unlock: Variant in raw_unlocks:
		var unlock_id := StringName(raw_unlock)
		if not unlocks.has(unlock_id):
			unlocks.append(unlock_id)


func _refresh_unlocks() -> Array[StringName]:
	var new_unlocks: Array[StringName] = []
	if get_resource("experience_lessons") >= 10 and not unlocks.has(UNLOCK_SELF_CARE_SEED):
		unlocks.append(UNLOCK_SELF_CARE_SEED)
		new_unlocks.append(UNLOCK_SELF_CARE_SEED)
	if get_resource("paper_fragments") >= 1 and not unlocks.has(UNLOCK_REVISION_STRATEGY_SEED):
		unlocks.append(UNLOCK_REVISION_STRATEGY_SEED)
		new_unlocks.append(UNLOCK_REVISION_STRATEGY_SEED)
	if last_outcome_id == "supplementary_defense_failed" and not unlocks.has(UNLOCK_REVISION_MATRIX_SEED):
		unlocks.append(UNLOCK_REVISION_MATRIX_SEED)
		new_unlocks.append(UNLOCK_REVISION_MATRIX_SEED)
	return new_unlocks


func _format_progression_summary(new_unlocks: Array[StringName]) -> String:
	var lines: Array[String] = []
	lines.append("累计局外资源：经验教训 %d，方法论笔记 %d，心理韧性 %d，论文碎片 %d，黑历史档案 %d。" % [
		get_resource("experience_lessons"),
		get_resource("methodology_notes"),
		get_resource("psychological_resilience"),
		get_resource("paper_fragments"),
		get_resource("black_history_archive"),
	])
	lines.append("累计结算次数：%d。" % runs_completed)
	if not new_unlocks.is_empty():
		var unlock_names: Array[String] = []
		for unlock_id: StringName in new_unlocks:
			unlock_names.append(get_unlock_display_name(unlock_id))
		lines.append("新解锁：%s。" % "、".join(unlock_names))
	return "\n".join(lines)


func _stringify_ids(ids: Array) -> Array[String]:
	var output: Array[String] = []
	for id: Variant in ids:
		output.append(String(id))
	return output
