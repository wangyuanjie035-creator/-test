class_name LabResultSheetArt
extends Control

var archive_kind: StringName = &"revision"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_archive_kind(value: StringName) -> void:
	archive_kind = value
	queue_redraw()

func _draw() -> void:
	var line_color := Color("87a7a214")
	if archive_kind == &"interrupted":
		line_color = Color("b8c2c817")
	elif archive_kind == &"revision":
		line_color = Color("b79b6418")
	for y: float in range(92, int(size.y) - 54, 30):
		draw_line(Vector2(24, y), Vector2(size.x - 24, y), line_color, 1.0)
	var corner_color := Color("62d5ad22") if archive_kind == &"archived" else Color("ef754622") if archive_kind == &"interrupted" else Color("e6a84a22")
	draw_line(Vector2(18, 54), Vector2(18, size.y - 24), corner_color, 2.0)
	draw_line(Vector2(size.x - 18, 54), Vector2(size.x - 18, size.y - 24), corner_color, 2.0)
