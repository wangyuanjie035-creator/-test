class_name LabResultOverlay
extends PanelContainer

signal retry_requested(seed: int)
signal fresh_seed_requested(seed: int)

const RESULT_ANALYZER_SCRIPT := preload("res://scripts/lab_engine/ui/lab_result_analyzer.gd")
const VISUAL_STYLE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")
const RESULT_SHEET_ART_SCRIPT := preload("res://scripts/lab_engine/ui/lab_result_sheet_art.gd")
const VICTORY_ENTRY_DURATION: float = 0.20
const FAILURE_ENTRY_DURATION: float = 0.14
const VICTORY_BUTTON_LOCK_DURATION: float = 0.70
const FAILURE_BUTTON_LOCK_DURATION: float = 0.32

var _current_seed: int = 1
var _title: Label
var _archive_meta: Label
var _result_stamp: PanelContainer
var _result_stamp_label: Label
var _sheet_art: Control
var _summary_box: VBoxContainer
var _summary_scroll: ScrollContainer
var _result_panel: PanelContainer
var _retry_button: Button
var _fresh_button: Button
var _entry_tween: Tween
var _current_archive_kind: StringName = &"revision"

func _ready() -> void:
	name = "ResultOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", _backdrop_style())
	_build_persistent_content()
	_set_focus_enabled(false)
	visible = false

func present(state: RefCounted, won: bool, seed: int, history: Array[Dictionary] = [], topic: Dictionary = {}) -> void:
	_current_seed = seed
	_title.text = "论文完成！" if won else "DDL 到了"
	var diagnosis: Dictionary = {} if won else RESULT_ANALYZER_SCRIPT.new().analyze(state, history)
	var archive_kind := _archive_kind(won, diagnosis)
	_apply_archive_presentation(archive_kind, seed, state, history)
	_clear_summary()
	_build_summary(_summary_box, state, won, history, topic)
	visible = true
	_set_focus_enabled(true)
	_play_entry(won)

func reset() -> void:
	_kill_entry_tween()
	_set_buttons_locked(true)
	_retry_button.release_focus()
	_fresh_button.release_focus()
	_result_panel.modulate = Color.WHITE
	_set_focus_enabled(false)
	visible = false
	_clear_summary()

