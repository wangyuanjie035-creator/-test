class_name LabWorkstationArt
extends Control

const STYLE := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")

var slot_index: int = 0
var active: bool = true
var selected: bool = false

func setup(index: int) -> void:
	slot_index = index
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	queue_redraw()

func set_state(is_active: bool, is_selected: bool) -> void:
	active = is_active
	selected = is_selected
	queue_redraw()

func _draw() -> void:
	var accent: Color = Color("d85b5b") if not active else STYLE.AMBER if selected else STYLE.MINT
	var icon_rect := Rect2(13, 20, 50, 54)
	draw_rect(Rect2(8, 8, 59, size.y - 16), Color("101c22"), true)
	draw_rect(Rect2(8, 8, 59, size.y - 16), Color("3d5964"), false, 1.0)
	draw_rect(Rect2(11, 11, 53, size.y - 22), Color("233942"), false, 1.0)
	for screw: Vector2 in [Vector2(13, 13), Vector2(62, 13), Vector2(13, size.y - 13), Vector2(62, size.y - 13)]:
		draw_circle(screw, 1.4, Color("70858a"))
	draw_circle(Vector2(18, 17), 4.0, accent)
	draw_circle(Vector2(18, 17), 7.0, Color(accent, 0.16), false, 2.0)
	match slot_index:
		0: _draw_literature(icon_rect, accent)
		1: _draw_experiment(icon_rect, accent)
		2: _draw_data(icon_rect, accent)
		3: _draw_analysis(icon_rect, accent)
		4: _draw_writing(icon_rect, accent)
		5: _draw_rest(icon_rect, accent)
	if slot_index < 5:
		draw_line(Vector2(size.x - 13, size.y - 13), Vector2(size.x - 4, size.y - 13), Color(accent, 0.8), 2.0, true)
	draw_line(Vector2(13, size.y - 18), Vector2(62, size.y - 18), Color(STYLE.category_color(slot_index), 0.72), 2.0, true)

func _draw_literature(rect: Rect2, accent: Color) -> void:
	var left := Rect2(rect.position + Vector2(4, 14), Vector2(19, 25))
	var right := Rect2(rect.position + Vector2(25, 14), Vector2(19, 25))
	draw_rect(left, Color("d8cfb8"), true); draw_rect(right, Color("d8cfb8"), true)
	draw_line(Vector2(rect.position.x + 24, rect.position.y + 14), Vector2(rect.position.x + 24, rect.position.y + 41), accent, 2.0)
	for y: float in [20.0, 26.0, 32.0]:
		draw_line(rect.position + Vector2(8, y), rect.position + Vector2(19, y), Color("60747a"), 1.0)
		draw_line(rect.position + Vector2(29, y), rect.position + Vector2(40, y), Color("60747a"), 1.0)

func _draw_experiment(rect: Rect2, accent: Color) -> void:
	var flask := PackedVector2Array([rect.position + Vector2(18, 8), rect.position + Vector2(30, 8), rect.position + Vector2(29, 22), rect.position + Vector2(40, 42), rect.position + Vector2(8, 42), rect.position + Vector2(19, 22)])
	draw_polyline(flask, Color("b6c7ca"), 2.0, true)
	draw_line(rect.position + Vector2(12, 34), rect.position + Vector2(36, 34), accent, 3.0, true)
	draw_circle(rect.position + Vector2(19, 30), 2.0, accent)

func _draw_data(rect: Rect2, accent: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(5, 10), Vector2(39, 32)), Color("0a1519"), true)
	draw_rect(Rect2(rect.position + Vector2(5, 10), Vector2(39, 32)), Color("71868c"), false, 2.0)
	var points := PackedVector2Array([rect.position + Vector2(9, 31), rect.position + Vector2(15, 24), rect.position + Vector2(20, 29), rect.position + Vector2(27, 18), rect.position + Vector2(34, 25), rect.position + Vector2(40, 16)])
	draw_polyline(points, accent, 2.0, true)

func _draw_analysis(rect: Rect2, accent: Color) -> void:
	draw_line(rect.position + Vector2(7, 40), rect.position + Vector2(43, 40), Color("71868c"), 1.0)
	draw_line(rect.position + Vector2(7, 40), rect.position + Vector2(7, 10), Color("71868c"), 1.0)
	for point: Vector2 in [Vector2(13, 33), Vector2(20, 27), Vector2(28, 30), Vector2(35, 17), Vector2(41, 13)]:
		draw_circle(rect.position + point, 2.5, accent)
	draw_line(rect.position + Vector2(11, 35), rect.position + Vector2(42, 12), Color(accent, 0.65), 1.5, true)

func _draw_writing(rect: Rect2, accent: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(5, 17), Vector2(39, 22)), Color("1a2022"), true)
	for x: float in [10.0, 17.0, 24.0, 31.0, 38.0]:
		draw_circle(rect.position + Vector2(x, 33), 2.2, Color("b8aa88"))
	draw_rect(Rect2(rect.position + Vector2(13, 6), Vector2(25, 17)), Color("d8cfb8"), true)
	draw_line(rect.position + Vector2(17, 12), rect.position + Vector2(34, 12), accent, 1.5)

func _draw_rest(rect: Rect2, accent: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(6, 27), Vector2(38, 13)), Color("596146"), true)
	draw_rect(Rect2(rect.position + Vector2(8, 20), Vector2(15, 9)), Color("d2c4a3"), true)
	draw_line(rect.position + Vector2(7, 42), rect.position + Vector2(7, 46), accent, 2.0)
	draw_line(rect.position + Vector2(43, 42), rect.position + Vector2(43, 46), accent, 2.0)
