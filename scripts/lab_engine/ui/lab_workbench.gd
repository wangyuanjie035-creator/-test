class_name LabWorkbenchView
extends Control

const CONTROLLER_SCRIPT := preload("res://scripts/lab_engine/run/lab_run_controller.gd")
const SLOT_VIEW_SCRIPT := preload("res://scripts/lab_engine/ui/lab_slot_view.gd")
const FEEDBACK_LAYER_SCRIPT := preload("res://scripts/lab_engine/ui/lab_feedback_layer.gd")
const AUDIO_FEEDBACK_SCRIPT := preload("res://scripts/lab_engine/audio/lab_audio_feedback.gd")
const RESULT_OVERLAY_SCRIPT := preload("res://scripts/lab_engine/ui/lab_result_overlay.gd")
const HELP_OVERLAY_SCRIPT := preload("res://scripts/lab_engine/ui/lab_help_overlay.gd")
const HUD_SCRIPT := preload("res://scripts/lab_engine/ui/lab_hud_view.gd")
const CANDIDATE_PANEL_SCRIPT := preload("res://scripts/lab_engine/ui/lab_candidate_panel.gd")
const SIDEBAR_SCRIPT := preload("res://scripts/lab_engine/ui/lab_sidebar_view.gd")
const DAY_PLAYBACK_SCRIPT := preload("res://scripts/lab_engine/ui/lab_day_playback.gd")
const CHAIN_FORECAST_SCRIPT := preload("res://scripts/lab_engine/ui/lab_chain_forecast_view.gd")
const PIPELINE_FLOW_SCRIPT := preload("res://scripts/lab_engine/ui/lab_pipeline_flow.gd")
const RESOURCE_PIPELINE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_resource_pipeline_strip.gd")
const PROFILE_STORE_SCRIPT := preload("res://scripts/lab_engine/persistence/lab_profile_store.gd")
const SETTINGS_STORE_SCRIPT := preload("res://scripts/lab_engine/persistence/lab_settings_store.gd")
const SETTINGS_APPLIER_SCRIPT := preload("res://scripts/lab_engine/persistence/lab_settings_applier.gd")
const SETTINGS_OVERLAY_SCRIPT := preload("res://scripts/lab_engine/ui/lab_settings_overlay.gd")
const INTERFACE_THEME_SCRIPT := preload("res://scripts/lab_engine/ui/lab_interface_theme.gd")
const BACKGROUND_ART_SCRIPT := preload("res://scripts/lab_engine/ui/lab_background_art.gd")
const VISUAL_STYLE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")

const SLOT_NAMES: Array[String] = ["文献台", "实验台", "数据台", "分析台", "写作台", "休息区"]
var _controller: RefCounted
var _selected_candidate: int = -1
var _selected_overclock: int = -1
var _choice_confirmed: bool = false
var _day_preview: Dictionary = {}
var _slot_views: Array = []
var _hud: Control
var _candidate_panel: Control
var _sidebar: Control
var _result_overlay: PanelContainer
var _help_overlay: PanelContainer
var _settings_overlay: PanelContainer
var _token_layer: Control
var _feedback_layer: Control
var _audio_feedback: Node
var _day_playback: Node
var _chain_forecast: PanelContainer
var _resource_pipeline: HBoxContainer
var _is_playing_day: bool = false
var profile_persistence_enabled: bool = true
var settings_persistence_enabled: bool = true
var settings_application_enabled: bool = true
var _profile_store: RefCounted
var _profile: Dictionary
var _settings_store: RefCounted
var _settings: Dictionary

