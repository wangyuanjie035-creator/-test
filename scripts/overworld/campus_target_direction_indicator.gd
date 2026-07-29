@tool
extends Control
class_name CampusTargetDirectionIndicator

const INDICATOR_SIZE: Vector2 = Vector2(52, 52)
const BASE_COLOR := Color(0.42, 0.88, 0.96)
const EMPHASIS_COLOR := Color(0.72, 0.96, 1.0)
const DISCOVERY_COLOR := Color(0.88, 1.0, 0.92)

@export var direction: Vector2 = Vector2.RIGHT
@export var emphasized: bool = false
@export var discovery_active: bool = false

var _pulse_time: float = 0.0


func _ready() -> void:
	custom_minimum_size = INDICATOR_SIZE
	size = INDICATOR_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_process_state()
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_time = fposmod(_pulse_time + delta * 3.0, TAU)
	queue_redraw()


func configure(new_visible: bool, new_direction: Vector2, new_emphasized: bool = false, new_discovery_active: bool = false) -> void:
	visible = new_visible
	if new_direction.length_squared() > 0.001:
		direction = new_direction.normalized()
	emphasized = new_emphasized
	discovery_active = new_discovery_active
	_refresh_process_state()
	queue_redraw()


func get_indicator_direction() -> Vector2:
	return direction


func _refresh_process_state() -> void:
	set_process(visible)


func _draw() -> void:
	if not visible:
		return

	var center: Vector2 = size * 0.5
	var forward: Vector2 = direction.normalized()
	if forward.length_squared() <= 0.001:
		forward = Vector2.RIGHT
	var side: Vector2 = Vector2(-forward.y, forward.x)
	var pulse: float = (sin(_pulse_time) + 1.0) * 0.5
	var discovery_pulse: float = (sin(_pulse_time * 1.65 + 0.9) + 1.0) * 0.5
	var accent: Color = BASE_COLOR
	if emphasized:
		accent = EMPHASIS_COLOR
	if discovery_active:
		accent = DISCOVERY_COLOR
	var glow: Color = accent
	if discovery_active:
		glow.a = 0.22 + 0.22 * discovery_pulse
	else:
		glow.a = 0.18 + 0.16 * pulse
	var body_color: Color = accent
	if discovery_active:
		body_color.a = 0.90 + 0.10 * discovery_pulse
	else:
		body_color.a = 0.84 + 0.12 * pulse
	var shadow_color: Color = Color(0.02, 0.04, 0.05, 0.72)

	var glow_size: float = 38.0 if discovery_active else 32.0
	draw_rect(Rect2(center - Vector2(glow_size, glow_size) * 0.5, Vector2(glow_size, glow_size)), glow)
	draw_rect(Rect2(center - Vector2(13, 13), Vector2(26, 26)), shadow_color)

	var tail: Vector2 = center - forward * 12.0
	var neck: Vector2 = center + forward * 4.0
	var tip: Vector2 = center + forward * 18.0
	var body_points: PackedVector2Array = PackedVector2Array([
		tail + side * 4.0,
		neck + side * 4.0,
		neck - side * 4.0,
		tail - side * 4.0,
	])
	var head_points: PackedVector2Array = PackedVector2Array([
		tip,
		center + forward * 2.0 + side * 11.0,
		center + forward * 2.0 - side * 11.0,
	])

	draw_polygon(body_points, PackedColorArray([body_color, body_color, body_color, body_color]))
	draw_polygon(head_points, PackedColorArray([body_color, body_color, body_color]))
	if discovery_active:
		_draw_discovery_ticks(center, forward, side, discovery_pulse)
	draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), Color(0.94, 0.98, 0.96, 0.82))


func _draw_discovery_ticks(center: Vector2, forward: Vector2, side: Vector2, pulse: float) -> void:
	var tick_color: Color = DISCOVERY_COLOR
	tick_color.a = 0.58 + 0.28 * pulse
	var ahead: Vector2 = center + forward * (22.0 + 3.0 * pulse)
	var left: Vector2 = center + side * 19.0
	var right: Vector2 = center - side * 19.0
	draw_rect(Rect2(ahead - side * 5.0 - forward * 2.0, Vector2(10, 4)), tick_color)
	draw_rect(Rect2(left - side * 2.0 - forward * 4.0, Vector2(4, 8)), tick_color)
	draw_rect(Rect2(right + side * 2.0 - forward * 4.0, Vector2(4, 8)), tick_color)
