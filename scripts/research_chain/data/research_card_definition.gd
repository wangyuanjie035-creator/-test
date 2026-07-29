class_name ResearchCardDefinition
extends Resource

enum Stage { LITERATURE, HYPOTHESIS, EXPERIMENT, DATA, ANALYSIS, PAPER }
enum Effect { NONE, NEXT_HYPOTHESIS, OTHER_LITERATURE, BRIDGE, HAS_HYPOTHESIS, AFTER_EXPERIMENT, HAS_DATA, FOUR_STAGES, REST, REPEAT_EXPERIMENT, REPLICATION_SCALE, HIGH_CREDIBILITY, REPLICATION_FINISHER, GAIN_NEGATIVE, ARCHIVE_NEGATIVE, REFRAME_NEGATIVE, PUBLISH_NEGATIVE, GAIN_DEBT_TWO, DEBT_SCORE, AUTOMATION_SCALE, REFACTOR_DEBT }

@export var id: StringName
@export var display_name: String
@export var stage: Stage
@export_range(0, 20, 1) var base_score: int
@export var archetype: StringName = &"general"
@export var tags: Array[StringName] = []
@export var effect: Effect = Effect.NONE
@export_multiline var rules_text: String

