class_name ResearchCardButton
extends Button

const STAGE_NAMES: PackedStringArray = ["文献", "假设", "实验", "数据", "分析", "论文"]
const ARCHETYPE_COLORS: Dictionary = {
	&"general": Color("d8dedb"), &"replication": Color("80bfff"),
	&"negative": Color("c79cff"), &"legacy": Color("f3ad62"),
}

var definition: ResearchCardDefinition

func setup(card: ResearchCardDefinition) -> void:
	definition = card
	text = "%s\n[%s]  %d 分\n%s" % [card.display_name, STAGE_NAMES[card.stage], card.base_score, card.rules_text]
	custom_minimum_size = Vector2(148, 118)
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_theme_color_override("font_color", Color("17201d"))
	add_theme_color_override("font_hover_color", Color("17201d"))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ARCHETYPE_COLORS.get(card.archetype, Color.WHITE)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("31423c")
	add_theme_stylebox_override("normal", style)

