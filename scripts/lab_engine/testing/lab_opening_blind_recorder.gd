class_name LabOpeningBlindRecorder
extends Node

## Phase 12 first-choice telemetry.
##
## This node is inert during normal play.  It only arms when all required
## `--blind-*` user arguments are present, so the playtest instrumentation can
## remain attached to the scene without changing the shipping interaction path.

const RECORD_SCHEMA_VERSION := 1
const REQUIRED_CANDIDATE_COUNT := 3
const PREREGISTRATION_PATH := "res://docs/playtests/phase12/preregistered_seeds.json"

var active: bool = false

var _test_id: String = ""
var _participant_id: String = ""
var _sample_type: String = ""
var _record_path: String = ""
var _expected_seed: int = -1
var _interface_ready_ticks: int = 0
var _interface_ready_unix_ms: int = 0
var _first_confirm_ticks: int = 0
var _first_confirm_unix_ms: int = 0
var _first_selected_index: int = -1
var _first_selected_id: StringName = &""
var _first_choice_kind: StringName = &""
var _candidate_ids: Array[String] = []
var _record_written: bool = false
var _preregistered_row: Dictionary = {}
var _workbench: Node
var _candidate_panel: Node
var _sidebar: Node

func _ready() -> void:
	var config: Dictionary = parse_configuration(OS.get_cmdline_user_args())
	if not bool(config.get("requested", false)):
		return
	if not bool(config.get("valid", false)):
		_fail_closed("invalid configuration: %s" % String(config.get("error", "unknown")))
		return
	arm_with_configuration(config)

func arm_with_configuration(config: Dictionary) -> bool:
	if active:
		return false
	_test_id = String(config.test_id)
	_participant_id = String(config.participant_id)
	_sample_type = String(config.sample_type)
	_record_path = String(config.record_path)
	_expected_seed = int(config.expected_seed)
	var preregistration: Dictionary = _find_preregistered_row(_expected_seed)
	if not bool(preregistration.get("valid", false)):
		_fail_closed(String(preregistration.get("error", "Seed is not preregistered")))
		return false
	_preregistered_row = preregistration.row
	call_deferred("_arm")
	return true

func _arm() -> void:
	_workbench = get_parent()
	if _workbench == null:
		_fail_closed("requires a LabWorkbench parent")
		return
	if int(_workbench.get("_controller").seed) != _expected_seed:
		_workbench.call("_start_new_run", _expected_seed)
	_candidate_panel = _workbench.find_child("CandidateBox", true, false)
	_sidebar = _workbench.find_child("Sidebar", true, false)
	if _candidate_panel == null or _sidebar == null:
		_fail_closed("could not find CandidateBox or Sidebar")
		return
	if not _candidate_panel.candidate_selected.is_connected(_on_candidate_selected):
		_candidate_panel.candidate_selected.connect(_on_candidate_selected)
	if not _sidebar.run_requested.is_connected(_on_run_requested):
		_sidebar.run_requested.connect(_on_run_requested, CONNECT_DEFERRED)
	if not _sidebar.skip_requested.is_connected(_on_maintenance_selected):
		_sidebar.skip_requested.connect(_on_maintenance_selected)
	active = true
	await _wait_for_unobstructed_choice_screen()

func _wait_for_unobstructed_choice_screen() -> void:
	while active and is_inside_tree():
		if _choice_screen_is_ready():
			var controller: RefCounted = _workbench.get("_controller")
			var ids: Array[StringName] = controller.candidates_for_today()
			_candidate_ids.clear()
			for id: StringName in ids:
				_candidate_ids.append(String(id))
			var mismatch: String = _preregistration_mismatch(controller, _candidate_ids)
			if not mismatch.is_empty():
				_fail_closed(mismatch)
				return
			_interface_ready_ticks = Time.get_ticks_msec()
			_interface_ready_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
			return
		await get_tree().process_frame

func _choice_screen_is_ready() -> bool:
	if _workbench == null or _candidate_panel == null:
		return false
	var controller: RefCounted = _workbench.get("_controller")
	if controller == null or int(controller.seed) != _expected_seed or int(controller.state.day) != 1:
		return false
	var help_overlay := _workbench.find_child("HelpOverlay", true, false) as Control
	var settings_overlay := _workbench.find_child("SettingsOverlay", true, false) as Control
	if (help_overlay != null and help_overlay.visible) or (settings_overlay != null and settings_overlay.visible):
		return false
	if _candidate_panel.get_child_count() != REQUIRED_CANDIDATE_COUNT:
		return false
	for child: Node in _candidate_panel.get_children():
		var button := child as Button
		if button == null or not button.visible or button.disabled:
			return false
	return true