func _ready() -> void:
	_load_settings()
	_profile_store = PROFILE_STORE_SCRIPT.new()
	if profile_persistence_enabled:
		var loaded_profile: Dictionary = _profile_store.load_profile()
		_profile = loaded_profile.data
		if bool(loaded_profile.get("recovered", false)):
			if bool(loaded_profile.get("disk_repaired", false)):
				push_warning("实验室档案主文件损坏，已从备份恢复。")
			else:
				push_warning("实验室档案已从备份载入，但主文件修复失败。")
		elif not bool(loaded_profile.get("ok", false)) and int(loaded_profile.get("error", ERR_FILE_NOT_FOUND)) != ERR_FILE_NOT_FOUND:
			profile_persistence_enabled = false
			push_warning("实验室档案不可读取，本次运行已停止写入以保护原文件。")
	else:
		_profile = _profile_store.defaults()
	_build_interface()
	_start_new_run(240731)

func _build_interface() -> void:
	theme = INTERFACE_THEME_SCRIPT.create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: Control = BACKGROUND_ART_SCRIPT.new()
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 18)
	add_child(margin)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	_hud = HUD_SCRIPT.new()
	_hud.help_requested.connect(_show_help)
	_hud.settings_requested.connect(_show_settings)
	root.add_child(_hud)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	var workspace: VBoxContainer = VBoxContainer.new()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 10)
	body.add_child(workspace)
	_build_slots(workspace)
	_build_candidates(workspace)
	_build_sidebar(body)
	_token_layer = Control.new()
	_token_layer.name = "TokenLayer"
	_token_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_token_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_token_layer.z_index = 5
	add_child(_token_layer)
	_feedback_layer = FEEDBACK_LAYER_SCRIPT.new()
	_feedback_layer.name = "FeedbackLayer"
	add_child(_feedback_layer)
	_audio_feedback = AUDIO_FEEDBACK_SCRIPT.new()
	_audio_feedback.name = "AudioFeedback"
	add_child(_audio_feedback)
	_result_overlay = RESULT_OVERLAY_SCRIPT.new()
	_result_overlay.retry_requested.connect(_start_new_run)
	_result_overlay.fresh_seed_requested.connect(_start_new_run)
	add_child(_result_overlay)
	_help_overlay = HELP_OVERLAY_SCRIPT.new()
	_help_overlay.help_closed.connect(_on_help_closed)
	add_child(_help_overlay)
	_settings_overlay = SETTINGS_OVERLAY_SCRIPT.new()
	_settings_overlay.preview_requested.connect(_preview_settings)
	_settings_overlay.settings_committed.connect(_commit_settings)
	add_child(_settings_overlay)
	_day_playback = DAY_PLAYBACK_SCRIPT.new()
	_day_playback.name = "DayPlayback"
	add_child(_day_playback)
	_day_playback.configure(_slot_views, SLOT_NAMES, _hud, _sidebar, _token_layer, _feedback_layer, _audio_feedback)

func _show_help() -> void:
	_help_overlay.open_help()

func _show_settings() -> void:
	_settings_overlay.open_settings(_settings)

func _preview_settings(settings: Dictionary) -> void:
	if settings_application_enabled:
		SETTINGS_APPLIER_SCRIPT.apply(settings)

