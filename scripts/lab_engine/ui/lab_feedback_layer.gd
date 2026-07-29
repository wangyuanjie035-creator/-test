class_name LabFeedbackLayer
extends Control

var _flash: ColorRect
var _banner: Label
var _banner_tween: Tween
var _flash_tween: Tween
var _banner_base_y: float

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 8
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	add_child(_flash)
	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 34)
	_banner.add_theme_color_override("font_outline_color", Color("101b22"))
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.set_anchor(SIDE_LEFT, 0.5)
	_banner.set_anchor(SIDE_TOP, 0.5)
	_banner.set_anchor(SIDE_RIGHT, 0.5)
	_banner.set_anchor(SIDE_BOTTOM, 0.5)
	_banner.offset_left = -310
	_banner.offset_top = -54
	_banner.offset_right = 310
	_banner.offset_bottom = 54
	_banner.modulate.a = 0.0
	add_child(_banner)
	_banner_base_y = _banner.position.y

func show_feedback(message: String, color: Color, flash_strength: float = 0.08, hold_time: float = 0.34) -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_banner.text = message
	_banner.modulate = color
	_banner.modulate.a = 0.0
	_banner.position.y = _banner_base_y + 8.0
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.09)
	_banner_tween.tween_property(_banner, "position:y", _banner_base_y, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(hold_time)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.18)
	_flash.color = Color(color.r, color.g, color.b, flash_strength)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.28)
