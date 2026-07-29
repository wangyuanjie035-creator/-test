class_name LabCandidatePaperArt
extends Control

const INK_FAINT := Color(0.20, 0.27, 0.28, 0.16)
const EDGE := Color(0.34, 0.29, 0.20, 0.24)
const HOLE := Color("746c5c")

func _ready() -> void:
	name = "PaperDetail"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	for y: float in [36.0, 68.0, 100.0, 132.0]:
		if y < size.y - 8.0:
			draw_line(Vector2(12.0, y), Vector2(size.x - 12.0, y), INK_FAINT, 1.0)
	for x: float in [18.0, 31.0, 44.0]:
		draw_circle(Vector2(x, 8.0), 2.2, HOLE)
		draw_circle(Vector2(x, 8.0), 1.1, Color("312f2a"))
	var fold := PackedVector2Array([
		Vector2(size.x - 18.0, size.y),
		Vector2(size.x, size.y - 18.0),
		Vector2(size.x, size.y),
	])
	draw_colored_polygon(fold, Color("c4b996"))
	draw_line(Vector2(size.x - 18.0, size.y), Vector2(size.x, size.y - 18.0), EDGE, 1.0)
