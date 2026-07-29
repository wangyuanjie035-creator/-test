extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/lab_engine/lab_workbench.tscn"
const RESULT_OVERLAY_SCRIPT := preload("res://scripts/lab_engine/ui/lab_result_overlay.gd")
const HELP_OVERLAY_SCRIPT := preload("res://scripts/lab_engine/ui/lab_help_overlay.gd")
const SETTINGS_OVERLAY_SCRIPT := preload("res://scripts/lab_engine/ui/lab_settings_overlay.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")
const PROFILE_PATH := "user://lab_engine/profile.json"
const SETTINGS_PATH := "user://lab_engine/settings.cfg"

var _failed: bool = false
var _profile_existed_before: bool
var _profile_bytes_before: PackedByteArray
var _settings_existed_before: bool
var _settings_bytes_before: PackedByteArray

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_profile_existed_before = FileAccess.file_exists(PROFILE_PATH)
	_profile_bytes_before = _read_bytes(PROFILE_PATH) if _profile_existed_before else PackedByteArray()
	_settings_existed_before = FileAccess.file_exists(SETTINGS_PATH)
	_settings_bytes_before = _read_bytes(SETTINGS_PATH) if _settings_existed_before else PackedByteArray()
	var resource: Resource = load(MAIN_SCENE_PATH)
	_check(resource is PackedScene, "main scene must load as PackedScene")
	if not resource is PackedScene:
		_finish()
		return
	var first_scene: Node = _instantiate_scene(resource as PackedScene)
	if first_scene == null:
		_finish()
		return
	await process_frame
	await process_frame
	_check_scene_structure(first_scene, "first instance")
	_check_help_button_binding(first_scene)
	_check_settings_button_binding(first_scene)
	_check_candidate_sidebar_binding(first_scene)
	await _check_run_flow(first_scene)
	current_scene = null
	first_scene.queue_free()
	await process_frame
	_check(not is_instance_valid(first_scene), "first scene must release cleanly")
	await _check_result_overlay_interactions()
	await _check_help_overlay_interactions()
	await _check_settings_overlay_interactions()
	var second_scene: Node = _instantiate_scene(resource as PackedScene)
	if second_scene == null:
		_finish()
		return
	await process_frame
	await process_frame
	_check_scene_structure(second_scene, "second instance")
	_check_single_cashout_flow(second_scene)
	_check_finished_forecast_is_hidden(second_scene)
	_check_maintenance_timing_copy(second_scene)
	_check_invalid_run_restores_interaction(second_scene)
	_check_main_scene_retry_binding(second_scene)
	_finish()

func _instantiate_scene(packed_scene: PackedScene) -> Node:
	var scene: Node = packed_scene.instantiate()
	_check(scene != null, "main scene must instantiate")
	if scene == null:
		return null
	scene.set("profile_persistence_enabled", false)
	scene.set("settings_persistence_enabled", false)
	scene.set("settings_application_enabled", false)
	root.add_child(scene)
	current_scene = scene
	return scene