func _commit_settings(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	_preview_settings(_settings)
	_save_settings()

func _load_settings() -> void:
	_settings_store = SETTINGS_STORE_SCRIPT.new()
	if not settings_persistence_enabled:
		_settings = _settings_store.defaults()
		_preview_settings(_settings)
		return
	var loaded: Dictionary = _settings_store.load_settings()
	_settings = loaded.data
	if bool(loaded.get("recovered", false)):
		push_warning("实验室设置主文件损坏，已从备份恢复。")
	elif not bool(loaded.get("ok", false)) and int(loaded.get("error", ERR_FILE_NOT_FOUND)) != ERR_FILE_NOT_FOUND:
		settings_persistence_enabled = false
		push_warning("实验室设置不可读取，本次运行已停止写入以保护原文件。")
	_preview_settings(_settings)

func _save_settings() -> void:
	if not settings_persistence_enabled:
		return
	var error: int = _settings_store.save(_settings)
	if error != OK:
		if error == ERR_UNAVAILABLE:
			settings_persistence_enabled = false
		push_warning("实验室设置保存失败：%s" % error_string(error))

func _on_help_closed() -> void:
	call_deferred("_focus_after_modal")
	if bool(_profile.get("tutorial_seen", false)):
		return
	_profile.tutorial_seen = true
	_save_profile()

func _focus_after_modal() -> void:
	var current := get_viewport().gui_get_focus_owner()
	if current != null and current.is_visible_in_tree():
		return
	if _candidate_panel != null:
		for child: Node in _candidate_panel.get_children():
			if child is Button and not (child as Button).disabled:
				(child as Button).grab_focus()
				return

func _build_slots(parent: VBoxContainer) -> void:
	var label: Label = Label.new()
	label.text = "实验室生产线 · 点击未停机工位选择超频"
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)
	_resource_pipeline = RESOURCE_PIPELINE_SCRIPT.new()
	parent.add_child(_resource_pipeline)
	_chain_forecast = CHAIN_FORECAST_SCRIPT.new()
	parent.add_child(_chain_forecast)
	var pipeline_board := PanelContainer.new()
	pipeline_board.name = "PipelineBoard"
	pipeline_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pipeline_board.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.workbench_panel_style())
	parent.add_child(pipeline_board)
	var flow := PIPELINE_FLOW_SCRIPT.new()
	flow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pipeline_board.add_child(flow)
	var slots: GridContainer = GridContainer.new()
	slots.name = "SlotGrid"
	slots.columns = 3
	slots.add_theme_constant_override("separation", 8)
	slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pipeline_board.add_child(slots)
	for index: int in range(6):
		var view = SLOT_VIEW_SCRIPT.new()
		view.name = "LabSlot%d" % index
		view.setup(index)
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		view.pressed.connect(_select_overclock.bind(index))
		slots.add_child(view)
		_slot_views.append(view)

func _build_candidates(parent: VBoxContainer) -> void:
	var title: Label = Label.new()
	title.text = "今日候选 · 选择一张安装/升级，或维护生产线"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)
	_candidate_panel = CANDIDATE_PANEL_SCRIPT.new()
	_candidate_panel.candidate_selected.connect(_select_candidate)
	parent.add_child(_candidate_panel)

func _build_sidebar(parent: HBoxContainer) -> void:
	_sidebar = SIDEBAR_SCRIPT.new()
	_sidebar.run_requested.connect(_run_day)
	_sidebar.skip_requested.connect(_select_skip)
	parent.add_child(_sidebar)

func _start_new_run(seed: int) -> void:
	_is_playing_day = false
	_controller = CONTROLLER_SCRIPT.new(seed)
	_selected_candidate = -1
	_selected_overclock = -1
	_choice_confirmed = false
	_result_overlay.reset()
	_sidebar.reset_topic()
	_sidebar.set_log("[color=#8fb7c9]选择候选与超频工位，然后开始一天。[/color]")
	_prepare_day()
	_profile.runs_started = int(_profile.get("runs_started", 0)) + 1
	_profile.last_seed = seed
	_save_profile()
	if not bool(_profile.get("tutorial_seen", false)):
		_show_help()
	else:
		call_deferred("_focus_after_modal")

func _save_profile() -> void:
	if not profile_persistence_enabled:
		return
	var error: int = _profile_store.save(_profile)
	if error != OK:
		if error == ERR_UNAVAILABLE:
			profile_persistence_enabled = false
		push_warning("实验室档案保存失败：%s" % error_string(error))

