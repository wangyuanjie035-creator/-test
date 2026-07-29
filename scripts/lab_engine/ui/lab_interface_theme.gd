class_name LabInterfaceTheme
extends RefCounted

const INK_LIGHT := Color("e8eee9")
const INK_MUTED := Color("8fa8af")
const MINT := Color("62d5ad")
const PANEL := Color("17272f")
const PANEL_HOVER := Color("203943")
const PANEL_PRESSED := Color("102027")

static var _cached_theme: Theme

static func create() -> Theme:
	if _cached_theme != null:
		return _cached_theme
	var theme := Theme.new()
	theme.set_color("font_color", "Label", INK_LIGHT)
	theme.set_color("font_disabled_color", "Label", INK_MUTED)
	theme.set_font_size("font_size", "Label", 16)
	_apply_button_family(theme, "Button")
	_apply_button_family(theme, "OptionButton")
	theme.set_color("font_color", "RichTextLabel", INK_LIGHT)
	theme.set_color("default_color", "RichTextLabel", INK_LIGHT)
	theme.set_font_size("normal_font_size", "RichTextLabel", 15)
	_cached_theme = theme
	return theme

static func _apply_button_family(theme: Theme, type_name: String) -> void:
	theme.set_color("font_color", type_name, INK_LIGHT)
	theme.set_color("font_hover_color", type_name, Color.WHITE)
	theme.set_color("font_pressed_color", type_name, Color("fff2c7"))
	theme.set_color("font_focus_color", type_name, Color.WHITE)
	theme.set_color("font_disabled_color", type_name, INK_MUTED.darkened(0.25))
	theme.set_font_size("font_size", type_name, 16)
	theme.set_stylebox("normal", type_name, _button_style(PANEL, Color("38545f"), 1))
	theme.set_stylebox("hover", type_name, _button_style(PANEL_HOVER, MINT.darkened(0.2), 2))
	theme.set_stylebox("pressed", type_name, _button_style(PANEL_PRESSED, MINT, 2))
	theme.set_stylebox("disabled", type_name, _button_style(Color("151d21"), Color("2b393e"), 1))
	theme.set_stylebox("focus", type_name, _focus_style())

static func _button_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

static func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("fff2c7")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.expand_margin_left = 2
	style.expand_margin_right = 2
	style.expand_margin_top = 2
	style.expand_margin_bottom = 2
	return style
