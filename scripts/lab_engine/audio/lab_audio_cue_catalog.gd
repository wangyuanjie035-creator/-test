class_name LabAudioCueCatalog
extends RefCounted

const EXPECTED_CUE_COUNT := 5
const CUE_SCRIPT_PATH := "res://scripts/lab_engine/audio/lab_audio_cue_definition.gd"
const CUE_RESOURCES: Array[Resource] = [
	preload("res://data/lab_engine/audio/success.tres"),
	preload("res://data/lab_engine/audio/failure.tres"),
	preload("res://data/lab_engine/audio/combo.tres"),
	preload("res://data/lab_engine/audio/breakthrough.tres"),
	preload("res://data/lab_engine/audio/victory.tres"),
]

func build_cues() -> Dictionary[StringName, Resource]:
	var errors := validate_definitions(CUE_RESOURCES)
	assert(errors.is_empty(), "Invalid lab audio cue data:\n%s" % "\n".join(errors))
	var cues: Dictionary[StringName, Resource] = {}
	for cue: Resource in CUE_RESOURCES:
		var cue_id: StringName = cue.get(&"id")
		cues[cue_id] = cue
	return cues

func validate_definitions(definitions: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary[StringName, bool] = {}
	if definitions.size() != EXPECTED_CUE_COUNT:
		errors.append("audio catalog must contain %d cues, got %d" % [EXPECTED_CUE_COUNT, definitions.size()])
	for index: int in range(definitions.size()):
		var cue: Variant = definitions[index]
		var prefix := "cue[%d]" % index
		if not cue is Resource or cue.get_script() == null or cue.get_script().resource_path != CUE_SCRIPT_PATH:
			errors.append("%s is not a LabAudioCueDefinition" % prefix)
			continue
		var cue_id: StringName = cue.get(&"id")
		if cue_id == &"":
			errors.append("%s has an empty id" % prefix)
		elif seen_ids.has(cue_id):
			errors.append("%s duplicates id '%s'" % [prefix, cue_id])
		else:
			seen_ids[cue_id] = true
		var frequencies: PackedFloat32Array = cue.get(&"frequencies")
		if frequencies.is_empty():
			errors.append("%s has no frequencies" % prefix)
		for frequency: float in frequencies:
			if frequency <= 0.0:
				errors.append("%s has a non-positive frequency" % prefix)
		if float(cue.get(&"duration")) <= 0.0:
			errors.append("%s has invalid duration" % prefix)
		var amplitude := float(cue.get(&"amplitude"))
		if amplitude <= 0.0 or amplitude > 1.0:
			errors.append("%s has invalid amplitude" % prefix)
		if float(cue.get(&"level_volume_step_db")) < 0.0 or float(cue.get(&"max_level_boost_db")) < 0.0:
			errors.append("%s has invalid level volume boost" % prefix)
	return errors
