class_name LabTokenView
extends Label

func play(message: String, color: Color, start_position: Vector2, end_position: Vector2) -> void:
	text = message
	modulate = color
	global_position = start_position
	z_index = 6
	add_theme_font_size_override("font_size", 17)
	add_theme_color_override("font_outline_color", Color("101b22"))
	add_theme_constant_override("outline_size", 5)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", end_position, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.42).set_delay(0.18)
	await tween.finished
	queue_free()
