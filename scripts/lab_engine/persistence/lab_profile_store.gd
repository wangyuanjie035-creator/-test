class_name LabProfileStore
extends RefCounted

const CURRENT_VERSION := 1
const DEFAULT_PATH := "user://lab_engine/profile.json"

func defaults() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"tutorial_seen": false,
		"runs_started": 0,
		"last_seed": 240731,
	}

func load_profile(path: String = DEFAULT_PATH) -> Dictionary:
	var primary: Dictionary = _read_profile(path)
	if bool(primary.get("ok", false)):
		return {"ok": true, "recovered": false, "disk_repaired": false, "data": primary.data, "error": OK}
	if bool(primary.get("unsupported", false)):
		return {"ok": false, "recovered": false, "disk_repaired": false, "unsupported": true, "data": defaults(), "error": ERR_UNAVAILABLE}
	var backup_path := _backup_path(path)
	var backup: Dictionary = _read_profile(backup_path)
	if bool(backup.get("unsupported", false)):
		return {"ok": false, "recovered": false, "disk_repaired": false, "unsupported": true, "data": defaults(), "error": ERR_UNAVAILABLE}
	if bool(backup.get("ok", false)):
		var recovery_error := _write_atomic(backup.data, path, false)
		return {
			"ok": true,
			"recovered": true,
			"disk_repaired": recovery_error == OK,
			"data": backup.data,
			"error": recovery_error,
		}
	return {
		"ok": false,
		"recovered": false,
		"disk_repaired": false,
		"data": defaults(),
		"error": int(primary.get("error", ERR_FILE_NOT_FOUND)),
	}

func save(data: Dictionary, path: String = DEFAULT_PATH) -> int:
	return _write_atomic(_normalize(data), path, true)

func delete_profile(path: String = DEFAULT_PATH) -> int:
	var first_error := OK
	for candidate: String in [path, _backup_path(path), _temp_path(path)]:
		var absolute := ProjectSettings.globalize_path(candidate)
		if not FileAccess.file_exists(candidate):
			continue
		var error := DirAccess.remove_absolute(absolute)
		if error != OK and first_error == OK:
			first_error = error
	return first_error

func get_save_slots(path: String = DEFAULT_PATH) -> Array[String]:
	var slots: Array[String] = []
	if FileAccess.file_exists(path):
		slots.append(path)
	return slots

func _read_profile(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": ERR_FILE_NOT_FOUND}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": FileAccess.get_open_error()}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": ERR_PARSE_ERROR}
	var migrated := _migrate(json.data as Dictionary)
	if not bool(migrated.get("ok", false)):
		return migrated
	return {"ok": true, "data": _normalize(migrated.data), "error": OK}

func _migrate(raw: Dictionary) -> Dictionary:
	var data := raw.duplicate(true)
	var version := int(data.get("version", 0))
	if version > CURRENT_VERSION:
		return {"ok": false, "unsupported": true, "error": ERR_UNAVAILABLE}
	if version < 0:
		return {"ok": false, "error": ERR_INVALID_DATA}
	while version < CURRENT_VERSION:
		match version:
			0:
				data = {
					"version": 1,
					"tutorial_seen": bool(data.get("help_seen", false)),
					"runs_started": int(data.get("launch_count", 0)),
					"last_seed": int(data.get("seed", 240731)),
				}
				version = 1
			_:
				return {"ok": false, "error": ERR_INVALID_DATA}
	return {"ok": true, "data": data, "error": OK}

func _normalize(raw: Dictionary) -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"tutorial_seen": bool(raw.get("tutorial_seen", false)),
		"runs_started": maxi(0, int(raw.get("runs_started", 0))),
		"last_seed": maxi(0, int(raw.get("last_seed", 240731))),
	}

func _write_atomic(data: Dictionary, path: String, rotate_backup: bool) -> int:
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory := absolute_path.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(directory)
	if directory_error != OK:
		return directory_error
	var temp_path := _temp_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(absolute_temp)
		return write_error
	var backup_path := _backup_path(path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if rotate_backup and FileAccess.file_exists(path):
		var existing: Dictionary = _read_profile(path)
		if bool(existing.get("unsupported", false)):
			DirAccess.remove_absolute(absolute_temp)
			return ERR_UNAVAILABLE
		if bool(existing.get("ok", false)):
			if FileAccess.file_exists(backup_path):
				var existing_backup: Dictionary = _read_profile(backup_path)
				if bool(existing_backup.get("unsupported", false)):
					DirAccess.remove_absolute(absolute_temp)
					return ERR_UNAVAILABLE
				var remove_backup_error := DirAccess.remove_absolute(absolute_backup)
				if remove_backup_error != OK:
					DirAccess.remove_absolute(absolute_temp)
					return remove_backup_error
			var rotate_error := DirAccess.rename_absolute(absolute_path, absolute_backup)
			if rotate_error != OK:
				DirAccess.remove_absolute(absolute_temp)
				return rotate_error
		else:
			var remove_invalid_error := DirAccess.remove_absolute(absolute_path)
			if remove_invalid_error != OK:
				DirAccess.remove_absolute(absolute_temp)
				return remove_invalid_error
	elif not rotate_backup and FileAccess.file_exists(path):
		var remove_primary_error := DirAccess.remove_absolute(absolute_path)
		if remove_primary_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return remove_primary_error
	var commit_error := DirAccess.rename_absolute(absolute_temp, absolute_path)
	if commit_error != OK and rotate_backup and FileAccess.file_exists(backup_path) and not FileAccess.file_exists(path):
		DirAccess.rename_absolute(absolute_backup, absolute_path)
	return commit_error

func _backup_path(path: String) -> String:
	return path + ".bak"

func _temp_path(path: String) -> String:
	return path + ".tmp"
