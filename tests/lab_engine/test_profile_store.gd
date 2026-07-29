extends "res://tests/lab_engine/lab_test_case.gd"

const STORE_SCRIPT := preload("res://scripts/lab_engine/persistence/lab_profile_store.gd")
const TEST_PATH := "user://lab_engine_tests/profile.json"

func run() -> Array[String]:
	_cleanup()
	_test_round_trip_and_backup_recovery()
	_cleanup()
	_test_version_zero_migration()
	_cleanup()
	_test_future_version_is_preserved()
	_cleanup()
	_test_future_version_backup_only_is_preserved()
	_cleanup()
	_test_invalid_primary_never_replaces_good_backup()
	_cleanup()
	_test_backup_only_recovery()
	_cleanup()
	return failures

func _test_round_trip_and_backup_recovery() -> void:
	var store: RefCounted = STORE_SCRIPT.new()
	var first: Dictionary = store.defaults()
	first.tutorial_seen = true
	first.runs_started = 2
	first.last_seed = 240731
	check_equal(store.save(first, TEST_PATH), OK, "profile save must succeed")
	var loaded: Dictionary = store.load_profile(TEST_PATH)
	check(bool(loaded.ok), "saved profile must load")
	check(bool(loaded.data.tutorial_seen), "tutorial state must round-trip")
	check_equal(int(loaded.data.runs_started), 2, "run count must round-trip")

	var second: Dictionary = loaded.data.duplicate(true)
	second.runs_started = 3
	check_equal(store.save(second, TEST_PATH), OK, "second save must rotate the first save to backup")
	var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	check(corrupt != null, "test must be able to corrupt the primary profile")
	if corrupt != null:
		corrupt.store_string("{broken")
		corrupt.close()
	var recovered: Dictionary = store.load_profile(TEST_PATH)
	check(bool(recovered.ok), "corrupt primary must recover from backup")
	check(bool(recovered.recovered), "backup load must report recovery")
	check(bool(recovered.disk_repaired), "backup recovery must report that the primary was repaired")
	check_equal(int(recovered.error), OK, "successful recovery must expose an OK repair result")
	check_equal(int(recovered.data.runs_started), 2, "backup must preserve the previous complete generation")
	var second_load: Dictionary = store.load_profile(TEST_PATH)
	check(bool(second_load.ok) and not bool(second_load.recovered), "a repaired primary must load directly on the next read")
	check_equal(int(second_load.data.runs_started), 2, "repaired primary must contain the recovered generation")

func _test_version_zero_migration() -> void:
	var dir_path := TEST_PATH.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	check(file != null, "test must be able to write a version-zero fixture")
	if file == null:
		return
	file.store_string(JSON.stringify({"help_seen": true, "launch_count": 4, "seed": 99}))
	file.close()
	var loaded: Dictionary = STORE_SCRIPT.new().load_profile(TEST_PATH)
	check(bool(loaded.ok), "version-zero profile must migrate")
	check_equal(int(loaded.data.version), 1, "migration must advance to current version")
	check(bool(loaded.data.tutorial_seen), "migration must preserve tutorial state")
	check_equal(int(loaded.data.runs_started), 4, "migration must preserve run count")
	check_equal(int(loaded.data.last_seed), 99, "migration must preserve last seed")

func _test_future_version_is_preserved() -> void:
	_write_text(TEST_PATH, JSON.stringify({"version": 2, "tutorial_seen": true, "future": "keep"}))
	_write_text(TEST_PATH + ".bak", JSON.stringify({"version": 1, "tutorial_seen": false, "runs_started": 1, "last_seed": 1}))
	var before := _read_text(TEST_PATH)
	var loaded: Dictionary = STORE_SCRIPT.new().load_profile(TEST_PATH)
	check(not bool(loaded.ok) and bool(loaded.get("unsupported", false)), "future profile must report unsupported instead of loading an old backup")
	check_equal(_read_text(TEST_PATH), before, "future profile must never be overwritten by an older backup")

func _test_future_version_backup_only_is_preserved() -> void:
	var future_backup := JSON.stringify({"version": 2, "tutorial_seen": true, "future": "keep-backup"})
	_write_text(TEST_PATH + ".bak", future_backup)
	var store: RefCounted = STORE_SCRIPT.new()
	var loaded: Dictionary = store.load_profile(TEST_PATH)
	check(not bool(loaded.ok) and bool(loaded.get("unsupported", false)), "future backup without a primary must report unsupported")
	check_equal(store.save(store.defaults(), TEST_PATH), OK, "an explicit standalone save may create a primary without rotating backup")
	check_equal(_read_text(TEST_PATH + ".bak"), future_backup, "future backup-only data must not be deleted or replaced")
	check_equal(store.save(store.defaults(), TEST_PATH), ERR_UNAVAILABLE, "a second save must refuse to rotate over a future-version backup")
	check_equal(_read_text(TEST_PATH + ".bak"), future_backup, "repeated saves must preserve the future-version backup")

func _test_invalid_primary_never_replaces_good_backup() -> void:
	var store: RefCounted = STORE_SCRIPT.new()
	var first: Dictionary = store.defaults()
	first.runs_started = 4
	check_equal(store.save(first, TEST_PATH), OK, "first fixture save must succeed")
	var second: Dictionary = first.duplicate(true)
	second.runs_started = 5
	check_equal(store.save(second, TEST_PATH), OK, "second fixture save must create a good backup")
	_write_text(TEST_PATH, "{broken")
	var third: Dictionary = first.duplicate(true)
	third.runs_started = 6
	check_equal(store.save(third, TEST_PATH), OK, "explicit save may replace a corrupt primary")
	_write_text(TEST_PATH, "{broken-again")
	var recovered: Dictionary = store.load_profile(TEST_PATH)
	check(bool(recovered.ok), "good backup must survive saving over a corrupt primary")
	check_equal(int(recovered.data.runs_started), 4, "corrupt primary must never rotate over the last known-good backup")

func _test_backup_only_recovery() -> void:
	var store: RefCounted = STORE_SCRIPT.new()
	var data: Dictionary = store.defaults()
	data.runs_started = 7
	_write_text(TEST_PATH + ".bak", JSON.stringify(data))
	var recovered: Dictionary = store.load_profile(TEST_PATH)
	check(bool(recovered.ok) and bool(recovered.recovered), "a backup-only crash state must recover")
	check_equal(int(recovered.data.runs_started), 7, "backup-only recovery must preserve data")
	check(FileAccess.file_exists(TEST_PATH), "backup-only recovery must rebuild the primary")

func _cleanup() -> void:
	var store: RefCounted = STORE_SCRIPT.new()
	store.delete_profile(TEST_PATH)

func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "test fixture must be writable: %s" % path)
	if file == null:
		return
	file.store_string(text)
	file.close()

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text
