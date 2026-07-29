extends "res://tests/lab_engine/lab_test_case.gd"

const CUE_SCRIPT := preload("res://scripts/lab_engine/audio/lab_audio_cue_definition.gd")
const CATALOG_SCRIPT := preload("res://scripts/lab_engine/audio/lab_audio_cue_catalog.gd")
const FROZEN_CUES := {
	&"success": [[520.0, 660.0], 0.11, 0.22, -12.0, false, 0.0, 0.0],
	&"failure": [[190.0, 145.0], 0.16, 0.2, -8.0, false, 0.0, 0.0],
	&"combo": [[620.0, 780.0, 980.0], 0.2, 0.2, -8.0, false, 1.0, 3.0],
	&"breakthrough": [[520.0, 660.0, 820.0, 1040.0], 0.38, 0.22, -6.0, true, 0.0, 0.0],
	&"victory": [[440.0, 554.0, 660.0, 880.0], 0.58, 0.24, -4.0, true, 0.0, 0.0],
}

func run() -> Array[String]:
	var catalog: RefCounted = CATALOG_SCRIPT.new()
	var cues: Dictionary = catalog.build_cues()
	check_equal(_sorted_ids(cues), _sorted_ids(FROZEN_CUES), "audio cue ids must match the frozen set")
	for id: StringName in cues:
		var cue: Resource = cues[id]
		var expected: Array = FROZEN_CUES[id]
		check_equal(cue.get(&"frequencies"), PackedFloat32Array(expected[0]), "%s frequencies must preserve the original tone" % id)
		check_equal(cue.get(&"duration"), expected[1], "%s duration must preserve the original tone" % id)
		check_equal(cue.get(&"amplitude"), expected[2], "%s amplitude must preserve the original tone" % id)
		check_equal(cue.get(&"volume_db"), expected[3], "%s volume must preserve the original mix" % id)
		check_equal(cue.get(&"important"), expected[4], "%s priority must preserve the original playback path" % id)
		check_equal(cue.get(&"level_volume_step_db"), expected[5], "%s level step must preserve the original mix" % id)
		check_equal(cue.get(&"max_level_boost_db"), expected[6], "%s boost cap must preserve the original mix" % id)
	_test_invalid_definitions(catalog)
	return failures

func _test_invalid_definitions(catalog: RefCounted) -> void:
	var invalid: Resource = CUE_SCRIPT.new()
	invalid.id = &""
	invalid.frequencies = PackedFloat32Array([-1.0])
	invalid.duration = -1.0
	invalid.amplitude = 2.0
	invalid.level_volume_step_db = -1.0
	var errors: PackedStringArray = catalog.validate_definitions([invalid, invalid])
	var combined := "\n".join(errors)
	for expected: String in ["empty id", "non-positive frequency", "invalid duration", "invalid amplitude", "invalid level volume boost"]:
		check(combined.contains(expected), "audio validator must reject %s" % expected)

func _sorted_ids(dictionary: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in dictionary:
		ids.append(id)
	ids.sort()
	return ids