func _on_candidate_selected(index: int) -> void:
	if not active or _record_written or _interface_ready_ticks <= 0 or _first_confirm_ticks > 0:
		return
	if index < 0 or index >= _candidate_ids.size():
		return
	_first_confirm_ticks = Time.get_ticks_msec()
	_first_confirm_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
	_first_selected_index = index
	_first_selected_id = StringName(_candidate_ids[index])
	_first_choice_kind = &"candidate"

func _on_maintenance_selected() -> void:
	if not active or _record_written or _interface_ready_ticks <= 0 or _first_confirm_ticks > 0:
		return
	_first_confirm_ticks = Time.get_ticks_msec()
	_first_confirm_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
	_first_selected_index = -1
	_first_selected_id = &""
	_first_choice_kind = &"maintenance"

func _on_run_requested() -> void:
	if not active or _record_written:
		return
	call_deferred("_capture_day_one")

func _capture_day_one() -> void:
	var controller: RefCounted = _workbench.get("_controller")
	if controller == null or controller.history.is_empty():
		_fail_closed("submission did not produce a resolved day")
		return
	var result: Dictionary = controller.history.back()
	if int(result.get("day", -1)) != 1:
		_fail_closed("submission resolved a non-Day-1 result")
		return
	var mismatch: String = _preregistration_mismatch(controller, _candidate_ids)
	if not mismatch.is_empty():
		_fail_closed(mismatch)
		return
	if _first_confirm_ticks <= 0 or _first_choice_kind == &"":
		_fail_closed("Day 1 submission is missing the automatic first-confirm timestamp")
		return
	if _first_choice_kind == &"candidate" and (
			_first_selected_index < 0
			or _first_selected_index >= _candidate_ids.size()
			or String(_first_selected_id) != _candidate_ids[_first_selected_index]
	):
		_fail_closed("first candidate confirmation does not match the frozen candidate set")
		return
	var submitted_index: int = int(result.get("choice_index", -2))
	var submitted_id: StringName = StringName(result.get("selected_id", &""))
	var record: Dictionary = {
		"schema_version": RECORD_SCHEMA_VERSION,
		"test_id": _test_id,
		"sample_type": _sample_type,
		"participant_id": _participant_id,
		"seed": int(controller.seed),
		"topic_id": String(controller.topic_snapshot().get("topic_id", "")),
		"candidate_ids": _candidate_ids.duplicate(),
		"timing": {
			"interface_ready_unix_ms": _interface_ready_unix_ms,
			"first_confirm_unix_ms": _first_confirm_unix_ms,
			"decision_ms": maxi(0, _first_confirm_ticks - _interface_ready_ticks),
			"source": "automatic",
		},
		"unprompted": {
			"chosen_card_id": String(_first_selected_id),
			"chosen_index": _first_selected_index,
			"choice_kind": String(_first_choice_kind),
			"player_words": "",
			"spontaneous_comparison": "",
			"acceptable_alternative": "",
			"confidence_1_to_5": 0,
		},
		"submission": {
			"chosen_card_id": String(submitted_id),
			"chosen_index": submitted_index,
			"overclock_slot": int(result.get("overclock_slot", -1)),
		},
		"actual_day_one_result": _json_safe(result),
		"post_choice_state": _state_snapshot(controller.state),
		"neutral_follow_up": {
			"noticed_differences": "",
			"expected_outcome": "",
		},
		"structured_follow_up": {
			"used": false,
			"immediate_expectation": "",
			"day_three_four_expectation": "",
		},
		"expectation_match": "unscored",
		"blind_coding": {
			"coder_a": {},
			"coder_b": {},
			"resolved": false,
			"resolution": "",
		},
	}
	var error: int = _append_verified_json_line(_record_path, record)
	if error != OK:
		_fail_closed("failed to write %s: %s" % [_record_path, error_string(error)])
		return
	_record_written = true
	active = false
	print("PHASE12_BLIND_RECORD: PASS test_id=%s seed=%d path=%s" % [_test_id, controller.seed, _record_path])

func _state_snapshot(state: RefCounted) -> Dictionary:
	return {
		"day": int(state.day),
		"inspiration": int(state.inspiration),
		"raw_data": int(state.raw_data),
		"clean_data": int(state.clean_data),
		"charts": int(state.charts),
		"paper_progress": int(state.paper_progress),
		"energy": int(state.energy),
		"technical_debt": int(state.technical_debt),
		"stopped_slot": int(state.stopped_slot),
	}