func _build_persistent_content() -> void:
	var center := CenterContainer.new()
	center.name = "ResultCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_result_panel = PanelContainer.new()
	_result_panel.name = "ResultPanel"
	_result_panel.custom_minimum_size = Vector2(560, 420)
	_result_panel.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.result_sheet_style(&"revision"))
	center.add_child(_result_panel)
	_sheet_art = RESULT_SHEET_ART_SCRIPT.new()
	_sheet_art.name = "ResultSheetArt"
	_result_panel.add_child(_sheet_art)
	var box := VBoxContainer.new()
	box.name = "ResultVBox"
	box.add_theme_constant_override("separation", 14)
	_result_panel.add_child(box)
	var archive_header := HBoxContainer.new()
	archive_header.name = "ArchiveHeader"
	archive_header.add_theme_constant_override("separation", 16)
	box.add_child(archive_header)
	var heading_box := VBoxContainer.new()
	heading_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_box.add_theme_constant_override("separation", 3)
	archive_header.add_child(heading_box)
	_archive_meta = Label.new()
	_archive_meta.name = "ArchiveMetaLabel"
	_archive_meta.add_theme_font_size_override("font_size", 12)
	_archive_meta.add_theme_color_override("font_color", Color("5b6664"))
	heading_box.add_child(_archive_meta)
	_title = Label.new()
	_title.name = "ResultTitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.add_theme_font_size_override("font_size", 30)
	heading_box.add_child(_title)
	_result_stamp = PanelContainer.new()
	_result_stamp.name = "ResultStamp"
	_result_stamp.custom_minimum_size = Vector2(112, 48)
	archive_header.add_child(_result_stamp)
	var stamp_center := CenterContainer.new()
	_result_stamp.add_child(stamp_center)
	_result_stamp_label = Label.new()
	_result_stamp_label.name = "ResultStampLabel"
	_result_stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_stamp_label.add_theme_font_size_override("font_size", 17)
	stamp_center.add_child(_result_stamp_label)
	_summary_scroll = ScrollContainer.new()
	_summary_scroll.name = "ResultSummaryScroll"
	_summary_scroll.custom_minimum_size = Vector2(0, 190)
	_summary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_scroll.focus_mode = Control.FOCUS_ALL
	_summary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_summary_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(_summary_scroll)
	_summary_box = VBoxContainer.new()
	_summary_box.name = "ResultSummary"
	_summary_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_box.add_theme_constant_override("separation", 14)
	_summary_scroll.add_child(_summary_box)
	_retry_button = Button.new()
	_retry_button.name = "RetryButton"
	_retry_button.text = "相同 Seed 再来一次"
	_retry_button.pressed.connect(_request_retry)
	box.add_child(_retry_button)
	_fresh_button = Button.new()
	_fresh_button.name = "FreshSeedButton"
	_fresh_button.text = "换一个 Seed"
	_fresh_button.pressed.connect(_request_fresh_seed)
	box.add_child(_fresh_button)
	_summary_scroll.focus_neighbor_top = _summary_scroll.get_path_to(_fresh_button)
	_summary_scroll.focus_neighbor_bottom = _summary_scroll.get_path_to(_retry_button)
	_summary_scroll.focus_next = _summary_scroll.get_path_to(_retry_button)
	_summary_scroll.focus_previous = _summary_scroll.get_path_to(_fresh_button)
	_retry_button.focus_neighbor_top = _retry_button.get_path_to(_summary_scroll)
	_retry_button.focus_neighbor_bottom = _retry_button.get_path_to(_fresh_button)
	_retry_button.focus_next = _retry_button.get_path_to(_fresh_button)
	_retry_button.focus_previous = _retry_button.get_path_to(_summary_scroll)
	_fresh_button.focus_neighbor_top = _fresh_button.get_path_to(_retry_button)
	_fresh_button.focus_neighbor_bottom = _fresh_button.get_path_to(_summary_scroll)
	_fresh_button.focus_next = _fresh_button.get_path_to(_summary_scroll)
	_fresh_button.focus_previous = _fresh_button.get_path_to(_retry_button)
	_set_buttons_locked(true)

func _summary_text(state: RefCounted, won: bool, history: Array[Dictionary]) -> String:
	var text: String = "论文 %d/100\n总触发 %d · 最大连锁 %d · 最高单日进度 %d\n最终技术债 %d" % [
		state.paper_progress,
		state.total_triggers,
		state.highest_combo,
		state.highest_daily_progress,
		state.technical_debt,
	]
	if not won:
		var diagnosis: Dictionary = RESULT_ANALYZER_SCRIPT.new().analyze(state, history)
		text += "\n\n%s\n%s\n主要断点：%s\n建议：%s" % [
			diagnosis.title,
			diagnosis.last_day_line,
			diagnosis.cause,
			diagnosis.advice,
		]
	return text

func _build_summary(box: VBoxContainer, state: RefCounted, won: bool, history: Array[Dictionary], topic: Dictionary = {}) -> void:
	if not won:
		var summary := _label(_summary_text(state, false, history), 19)
		summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(summary)
		_add_topic_summary(box, topic)
		return
	var victory: Dictionary = RESULT_ANALYZER_SCRIPT.new().analyze_victory(state, history)
	var final_value := _label("论文 %d/100" % int(state.paper_progress), 28)
	final_value.name = "FinalProgressLabel"
	final_value.add_theme_color_override("font_color", VISUAL_STYLE_SCRIPT.result_accent_color(_current_archive_kind))
	box.add_child(final_value)
	var key_lines := PackedStringArray(["本局制胜点", String(victory.last_day_line)])
	if not String(victory.cashout_line).is_empty():
		key_lines.append(String(victory.cashout_line))
	if not String(victory.maintenance_line).is_empty():
		key_lines.append(String(victory.maintenance_line))
	var key_point := _label("\n".join(key_lines), 20)
	key_point.name = "VictoryKeyPointLabel"
	key_point.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(key_point)
	var stats := _label("总触发 %d · 最大连锁 %d · 最高单日 %d · 最终技术债 %d" % [state.total_triggers, state.highest_combo, state.highest_daily_progress, state.technical_debt], 16)
	stats.name = "RunStatsLabel"
	box.add_child(stats)
	_add_topic_summary(box, topic)

