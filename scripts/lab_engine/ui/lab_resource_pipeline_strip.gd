class_name LabResourcePipelineStrip
extends HBoxContainer

const VISUAL_STYLE := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")

const STAGES: Array[Dictionary] = [
	{"id": &"inspiration", "title": "灵感", "symbol": "✦"},
	{"id": &"raw_data", "title": "原始数据", "symbol": "◇"},
	{"id": &"clean_data", "title": "整洁数据", "symbol": "◆"},
	{"id": &"charts", "title": "图表", "symbol": "▥"},
	{"id": &"paper_progress", "title": "论文", "symbol": "▤"},
]

var _panels: Dictionary[StringName, PanelContainer] = {}
var _values: Dictionary[StringName, Label] = {}
var _status_labels: Dictionary[StringName, Label] = {}

func _ready() -> void:
	name = "ResourcePipelineStrip"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 5)
	_build_stages()

func refresh(state: RefCounted, forecast: Dictionary = {}) -> void:
	var values: Dictionary[StringName, int] = {
		&"inspiration": state.inspiration,
		&"raw_data": state.raw_data,
		&"clean_data": state.clean_data,
		&"charts": state.charts,
		&"paper_progress": state.paper_progress,
	}
	var bottleneck: StringName = _forecast_bottleneck(forecast)
	for definition: Dictionary in STAGES:
		var resource_id: StringName = definition.id
		var is_bottleneck: bool = resource_id == bottleneck
		_panels[resource_id].add_theme_stylebox_override("panel", VISUAL_STYLE.pipeline_stage_style(is_bottleneck, resource_id == &"paper_progress"))
		_values[resource_id].text = "%d/100" % values[resource_id] if resource_id == &"paper_progress" else str(values[resource_id])
		_values[resource_id].add_theme_color_override("font_color", VISUAL_STYLE.AMBER if is_bottleneck else VISUAL_STYLE.MINT)
		_status_labels[resource_id].text = "首个断点" if is_bottleneck else "库存" if resource_id != &"paper_progress" else "完成度"
		_status_labels[resource_id].add_theme_color_override("font_color", VISUAL_STYLE.WARNING if is_bottleneck else Color("8299a3"))

func _build_stages() -> void:
	for index: int in range(STAGES.size()):
		var definition: Dictionary = STAGES[index]
		if index > 0:
			var arrow: Label = Label.new()
			arrow.text = "→"
			arrow.add_theme_font_size_override("font_size", 21)
			arrow.add_theme_color_override("font_color", Color("5f9c91"))
			arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			arrow.focus_mode = Control.FOCUS_NONE
			add_child(arrow)
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(104, 62)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", VISUAL_STYLE.pipeline_stage_style(false, definition.id == &"paper_progress"))
		add_child(panel)
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 7)
		panel.add_child(row)
		var symbol: Label = Label.new()
		symbol.text = definition.symbol
		symbol.add_theme_font_size_override("font_size", 22)
		symbol.add_theme_color_override("font_color", VISUAL_STYLE.category_color(index))
		row.add_child(symbol)
		var text_stack: VBoxContainer = VBoxContainer.new()
		text_stack.add_theme_constant_override("separation", -3)
		row.add_child(text_stack)
		var heading: Label = Label.new()
		heading.text = definition.title
		heading.add_theme_font_size_override("font_size", 13)
		heading.add_theme_color_override("font_color", Color("c9d4d2"))
		text_stack.add_child(heading)
		var value: Label = Label.new()
		value.add_theme_font_size_override("font_size", 20)
		value.add_theme_color_override("font_color", VISUAL_STYLE.MINT)
		text_stack.add_child(value)
		var status: Label = Label.new()
		status.add_theme_font_size_override("font_size", 10)
		status.add_theme_color_override("font_color", Color("8299a3"))
		text_stack.add_child(status)
		var resource_id: StringName = definition.id
		_panels[resource_id] = panel
		_values[resource_id] = value
		_status_labels[resource_id] = status

func _forecast_bottleneck(forecast: Dictionary) -> StringName:
	if StringName(forecast.get("risk_reason", &"")) != &"input_shortage":
		return &""
	match int(forecast.get("risk_slot", -1)):
		1:
			return &"inspiration"
		2:
			return &"raw_data"
		3:
			return &"clean_data"
		4:
			return &"charts"
		_:
			return &""
