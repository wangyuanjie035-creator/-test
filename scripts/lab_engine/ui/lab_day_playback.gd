class_name LabDayPlayback
extends Node

const TOKEN_VIEW_SCRIPT := preload("res://scripts/lab_engine/ui/lab_token_view.gd")
const HUD_SCRIPT := preload("res://scripts/lab_engine/ui/lab_hud_view.gd")
const SIDEBAR_SCRIPT := preload("res://scripts/lab_engine/ui/lab_sidebar_view.gd")
const FEEDBACK_SCRIPT := preload("res://scripts/lab_engine/ui/lab_feedback_layer.gd")
const AUDIO_SCRIPT := preload("res://scripts/lab_engine/audio/lab_audio_feedback.gd")
const CASHOUT_FEEDBACK_SCRIPT := preload("res://scripts/lab_engine/ui/lab_cashout_feedback.gd")
const RESULT_SUMMARY_SCRIPT := preload("res://scripts/lab_engine/ui/lab_day_result_summary.gd")

var _slot_views: Array
var _slot_names: Array[String]
var _hud: Control
var _sidebar: Control
var _token_layer: Control
var _feedback: Control
var _audio: Node
var _cashout_feedback: Control

func configure(
	slot_views: Array,
	slot_names: Array[String],
	hud: Control,
	sidebar: Control,
	token_layer: Control,
	feedback: Control,
	audio: Node
) -> void:
	assert(hud.get_script() == HUD_SCRIPT, "LabDayPlayback requires LabHudView")
	assert(sidebar.get_script() == SIDEBAR_SCRIPT, "LabDayPlayback requires LabSidebarView")
	assert(feedback.get_script() == FEEDBACK_SCRIPT, "LabDayPlayback requires LabFeedbackLayer")
	assert(audio.get_script() == AUDIO_SCRIPT, "LabDayPlayback requires LabAudioFeedback")
	assert(slot_views.size() == 6, "LabDayPlayback requires six slot views")
	assert(slot_names.size() == 6, "LabDayPlayback requires six slot names")
	_slot_views = slot_views
	_slot_names = slot_names
	_hud = hud
	_sidebar = sidebar
	_token_layer = token_layer
	_feedback = feedback
	_audio = audio
	_cashout_feedback = CASHOUT_FEEDBACK_SCRIPT.new()
	_cashout_feedback.name = "CashoutFeedback"
	_token_layer.add_child(_cashout_feedback)

func play(result: Dictionary, final_progress: int, is_final_run: bool = false) -> void:
	assert(_hud != null and _sidebar != null and _feedback != null and _audio != null, "LabDayPlayback must be configured before play")
	var lines: PackedStringArray = []
	lines.append("[b]第 %d 天结算[/b]　论文 %+d" % [result.day, result.daily_progress])
	var combo_counts: Dictionary[int, int] = {}
	var running_chain_counts: Dictionary[int, int] = {}
	var crossed_goal_today: bool = false
	var displayed_progress := final_progress - int(result.daily_progress)
	_hud.set_progress(displayed_progress)
	_sidebar.set_log("\n".join(lines))
	var stopped_slot := int(result.get("stopped_slot", -1))
	if stopped_slot >= 0:
		_feedback.show_feedback("⚠ %s停机" % _slot_names[stopped_slot], Color("ff6b6b"), 0.12, 0.42)
		await get_tree().create_timer(0.48).timeout
	for event: Dictionary in result.events:
		var chain_id := int(event.chain_id)
		combo_counts[chain_id] = int(combo_counts.get(chain_id, 0)) + 1
		running_chain_counts[chain_id] = int(running_chain_counts.get(chain_id, 0)) + 1
		var slot := int(event.slot)
		var holding: bool = _is_holding_event(event)
		var label := "囤积 %d 图" % int(event.details.get("charts_held", 0)) if holding else "成功" if bool(event.success) else "空转"
		var color := "#6fa8bd" if holding else "#77e0a0" if bool(event.success) else "#e27676"
		lines.append("[color=%s]%s · %s[/color]" % [color, _slot_names[slot], label])
		_sidebar.set_log("\n".join(lines), true)
		_slot_views[slot].pulse(bool(event.success), int(event.type), holding)
		var cashout_spec: Dictionary = cashout_feedback_spec(event)
		if cashout_spec.is_empty():
			_spawn_event_tokens(event)
			_play_event_feedback(event, running_chain_counts, chain_id, slot)
		else:
			await _play_cashout_feedback(cashout_spec)
		var progress_delta := int(event.deltas.get(&"paper_progress", 0))
		if progress_delta > 0:
			var crossed_goal := displayed_progress < 100 and displayed_progress + progress_delta >= 100
			displayed_progress += progress_delta
			_hud.animate_progress(displayed_progress)
			if crossed_goal:
				crossed_goal_today = true
				_feedback.show_feedback("论文完成！", Color("ffd36a"), 0.18, 0.62)
				await get_tree().create_timer(0.28).timeout
		await get_tree().create_timer(0.18).timeout
	_finish_summary(result, lines, combo_counts, crossed_goal_today)
	if not is_final_run:
		await get_tree().create_timer(0.28).timeout

