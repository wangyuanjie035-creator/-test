class_name LabTopicPanel
extends FoldableContainer

var _body: Label
var _reward_flash: Label
var _last_rendered_day: int = 0
var _feedback_tween: Tween
var _last_snapshot: Dictionary = {}

func _ready() -> void:
	name = "CumulativeTopicPanel"
	title = "累计课题"
	folded = false
	# Let FoldableContainer collapse to its header height. The content determines
	# its expanded height without stealing permanent space from the sidebar log.
	custom_minimum_size = Vector2.ZERO
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	add_child(content)
	_body = Label.new()
	_body.name = "TopicBodyLabel"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 15)
	content.add_child(_body)
	_reward_flash = Label.new()
	_reward_flash.name = "TopicRewardFlashLabel"
	_reward_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward_flash.add_theme_font_size_override("font_size", 17)
	_reward_flash.add_theme_color_override("font_color", Color("7ee0bf"))
	_reward_flash.visible = false
	content.add_child(_reward_flash)
	focus_mode = Control.FOCUS_NONE

func render(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		visible = false
		focus_mode = Control.FOCUS_NONE
		return
	visible = true
	focus_mode = Control.FOCUS_ALL
	_last_snapshot = snapshot.duplicate(true)
	var day: int = int(snapshot.get("day", 1))
	var status: StringName = StringName(snapshot.get("status", &"active"))
	var progress: int = int(snapshot.get("progress", 0))
	var target: int = int(snapshot.get("target", 0))
	var title_text: String = String(snapshot.get("title", "累计课题"))
	title = "课题 · %s  %d/%d" % [title_text, mini(progress, target), target]
	if day >= 5 and _last_rendered_day != day and status in [&"rewarded", &"missed"]:
		folded = true
	_last_rendered_day = day
	var reward_line := "奖励：%s +%d（第4天结算；失败无惩罚）" % [snapshot.get("reward_resource_name", ""), int(snapshot.get("reward", 0))]
	match status:
		&"active":
			_body.text = "前3天累计正产出 %s：%d/%d\n后续消费不扣减累计值\n%s" % [snapshot.get("resource_name", ""), progress, target, reward_line]
		&"achieved_waiting":
			_body.text = "✓ 累计正产出已达成 %d/%d（消费不扣减）\n等待第4天结算\n%s" % [progress, target, reward_line]
		&"rewarded":
			var settled: Dictionary = snapshot.get("settlement", {})
			var overflow: int = int(settled.get("overflow", 0))
			_body.text = "✓ 已完成：实际获得 %s +%d%s\n奖励只入库，不主动触发连锁。" % [
				snapshot.get("reward_resource_name", ""), int(settled.get("actual", 0)),
				"（溢出 %d）" % overflow if overflow > 0 else "",
			]
		&"missed":
			_body.text = "未完成：%d/%d，本局无奖励、无惩罚。" % [progress, target]

func reset() -> void:
	_kill_feedback_tween()
	folded = false
	_last_rendered_day = 0
	visible = false
	focus_mode = Control.FOCUS_NONE
	if _body != null:
		_body.text = ""
	if _reward_flash != null:
		_reward_flash.visible = false
	modulate = Color.WHITE
	_last_snapshot = {}

func play_settlement_feedback(achieved: bool) -> void:
	_kill_feedback_tween()
	folded = false
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	if not achieved:
		modulate = Color(0.78, 0.84, 0.86, 1.0)
		_feedback_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_feedback_tween.tween_property(self, "modulate", Color.WHITE, 0.20)
		return
	var settlement: Dictionary = _last_snapshot.get("settlement", {})
	var overflow: int = int(settlement.get("overflow", 0))
	_reward_flash.text = "奖励已入库：%s +%d%s" % [
		_last_snapshot.get("reward_resource_name", ""), int(settlement.get("actual", 0)),
		" · 溢出 %d" % overflow if overflow > 0 else "",
	]
	_reward_flash.visible = true
	_reward_flash.modulate.a = 0.0
	_feedback_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(_reward_flash, "modulate:a", 1.0, 0.18)

func _kill_feedback_tween() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = null