func _append_verified_json_line(path: String, value: Dictionary) -> int:
	var absolute_directory: String = ProjectSettings.globalize_path(path.get_base_dir())
	var directory_error: int = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return directory_error
	var recovery_error: int = _recover_atomic_files(path)
	if recovery_error != OK:
		return recovery_error
	var lines: Array[String] = []
	if FileAccess.file_exists(path):
		var existing: FileAccess = FileAccess.open(path, FileAccess.READ)
		if existing == null:
			return FileAccess.get_open_error()
		while existing.get_position() < existing.get_length():
			var existing_line: String = existing.get_line()
			if existing_line.strip_edges().is_empty():
				continue
			var parsed_existing: Variant = JSON.parse_string(existing_line)
			if not parsed_existing is Dictionary:
				existing.close()
				return ERR_PARSE_ERROR
			if String(parsed_existing.get("test_id", "")) == String(value.get("test_id", "")):
				existing.close()
				return ERR_ALREADY_EXISTS
			lines.append(existing_line)
		existing.close()
	lines.append(JSON.stringify(value))
	var temporary_path := path + ".tmp"
	var backup_path := path + ".bak"
	var temporary: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary == null:
		return FileAccess.get_open_error()
	for line: String in lines:
		temporary.store_line(line)
	temporary.flush()
	var write_error: int = temporary.get_error()
	temporary.close()
	if write_error != OK:
		return write_error
	var verified_lines: Array[Dictionary] = _read_valid_json_lines(temporary_path)
	if verified_lines.size() != lines.size():
		return ERR_PARSE_ERROR
	var verified_last: Dictionary = verified_lines.back()
	if (
			String(verified_last.get("test_id", "")) != String(value.get("test_id", ""))
			or int(verified_last.get("seed", -1)) != int(value.get("seed", -2))
	):
		return ERR_INVALID_DATA
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(absolute_backup)
	var had_existing: bool = FileAccess.file_exists(path)
	if had_existing:
		var backup_error: int = DirAccess.rename_absolute(absolute_path, absolute_backup)
		if backup_error != OK:
			return backup_error
	var replace_error: int = DirAccess.rename_absolute(absolute_temporary, absolute_path)
	if replace_error != OK:
		if had_existing:
			DirAccess.rename_absolute(absolute_backup, absolute_path)
		return replace_error
	if had_existing:
		DirAccess.remove_absolute(absolute_backup)
	return OK

func _recover_atomic_files(path: String) -> int:
	var temporary_path := path + ".tmp"
	var backup_path := path + ".bak"
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	var has_primary: bool = FileAccess.file_exists(path)
	var has_backup: bool = FileAccess.file_exists(backup_path)
	if has_backup:
		var primary_valid: bool = has_primary and not _read_valid_json_lines(path).is_empty()
		var backup_valid: bool = not _read_valid_json_lines(backup_path).is_empty()
		if primary_valid:
			DirAccess.remove_absolute(absolute_backup)
		elif backup_valid:
			if has_primary:
				var remove_error: int = DirAccess.remove_absolute(absolute_path)
				if remove_error != OK:
					return remove_error
			var restore_error: int = DirAccess.rename_absolute(absolute_backup, absolute_path)
			if restore_error != OK:
				return restore_error
		else:
			return ERR_FILE_CORRUPT
	if FileAccess.file_exists(temporary_path):
		var cleanup_error: int = DirAccess.remove_absolute(absolute_temporary)
		if cleanup_error != OK:
			return cleanup_error
	return OK

