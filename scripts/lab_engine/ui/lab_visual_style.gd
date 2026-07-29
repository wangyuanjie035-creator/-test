class_name LabVisualStyle
extends RefCounted

const PAPER := Color("d8cfb8")
const PAPER_HOVER := Color("e8dfc7")
const INK := Color("263238")
const METAL := Color("17272f")
const METAL_RAISED := Color("203943")
const MINT := Color("62d5ad")
const AMBER := Color("e6a84a")
const WARNING := Color("ef7546")
static var _workstation_cache: Dictionary = {}
static var _paper_cache: Dictionary = {}
static var _chip_cache: Dictionary = {}
static var _pipeline_cache: Dictionary = {}

static func workbench_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14252cdd")
	style.border_color = Color("35545d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 5
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func workstation_style(selected: bool, stopped: bool, interaction: StringName = &"normal") -> StyleBoxFlat:
	var key := "%s:%s:%s" % [selected, stopped, interaction]
	if _workstation_cache.has(key):
		return _workstation_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = Color("3b2026") if stopped else Color("3e3323") if selected else METAL_RAISED
	if interaction == &"hover" and not stopped:
		style.bg_color = style.bg_color.lightened(0.08)
	elif interaction == &"pressed" and not stopped:
		style.bg_color = style.bg_color.darkened(0.08)
	style.border_color = Color("d85b5b") if stopped else AMBER if selected else Color("486b78")
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.content_margin_left = 76
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 9
	_workstation_cache[key] = style
	return style

static func workstation_badge_style(kind: StringName) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match kind:
		&"stopped":
			style.bg_color = Color("9e3f46")
		&"selected":
			style.bg_color = Color("9a6a27")
		&"online":
			style.bg_color = Color("24594f")
		&"rest":
			style.bg_color = Color("4c5345")
		_:
			style.bg_color = Color("17272f")
	style.border_color = Color("ffffff22")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

static func paper_card_style(hovered: bool = false, pressed: bool = false, selected: bool = false) -> StyleBoxFlat:
	var key := "%s:%s:%s" % [hovered, pressed, selected]
	if _paper_cache.has(key):
		return _paper_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ead9ad") if selected else PAPER_HOVER if hovered else PAPER
	if pressed:
		style.bg_color = Color("cbbd99")
	style.border_color = AMBER if selected else Color("8c8065")
	style.set_border_width_all(3 if selected else 2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_paper_cache[key] = style
	return style

static func paper_card_disabled_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER.darkened(0.16)
	style.border_color = Color("6f695b")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func candidate_badge_style(category_id: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = category_color(category_id).darkened(0.35)
	style.set_corner_radius_all(3)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

static func candidate_action_style(action_hint: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("a8cdbb") if action_hint == "升级" else Color("d8b36d") if action_hint == "替换" else Color("c7d3ce")
	style.set_corner_radius_all(3)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

static func resource_chip_style(danger: bool = false) -> StyleBoxFlat:
	var key := "danger" if danger else "normal"
	if _chip_cache.has(key):
		return _chip_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = Color("18272e")
	style.border_color = WARNING if danger else Color("38545f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	_chip_cache[key] = style
	return style

static func pipeline_stage_style(bottleneck: bool = false, terminal: bool = false) -> StyleBoxFlat:
	var key := "%s:%s" % [bottleneck, terminal]
	if _pipeline_cache.has(key):
		return _pipeline_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21333a") if not terminal else Color("24362f")
	style.border_color = WARNING if bottleneck else MINT if terminal else Color("3e6870")
	style.set_border_width_all(2 if bottleneck else 1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_pipeline_cache[key] = style
	return style

static func notebook_cover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("171d1ddd")
	style.border_color = Color("8a7248")
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_bottom_left = 3
	style.content_margin_left = 14
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 6
	return style

static func modal_backdrop_style(alpha: float = 0.78) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.05, clampf(alpha, 0.0, 1.0))
	return style

static func modal_panel_style(accent: Color = MINT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182a33")
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	return style

static func result_sheet_style(kind: StringName) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match kind:
		&"archived":
			style.bg_color = Color("d8cfb8")
			style.border_color = MINT.darkened(0.18)
		&"interrupted":
			style.bg_color = Color("c6c9c6")
			style.border_color = WARNING
		_:
			style.bg_color = Color("d3c39b")
			style.border_color = AMBER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 8
	return style

static func result_stamp_style(kind: StringName) -> StyleBoxFlat:
	var accent := MINT.darkened(0.30) if kind == &"archived" else WARNING.darkened(0.12) if kind == &"interrupted" else AMBER.darkened(0.24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent, 0.10)
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func result_ink_color(kind: StringName) -> Color:
	return Color("263238") if kind != &"interrupted" else Color("30383c")

static func result_accent_color(kind: StringName) -> Color:
	return MINT.darkened(0.30) if kind == &"archived" else WARNING.darkened(0.12) if kind == &"interrupted" else AMBER.darkened(0.24)

static func category_color(slot: int) -> Color:
	return [Color("7bb8a8"), Color("d49d59"), Color("6fa8bd"), Color("79b98d"), Color("b89a72"), Color("8b9279")][clampi(slot, 0, 5)]
