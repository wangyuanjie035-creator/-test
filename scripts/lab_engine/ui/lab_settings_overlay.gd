class_name LabSettingsOverlay
extends PanelContainer

signal preview_requested(settings: Dictionary)
signal settings_committed(settings: Dictionary)

const VISUAL_STYLE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")

var _settings: Dictionary = {}
var _volume_slider: HSlider
var _volume_value: Label
var _window_mode: OptionButton
var _close_button: Button
var _previous_focus: Control

func _ready() -> void:
	name = "SettingsOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 30
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_interface()

func open_settings(settings: Dictionary) -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	_previous_focus = focus_owner if focus_owner != null and not is_ancestor_of(focus_owner) else null
	_settings = settings.duplicate(true)
	_volume_slider.value = float(_settings.get("master_volume", 0.8)) * 100.0
	_window_mode.select(1 if String(_settings.get("window_mode", "windowed")) == "fullscreen" else 0)
	_update_volume_copy()
	visible = true
	_set_focus_enabled(true)
	_volume_slider.grab_focus()

func close_settings() -> void:
	if not visible:
		return
	visible = false
	_volume_slider.release_focus()
	_window_mode.release_focus()
	_close_button.release_focus()
	_set_focus_enabled(false)
	call_deferred("_restore_previous_focus")
	settings_committed.emit(_settings.duplicate(true))

func _restore_previous_focus() -> void:
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree() and _previous_focus.focus_mode != Control.FOCUS_NONE:
		_previous_focus.grab_focus()
	_previous_focus = null

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_settings()
		get_viewport().set_input_as_handled()

func _build_interface() -> void:
	add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.modal_backdrop_style(0.88))
	var center := CenterContainer.new()
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.custom_minimum_size = Vector2(440, 300)
	panel.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.modal_panel_style())
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	var title := Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	var volume_title := HBoxContainer.new()
	content.add_child(volume_title)
	var volume_label := Label.new()
	volume_label.text = "主音量"
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_title.add_child(volume_label)
	_volume_value = Label.new()
	volume_title.add_child(_volume_value)
	_volume_slider = HSlider.new()
	_volume_slider.name = "MasterVolumeSlider"
	_volume_slider.min_value = 0
	_volume_slider.max_value = 100
	_volume_slider.step = 1
	_volume_slider.value_changed.connect(_on_volume_changed)
	content.add_child(_volume_slider)
	var mode_row := HBoxContainer.new()
	content.add_child(mode_row)
	var mode_label := Label.new()
	mode_label.text = "窗口模式"
	mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_child(mode_label)
	_window_mode = OptionButton.new()
	_window_mode.name = "WindowModeOption"
	_window_mode.add_item("窗口化")
	_window_mode.add_item("全屏")
	_window_mode.item_selected.connect(_on_window_mode_selected)
	mode_row.add_child(_window_mode)
	var note := Label.new()
	note.text = "设置会在关闭面板时保存。"
	note.add_theme_color_override("font_color", Color("8fb7c9"))
	content.add_child(note)
	_close_button = Button.new()
	_close_button.name = "SettingsCloseButton"
	_close_button.text = "保存并返回"
	_close_button.pressed.connect(close_settings)
	content.add_child(_close_button)
	_volume_slider.focus_neighbor_bottom = _volume_slider.get_path_to(_window_mode)
	_window_mode.focus_neighbor_top = _window_mode.get_path_to(_volume_slider)
	_window_mode.focus_neighbor_bottom = _window_mode.get_path_to(_close_button)
	_close_button.focus_neighbor_top = _close_button.get_path_to(_window_mode)
	_close_button.focus_neighbor_bottom = _close_button.get_path_to(_volume_slider)
	_volume_slider.focus_neighbor_top = _volume_slider.get_path_to(_close_button)
	_set_focus_enabled(false)

func _on_volume_changed(value: float) -> void:
	_settings.master_volume = value / 100.0
	_update_volume_copy()
	preview_requested.emit(_settings.duplicate(true))

func _on_window_mode_selected(index: int) -> void:
	_settings.window_mode = "fullscreen" if index == 1 else "windowed"
	preview_requested.emit(_settings.duplicate(true))

func _update_volume_copy() -> void:
	_volume_value.text = "%d%%" % int(round(_volume_slider.value))

func _set_focus_enabled(enabled: bool) -> void:
	var mode := Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	_volume_slider.focus_mode = mode
	_window_mode.focus_mode = mode
	_close_button.focus_mode = mode
