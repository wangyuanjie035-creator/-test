@tool
extends EditorPlugin


var _dock: Control
var _backend: ExecutorBackend


func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	HasturOperationGDPluginSettings.register_settings()

	_backend = ExecutorBackend.new()
	add_child(_backend)
	_backend.initialize(self)

	var dock_content = preload("executor_dock.gd").new()
	dock_content.initialize(_backend)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock_content)
	_dock = dock_content


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	if _backend:
		remove_child(_backend)
		_backend.queue_free()
		_backend = null