func _read_valid_json_lines(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	while file.get_position() < file.get_length():
		var line: String = file.get_line()
		if line.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if not parsed is Dictionary:
			rows.clear()
			break
		rows.append(parsed)
	file.close()
	return rows

func _find_preregistered_row(seed: int) -> Dictionary:
	var file: FileAccess = FileAccess.open(PREREGISTRATION_PATH, FileAccess.READ)
	if file == null:
		return {"valid": false, "error": "cannot read locked preregistration"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not bool(parsed.get("coverage_ok", false)):
		return {"valid": false, "error": "locked preregistration is invalid"}
	var matches: Array[Dictionary] = []
	for row: Variant in parsed.get("selected", []):
		if row is Dictionary and int(row.get("seed", -1)) == seed:
			matches.append(row)
	if matches.size() != 1:
		return {"valid": false, "error": "Seed %d is not uniquely preregistered" % seed}
	return {"valid": true, "row": matches[0]}

func _preregistration_mismatch(controller: RefCounted, candidates: Array[String]) -> String:
	if int(controller.seed) != _expected_seed:
		return "running Seed no longer matches expected Seed"
	var expected_candidates: Array[String] = []
	for candidate: Variant in _preregistered_row.get("candidates", []):
		expected_candidates.append(String(candidate))
	if candidates != expected_candidates:
		return "candidate order does not match locked preregistration"
	var actual_topic: String = String(controller.topic_snapshot().get("topic_id", ""))
	if actual_topic.is_empty() or actual_topic != String(_preregistered_row.get("topic_id", "")):
		return "topic does not match locked preregistration"
	return ""

func _fail_closed(reason: String) -> void:
	active = false
	push_error("PHASE12_BLIND_RECORD: FAIL: %s" % reason)
	if get_tree() != null and _blind_arguments_requested(OS.get_cmdline_user_args()):
		get_tree().quit(2)

static func _blind_arguments_requested(arguments: PackedStringArray) -> bool:
	for argument: String in arguments:
		if argument.begins_with("--blind-"):
			return true
	return false

static func parse_configuration(arguments: PackedStringArray) -> Dictionary:
	var values: Dictionary = {}
	var requested: bool = false
	for argument: String in arguments:
		if not argument.begins_with("--blind-"):
			continue
		requested = true
		var separator: int = argument.find("=")
		if separator <= 0:
			return {"requested": true, "valid": false, "error": "blind arguments must use --name=value"}
		values[argument.substr(2, separator - 2)] = argument.substr(separator + 1)
	if not requested:
		return {"requested": false, "valid": false}
	for key: String in ["blind-test-id", "blind-participant-id", "blind-record-path", "blind-expected-seed"]:
		if String(values.get(key, "")).strip_edges().is_empty():
			return {"requested": true, "valid": false, "error": "missing --%s" % key}
	var path := String(values["blind-record-path"])
	if not path.begins_with("res://docs/playtests/phase12/sessions/") or not path.ends_with(".jsonl") or path.contains(".."):
		return {"requested": true, "valid": false, "error": "record path must be a safe Phase 12 res:// JSONL path"}
	if not String(values["blind-expected-seed"]).is_valid_int():
		return {"requested": true, "valid": false, "error": "expected seed must be an integer"}
	var expected_seed: int = int(values["blind-expected-seed"])
	if expected_seed <= 0:
		return {"requested": true, "valid": false, "error": "expected seed must be positive"}
	var participant_id := String(values["blind-participant-id"]).strip_edges()
	if not _is_anonymous_participant_id(participant_id):
		return {"requested": true, "valid": false, "error": "participant ID must use an anonymous anon-* token"}
	var sample_type: String = _sample_type_for_test_id(String(values["blind-test-id"]).strip_edges())
	if sample_type.is_empty():
		return {"requested": true, "valid": false, "error": "test ID must use a registered P12-AGENT, P12-EXT, or P12-E2E prefix"}
	return {
		"requested": true,
		"valid": true,
		"test_id": String(values["blind-test-id"]).strip_edges(),
		"participant_id": participant_id,
		"sample_type": sample_type,
		"record_path": path,
		"expected_seed": expected_seed,
	}

static func _sample_type_for_test_id(test_id: String) -> String:
	if test_id.begins_with("P12-AGENT-"):
		return "agent_pilot"
	if test_id.begins_with("P12-EXT-"):
		return "external_first_exposure"
	if test_id.begins_with("P12-E2E-"):
		return "test_fixture"
	return ""

static func _is_anonymous_participant_id(value: String) -> bool:
	if not value.begins_with("anon-") or value.length() < 6 or value.length() > 48:
		return false
	for character: String in value:
		if not "abcdefghijklmnopqrstuvwxyz0123456789-_".contains(character.to_lower()):
			return false
	return true

static func _json_safe(value: Variant) -> Variant:
	if value is Dictionary:
		var safe_dictionary: Dictionary = {}
		for key: Variant in value:
			safe_dictionary[str(key)] = _json_safe(value[key])
		return safe_dictionary
	if value is Array:
		var safe_array: Array = []
		for item: Variant in value:
			safe_array.append(_json_safe(item))
		return safe_array
	if value is StringName:
		return str(value)
	return value
