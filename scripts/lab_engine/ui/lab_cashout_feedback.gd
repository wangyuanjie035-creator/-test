class_name LabCashoutFeedback
extends Control

const EMERGENCY_TOTAL_DURATION := 1.37
const EMERGENCY_FINAL_SEGMENT_DURATION := 0.56

var _label: Label
var _active_tween: Tween
var _last_steps: PackedStringArray = []
var _sequence_id: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 7
	_label = Label.new()
	_label.name = "CashoutFeedbackLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_outline_color", Color("101b22"))
	_label.add_theme_constant_override("outline_size", 7)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.modulate.a = 0.0
	add_child(_label)
	_layout_label()
	get_viewport().size_changed.connect(_layout_label)

func play_emergency(progress_gained: int, value_per_chart: int = 0) -> void:
	var unit_value: int = value_per_chart if value_per_chart > 0 else progress_gained
	_last_steps = PackedStringArray(["应急补图 · 整洁 -1", "临时图 +1", "临时图 1 × %d = 论文 +%d" % [unit_value, progress_gained]])
	_stop_active()
	var sequence := _sequence_id
	await _play_step(_last_steps[0], Color("7fd8c4"), 0.18, 0.08)
	if sequence != _sequence_id: return
	await _play_step(_last_steps[1], Color("65d6ff"), 0.18, 0.08)
	if sequence != _sequence_id: return
	await _play_step(_last_steps[2], Color("ffd36a"), 0.41, 0.08)

func play_standard(charts_used: int, progress_gained: int, value_per_chart: int = 0) -> void:
	var unit_value: int = value_per_chart if value_per_chart > 0 else progress_gained / maxi(1, charts_used)
	_last_steps = PackedStringArray(["通宵兑现 · %d 图 × %d = 论文 +%d" % [charts_used, unit_value, progress_gained]])
	_stop_active()
	await _play_step(_last_steps[0], Color("9dc8d8"), 0.30, 0.12)

func play_failure(message: String) -> void:
	_last_steps = PackedStringArray([message])
	_stop_active()
	await _play_step(message, Color("e27676"), 0.24, 0.12)

func cancel() -> void:
	_stop_active()

func last_steps() -> PackedStringArray:
	return _last_steps.duplicate()

func _play_step(message: String, color: Color, hold_time: float, fade_time: float) -> void:
	_label.text = message
	_label.modulate = color
	_label.modulate.a = 0.0
	_label.position.y += 5.0
	var resting_y := _label.position.y - 5.0
	_active_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tween.set_parallel(true)
	_active_tween.tween_property(_label, "modulate:a", 1.0, 0.07)
	_active_tween.tween_property(_label, "position:y", resting_y, 0.12)
	_active_tween.chain().tween_interval(hold_time)
	_active_tween.chain().tween_property(_label, "modulate:a", 0.0, fade_time)
	await _active_tween.finished

func _stop_active() -> void:
	_sequence_id += 1
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	if _label != null:
		_label.modulate.a = 0.0

func _layout_label() -> void:
	if _label == null:
		return
	# Keep the cue over the production workspace and out of the fixed right sidebar.
	var viewport_width := get_viewport_rect().size.x
	var workspace_right := minf(viewport_width - 330.0, 970.0)
	_label.position = Vector2(30.0, 170.0)
	_label.size = Vector2(maxf(300.0, workspace_right - 30.0), 70.0)
