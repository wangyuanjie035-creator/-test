class_name LabCardDefinition
extends Resource

enum Slot { LITERATURE, EXPERIMENT, DATA, ANALYSIS, WRITING, REST }
enum Effect { LITERATURE_CRAWLER, KEYWORD_SUBSCRIPTION, BATCH_EXPERIMENT, UNATTENDED_NIGHT, CLEANING_PIPELINE, LEGACY_CONVERTER, AUTO_STATISTICS, PARAMETER_SCAN, PAPER_TEMPLATE, ALL_NIGHTER, LEGACY_SCHEDULER, LOOP_GUARD }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var slot: Slot
@export var effect: Effect
@export var output_score_level_1: int
@export var output_score_level_2: int
@export var automation_card: bool = false
@export var build_tags: Array[StringName] = []
@export var candidate_tags: Array[StringName] = []

func output_score(level: int) -> int:
	return output_score_level_2 if level >= 2 else output_score_level_1
