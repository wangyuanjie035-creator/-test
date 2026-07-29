@tool
extends CharacterBody2D
class_name CampusPlayer

@export var speed: float = 150.0
@export var acceleration: float = 900.0
@export var friction: float = 1000.0
@export var map_bounds: Rect2 = Rect2(Vector2(32, 32), Vector2(896, 576))

var movement_enabled: bool = true
var facing_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	_ensure_collision_shape()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir != Vector2.ZERO:
		facing_direction = input_dir
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_clamp_to_map_bounds()


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func _clamp_to_map_bounds() -> void:
	var bounds_end: Vector2 = map_bounds.position + map_bounds.size
	position = Vector2(
		clampf(position.x, map_bounds.position.x, bounds_end.x),
		clampf(position.y, map_bounds.position.y, bounds_end.y)
	)


func _ensure_collision_shape() -> void:
	for child: Node in get_children():
		if child is CollisionShape2D:
			return

	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(18, 22)
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)


func _draw() -> void:
	draw_rect(Rect2(Vector2(-8, -12), Vector2(16, 24)), Color(0.08, 0.12, 0.18))
	draw_rect(Rect2(Vector2(-7, -11), Vector2(14, 10)), Color(0.82, 0.66, 0.50))
	draw_rect(Rect2(Vector2(-8, -1), Vector2(16, 15)), Color(0.20, 0.42, 0.66))
	draw_rect(Rect2(Vector2(-10, 1), Vector2(4, 12)), Color(0.12, 0.22, 0.36))
	draw_rect(Rect2(Vector2(6, 1), Vector2(4, 12)), Color(0.12, 0.22, 0.36))
	draw_rect(Rect2(Vector2(-6, 14), Vector2(5, 6)), Color(0.10, 0.10, 0.12))
	draw_rect(Rect2(Vector2(1, 14), Vector2(5, 6)), Color(0.10, 0.10, 0.12))
