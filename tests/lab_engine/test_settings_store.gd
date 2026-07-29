extends "res://tests/lab_engine/lab_test_case.gd"

const STORE_SCRIPT := preload("res://scripts/lab_engine/persistence/lab_settings_store.gd")
const APPLIER_SCRIPT := preload("res://scripts/lab_engine/persistence/lab_settings_applier.gd")
const TEST_PATH := "user://lab_engine_tests/settings.cfg"

func run() -> Array[String]:
	_cleanup()
	_test_round_trip_and_normalization()
	_cleanup()
	_test_migration_and_recovery()
	_cleanup()
	_test_future_versions_are_protected()
	_cleanup()
	return failures

func _test_round_trip_and_normalization() -> void:
	var store: RefCounted = STORE_SCRIPT.new()
	check_equal(store.save({"master_volume": 2.0, "window_mode": "invalid"}, TEST_PATH), OK, "settings save must succeed")
	var loaded: Dictionary = store.load_settings(TEST_PATH)
	check(bool(loaded.ok), "settings must load")
	check_equal(float(loaded.data.master_volume), 1.0, "volume must clamp to one")
	check_equal(String(loaded.data.window_mode), "windowed", "unknown window modes must use the safe default")
	check(is_equal_approx(float(APPLIER_SCRIPT.volume_to_db(1.0)), 0.0), "full volume must map to zero dB")
	check(float(APPLIER_SCRIPT.volume_to_db(0.0)) <= -59.0, "zero volume must map near silence")

func _test_migration_and_recovery() -> void:
	_write_text(TEST_PATH, "[audio]\nvolume=0.35\n[display]\nfullscreen=true\n")
	var migrated: Dictionary = STORE_SCRIPT.new().load_settings(TEST_PATH)
	check(bool(migrated.ok), "version-zero settings must migrate")
	check(is_equal_approx(float(migrated.data.master_volume), 0.35), "migration must preserve volume")
	check_equal(String(migrated.data.window_mode), "fullscreen", "migration must preserve fullscreen")
	var store: RefCounted = STORE_SCRIPT.new()
	check_equal(store.save(migrated.data, TEST_PATH), OK, "migrated settings must save")
	var changed: Dictionary = migrated.data.duplicate(true)
	changed.master_volume = 0.7
	check_equal(store.save(changed, TEST_PATH), OK, "second settings save must create a backup")
	_write_text(TEST_PATH, "[meta]\nversion=-1\n")
	var recovered: Dictionary = store.load_settings(TEST_PATH)
	check(bool(recovered.ok) and bool(recovered.recovered) and bool(recovered.disk_repaired), "corrupt settings must recover and repair from backup")
	check(is_equal_approx(float(recovered.data.master_volume), 0.35), "recovery must retain the previous complete generation")
	check(not bool(store.load_settings(TEST_PATH).recovered), "repaired settings must load directly next time")

func _test_future_versions_are_protected() -> void:
	_write_text(TEST_PATH, "[meta]\nversion=2\n[audio]\nmaster_volume=0.2\n")
	var before := _read_text(TEST_PATH)
	var store: RefCounted = STORE_SCRIPT.new()
	var loaded: Dictionary = store.load_settings(TEST_PATH)
	check(not bool(loaded.ok) and bool(loaded.get("unsupported", false)), "future settings must report unsupported")
	check_equal(store.save(store.defaults(), TEST_PATH), ERR_UNAVAILABLE, "save must refuse to overwrite future settings")
	check_equal(_read_text(TEST_PATH), before, "future settings bytes must remain unchanged")

func _cleanup() -> void:
	STORE_SCRIPT.new().delete_settings(TEST_PATH)

func _write_text(path: String, value: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "settings fixture must be writable")
	if file != null:
		file.store_string(value)
		file.close()

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var value := file.get_as_text()
	file.close()
	return value
