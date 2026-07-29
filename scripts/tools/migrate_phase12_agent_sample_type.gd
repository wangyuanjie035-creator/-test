extends SceneTree

const SESSION_DIRECTORY := "res://docs/playtests/phase12/sessions"

func _init() -> void:
	var migrated: int = 0
	for index: int in range(1, 9):
		var test_id := "P12-AGENT-%03d" % index
		var path := "%s/%s.jsonl" % [SESSION_DIRECTORY, test_id]
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("PHASE12_AGENT_MIGRATION: missing %s" % path)
			quit(1)
			return
		var original: String = file.get_as_text().strip_edges()
		file.close()
		var parsed: Variant = JSON.parse_string(original)
		if not parsed is Dictionary or String(parsed.get("test_id", "")) != test_id:
			push_error("PHASE12_AGENT_MIGRATION: invalid %s" % path)
			quit(1)
			return
		if String(parsed.get("sample_type", "")) != "external_first_exposure":
			push_error("PHASE12_AGENT_MIGRATION: unexpected source classification in %s" % path)
			quit(1)
			return
		parsed["sample_type"] = "agent_pilot"
		parsed["classification_migration"] = {
			"date": "2026-07-23",
			"reason": "Agent pilot records must be excluded from external first-exposure statistics.",
			"source_sample_type": "external_first_exposure",
		}
		var temporary_path := path + ".migration.tmp"
		var temporary: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
		if temporary == null:
			push_error("PHASE12_AGENT_MIGRATION: cannot write %s" % temporary_path)
			quit(1)
			return
		temporary.store_line(JSON.stringify(parsed))
		temporary.flush()
		var write_error: int = temporary.get_error()
		temporary.close()
		if write_error != OK:
			push_error("PHASE12_AGENT_MIGRATION: write failed %s" % error_string(write_error))
			quit(1)
			return
		var verify_file: FileAccess = FileAccess.open(temporary_path, FileAccess.READ)
		var verified: Variant = JSON.parse_string(verify_file.get_as_text()) if verify_file != null else null
		if verify_file != null:
			verify_file.close()
		if not verified is Dictionary or String(verified.get("sample_type", "")) != "agent_pilot":
			push_error("PHASE12_AGENT_MIGRATION: verification failed %s" % path)
			quit(1)
			return
		var absolute_path := ProjectSettings.globalize_path(path)
		var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
		var replace_error: int = DirAccess.remove_absolute(absolute_path)
		if replace_error != OK:
			push_error("PHASE12_AGENT_MIGRATION: remove failed %s" % error_string(replace_error))
			quit(1)
			return
		replace_error = DirAccess.rename_absolute(absolute_temporary, absolute_path)
		if replace_error != OK:
			push_error("PHASE12_AGENT_MIGRATION: replace failed %s" % error_string(replace_error))
			quit(1)
			return
		migrated += 1
	print("PHASE12_AGENT_MIGRATION: PASS migrated=%d" % migrated)
	quit(0)