func _prepare_day() -> void:
	_day_preview = _controller.begin_day()
	_selected_candidate = -1
	_selected_overclock = -1
	_choice_confirmed = bool(_day_preview.get("forced_rest", false))
	_refresh_all()
	if bool(_day_preview.get("topic_just_settled", false)):
		var topic: Dictionary = _controller.topic_snapshot()
		var settlement: Dictionary = topic.get("settlement", {})
		var topic_log := (
			"[color=#7ee0bf]累计课题完成：%s +%d[/color]" % [topic.get("reward_resource_name", ""), int(settlement.get("actual", 0))]
			if bool(settlement.get("achieved", false))
			else "[color=#8fb7c9]累计课题未完成：无奖励、无惩罚。[/color]"
		)
		_sidebar.append_log(topic_log)
		var achieved: bool = bool(settlement.get("achieved", false))
		_sidebar.play_topic_settlement_feedback(achieved)
		if achieved:
			_audio_feedback.play_success()
	_sidebar.set_run_action("休息一天" if _choice_confirmed else "开始一天", _choice_confirmed)

func _refresh_all() -> void:
	var state: RefCounted = _controller.state
	_hud.refresh(state, _controller.seed)
	var pipeline_choice: int = _selected_candidate if _choice_confirmed else -2
	var pipeline_forecast: Dictionary = _controller.forecast_day(pipeline_choice, _selected_overclock)
	_resource_pipeline.refresh(state, pipeline_forecast)
	var stopped_slot: int = int(_day_preview.get("stopped_slot", -1))
	var prevented_slot: int = int(_day_preview.get("maintenance_prevented_slot", -1))
	var day_status: String = (
		"维护保障生效：%s免于停机" % SLOT_NAMES[prevented_slot]
		if prevented_slot >= 0
		else "%s停机" % SLOT_NAMES[stopped_slot]
		if stopped_slot >= 0
		else "全部工位在线"
	)
	var is_final_day: bool = int(state.day) >= 8
	var today_stopped: bool = stopped_slot >= 0
	var maintenance_hint := (
		"维护提示：今日停机不可修复；最终日仅技术债 -1。"
		if is_final_day and today_stopped
		else "维护提示：最终日仅技术债 -1。"
		if is_final_day
		else "维护提示：保障从未来日初生效，今日停机不可修复。"
		if today_stopped
		else "维护提示：保障用于未来日初停机，不修今日。"
	)
	_sidebar.set_status("今日状态：%s\n可选操作：超频任一在线工位（精力 -1，技术债 +2）\n%s\n建议：%s" % [day_status, maintenance_hint, _guidance_text(state)])
	_sidebar.set_topic(_controller.topic_snapshot())
	_sidebar.set_maintenance_ready(bool(state.maintenance_ready), is_final_day, today_stopped)
	_refresh_slot_views()
	_refresh_candidates()
	_refresh_forecast()

func _refresh_forecast() -> void:
	if _chain_forecast == null or _controller == null:
		return
	_sidebar.set_action_plan(_action_plan_text(), _choice_confirmed)
	if _controller.finished:
		_chain_forecast.clear_and_hide()
		return
	var choice := _selected_candidate if _choice_confirmed else -2
	var forecast: Dictionary = _controller.forecast_day(choice, _selected_overclock)
	var cashout_forecast := _all_nighter_forecast_for_choice(choice)
	if _selected_overclock == 4 and not cashout_forecast.is_empty() and StringName(cashout_forecast.get("reason", &"")) != &"not_installed":
		_chain_forecast.show_value_comparison(cashout_forecast)
	else:
		_chain_forecast.show_forecast(forecast, SLOT_NAMES)
	if _choice_confirmed:
		var block_reason := _cashout_block_reason(choice)
		if not block_reason.is_empty():
			_sidebar.set_run_action("无法开始：%s" % block_reason, false)
		else:
			_sidebar.set_run_action("开始一天", true)

func _action_plan_text() -> String:
	if bool(_day_preview.get("forced_rest", false)):
		return "今日计划：精力耗尽，强制休息"
	var choice_text := "尚未选择候选"
	if _choice_confirmed:
		if _selected_candidate < 0:
			choice_text = "维护生产线"
		else:
			var candidates: Array[StringName] = _controller.candidates_for_today()
			if _selected_candidate < candidates.size():
				choice_text = String(_controller.cards[candidates[_selected_candidate]].display_name)
	var overclock_text := "不超频" if _selected_overclock < 0 else "超频%s" % SLOT_NAMES[_selected_overclock]
	return "今日计划：%s｜%s" % [choice_text, overclock_text]

