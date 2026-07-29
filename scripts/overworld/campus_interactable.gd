@tool
extends Area2D
class_name CampusInteractable

const CAMPUS_MAP_MARKER := preload("res://scripts/overworld/campus_map_marker.gd")

signal interaction_requested(interactable_id: StringName)

@export var interaction_id: StringName = &""
@export var display_name: String = ""
@export var interaction_kind: StringName = &"encounter"
@export var route_node_id: StringName = &""
@export var resource_id: StringName = &""
@export var resource_amount: int = 0
@export var content_tags: Array[StringName] = []
@export var base_marker_state: StringName = &"default"
@export var marker_state: StringName = &"default"
@export var accent_color: Color = Color(0.85, 0.72, 0.36)
@export var guidance_target: bool = false
@export var supply_hint_target: bool = false
@export var focused_target: bool = false
@export var summary_guidance_target: bool = false

var collected: bool = false
var requirement_summary: String = ""
var marker: Node2D


func _ready() -> void:
	monitoring = true
	monitorable = true
	_ensure_marker()
	_ensure_collision_shape()
	refresh_marker()


func interact() -> bool:
	if collected:
		return false
	interaction_requested.emit(interaction_id)
	return true


func mark_collected() -> void:
	collected = true
	focused_target = false
	summary_guidance_target = false
	visible = false
	monitoring = false
	refresh_marker()


func get_interaction_summary() -> String:
	var summary: String = ""
	if interaction_kind == &"resource":
		summary = "%s +%d" % [display_name, resource_amount]
	elif route_node_id != &"":
		summary = "%s 路 %s" % [display_name, String(route_node_id)]
	else:
		summary = display_name
	if requirement_summary != "":
		return "%s｜准备不足：%s" % [summary, requirement_summary]
	return summary


func get_content_tags() -> Array[StringName]:
	return content_tags.duplicate()


func refresh_marker() -> void:
	_ensure_marker()
	if marker == null:
		return
	if marker.has_method("configure_marker"):
		marker.call("configure_marker", interaction_kind, resource_id, accent_color, marker_state, guidance_target, supply_hint_target, focused_target, summary_guidance_target, content_tags)
	if marker.has_method("set_completed"):
		marker.call("set_completed", collected)


func set_marker_state(new_marker_state: StringName) -> void:
	marker_state = new_marker_state
	refresh_marker()


func set_base_marker_state(new_marker_state: StringName) -> void:
	base_marker_state = new_marker_state
	set_marker_state(new_marker_state)


func set_requirement_summary(new_requirement_summary: String) -> void:
	requirement_summary = new_requirement_summary


func set_guidance_target(new_guidance_target: bool) -> void:
	guidance_target = new_guidance_target
	if marker != null and marker.has_method("set_guidance_target"):
		marker.call("set_guidance_target", guidance_target)
	else:
		refresh_marker()


func set_supply_hint_target(new_supply_hint_target: bool) -> void:
	supply_hint_target = new_supply_hint_target
	if marker != null and marker.has_method("set_supply_hint_target"):
		marker.call("set_supply_hint_target", supply_hint_target)
	else:
		refresh_marker()


func set_focused_target(new_focused_target: bool) -> void:
	focused_target = new_focused_target
	if marker != null and marker.has_method("set_focused_target"):
		marker.call("set_focused_target", focused_target)
	else:
		refresh_marker()


func set_summary_guidance_target(new_summary_guidance_target: bool) -> void:
	summary_guidance_target = new_summary_guidance_target
	if marker != null and marker.has_method("set_summary_guidance_target"):
		marker.call("set_summary_guidance_target", summary_guidance_target)
	else:
		refresh_marker()


func has_marker_component() -> bool:
	_ensure_marker()
	return marker != null and marker.has_method("configure_marker")


func is_marker_processing() -> bool:
	if marker == null:
		return false
	return marker.is_processing()


func get_marker_kind() -> StringName:
	if marker == null or marker.get("marker_kind") == null:
		return &""
	return StringName(marker.get("marker_kind"))


func get_marker_state() -> StringName:
	if marker == null or marker.get("marker_state") == null:
		return &""
	return StringName(marker.get("marker_state"))


func get_marker_visual_profile() -> StringName:
	_ensure_marker()
	if marker == null or not marker.has_method("get_visual_profile"):
		return &""
	return marker.call("get_visual_profile")


func is_guidance_target() -> bool:
	if marker == null or marker.get("guidance_target") == null:
		return guidance_target
	return bool(marker.get("guidance_target"))


func is_supply_hint_target() -> bool:
	if marker == null or marker.get("supply_hint_target") == null:
		return supply_hint_target
	return bool(marker.get("supply_hint_target"))


func is_focused_target() -> bool:
	if marker == null or marker.get("focused_target") == null:
		return focused_target
	return bool(marker.get("focused_target"))


func is_summary_guidance_target() -> bool:
	if marker == null or marker.get("summary_guidance_target") == null:
		return summary_guidance_target
	return bool(marker.get("summary_guidance_target"))


func _ensure_marker() -> void:
	if marker != null:
		return
	for child: Node in get_children():
		if child.has_method("configure_marker"):
			marker = child as Node2D
			return

	marker = CAMPUS_MAP_MARKER.new()
	marker.name = "Marker"
	add_child(marker)


func _ensure_collision_shape() -> void:
	for child: Node in get_children():
		if child is CollisionShape2D:
			return

	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(42, 42)
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)
