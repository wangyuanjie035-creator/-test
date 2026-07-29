class_name LabAudioCueDefinition
extends Resource

@export var id: StringName
@export var frequencies: PackedFloat32Array = PackedFloat32Array()
@export_range(0.01, 2.0, 0.01) var duration: float = 0.1
@export_range(0.01, 1.0, 0.01) var amplitude: float = 0.2
@export_range(-40.0, 6.0, 0.5) var volume_db: float = -8.0
@export var important: bool = false
@export_range(0.0, 6.0, 0.5) var level_volume_step_db: float = 0.0
@export_range(0.0, 12.0, 0.5) var max_level_boost_db: float = 0.0
