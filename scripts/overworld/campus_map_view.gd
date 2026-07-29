@tool
extends Node2D
class_name CampusMapView

const TILE_SIZE: int = 32
const MAP_SIZE: Vector2 = Vector2(1600, 960)

var building_defs: Array[Dictionary] = [
	{
		"name": "宿舍",
		"rect": Rect2(Vector2(96, 96), Vector2(220, 144)),
		"color": Color(0.32, 0.42, 0.62),
		"roof": Color(0.20, 0.27, 0.45),
	},
	{
		"name": "图书馆",
		"rect": Rect2(Vector2(560, 88), Vector2(260, 160)),
		"color": Color(0.56, 0.48, 0.36),
		"roof": Color(0.36, 0.28, 0.20),
	},
	{
		"name": "实验楼",
		"rect": Rect2(Vector2(1110, 96), Vector2(280, 176)),
		"color": Color(0.38, 0.52, 0.54),
		"roof": Color(0.22, 0.34, 0.36),
	},
	{
		"name": "食堂",
		"rect": Rect2(Vector2(150, 620), Vector2(240, 148)),
		"color": Color(0.64, 0.45, 0.30),
		"roof": Color(0.44, 0.26, 0.18),
	},
	{
		"name": "导师办公室",
		"rect": Rect2(Vector2(710, 608), Vector2(220, 152)),
		"color": Color(0.45, 0.42, 0.58),
		"roof": Color(0.28, 0.24, 0.40),
	},
	{
		"name": "会议室",
		"rect": Rect2(Vector2(1170, 612), Vector2(240, 156)),
		"color": Color(0.50, 0.56, 0.42),
		"roof": Color(0.30, 0.36, 0.25),
	},
]


func _ready() -> void:
	queue_redraw()


func get_map_bounds() -> Rect2:
	return Rect2(Vector2(32, 32), MAP_SIZE - Vector2(64, 64))


func get_map_size() -> Vector2:
	return MAP_SIZE


func get_site_positions() -> Dictionary:
	return {
		&"dorm": Vector2(210, 284),
		&"library": Vector2(690, 292),
		&"lab": Vector2(1250, 320),
		&"canteen": Vector2(270, 812),
		&"advisor": Vector2(820, 812),
		&"conference": Vector2(1290, 824),
		&"quad": Vector2(800, 500),
	}


func _draw() -> void:
	_draw_ground()
	_draw_paths()
	for building: Dictionary in building_defs:
		_draw_building(building)
	_draw_border()


func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.18, 0.34, 0.27))
	for x: int in range(0, int(MAP_SIZE.x), TILE_SIZE):
		for y: int in range(0, int(MAP_SIZE.y), TILE_SIZE):
			var tint: Color = Color(0.20, 0.38, 0.29)
			if int((x / TILE_SIZE) + (y / TILE_SIZE)) % 2 == 0:
				tint = Color(0.22, 0.41, 0.31)
			draw_rect(Rect2(Vector2(x, y), Vector2(TILE_SIZE, TILE_SIZE)), tint)


func _draw_paths() -> void:
	var path_color: Color = Color(0.58, 0.54, 0.44)
	var path_shadow: Color = Color(0.38, 0.36, 0.30)
	var paths: Array[Rect2] = [
		Rect2(Vector2(760, 0), Vector2(64, MAP_SIZE.y)),
		Rect2(Vector2(0, 444), Vector2(MAP_SIZE.x, 64)),
		Rect2(Vector2(220, 240), Vector2(56, 380)),
		Rect2(Vector2(1248, 272), Vector2(56, 360)),
		Rect2(Vector2(0, 292), Vector2(MAP_SIZE.x, 48)),
		Rect2(Vector2(0, 792), Vector2(MAP_SIZE.x, 48)),
	]
	for path: Rect2 in paths:
		draw_rect(path.grow(2), path_shadow)
		draw_rect(path, path_color)


func _draw_building(building: Dictionary) -> void:
	var rect: Rect2 = building.get("rect", Rect2())
	var color: Color = building.get("color", Color.WHITE)
	var roof: Color = building.get("roof", color.darkened(0.25))
	draw_rect(rect.grow(4), Color(0.10, 0.14, 0.16, 0.75))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 24)), roof)
	draw_rect(Rect2(rect.position + Vector2(0, 24), rect.size - Vector2(0, 24)), color)
	for window_x: int in range(int(rect.position.x + 24), int(rect.end.x - 16), 40):
		draw_rect(Rect2(Vector2(window_x, rect.position.y + 48), Vector2(14, 14)), Color(0.84, 0.82, 0.54))
	for door_x: int in [int(rect.position.x + rect.size.x * 0.5 - 12)]:
		draw_rect(Rect2(Vector2(door_x, rect.end.y - 34), Vector2(24, 34)), Color(0.16, 0.12, 0.10))


func _draw_border() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.07, 0.10, 0.12), false, 6.0)
