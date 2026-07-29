@tool
extends Control
class_name CampusTaskTrackerMinimap

const ROLE_STORY := &"story"
const ROLE_SUPPLY := &"supply"
const ROLE_BOSS := &"boss"
const ROLE_RESOURCE := &"resource"
const ROLE_EVENT := &"event"
const ROLE_ENCOUNTER := &"encounter"
const ROLE_SAFEHOUSE := &"safehouse"

const COLOR_BACKGROUND := Color(0.05, 0.08, 0.08, 0.92)
const COLOR_GRID := Color(0.18, 0.25, 0.24, 0.42)
const COLOR_PATH := Color(0.45, 0.43, 0.35, 0.62)
const COLOR_BORDER := Color(0.26, 0.34, 0.34, 0.95)
const COLOR_PLAYER := Color(0.96, 0.98, 0.92)
const COLOR_STORY := Color(0.42, 0.88, 0.96)
const COLOR_SUPPLY := Color(0.98, 0.82, 0.32)
const COLOR_BOSS := Color(0.94, 0.34, 0.42)
const COLOR_RESOURCE := Color(0.86, 0.78, 0.42)
const COLOR_EVENT := Color(0.70, 0.56, 0.92)
const COLOR_ENCOUNTER := Color(0.52, 0.66, 0.82)
const COLOR_SAFEHOUSE := Color(0.60, 0.90, 0.68)

var map_bounds: Rect2 = Rect2(Vector2(32, 32), Vector2(1536, 896))
var player_position: Vector2 = Vector2.ZERO
var point_entries: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(new_map_bounds: Rect2, new_player_position: Vector2, new_point_entries: Array[Dictionary]) -> void:
	map_bounds = new_map_bounds
	player_position = new_player_position
	point_entries.clear()
	for entry: Dictionary in new_point_entries:
		point_entries.append(entry.duplicate(true))
	queue_redraw()


func get_point_count() -> int:
	return point_entries.size()


func get_role_count(role: StringName) -> int:
	var count: int = 0
	for entry: Dictionary in point_entries:
		if StringName(entry.get("role", ROLE_ENCOUNTER)) == role:
			count += 1
	return count


func get_marker_summary() -> String:
	return "story=%d,supply=%d,boss=%d,resource=%d,event=%d,encounter=%d,safehouse=%d,player=1" % [
		get_role_count(ROLE_STORY),
		get_role_count(ROLE_SUPPLY),
		get_role_count(ROLE_BOSS),
		get_role_count(ROLE_RESOURCE),
		get_role_count(ROLE_EVENT),
		get_role_count(ROLE_ENCOUNTER),
		get_role_count(ROLE_SAFEHOUSE),
	]


func _draw() -> void:
	var draw_rect_area: Rect2 = Rect2(Vector2.ZERO, size)
	if draw_rect_area.size.x <= 0.0 or draw_rect_area.size.y <= 0.0:
		return

	var map_rect: Rect2 = draw_rect_area.grow(-3.0)
	draw_rect(map_rect, COLOR_BACKGROUND, true)
	_draw_grid(map_rect)
	_draw_paths(map_rect)
	_draw_points(map_rect)
	_draw_player(map_rect)
	draw_rect(map_rect, COLOR_BORDER, false, 2.0)


func _draw_grid(map_rect: Rect2) -> void:
	for step: int in range(1, 4):
		var x: float = map_rect.position.x + map_rect.size.x * float(step) / 4.0
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), COLOR_GRID, 1.0)
	for step: int in range(1, 3):
		var y: float = map_rect.position.y + map_rect.size.y * float(step) / 3.0
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), COLOR_GRID, 1.0)


