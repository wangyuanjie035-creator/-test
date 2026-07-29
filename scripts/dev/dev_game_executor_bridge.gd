extends Node

const EXECUTOR_PATH := "res://addons/hasturoperationgd/game_executor.gd"

var _executor: Node

func _ready() -> void:
	# The editor binary carries the `editor` feature even when it launches the game.
	# Exported builds do not, so production never loads or parses the development addon.
	if not OS.has_feature("editor") or not ResourceLoader.exists(EXECUTOR_PATH):
		queue_free()
		return
	var executor_script := load(EXECUTOR_PATH) as Script
	if executor_script == null:
		push_warning("Godot remote executor bridge could not load the development executor.")
		queue_free()
		return
	_executor = executor_script.new() as Node
	if _executor == null:
		push_warning("Godot remote executor bridge could not instantiate the development executor.")
		queue_free()
		return
	_executor.name = "DevelopmentGameExecutor"
	add_child(_executor)