func _all_nighter_forecast_for_choice(choice: int) -> Dictionary:
	var pending_card_id: StringName = &""
	if choice >= 0:
		var candidates: Array[StringName] = _controller.candidates_for_today()
		if choice < candidates.size() and int(_controller.cards[candidates[choice]].slot) == 4:
			pending_card_id = candidates[choice]
	return _controller.forecast_all_nighter(pending_card_id, _selected_overclock, choice == -1)

func _cashout_block_reason(choice: int) -> String:
	if _selected_overclock != 4:
		return ""
	var pending_card_id: StringName = &""
	if choice >= 0:
		var candidates: Array[StringName] = _controller.candidates_for_today()
		if choice < candidates.size() and int(_controller.cards[candidates[choice]].slot) == 4:
			pending_card_id = candidates[choice]
	var forecast: Dictionary = _controller.forecast_all_nighter(pending_card_id, _selected_overclock, choice == -1)
	if bool(forecast.get("available", false)) or StringName(forecast.get("reason", &"")) in [&"not_installed", &"holding", &"stopped"]:
		return ""
	match StringName(forecast.get("reason", &"")):
		&"insufficient_energy": return "精力不足，无法完成兑现"
		&"no_cashout_resource": return "没有库存图表，应急补图还需要 1 份整洁数据"
		_: return ""

func _refresh_slot_views() -> void:
	var state: RefCounted = _controller.state
	var stopped_slot: int = int(_day_preview.get("stopped_slot", -1))
	for index: int in range(_slot_views.size()):
		var entry: Dictionary = state.slots[index]
		var card_title: String = ""
		if StringName(entry.card_id) != &"":
			card_title = _controller.cards[StringName(entry.card_id)].display_name
		var card_effect: String = _card_description(StringName(entry.card_id)) if StringName(entry.card_id) != &"" else "改变生产线"
		_slot_views[index].refresh(entry, card_title, card_effect, index == _selected_overclock, index == stopped_slot)

func _guidance_text(state: RefCounted) -> String:
	if state.technical_debt >= 7:
		return "技术债已进入停机区，考虑跳过或减少超频。"
	if state.paper_progress >= 70:
		return "论文接近完成，优先让写作台获得图表。"
	if state.charts > 0:
		return "已有图表，强化或超频写作台可以兑现进度。"
	if state.clean_data > 0:
		return "已有整洁数据，分析台可以把它变成图表。"
	if state.raw_data >= 4:
		return "原始数据足够，优先改善数据台的清洗能力。"
	if state.inspiration > 0:
		return "已有灵感，可以强化实验台制造原始数据。"
	return "先建立灵感或实验产能，不必第一天就追求论文。"

func _refresh_candidates() -> void:
	var candidates: Array[StringName] = _controller.candidates_for_today()
	var items: Array[Dictionary] = []
	for index: int in range(candidates.size()):
		var id: StringName = candidates[index]
		var card: Resource = _controller.cards[id]
		var current: Dictionary = _controller.state.slots[int(card.slot)]
		var action_hint: String = "升级" if StringName(current.card_id) == id else "替换" if int(current.level) > 0 else "安装"
		items.append({
			"title": card.display_name,
			"slot_name": SLOT_NAMES[int(card.slot)],
			"category_id": int(card.slot),
			"description": _card_description(id, id),
			"action_hint": action_hint,
		})
	_candidate_panel.show_candidates(items, _selected_candidate)