func _add_topic_summary(box: VBoxContainer, topic: Dictionary) -> void:
	if topic.is_empty():
		return
	var status: StringName = StringName(topic.get("status", &"active"))
	var line := "累计课题 · %s：%d/%d" % [topic.get("title", ""), int(topic.get("progress", 0)), int(topic.get("target", 0))]
	if status == &"rewarded":
		var settled: Dictionary = topic.get("settlement", {})
		line += " · 已完成，%s +%d" % [topic.get("reward_resource_name", ""), int(settled.get("actual", 0))]
	elif status == &"missed":
		line += " · 未完成（无惩罚）"
	else:
		line += " · 未到结算日"
	var label := _label(line, 15)
	label.name = "TopicResultLabel"
	box.add_child(label)

func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", VISUAL_STYLE_SCRIPT.result_ink_color(_current_archive_kind))
	return label

func _archive_kind(won: bool, diagnosis: Dictionary) -> StringName:
	if won:
		return &"archived"
	return &"interrupted" if int(diagnosis.get("stopped_slot", -1)) >= 0 else &"revision"

func _apply_archive_presentation(kind: StringName, seed: int, state: RefCounted, history: Array[Dictionary]) -> void:
	_current_archive_kind = kind
	var settled_day: int = int(history.back().get("day", history.size())) if not history.is_empty() else maxi(1, int(state.day) - 1)
	_archive_meta.text = "研究结项档案  ·  Seed %d  ·  结算日 D%02d" % [seed, settled_day]
	_result_stamp_label.text = "已归档" if kind == &"archived" else "生产中断" if kind == &"interrupted" else "退回修改"
	var ink: Color = VISUAL_STYLE_SCRIPT.result_ink_color(kind)
	var accent: Color = VISUAL_STYLE_SCRIPT.result_accent_color(kind)
	_result_panel.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.result_sheet_style(kind))
	_result_stamp.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.result_stamp_style(kind))
	_result_stamp_label.add_theme_color_override("font_color", accent)
	_title.add_theme_color_override("font_color", ink)
	_sheet_art.set_archive_kind(kind)

func _request_fresh_seed() -> void:
	var seed: int = int(Time.get_unix_time_from_system()) % 2147483646 + 1
	fresh_seed_requested.emit(seed)

func _request_retry() -> void:
	retry_requested.emit(_current_seed)

func _clear_summary() -> void:
	for child: Node in _summary_box.get_children():
		_summary_box.remove_child(child)
		child.queue_free()

func _play_entry(won: bool) -> void:
	_kill_entry_tween()
	_set_buttons_locked(true)
	_result_panel.pivot_offset = _result_panel.size * 0.5
	_result_panel.modulate.a = 0.0
	var entry_duration := VICTORY_ENTRY_DURATION if won else FAILURE_ENTRY_DURATION
	var lock_duration := VICTORY_BUTTON_LOCK_DURATION if won else FAILURE_BUTTON_LOCK_DURATION
	_entry_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_entry_tween.tween_property(_result_panel, "modulate:a", 1.0, entry_duration)
	_entry_tween.chain().tween_interval(maxf(0.0, lock_duration - entry_duration))
	_entry_tween.chain().tween_callback(_unlock_buttons)

func _unlock_buttons() -> void:
	_set_buttons_locked(false)
	_fresh_button.grab_focus()

func _set_buttons_locked(locked: bool) -> void:
	_retry_button.disabled = locked
	_fresh_button.disabled = locked

func _set_focus_enabled(enabled: bool) -> void:
	_summary_scroll.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	_retry_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	_fresh_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE

func _kill_entry_tween() -> void:
	if _entry_tween != null and _entry_tween.is_valid():
		_entry_tween.kill()
	_entry_tween = null

func _panel_style() -> StyleBoxFlat:
	return VISUAL_STYLE_SCRIPT.modal_panel_style()

func _backdrop_style() -> StyleBoxFlat:
	return VISUAL_STYLE_SCRIPT.modal_backdrop_style(0.78)
