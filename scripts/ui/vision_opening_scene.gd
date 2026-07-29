extends Control
class_name VisionOpeningScene

const BATTLE_SCENE_PATH := "res://scenes/battle_test_scene.tscn"
const INCLINATIONS: Array[Resource] = [
	preload("res://data/inclinations/literature.tres"),
	preload("res://data/inclinations/experiment.tres"),
	preload("res://data/inclinations/sprint.tres"),
]

var selected_inclination_id: StringName = &""
var selected_button: Button
var seed_input: LineEdit
var start_button: Button
var selection_summary: Label
var inclination_buttons: Array[Button] = []


func _ready() -> void:
	_build_ui()
	inclination_buttons[0].grab_focus()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.035, 0.075, 0.09)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 52)
	margin.add_theme_constant_override("margin_bottom", 52)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)

	var eyebrow := Label.new()
	eyebrow.text = "研一 · 开题之前"
	eyebrow.add_theme_color_override("font_color", Color(0.48, 0.80, 0.72))
	eyebrow.add_theme_font_size_override("font_size", 20)
	layout.add_child(eyebrow)

	var title := Label.new()
	title.text = "这一次，你准备怎样开始研究？"
	title.add_theme_font_size_override("font_size", 38)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "研究倾向会替换两张起始牌，并在每场战斗提供一次可见的构筑触发。"
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.75, 0.76))
	subtitle.add_theme_font_size_override("font_size", 17)
	layout.add_child(subtitle)

	var choices := HBoxContainer.new()
	choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 18)
	layout.add_child(choices)

	for inclination: Resource in INCLINATIONS:
		var button := _create_inclination_button(inclination)
		choices.add_child(button)
		inclination_buttons.append(button)

	selection_summary = Label.new()
	selection_summary.text = "选择一种研究倾向。"
	selection_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_summary.add_theme_color_override("font_color", Color(0.72, 0.80, 0.80))
	selection_summary.add_theme_font_size_override("font_size", 17)
	layout.add_child(selection_summary)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)

	var seed_label := Label.new()
	seed_label.text = "Seed"
	footer.add_child(seed_label)

	seed_input = LineEdit.new()
	seed_input.text = str(VisionRun.DEFAULT_SEED)
	seed_input.custom_minimum_size = Vector2(180, 46)
	seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	seed_input.focus_mode = Control.FOCUS_ALL
	footer.add_child(seed_input)

	start_button = Button.new()
	start_button.text = "带着这个方法出发"
	start_button.custom_minimum_size = Vector2(260, 48)
	start_button.disabled = true
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.pressed.connect(_on_start_pressed)
	footer.add_child(start_button)


func _create_inclination_button(inclination: Resource) -> Button:
	var button := Button.new()
	button.name = "Inclination_%s" % String(inclination.id)
	button.text = "%s\n\n%s\n\n%s" % [
		inclination.display_name,
		inclination.description,
		inclination.rule_text,
	]
	button.tooltip_text = "移除：%s\n加入：%s" % [
		", ".join(inclination.remove_card_ids),
		", ".join(inclination.add_card_ids),
	]
	button.custom_minimum_size = Vector2(0, 260)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_stretch_ratio = 1.0
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_hover_color", inclination.accent_color)
	button.add_theme_color_override("font_focus_color", inclination.accent_color)
	button.pressed.connect(_on_inclination_selected.bind(inclination, button))
	return button


func _on_inclination_selected(inclination: Resource, button: Button) -> void:
	selected_inclination_id = inclination.id
	selected_button = button
	selection_summary.text = "已选择 %s：%s" % [
		inclination.display_name,
		inclination.rule_text,
	]
	selection_summary.add_theme_color_override("font_color", inclination.accent_color)
	start_button.disabled = false
	start_button.grab_focus()


func _on_start_pressed() -> void:
	var parsed_seed := int(seed_input.text)
	if parsed_seed <= 0:
		parsed_seed = VisionRun.DEFAULT_SEED
		seed_input.text = str(parsed_seed)
	if not VisionRun.begin_run(selected_inclination_id, parsed_seed):
		return
	var change_error := get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
	if change_error != OK:
		push_error("VisionOpeningScene: failed to enter battle (%s)." % error_string(change_error))