func _draw_paths(map_rect: Rect2) -> void:
	var vertical_center: Vector2 = _project_world_position(Vector2(800, 536), map_rect)
	var horizontal_center: Vector2 = _project_world_position(Vector2(800, 476), map_rect)
	draw_rect(Rect2(Vector2(vertical_center.x - 2.0, map_rect.position.y), Vector2(4.0, map_rect.size.y)), COLOR_PATH, true)
	draw_rect(Rect2(Vector2(map_rect.position.x, horizontal_center.y - 2.0), Vector2(map_rect.size.x, 4.0)), COLOR_PATH, true)


func _draw_points(map_rect: Rect2) -> void:
	var sorted_entries: Array[Dictionary] = point_entries.duplicate()
	sorted_entries.sort_custom(_compare_point_priority)
	for entry: Dictionary in sorted_entries:
		var world_position: Vector2 = entry.get("position", Vector2.ZERO)
		var role: StringName = StringName(entry.get("role", ROLE_ENCOUNTER))
		var point_position: Vector2 = _project_world_position(world_position, map_rect)
		_draw_marker(point_position, role)


func _draw_player(map_rect: Rect2) -> void:
	var point_position: Vector2 = _project_world_position(player_position, map_rect)
	draw_rect(Rect2(point_position - Vector2(4, 4), Vector2(8, 8)), Color(0.02, 0.03, 0.03, 0.88), true)
	draw_rect(Rect2(point_position - Vector2(3, 3), Vector2(6, 6)), COLOR_PLAYER, true)


func _draw_marker(point_position: Vector2, role: StringName) -> void:
	var marker_size: Vector2 = Vector2(5, 5)
	if role == ROLE_STORY:
		marker_size = Vector2(8, 8)
	elif role == ROLE_SUPPLY or role == ROLE_BOSS:
		marker_size = Vector2(7, 7)
	elif role == ROLE_SAFEHOUSE:
		marker_size = Vector2(7, 7)
	var marker_rect: Rect2 = Rect2(point_position - marker_size * 0.5, marker_size)
	draw_rect(marker_rect.grow(1.0), Color(0.02, 0.03, 0.03, 0.86), true)
	draw_rect(marker_rect, _get_role_color(role), true)
	if role == ROLE_STORY:
		draw_rect(marker_rect.grow(2.0), COLOR_STORY, false, 1.0)
	elif role == ROLE_SAFEHOUSE:
		draw_rect(marker_rect.grow(1.8), COLOR_SAFEHOUSE, false, 1.0)


func _project_world_position(world_position: Vector2, map_rect: Rect2) -> Vector2:
	if map_bounds.size.x <= 0.0 or map_bounds.size.y <= 0.0:
		return map_rect.get_center()
	var normalized: Vector2 = Vector2(
		clampf((world_position.x - map_bounds.position.x) / map_bounds.size.x, 0.0, 1.0),
		clampf((world_position.y - map_bounds.position.y) / map_bounds.size.y, 0.0, 1.0)
	)
	return map_rect.position + normalized * map_rect.size


func _get_role_color(role: StringName) -> Color:
	match role:
		ROLE_STORY:
			return COLOR_STORY
		ROLE_SUPPLY:
			return COLOR_SUPPLY
		ROLE_BOSS:
			return COLOR_BOSS
		ROLE_RESOURCE:
			return COLOR_RESOURCE
		ROLE_EVENT:
			return COLOR_EVENT
		ROLE_SAFEHOUSE:
			return COLOR_SAFEHOUSE
		_:
			return COLOR_ENCOUNTER


func _compare_point_priority(left: Dictionary, right: Dictionary) -> bool:
	return _get_role_priority(StringName(left.get("role", ROLE_ENCOUNTER))) < _get_role_priority(StringName(right.get("role", ROLE_ENCOUNTER)))


func _get_role_priority(role: StringName) -> int:
	match role:
		ROLE_ENCOUNTER:
			return 10
		ROLE_EVENT:
			return 20
		ROLE_SAFEHOUSE:
			return 25
		ROLE_RESOURCE:
			return 30
		ROLE_BOSS:
			return 40
		ROLE_SUPPLY:
			return 50
		ROLE_STORY:
			return 60
		_:
			return 0