func cashout_feedback_spec(event: Dictionary) -> Dictionary:
	if StringName(event.get("card_id", &"")) != &"all_nighter" or _is_holding_event(event):
		return {}
	var details: Dictionary = event.get("details", {})
	if bool(event.get("success", false)):
		var kind := StringName(details.get("cashout_kind", &"standard"))
		return {
			"kind": kind,
			"charts_used": int(details.get("charts_used", 0)),
			"value_per_chart": int(details.get("value_per_chart", 0)),
			"progress_gained": int(details.get("progress_gained", event.get("deltas", {}).get(&"paper_progress", 0))),
		}
	var reason := StringName(details.get("reason", event.get("failure_reason", &"input_shortage")))
	return {
		"kind": &"failure",
		"message": _cashout_failure_message(reason),
	}

func _cashout_failure_message(reason: StringName) -> String:
	match reason:
		&"no_cashout_resource": return "兑现失败 · 无库存图表或整洁数据"
		&"insufficient_energy": return "兑现失败 · 精力不足"
		_: return "通宵兑现失败"

func _play_cashout_feedback(spec: Dictionary) -> void:
	match StringName(spec.kind):
		&"emergency":
			_audio.play_success()
			await _cashout_feedback.play_emergency(int(spec.progress_gained), int(spec.value_per_chart))
		&"standard":
			_audio.play_success()
			await _cashout_feedback.play_standard(int(spec.charts_used), int(spec.progress_gained), int(spec.value_per_chart))
		_:
			_audio.play_failure()
			await _cashout_feedback.play_failure(String(spec.message))

func _play_event_feedback(event: Dictionary, running_counts: Dictionary[int, int], chain_id: int, slot: int) -> void:
	if _is_holding_event(event):
		_feedback.show_feedback("写作台囤积中 · 超频可兑现", Color("6fa8bd"), 0.05, 0.22)
	elif not bool(event.success):
		_feedback.show_feedback("%s空转 · 缺少输入" % _slot_names[slot], Color("e27676"), 0.05, 0.22)
		_audio.play_failure()
	elif int(running_counts[chain_id]) >= 2:
		_feedback.show_feedback("COMBO ×%d" % running_counts[chain_id], Color("62c7ff"), 0.08, 0.24)
		_audio.play_combo(int(running_counts[chain_id]))
	else:
		_audio.play_success()

func _finish_summary(result: Dictionary, lines: PackedStringArray, combo_counts: Dictionary[int, int], crossed_goal: bool = false) -> void:
	var largest_combo := 1
	for count: int in combo_counts.values():
		largest_combo = maxi(largest_combo, count)
	if largest_combo >= 2:
		lines.append("[color=#62c7ff][b]COMBO ×%d[/b][/color]" % largest_combo)
	if int(result.daily_progress) >= 20:
		lines.append("[color=#ffd36a][b]关键突破！单日进度 +%d[/b][/color]" % result.daily_progress)
		# Crossing the goal already owns the victory cue and immediately hands off to
		# the result panel. Do not let the ordinary breakthrough cue compete with it.
		if not crossed_goal:
			_feedback.show_feedback("关键突破 · 单日 +%d" % result.daily_progress, Color("ffd36a"), 0.12, 0.5)
			_audio.play_breakthrough()
	var attribution: PackedStringArray = RESULT_SUMMARY_SCRIPT.new().summarize(result, _slot_names)
	if not attribution.is_empty():
		lines.append("[b]本日归因[/b]")
		for line: String in attribution:
			lines.append("[color=#c8dce5]%s[/color]" % line)
	_sidebar.set_log("\n".join(lines), true)

func _spawn_event_tokens(event: Dictionary) -> void:
	if _is_holding_event(event):
		return
	if not bool(event.success):
		_spawn_token("缺少输入", Color("e27676"), int(event.slot), int(event.slot))
		return
	var resource_targets: Dictionary[StringName, int] = {
		&"inspiration": 1,
		&"raw_data": 2,
		&"clean_data": 3,
		&"charts": 4,
	}
	for resource_id: StringName in event.deltas:
		var amount := int(event.deltas[resource_id])
		if amount <= 0:
			continue
		if resource_id == &"paper_progress":
			_spawn_token("论文 +%d" % amount, Color("ffd36a"), int(event.slot), -1)
		elif resource_targets.has(resource_id):
			_spawn_token("+%d %s" % [amount, _resource_short_name(resource_id)], Color("65d6ff"), int(event.slot), resource_targets[resource_id])
		elif resource_id == &"technical_debt":
			_spawn_token("技术债 +%d" % amount, Color("ff8a5b"), int(event.slot), -1)

func _spawn_token(message: String, color: Color, source_slot: int, target_slot: int) -> void:
	var token: Control = TOKEN_VIEW_SCRIPT.new()
	_token_layer.add_child(token)
	var source_rect: Rect2 = _slot_views[source_slot].get_global_rect()
	var start_position := source_rect.get_center() - Vector2(30, 10)
	var end_position: Vector2
	if target_slot >= 0:
		end_position = _slot_views[target_slot].get_global_rect().get_center() - Vector2(30, 10)
	else:
		end_position = _hud.progress_global_center() - Vector2(30, 10)
	token.play(message, color, start_position, end_position)

func _resource_short_name(resource_id: StringName) -> String:
	match resource_id:
		&"inspiration": return "灵感"
		&"raw_data": return "原始"
		&"clean_data": return "整洁"
		&"charts": return "图表"
	return String(resource_id)

func _is_holding_event(event: Dictionary) -> bool:
	return (
		event.has("details")
		and StringName(event.details.get("reason", &"")) == &"awaiting_manual_cashout"
	)
