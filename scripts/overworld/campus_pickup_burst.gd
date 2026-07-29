extends Node2D
class_name CampusPickupBurst

const LIFETIME := 0.55
const SPARK_OFFSETS: Array[Vector2] = [
	Vector2(-4, -14),
	Vector2(8, -12),
	Vector2(14, -4),
	Vector2(10, 8),
	Vector2(-6, 12),
	Vector2(-14, 4),
	Vector2(-12, -8),
	Vector2(0, 0),
]
const SPARK_DIRECTIONS: Array[Vector2] = [
	Vector2(-0.35, -1.00),
	Vector2(0.55, -0.90),
	Vector2(1.00, -0.15),
	Vector2(0.70, 0.65),
	Vector2(-0.20, 1.00),
	Vector2(-0.95, 0.35),
	Vector2(-0.70, -0.70),
	Vector2(0.00, -0.60),
]

var accent_color: Color = Color(0.98, 0.82, 0.32)
var _age: float = 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func configure(new_accent_color: Color) -> void:
	accent_color = new_accent_color
	queue_redraw()


func get_lifetime_progress() -> float:
	return clampf(_age / LIFETIME, 0.0, 1.0)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = get_lifetime_progress()
	var fade: float = 1.0 - progress
	_draw_flash_ring(progress, fade)
	_draw_sparks(progress, fade)


func _draw_flash_ring(progress: float, fade: float) -> void:
	var ring_color: Color = accent_color.lightened(0.24)
	ring_color.a = 0.42 * fade
	var half_size: float = 13.0 + 10.0 * progress
	draw_rect(Rect2(Vector2(-half_size, -half_size), Vector2(8, 3)), ring_color)
	draw_rect(Rect2(Vector2(half_size - 8, -half_size), Vector2(8, 3)), ring_color)
	draw_rect(Rect2(Vector2(-half_size, half_size - 3), Vector2(8, 3)), ring_color)
	draw_rect(Rect2(Vector2(half_size - 8, half_size - 3), Vector2(8, 3)), ring_color)
	draw_rect(Rect2(Vector2(-half_size, -half_size), Vector2(3, 8)), ring_color)
	draw_rect(Rect2(Vector2(half_size - 3, -half_size), Vector2(3, 8)), ring_color)
	draw_rect(Rect2(Vector2(-half_size, half_size - 8), Vector2(3, 8)), ring_color)
	draw_rect(Rect2(Vector2(half_size - 3, half_size - 8), Vector2(3, 8)), ring_color)


func _draw_sparks(progress: float, fade: float) -> void:
	var spark_color: Color = accent_color.lightened(0.36)
	spark_color.a = 0.88 * fade
	var core_color: Color = Color(1.0, 0.98, 0.76, 0.80 * fade)
	for index: int in range(SPARK_OFFSETS.size()):
		var offset: Vector2 = SPARK_OFFSETS[index] + SPARK_DIRECTIONS[index] * (18.0 * progress)
		var size: float = 4.0 if index % 2 == 0 else 3.0
		size = max(2.0, size - 1.5 * progress)
		var color: Color = core_color if index == SPARK_OFFSETS.size() - 1 else spark_color
		draw_rect(Rect2(offset - Vector2(size * 0.5, size * 0.5), Vector2(size, size)), color)