func _card_description(card_id: StringName, pending_card_id: StringName = &"") -> String:
	var description := String(_controller.cards[card_id].get(&"description"))
	if card_id != &"all_nighter":
		return description
	var skip_debt_reduction: bool = _choice_confirmed and _selected_candidate == -1
	var forecast: Dictionary = _controller.forecast_all_nighter(
		pending_card_id,
		_selected_overclock,
		skip_debt_reduction
	)
	if not bool(forecast.get("available", false)):
		var reason := String(forecast.get("reason", "no_cashout_resource"))
		if reason == "stopped":
			return description + "\n预计：写作台停机，今天无法兑现"
		if reason == "holding":
			return description + "\n囤积中：保留 %d 图；超频写作台可兑现" % int(forecast.get("charts_held", 0))
		return description + "\n预计：没有图表可兑现；仍会支付超频代价"
	if _selected_overclock == 4:
		return description + "\n⚡ 已选择兑现，详见上方预判"
	var warning := "；自动化仍锁定" if bool(forecast.automation_locked) else ""
	var completion := "；可立即完成" if int(_controller.state.paper_progress) + int(forecast.progress_gained) >= 100 else ""
	return description + "\n通宵兑现：%d 图 × %d = +%d；日末债 %d，精力 %d%s%s" % [
		int(forecast.charts_used),
		int(forecast.value_per_chart),
		int(forecast.progress_gained),
		int(forecast.day_end_debt),
		int(forecast.day_end_energy),
		warning,
		completion,
	]

func _select_candidate(index: int) -> void:
	_selected_candidate = index
	_choice_confirmed = true
	_sidebar.set_run_enabled(true)
	_candidate_panel.set_selected(index)
	_refresh_slot_views()
	_refresh_forecast()

func _select_skip() -> void:
	_selected_candidate = -1
	_choice_confirmed = true
	_sidebar.set_run_enabled(true)
	_candidate_panel.set_selected(-1)
	_refresh_slot_views()
	_refresh_forecast()

func _select_overclock(index: int) -> void:
	_selected_overclock = -1 if _selected_overclock == index else index
	_refresh_all()

func _run_day() -> void:
	if _is_playing_day:
		return
	_is_playing_day = true
	_set_interaction_enabled(false)
	var result: Dictionary = _controller.play_day(_selected_candidate, _selected_overclock)
	if not bool(result.get("valid", false)):
		_is_playing_day = false
		_set_interaction_enabled(true)
		_sidebar.set_status("无法开始：%s" % _run_failure_text(StringName(result.get("reason", &"unknown"))))
		_refresh_forecast()
		return
	await _day_playback.play(result, _controller.state.paper_progress, _controller.finished)
	_is_playing_day = false
	if _controller.finished:
		# Result presentation is the terminal hand-off.  Do not place optional HUD /
		# candidate refreshes in front of it: one failing refresh would otherwise
		# leave the run finished, input locked, and no result panel visible.
		_show_result()
		return
	_set_interaction_enabled(true)
	_prepare_day()

func _run_failure_text(reason: StringName) -> String:
	match reason:
		&"insufficient_energy": return "精力不足，无法完成兑现"
		&"no_cashout_resource": return "没有库存图表，应急补图还需要 1 份整洁数据"
		&"cashout_not_resolved": return "写作台未能完成兑现，请重新检查选择"
		_: return String(reason)

func _set_interaction_enabled(enabled: bool) -> void:
	_sidebar.set_interaction_enabled(enabled)
	_candidate_panel.set_interaction_enabled(enabled)
	_chain_forecast.set_interaction_enabled(enabled)
	var stopped_slot := int(_day_preview.get("stopped_slot", -1))
	for index: int in range(_slot_views.size()):
		_slot_views[index].disabled = not enabled or index == 5 or index == stopped_slot

func _show_result() -> void:
	if _controller.won:
		_audio_feedback.play_victory()
	_set_interaction_enabled(false)
	_chain_forecast.clear_and_hide()
	var state: RefCounted = _controller.state
	_result_overlay.present(state, _controller.won, _controller.seed, _controller.history, _controller.topic_snapshot())
