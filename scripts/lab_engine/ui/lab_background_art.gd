class_name LabBackgroundArt
extends Control

const BASE := Color("0c171d")
const UPPER_GLOW := Color("17313a")
const DESK := Color("111d20")
const DESK_EDGE := Color("765f3a")
const GRID := Color(0.31, 0.64, 0.61, 0.055)

func _ready() -> void:
	name = "LabBackgroundArt"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BASE)
	draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.42), UPPER_GLOW)
	_draw_wall_grid()
	var desk_y := size.y * 0.72
	draw_rect(Rect2(0.0, desk_y, size.x, size.y - desk_y), DESK)
	draw_rect(Rect2(0.0, desk_y, size.x, 2.0), DESK_EDGE)

func _draw_wall_grid() -> void:
	var spacing := 48.0
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y * 0.7), GRID, 1.0)
		x += spacing
	var y := 0.0
	while y <= size.y * 0.7:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), GRID, 1.0)
		y += spacing
