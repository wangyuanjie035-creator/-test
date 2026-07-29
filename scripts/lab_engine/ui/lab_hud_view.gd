class_name LabHudView
extends VBoxContainer

const VISUAL_STYLE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")

signal help_requested
signal settings_requested

var _day_label: Label
var _progress_bar: ProgressBar
var _progress_text: Label
var _resource_label: Label
var _resource_values: Dictionary[StringName, Label] = {}
var _resource_panels: Dictionary[StringName, PanelContainer] = {}

func _ready() -> void:
	name = "Header"
	_build_title_row()
	_build_progress_row()

func refresh(state: RefCounted, seed: int) -> void:
	_day_label.text = "第 %d / 8 天　Seed %d" % [state.day, seed]
	_progress_bar.value = state.paper_progress
	_update_progress_text(state.paper_progress)
	_resource_label.text = "论文 %d/100　灵感 %d　原始 %d　整洁 %d　图表 %d　精力 %d　技术债 %d" % [
		state.paper_progress,
		state.inspiration,
		state.raw_data,
		state.clean_data,
		state.charts,
		state.energy,
		state.technical_debt,
	]
	var values: Dictionary[StringName, int] = {
		&"inspiration": state.inspiration, &"raw_data": state.raw_data,
		&"clean_data": state.clean_data, &"charts": state.charts,
		&"energy": state.energy, &"technical_debt": state.technical_debt,
	}
	for resource_id: StringName in values:
		_resource_values[resource_id].text = str(values[resource_id])
		var danger: bool = (resource_id == &"technical_debt" and values[resource_id] >= 7) or (resource_id == &"energy" and values[resource_id] <= 2)
		_resource_panels[resource_id].add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.resource_chip_style(danger))
		_resource_values[resource_id].add_theme_color_override("font_color", VISUAL_STYLE_SCRIPT.WARNING if danger else Color("e8eee9"))

func set_progress(value: int) -> void:
	_progress_bar.value = value
	_update_progress_text(value)

func animate_progress(value: int, duration: float = 0.22) -> void:
	_update_progress_text(value)
	var tween := create_tween()
	tween.tween_property(_progress_bar, "value", value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func progress_global_center() -> Vector2:
	return _progress_bar.get_global_rect().get_center()

func _build_title_row() -> void:
	var title_row := HBoxContainer.new()
	add_child(title_row)
	var title := Label.new()
	title.text = "博三之前 · 实验室引擎"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f2e8d2"))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_day_label = Label.new()
	_day_label.name = "DayLabel"
	_day_label.add_theme_font_size_override("font_size", 20)
	title_row.add_child(_day_label)
	var settings_button := Button.new()
	settings_button.name = "SettingsButton"
	settings_button.text = "设置"
	settings_button.pressed.connect(settings_requested.emit)
	title_row.add_child(settings_button)
	var help_button := Button.new()
	help_button.name = "HelpButton"
	help_button.text = "？玩法说明"
	help_button.pressed.connect(help_requested.emit)
	title_row.add_child(help_button)

func _build_progress_row() -> void:
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 12)
	add_child(progress_row)
	_progress_bar = ProgressBar.new()
	_progress_bar.name = "ProgressBar"
	_progress_bar.max_value = 100
	_progress_bar.custom_minimum_size = Vector2(470, 28)
	_progress_bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("172a33")
	background.border_color = Color("36515e")
	background.set_border_width_all(1)
	background.set_corner_radius_all(7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("54c6a2")
	fill.set_corner_radius_all(7)
	_progress_bar.add_theme_stylebox_override("background", background)
	_progress_bar.add_theme_stylebox_override("fill", fill)
	progress_row.add_child(_progress_bar)
	_progress_text = Label.new()
	_progress_text.name = "ProgressText"
	_progress_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_text.focus_mode = Control.FOCUS_NONE
	_progress_text.add_theme_font_size_override("font_size", 14)
	_progress_text.add_theme_color_override("font_color", Color("dce8e4"))
	_progress_text.add_theme_color_override("font_outline_color", Color("0d171c"))
	_progress_text.add_theme_constant_override("outline_size", 2)
	_progress_bar.add_child(_progress_text)
	_resource_label = Label.new()
	_resource_label.name = "ResourceLabel"
	_resource_label.visible = false
	progress_row.add_child(_resource_label)
	var strip := HBoxContainer.new()
	strip.name = "ResourceStrip"
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_theme_constant_override("separation", 6)
	progress_row.add_child(strip)
	for definition: Dictionary in [
		{"id": &"inspiration", "title": "灵感", "icon": "✦"},
		{"id": &"raw_data", "title": "原始", "icon": "◈"},
		{"id": &"clean_data", "title": "整洁", "icon": "◇"},
		{"id": &"charts", "title": "图表", "icon": "▥"},
		{"id": &"energy", "title": "精力", "icon": "⚡"},
		{"id": &"technical_debt", "title": "技术债", "icon": "△"},
	]:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.resource_chip_style())
		strip.add_child(panel)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		panel.add_child(row)
		var title := Label.new()
		title.text = "%s %s" % [definition.icon, definition.title]
		title.add_theme_font_size_override("font_size", 14)
		row.add_child(title)
		var value := Label.new()
		value.add_theme_font_size_override("font_size", 18)
		value.add_theme_color_override("font_color", VISUAL_STYLE_SCRIPT.MINT)
		row.add_child(value)
		_resource_panels[definition.id] = panel
		_resource_values[definition.id] = value

func _update_progress_text(value: int) -> void:
	if _progress_text == null:
		return
	_progress_text.text = "论文进度　%d / 100" % value
	_progress_text.add_theme_color_override("font_color", Color("fff2c7") if value >= 80 else Color("dce8e4"))
