extends "res://tests/lab_engine/lab_test_case.gd"

const RECORDER_SCRIPT := preload("res://scripts/lab_engine/testing/lab_opening_blind_recorder.gd")

func run() -> Array[String]:
	_test_inert_without_arguments()
	_test_valid_configuration()
	_test_rejects_incomplete_and_unsafe_configuration()
	_test_rejects_identifying_participant_id()
	_test_atomic_jsonl_create_append_and_duplicate_guard()
	_test_atomic_jsonl_recovers_interrupted_replace()
	return failures

func _test_inert_without_arguments() -> void:
	var config: Dictionary = RECORDER_SCRIPT.parse_configuration(PackedStringArray())
	check(not bool(config.get("requested", true)), "recorder must be inert without blind-test arguments")

func _test_valid_configuration() -> void:
	var config: Dictionary = RECORDER_SCRIPT.parse_configuration(PackedStringArray([
		"--blind-test-id=P12-EXT-001",
		"--blind-participant-id=anon-001",
		"--blind-record-path=res://docs/playtests/phase12/sessions/P12-EXT-001.jsonl",
		"--blind-expected-seed=244001",
	]))
	check(bool(config.get("valid", false)), "complete blind-test configuration must be accepted")
	check_equal(int(config.get("expected_seed", 0)), 244001, "expected seed must be parsed")
	check_equal(String(config.get("sample_type", "")), "external_first_exposure", "external test ID must derive external sample type")
	check_equal(RECORDER_SCRIPT._sample_type_for_test_id("P12-AGENT-001"), "agent_pilot", "agent IDs must never enter external sample statistics")

func _test_rejects_incomplete_and_unsafe_configuration() -> void:
	var incomplete: Dictionary = RECORDER_SCRIPT.parse_configuration(PackedStringArray([
		"--blind-test-id=P12-EXT-001",
	]))
	check(not bool(incomplete.get("valid", true)), "partial blind-test configuration must be rejected")
	var unsafe: Dictionary = RECORDER_SCRIPT.parse_configuration(PackedStringArray([
		"--blind-test-id=P12-EXT-001",
		"--blind-participant-id=anon-001",
		"--blind-record-path=res://docs/playtests/phase12/sessions/../escape.jsonl",
		"--blind-expected-seed=244001",
	]))
	check(not bool(unsafe.get("valid", true)), "unsafe record path must be rejected")

func _test_rejects_identifying_participant_id() -> void:
	var identifying: Dictionary = RECORDER_SCRIPT.parse_configuration(PackedStringArray([
		"--blind-test-id=P12-EXT-001",
		"--blind-participant-id=person@example.com",
		"--blind-record-path=res://docs/playtests/phase12/sessions/P12-EXT-001.jsonl",
		"--blind-expected-seed=244001",
	]))
	check(not bool(identifying.get("valid", true)), "participant ID must be an anonymous anon-* token")

func _test_atomic_jsonl_create_append_and_duplicate_guard() -> void:
	var recorder: Node = RECORDER_SCRIPT.new()
	var path := "res://docs/playtests/phase12/sessions/_recorder_io_test.jsonl"
	var absolute_path := ProjectSettings.globalize_path(path)
	var temporary_path := ProjectSettings.globalize_path(path + ".tmp")
	var backup_path := ProjectSettings.globalize_path(path + ".bak")
	for cleanup_path: String in [absolute_path, temporary_path, backup_path]:
		if FileAccess.file_exists(cleanup_path):
			DirAccess.remove_absolute(cleanup_path)
	var first_error: int = recorder.call("_append_verified_json_line", path, {"test_id": "IO-001", "seed": 244002})
	var second_error: int = recorder.call("_append_verified_json_line", path, {"test_id": "IO-002", "seed": 244003})
	var duplicate_error: int = recorder.call("_append_verified_json_line", path, {"test_id": "IO-002", "seed": 244003})
	check_equal(first_error, OK, "atomic writer must create the first JSONL file")
	check_equal(second_error, OK, "atomic writer must append through replacement")
	check_equal(duplicate_error, ERR_ALREADY_EXISTS, "atomic writer must reject duplicate test IDs")
	var rows: Array[Dictionary] = recorder.call("_read_valid_json_lines", path)
	check_equal(rows.size(), 2, "atomic writer must retain two parseable rows")
	recorder.free()
	for cleanup_path: String in [absolute_path, temporary_path, backup_path]:
		if FileAccess.file_exists(cleanup_path):
			DirAccess.remove_absolute(cleanup_path)

func _test_atomic_jsonl_recovers_interrupted_replace() -> void:
	var recorder: Node = RECORDER_SCRIPT.new()
	var path := "res://docs/playtests/phase12/sessions/_recorder_recovery_test.jsonl"
	var absolute_path := ProjectSettings.globalize_path(path)
	var temporary_path := ProjectSettings.globalize_path(path + ".tmp")
	var backup_path := ProjectSettings.globalize_path(path + ".bak")
	for cleanup_path: String in [absolute_path, temporary_path, backup_path]:
		if FileAccess.file_exists(cleanup_path):
			DirAccess.remove_absolute(cleanup_path)
	check_equal(
		int(recorder.call("_append_verified_json_line", path, {"test_id": "RECOVERY-001", "seed": 244002})),
		OK,
		"recovery fixture must create its committed primary"
	)
	check_equal(
		DirAccess.rename_absolute(absolute_path, backup_path),
		OK,
		"test must simulate a crash after primary-to-backup rename"
	)
	var stale_temporary: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if stale_temporary != null:
		stale_temporary.store_line("{\"partial\":")
		stale_temporary.close()
	check_equal(
		int(recorder.call("_append_verified_json_line", path, {"test_id": "RECOVERY-002", "seed": 244003})),
		OK,
		"writer must restore committed backup before appending"
	)
	var rows: Array[Dictionary] = recorder.call("_read_valid_json_lines", path)
	check_equal(rows.size(), 2, "recovery must preserve the old row and append the new row")
	if rows.size() == 2:
		check_equal(String(rows[0].get("test_id", "")), "RECOVERY-001", "recovery must retain committed row order")
		check_equal(String(rows[1].get("test_id", "")), "RECOVERY-002", "recovery must append after restored row")
	recorder.free()
	for cleanup_path: String in [absolute_path, temporary_path, backup_path]:
		if FileAccess.file_exists(cleanup_path):
			DirAccess.remove_absolute(cleanup_path)
