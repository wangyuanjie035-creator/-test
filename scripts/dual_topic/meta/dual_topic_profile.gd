extends RefCounted
class_name DualTopicProfile

const SAVE_VERSION := 1
const SAVE_PATH := "user://dual_topic_profile.json"
const MAX_HISTORY := 8

var legacy_counts: Dictionary = {
	"mature_method": 0,
	"risk_insight": 0,
	"remediation_method": 0,
}
var recent_results: Array[Dictionary] = []
var last_legacy: Dictionary = {}


func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("无法读取研究档案：%s" % FileAccess.get_open_error())
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("研究档案格式无效，已使用空档案。")
		return
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("研究档案版本暂不支持，已使用空档案。")
		return
	var stored_counts: Dictionary = data.get("legacy_counts", {})
	for key: String in legacy_counts:
		legacy_counts[key] = maxi(0, int(stored_counts.get(key, 0)))
	for entry: Variant in data.get("recent_results", []):
		if entry is Dictionary:
			recent_results.append(entry)
	var stored_legacy: Variant = data.get("last_legacy", {})
	if stored_legacy is Dictionary:
		last_legacy = stored_legacy
	if recent_results.size() > MAX_HISTORY:
		recent_results = recent_results.slice(-MAX_HISTORY)


func record_result(result: Dictionary, topic_name: String) -> Error:
	var legacy: Dictionary = result.get("legacy", {})
	var legacy_type: String = String(legacy.get("type", ""))
	if legacy_counts.has(legacy_type):
		legacy_counts[legacy_type] = int(legacy_counts[legacy_type]) + 1
	last_legacy = {
		"type": legacy_type,
		"method_id": String(legacy.get("method_id", "")),
		"risk_id": String(legacy.get("risk_id", "")),
		"category": String(legacy.get("category", "")),
	}
	recent_results.append({
		"topic": topic_name,
		"grade": String(result.get("grade", "failed")),
		"legacy_type": legacy_type,
	})
	if recent_results.size() > MAX_HISTORY:
		recent_results.pop_front()
	return _save()


func get_summary() -> String:
	var total: int = 0
	for count: int in legacy_counts.values():
		total += count
	if total == 0:
		return "研究档案 · 尚无跨局成果"
	return "研究档案 · 成熟方法 %d  风险认知 %d  补救方法 %d" % [
		legacy_counts["mature_method"],
		legacy_counts["risk_insight"],
		legacy_counts["remediation_method"],
	]


func get_active_legacy() -> Dictionary:
	return last_legacy.duplicate(true)


func _save() -> Error:
	var absolute_directory := ProjectSettings.globalize_path("user://")
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		push_error("无法创建研究档案目录：%s" % directory_error)
		return directory_error
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var open_error := FileAccess.get_open_error()
		push_error("无法保存研究档案：%s" % open_error)
		return open_error
	var data := {
		"version": SAVE_VERSION,
		"legacy_counts": legacy_counts,
		"recent_results": recent_results,
		"last_legacy": last_legacy,
	}
	file.store_string(JSON.stringify(data, "\t"))
	return OK