func _check_scene_structure(scene: Node, context: String) -> void:
	_check(scene.is_inside_tree(), "%s must enter the scene tree" % context)
	_check(scene.get_script() != null, "%s must retain its controller script" % context)
	_check((scene as Control).theme != null, "%s must apply the shared interface theme" % context)
	_check(scene.find_child("SlotGrid", true, false) != null, "%s must build the slot grid" % context)
	var blind_recorder: Node = scene.find_child("OpeningBlindRecorder", true, false)
	_check(blind_recorder != null, "%s must retain the removable Phase 12 blind recorder" % context)
	_check(blind_recorder != null and not bool(blind_recorder.get("active")), "%s blind recorder must remain inert without explicit CLI arguments" % context)
	for slot_index: int in range(6):
		_check(scene.find_child("LabSlot%d" % slot_index, true, false) != null, "%s must build lab slot %d" % [context, slot_index])
	for node_name: String in ["Header", "DayLabel", "ProgressBar", "ResourceLabel", "HelpButton", "SettingsButton", "ChainForecast", "ForecastLabel", "PipelineBoard", "PipelineFlow", "CandidateBox", "Sidebar", "StatusLabel", "CumulativeTopicPanel", "TopicBodyLabel", "TopicRewardFlashLabel", "LogLabel", "RunButton", "SkipButton", "TokenLayer", "FeedbackLayer", "AudioFeedback", "DayPlayback", "HelpOverlay", "SettingsOverlay", "ResultOverlay"]:
		_check(scene.find_child(node_name, true, false) != null, "%s must build %s" % [context, node_name])
	var cashout_feedback := scene.find_child("CashoutFeedback", true, false) as Control
	var cashout_label := scene.find_child("CashoutFeedbackLabel", true, false) as Label
	_check(cashout_feedback != null and cashout_feedback.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s must build a non-blocking cashout feedback layer" % context)
	_check(cashout_label != null and cashout_label.get_global_rect().end.x <= 970.0, "%s cashout feedback must stay left of the sidebar at 1280x720" % context)
	var forecast_label := scene.find_child("ForecastLabel", true, false) as Label
	_check(forecast_label != null and forecast_label.text.contains("预计主链："), "%s must render the compact chain forecast" % context)
	var topic_body := scene.find_child("TopicBodyLabel", true, false) as Label
	_check(topic_body != null and topic_body.text.contains("累计正产出") and topic_body.text.contains("消费不扣减"), "%s must distinguish cumulative topic output from current inventory" % context)

func _check_help_button_binding(scene: Node) -> void:
	var overlay := scene.find_child("HelpOverlay", true, false) as Control
	var help_button := scene.find_child("HelpButton", true, false) as Button
	_check(overlay != null and help_button != null, "main scene must expose help interaction nodes")
	if overlay == null or help_button == null:
		return
	overlay.close_help()
	help_button.pressed.emit()
	_check(overlay.visible, "header help button must open the help overlay")

func _check_settings_button_binding(scene: Node) -> void:
	var overlay := scene.find_child("SettingsOverlay", true, false) as Control
	var settings_button := scene.find_child("SettingsButton", true, false) as Button
	_check(overlay != null and settings_button != null, "main scene must expose settings interaction nodes")
	if overlay == null or settings_button == null:
		return
	settings_button.pressed.emit()
	_check(overlay.visible, "header settings button must open the settings overlay")
	var slider := overlay.find_child("MasterVolumeSlider", true, false) as HSlider
	var mode := overlay.find_child("WindowModeOption", true, false) as OptionButton
	var close_button := overlay.find_child("SettingsCloseButton", true, false) as Button
	_check(slider != null and mode != null and close_button != null, "settings overlay must expose volume, display, and close controls")
	if slider != null:
		slider.value = 42
	if mode != null:
		mode.select(1)
		mode.item_selected.emit(1)
	if close_button != null:
		close_button.pressed.emit()
	_check(not overlay.visible, "settings close button must return to the game")
	var settings: Dictionary = scene.get("_settings")
	_check(is_equal_approx(float(settings.get("master_volume", 0.0)), 0.42), "settings interaction must commit master volume")
	_check_equal(String(settings.get("window_mode", "")), "fullscreen", "settings interaction must commit window mode")

func _check_single_cashout_flow(scene: Node) -> void:
	var controller: RefCounted = scene.get("_controller")
	var state: RefCounted = controller.state
	state.install(controller.cards[&"all_nighter"])
	state.charts = 1
	state.clean_data = 0
	state.energy = 3
	scene.call("_refresh_all")
	var writing_slot := scene.find_child("LabSlot4", true, false) as Button
	var forecast_label := scene.find_child("ForecastLabel", true, false) as Label
	var run_button := scene.find_child("RunButton", true, false) as Button
	_check(writing_slot != null and forecast_label != null and run_button != null, "single cashout smoke requires writing, forecast, and run controls")
	if writing_slot == null or forecast_label == null or run_button == null:
		return
	_check(scene.find_child("CashoutModeRow", true, false) == null, "single cashout UI must not build the legacy mode row")
	_check(scene.find_child("SafeCashoutButton", true, false) == null, "single cashout UI must not build the legacy safe button")
	_check(scene.find_child("PressCashoutButton", true, false) == null, "single cashout UI must not build the legacy press button")
	var has_legacy_mode_property := false
	for property: Dictionary in scene.get_property_list():
		if StringName(property.name) == &"_cashout_mode":
			has_legacy_mode_property = true
	_check(not has_legacy_mode_property, "workbench must not retain the legacy _cashout_mode property")
	scene.call("_select_skip")
	writing_slot.pressed.emit()
	_check(forecast_label.text.contains("同样图数") and forecast_label.text.count("\n") == 1, "stored charts must produce a two-line static value comparison")
	_check(scene.find_child("CashoutValueButton", true, false) == null, "value comparison must not add another button at 1280x720")
	_check(not run_button.disabled, "standard cashout with enough energy must allow the day to start")
	state.charts = 0
	state.clean_data = 1
	state.stopped_slot = 3
	state.energy = 4
	scene.call("_refresh_forecast")
	_check(forecast_label.text.contains("应急临时1图") and forecast_label.text.count("\n") == 1, "zero charts plus clean data must forecast emergency temporary-chart value: %s" % forecast_label.text)
	_check(not run_button.disabled, "emergency cashout with enough resources must allow the day to start")
	state.clean_data = 0
	scene.call("_refresh_forecast")
	_check(run_button.disabled and run_button.text.contains("整洁数据"), "zero charts and zero clean data must disable start with a Chinese resource reason")
	state.clean_data = 1
	state.energy = 2
	scene.call("_refresh_forecast")
	_check(run_button.disabled and run_button.text.contains("精力不足"), "insufficient emergency energy must disable start with a Chinese energy reason")
	scene.call("_start_new_run", 240731)

func _check_finished_forecast_is_hidden(scene: Node) -> void:
	var controller: RefCounted = scene.get("_controller")
	controller.finished = true
	scene.call("_refresh_forecast")
	var forecast := scene.find_child("ChainForecast", true, false) as Control
	var label := scene.find_child("ForecastLabel", true, false) as Label
	_check(forecast != null and not forecast.visible, "finished run must hide the forecast surface")
	_check(label != null and label.text.is_empty() and not label.text.contains("run_finished"), "finished run must clear internal forecast reasons")
	_check(scene.find_child("CashoutModeRow", true, false) == null, "finished run must not recreate legacy cashout controls")
	controller.finished = false
	scene.call("_start_new_run", 240731)

func _check_candidate_sidebar_binding(scene: Node) -> void:
	var candidate_box := scene.find_child("CandidateBox", true, false) as Control
	var run_button := scene.find_child("RunButton", true, false) as Button
	var skip_button := scene.find_child("SkipButton", true, false) as Button
	var action_plan := scene.find_child("ActionPlanLabel", true, false) as Label
	_check(candidate_box != null and run_button != null and skip_button != null and action_plan != null, "main scene must expose candidate and sidebar controls")
	if candidate_box == null or run_button == null or skip_button == null or action_plan == null:
		return
	_check_equal(candidate_box.get_child_count(), 3, "day one must render three candidate buttons")
	for candidate: Node in candidate_box.get_children():
		var category_badge := candidate.find_child("CategoryBadge", true, false) as Control
		var action_badge := candidate.find_child("ActionBadge", true, false) as Control
		_check(category_badge != null and category_badge.mouse_filter == Control.MOUSE_FILTER_IGNORE, "candidate category badge must not intercept card clicks")
		_check(action_badge != null and action_badge.mouse_filter == Control.MOUSE_FILTER_IGNORE, "candidate action badge must not intercept card clicks")
	_check(run_button.disabled, "run button must start disabled until a choice is confirmed")
	var first_candidate := candidate_box.get_child(0) as Button
	first_candidate.pressed.emit()
	_check(not run_button.disabled, "candidate selection must enable the run button")
	_check(first_candidate.modulate == Color("ffd38a"), "selected candidate must show selected feedback")
	_check(not action_plan.text.contains("尚未选择候选"), "candidate selection must be repeated in the action plan")
	skip_button.pressed.emit()
	_check(not run_button.disabled, "skip selection must keep the run button enabled")
	_check(first_candidate.modulate == Color.WHITE, "skip selection must clear candidate feedback")
	_check(action_plan.text.contains("维护生产线"), "maintenance selection must be repeated in the action plan")

func _check_maintenance_timing_copy(scene: Node) -> void:
	var controller: RefCounted = scene.get("_controller")
	var state: RefCounted = controller.state
	var skip_button := scene.find_child("SkipButton", true, false) as Button
	var status_label := scene.find_child("StatusLabel", true, false) as Label
	_check(skip_button != null and status_label != null, "maintenance timing test requires sidebar copy")
	if skip_button == null or status_label == null:
		return
	state.day = 7
	scene.set("_day_preview", {"stopped_slot": -1, "maintenance_prevented_slot": -1})
	scene.call("_refresh_all")
	_check(skip_button.text.contains("未来日初停机"), "ordinary-day maintenance must promise only a future day-start shutdown guarantee")
	_check(status_label.text.contains("不修今日"), "ordinary-day status must explain that maintenance does not affect today")
	state.day = 8
	scene.set("_day_preview", {"stopped_slot": -1, "maintenance_prevented_slot": -1})
	scene.call("_refresh_all")
	_check(skip_button.text.contains("最终日：仅技术债 -1"), "final-day maintenance button must state that only debt reduction remains")
	_check(not skip_button.text.contains("今日不可修复"), "final day without a shutdown must not claim that today cannot be repaired")
	_check(not skip_button.disabled, "final-day maintenance must remain available")
	scene.set("_day_preview", {"stopped_slot": 4, "maintenance_prevented_slot": -1})
	scene.call("_refresh_all")
	_check(skip_button.text.contains("今日不可修复"), "final-day maintenance button must flag an existing shutdown as irreversible today")
	_check(status_label.text.contains("今日停机不可修复"), "shutdown status must explain that maintenance cannot repair today's stopped slot")
	_check(not skip_button.disabled, "maintenance must remain available when today's slot is stopped")
	scene.call("_start_new_run", 240731)

func _check_run_flow(scene: Node) -> void:
	var overlay := scene.find_child("HelpOverlay", true, false) as Control
	var run_button := scene.find_child("RunButton", true, false) as Button
	var day_label := scene.find_child("DayLabel", true, false) as Label
	_check(overlay != null and run_button != null and day_label != null, "main scene must expose run flow controls")
	if overlay == null or run_button == null or day_label == null:
		return
	overlay.close_help()
	run_button.pressed.emit()
	var deadline := Time.get_ticks_msec() + 5000
	while not day_label.text.contains("第 2 / 8 天") and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(day_label.text.contains("第 2 / 8 天"), "run action must complete playback and advance to day two")
	_check(run_button.disabled, "new day must require a fresh candidate or skip choice")

func _check_invalid_run_restores_interaction(scene: Node) -> void:
	var run_button := scene.find_child("RunButton", true, false) as Button
	var skip_button := scene.find_child("SkipButton", true, false) as Button
	var candidate_box := scene.find_child("CandidateBox", true, false) as Control
	var status_label := scene.find_child("StatusLabel", true, false) as Label
	if run_button == null or skip_button == null or candidate_box == null or status_label == null:
		_check(false, "invalid run test requires sidebar and candidate controls")
		return
	scene.set("_selected_candidate", 99)
	scene.set("_choice_confirmed", true)
	run_button.pressed.emit()
	_check(status_label.text.contains("无法开始"), "invalid run must display a stable error status")
	_check(not skip_button.disabled, "invalid run must restore skip interaction")
	for candidate: Node in candidate_box.get_children():
		_check(not (candidate as Button).disabled, "invalid run must restore candidate interaction")
	for slot_index: int in range(5):
		var slot := scene.find_child("LabSlot%d" % slot_index, true, false) as Button
		_check(slot != null and not slot.disabled, "invalid run must restore production slot %d" % slot_index)
	var rest_slot := scene.find_child("LabSlot5", true, false) as Button
	_check(rest_slot != null and rest_slot.disabled, "rest slot must remain non-interactive after invalid run")

func _check_main_scene_retry_binding(scene: Node) -> void:
	var overlay := scene.find_child("ResultOverlay", true, false)
	var day_label := scene.find_child("DayLabel", true, false) as Label
	_check(overlay != null and day_label != null, "retry binding test requires result overlay and day label")
	if overlay == null or day_label == null:
		return
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 61
	state.technical_debt = 7
	state.total_triggers = 55
	state.highest_combo = 2
	state.highest_daily_progress = 24
	overlay.call("present", state, false, 1784217270)
	var retry_button := overlay.find_child("RetryButton", true, false) as Button
	_check(retry_button != null, "main scene result overlay must expose retry button")
	if retry_button == null:
		return
	retry_button.pressed.emit()
	_check(not (overlay as Control).visible, "same-seed retry must close the result overlay")
	_check(day_label.text.contains("第 1 / 8 天"), "same-seed retry must reset the run to day one")
	_check(day_label.text.contains("Seed 1784217270"), "same-seed retry must preserve the requested seed")

func _check_result_overlay_interactions() -> void:
	var overlay: Control = RESULT_OVERLAY_SCRIPT.new()
	root.add_child(overlay)
	await process_frame
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 61
	state.technical_debt = 7
	state.total_triggers = 55
	state.highest_combo = 2
	state.highest_daily_progress = 24
	var retry_seed: Array[int] = [-1]
	var fresh_seed: Array[int] = [-1]
	overlay.retry_requested.connect(func(seed: int) -> void: retry_seed[0] = seed)
	overlay.fresh_seed_requested.connect(func(seed: int) -> void: fresh_seed[0] = seed)
	overlay.present(state, false, 1784217270)
	var archive_meta := overlay.find_child("ArchiveMetaLabel", true, false) as Label
	var result_stamp := overlay.find_child("ResultStampLabel", true, false) as Label
	_check(archive_meta != null and archive_meta.text.contains("Seed 1784217270"), "result archive must expose seed metadata")
	_check(result_stamp != null and result_stamp.text == "退回修改", "ordinary failure must use the revision-returned archive stamp")
	var combined_text := ""
	for child: Node in overlay.find_children("*", "Label", true, false):
		combined_text += (child as Label).text
	_check(combined_text.contains("距离目标还差 39"), "failure result must show exact remaining progress")
	_check(combined_text.contains("主要断点"), "failure result must show one primary breakpoint")
	var retry_button := overlay.find_child("RetryButton", true, false) as Button
	var fresh_button := overlay.find_child("FreshSeedButton", true, false) as Button
	_check(retry_button != null, "result overlay must build retry button")
	_check(fresh_button != null, "result overlay must build fresh seed button")
	_check(retry_button != null and retry_button.disabled, "result retry must be locked during the entry reward")
	_check(fresh_button != null and fresh_button.disabled, "fresh seed must be locked during the entry reward")
	await create_timer(0.36).timeout
	_check(retry_button != null and not retry_button.disabled, "failure result retry must unlock after its entry reward")
	_check(fresh_button != null and not fresh_button.disabled, "failure fresh seed must unlock after its entry reward")
	_check(fresh_button != null and fresh_button.has_focus(), "fresh seed must receive default result focus")
	if retry_button != null:
		retry_button.pressed.emit()
	if fresh_button != null:
		fresh_button.pressed.emit()
	_check_equal(retry_seed[0], 1784217270, "retry button must emit the current seed")
	_check(fresh_seed[0] > 0, "fresh seed button must emit a positive seed")
	var shutdown_history: Array[Dictionary] = [{
		"day": 8, "daily_progress": 0, "progress_before": 61, "progress_after": 61,
		"stopped_slot": 1, "events": [],
	}]
	overlay.present(state, false, 1784217270, shutdown_history)
	await process_frame
	_check((overlay.find_child("ResultStampLabel", true, false) as Label).text == "生产中断", "real shutdown failure must use the interrupted archive stamp")
	# Reuse the same overlay repeatedly: retries happen without reloading the scene,
	# so a third (or later) result must not be hidden by deferred child deletion.
	var persistent_panel := overlay.find_child("ResultPanel", true, false)
	for cycle: int in range(5):
		overlay.reset()
		overlay.present(state, false, 1784217270 + cycle)
		await process_frame
		_check(overlay.visible, "result overlay must remain visible on repeat cycle %d" % (cycle + 1))
		_check_equal(overlay.find_children("ResultPanel", "PanelContainer", true, false).size(), 1, "repeat cycle must contain exactly one result panel")
		_check(overlay.find_child("ResultPanel", true, false) == persistent_panel, "repeat cycle must reuse the persistent result panel")
		_check(overlay.find_child("RetryButton", true, false) != null, "repeat cycle must retain retry interaction")
		_check(overlay.find_child("FreshSeedButton", true, false) != null, "repeat cycle must retain fresh-seed interaction")
	(overlay.find_child("RetryButton", true, false) as Button).pressed.emit()
	_check_equal(retry_seed[0], 1784217274, "persistent retry button must emit the latest presented seed")
	state.paper_progress = 106
	var victory_history: Array[Dictionary] = [{
		"day": 8, "daily_progress": 36, "progress_before": 70, "progress_after": 106,
		"events": [], "maintenance_prevented_slot": -1,
	}]
	overlay.present(state, true, 1784217270, victory_history)
	await process_frame
	_check((overlay.find_child("ResultStampLabel", true, false) as Label).text == "已归档", "victory must use the archived result stamp")
	_check((overlay.find_child("ArchiveMetaLabel", true, false) as Label).text.contains("结算日 D08"), "result archive must expose the settled day")
	_check((overlay.find_child("RetryButton", true, false) as Button).disabled, "victory retry must remain locked during the reward peak")
	_check((overlay.find_child("FreshSeedButton", true, false) as Button).disabled, "victory fresh seed must remain locked during the reward peak")
	var victory_text := ""
	for child: Node in overlay.find_children("*", "Label", true, false):
		victory_text += (child as Label).text
	_check(victory_text.contains("第 8 天 +36（70 → 106）"), "victory result must name the actual winning day")
	_check(not victory_text.contains("最后日"), "victory result must not imply every win happens on the final day")
	await create_timer(0.72).timeout
	_check(not (overlay.find_child("RetryButton", true, false) as Button).disabled, "victory retry must unlock after 0.7 seconds")
	_check((overlay.find_child("FreshSeedButton", true, false) as Button).has_focus(), "victory result must focus the recommended fresh-seed action")
	overlay.queue_free()
	await process_frame
	_check(not is_instance_valid(overlay), "standalone result overlay must release cleanly")

func _check_help_overlay_interactions() -> void:
	var background_button := Button.new()
	background_button.name = "HelpFocusReturnTarget"
	root.add_child(background_button)
	background_button.grab_focus()
	var overlay: Control = HELP_OVERLAY_SCRIPT.new()
	root.add_child(overlay)
	await process_frame
	_check(not overlay.visible, "help overlay must start hidden")
	overlay.open_help()
	_check(overlay.visible, "help overlay must open through its public API")
	_check(overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "help overlay must block pointer input from reaching gameplay")
	_check(
		is_equal_approx(overlay.anchor_left, 0.0) and is_equal_approx(overlay.anchor_top, 0.0)
		and is_equal_approx(overlay.anchor_right, 1.0) and is_equal_approx(overlay.anchor_bottom, 1.0)
		and is_zero_approx(overlay.offset_left) and is_zero_approx(overlay.offset_top)
		and is_zero_approx(overlay.offset_right) and is_zero_approx(overlay.offset_bottom),
		"help overlay must use full-rect anchors without offsets"
	)
	var close_button := overlay.find_child("HelpCloseButton", true, false) as Button
	_check(close_button != null, "help overlay must build its close button")
	_check(close_button != null and close_button.has_focus(), "help close button must receive focus when opened")
	if close_button != null:
		_check(close_button.find_next_valid_focus() == close_button, "help Tab focus must remain inside the modal")
		for side: Side in [SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM, SIDE_LEFT]:
			_check(close_button.find_valid_focus_neighbor(side) == close_button, "help directional focus must remain inside the modal")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	overlay.call("_unhandled_key_input", cancel)
	_check(not overlay.visible, "ui_cancel must close the help overlay")
	_check(close_button != null and close_button.focus_mode == Control.FOCUS_NONE, "hidden help controls must leave the focus graph")
	await process_frame
	_check(background_button.has_focus(), "closing help must restore the control that opened it")
	overlay.queue_free()
	background_button.queue_free()
	await process_frame
	_check(not is_instance_valid(overlay), "standalone help overlay must release cleanly")

func _check_settings_overlay_interactions() -> void:
	var background_button := Button.new()
	background_button.name = "SettingsFocusReturnTarget"
	root.add_child(background_button)
	background_button.grab_focus()
	var overlay: Control = SETTINGS_OVERLAY_SCRIPT.new()
	root.add_child(overlay)
	await process_frame
	var committed: Array[Dictionary] = []
	overlay.settings_committed.connect(func(settings: Dictionary) -> void: committed.append(settings))
	overlay.open_settings({"master_volume": 0.5, "window_mode": "windowed"})
	var slider := overlay.find_child("MasterVolumeSlider", true, false) as HSlider
	_check(overlay.visible and overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "settings overlay must open as a blocking modal")
	_check(slider != null and slider.has_focus(), "settings overlay must focus its first control")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	overlay.call("_unhandled_key_input", cancel)
	_check(not overlay.visible, "ui_cancel must close settings")
	_check(slider != null and slider.focus_mode == Control.FOCUS_NONE, "hidden settings controls must leave the focus graph")
	_check_equal(committed.size(), 1, "closing settings with ui_cancel must commit once")
	await process_frame
	_check(background_button.has_focus(), "closing settings must restore the control that opened it")
	overlay.queue_free()
	background_button.queue_free()
	await process_frame
	_check(not is_instance_valid(overlay), "standalone settings overlay must release cleanly")

func _finish() -> void:
	_check(FileAccess.file_exists(PROFILE_PATH) == _profile_existed_before, "scene smoke must not create or delete the real profile")
	if _profile_existed_before:
		_check_equal(_read_bytes(PROFILE_PATH), _profile_bytes_before, "scene smoke must not modify the real profile bytes")
	_check(FileAccess.file_exists(SETTINGS_PATH) == _settings_existed_before, "scene smoke must not create or delete the real settings")
	if _settings_existed_before:
		_check_equal(_read_bytes(SETTINGS_PATH), _settings_bytes_before, "scene smoke must not modify the real settings bytes")
	if _failed:
		quit(1)
		return
	print("LAB_MAIN_SCENE_SMOKE: PASS")
	quit(0)

func _read_bytes(path: String) -> PackedByteArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var bytes := file.get_buffer(file.get_length())
	file.close()
	return bytes

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("LAB_MAIN_SCENE_SMOKE: %s" % message)

func _check_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("LAB_MAIN_SCENE_SMOKE: %s (expected=%s, actual=%s)" % [message, expected, actual])
