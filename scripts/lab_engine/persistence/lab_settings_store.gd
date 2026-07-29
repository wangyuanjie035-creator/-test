class_name LabSettingsStore
extends RefCounted

const CURRENT_VERSION := 1
const DEFAULT_PATH := "user://lab_engine/settings.cfg"

func defaults() -> Dictionary:
	return {"version": CURRENT_VERSION, "master_volume": 0.8, "window_mode": "windowed"}

func load_settings(path: String = DEFAULT_PATH) -> Dictionary:
	var primary := _read_settings(path)
	if bool(primary.get("ok", false)):
		return {"ok": true, "recovered": false, "disk_repaired": false, "data": primary.data, "error": OK}
	if bool(primary.get("unsupported", false)):
		return {"ok": false, "unsupported": true, "recovered": false, "disk_repaired": false, "data": defaults(), "error": ERR_UNAVAILABLE}
	var backup := _read_settings(_backup_path(path))
	if bool(backup.get("unsupported", false)):
		return {"ok": false, "unsupported": true, "recovered": false, "disk_repaired": false, "data": defaults(), "error": ERR_UNAVAILABLE}
	if bool(backup.get("ok", false)):
		var repair_error := _write_atomic(backup.data, path, false)
		return {"ok": true, "recovered": true, "disk_repaired": repair_error == OK, "data": backup.data, "error": repair_error}
	return {"ok": false, "recovered": false, "disk_repaired": false, "data": defaults(), "error": int(primary.get("error", ERR_FILE_NOT_FOUND))}

func save(data: Dictionary, path: String = DEFAULT_PATH) -> int:
	return _write_atomic(_normalize(data), path, true)

func delete_settings(path: String = DEFAULT_PATH) -> int:
	var first_error := OK
	for candidate: String in [path, _backup_path(path), _temp_path(path)]:
		if not FileAccess.file_exists(candidate):
			continue
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
		if error != OK and first_error == OK:
			first_error = error
	return first_error

func _read_settings(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": ERR_FILE_NOT_FOUND}
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK:
		return {"ok": false, "error": load_error}
	var raw := {
		"version": config.get_value("meta", "version", 0),
		"master_volume": config.get_value("audio", "master_volume", config.get_value("audio", "volume", 0.8)),
		"window_mode": config.get_value("display", "window_mode", "fullscreen" if bool(config.get_value("display", "fullscreen", false)) else "windowed"),
	}
	var migrated := _migrate(raw)
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
				data.version = 1
				version = 1
			_:
				return {"ok": false, "error": ERR_INVALID_DATA}
	return {"ok": true, "data": data, "error": OK}

func _normalize(raw: Dictionary) -> Dictionary:
	var mode := String(raw.get("window_mode", "windowed"))
	if mode not in ["windowed", "fullscreen"]:
		mode = "windowed"
	return {
		"version": CURRENT_VERSION,
		"master_volume": clampf(float(raw.get("master_volume", 0.8)), 0.0, 1.0),
		"window_mode": mode,
	}

func _write_atomic(data: Dictionary, path: String, rotate_backup: bool) -> int:
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK:
		return directory_error
	var config := ConfigFile.new()
	config.set_value("meta", "version", int(data.version))
	config.set_value("audio", "master_volume", float(data.master_volume))
	config.set_value("display", "window_mode", String(data.window_mode))
	var temp_path := _temp_path(path)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(config.encode_to_text())
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return write_error
	var backup_path := _backup_path(path)
	if rotate_backup and FileAccess.file_exists(path):
		var existing := _read_settings(path)
		if bool(existing.get("unsupported", false)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
			return ERR_UNAVAILABLE
		if bool(existing.get("ok", false)):
			if FileAccess.file_exists(backup_path):
				var backup := _read_settings(backup_path)
				if bool(backup.get("unsupported", false)):
					DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
					return ERR_UNAVAILABLE
				var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
				if remove_error != OK:
					DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
					return remove_error
			var rotate_error := DirAccess.rename_absolute(absolute_path, ProjectSettings.globalize_path(backup_path))
			if rotate_error != OK:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
				return rotate_error
		else:
			var remove_invalid_error := DirAccess.remove_absolute(absolute_path)
			if remove_invalid_error != OK:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
				return remove_invalid_error
	elif not rotate_backup and FileAccess.file_exists(path):
		var remove_primary_error := DirAccess.remove_absolute(absolute_path)
		if remove_primary_error != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
			return remove_primary_error
	var commit_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), absolute_path)
	if commit_error != OK and rotate_backup and FileAccess.file_exists(backup_path) and not FileAccess.file_exists(path):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), absolute_path)
	return commit_error

func _backup_path(path: String) -> String:
	return path + ".bak"

func _temp_path(path: String) -> String:
	return path + ".tmp"
