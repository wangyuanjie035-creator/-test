class_name LabPipelineFlow
extends Control

const FLOW_COLOR := Color(0.38, 0.84, 0.68, 0.34)
const NODE_COLOR := Color(0.48, 0.93, 0.76, 0.72)

func _ready() -> void:
	name = "PipelineFlow"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var centers: Array[Vector2] = [
		Vector2(size.x / 6.0, size.y / 4.0),
		Vector2(size.x / 2.0, size.y / 4.0),
		Vector2(size.x * 5.0 / 6.0, size.y / 4.0),
		Vector2(size.x / 6.0, size.y * 3.0 / 4.0),
		Vector2(size.x / 2.0, size.y * 3.0 / 4.0),
	]
	_draw_link(centers[0], centers[1])
	_draw_link(centers[1], centers[2])
	# The production line snakes from the upper-right data station to the
	# lower-left analysis station, matching the existing 3x2 reading layout.
	var turn_x := size.x - 3.0
	var path := PackedVector2Array([centers[2], Vector2(turn_x, centers[2].y), Vector2(turn_x, centers[3].y), centers[3]])
	draw_polyline(path, FLOW_COLOR, 3.0, true)
	_draw_direction_node(Vector2(turn_x, size.y / 2.0), Vector2.DOWN)
	_draw_link(centers[3], centers[4])

func _draw_link(start: Vector2, finish: Vector2) -> void:
	draw_line(start, finish, FLOW_COLOR, 3.0, true)
	_draw_direction_node(start.lerp(finish, 0.5), (finish - start).normalized())

func _draw_direction_node(center: Vector2, direction: Vector2) -> void:
	draw_circle(center, 5.0, Color("101b22"))
	draw_circle(center, 4.0, NODE_COLOR)
	var perpendicular := Vector2(-direction.y, direction.x)
	var tip := center + direction * 6.0
	var triangle := PackedVector2Array([tip, center - direction * 3.0 + perpendicular * 4.0, center - direction * 3.0 - perpendicular * 4.0])
	draw_colored_polygon(triangle, NODE_COLOR)
