extends Button
class_name DualTopicMethodCardButton

signal card_requested(hand_index: int)

var hand_index: int = -1


func setup(index: int, card: DualTopicMethodCardDefinition) -> void:
	hand_index = index
	text = "%s\n%s\n%s" % [
		card.title,
		_category_text(card.category),
		card.description,
	]
	tooltip_text = card.description
	custom_minimum_size = Vector2(174, 142)
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pressed.connect(_on_pressed)
	_apply_category_style(card.category)


func _on_pressed() -> void:
	card_requested.emit(hand_index)


func _category_text(category: DualTopicMethodCardDefinition.Category) -> String:
	match category:
		DualTopicMethodCardDefinition.Category.INVESTIGATION:
			return "调查"
		DualTopicMethodCardDefinition.Category.EXPERIMENT:
			return "试验"
		DualTopicMethodCardDefinition.Category.ORGANIZATION:
			return "组织"
		DualTopicMethodCardDefinition.Category.COLLABORATION:
			return "协作"
		DualTopicMethodCardDefinition.Category.SURVIVAL:
			return "生存"
		_:
			return "方法"


func _apply_category_style(category: DualTopicMethodCardDefinition.Category) -> void:
	var accent: Color
	match category:
		DualTopicMethodCardDefinition.Category.INVESTIGATION:
			accent = Color(0.35, 0.72, 0.82)
		DualTopicMethodCardDefinition.Category.EXPERIMENT:
			accent = Color(0.84, 0.58, 0.28)
		DualTopicMethodCardDefinition.Category.ORGANIZATION:
			accent = Color(0.40, 0.72, 0.54)
		DualTopicMethodCardDefinition.Category.COLLABORATION:
			accent = Color(0.70, 0.52, 0.80)
		DualTopicMethodCardDefinition.Category.SURVIVAL:
			accent = Color(0.72, 0.68, 0.44)
		_:
			accent = Color(0.45, 0.72, 0.66)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.08, 0.085)
	normal.border_width_left = 4
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = accent.darkened(0.15)
	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_left = 7
	normal.corner_radius_bottom_right = 7
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = accent.darkened(0.68)
	hover.border_color = accent
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("focus", hover)
	add_theme_color_override("font_hover_color", accent.lightened(0.30))
