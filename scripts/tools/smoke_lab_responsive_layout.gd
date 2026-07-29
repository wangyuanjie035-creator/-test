extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/lab_engine/lab_workbench.tscn"
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")
const TARGETS: Array[Dictionary] = [
	{"label": "1280x720", "size": Vector2i(1280, 720)},
	{"label": "1920x1080", "size": Vector2i(1920, 1080)},
	{"label": "1280x800", "size": Vector2i(1280, 800)},
]
const REQUIRED_CONTROLS: Array[String] = [
	"Header", "ProgressBar", "ResourceStrip", "PipelineBoard", "CandidateBox",
	"Sidebar", "StatusLabel", "CumulativeTopicPanel", "RunButton", "SkipButton",
]

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	_check(packed != null, "main scene must load")
	if packed == null:
		_finish()
		return
	for target: Dictionary in TARGETS:
		await _check_target(packed, String(target.label), target.size)
	_finish()

func _check_target(packed: PackedScene, label: String, viewport_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.name = "LayoutViewport%s" % label
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var scene := packed.instantiate()
	scene.set("profile_persistence_enabled", false)
	scene.set("settings_persistence_enabled", false)
	scene.set("settings_application_enabled", false)
	viewport.add_child(scene)
	await process_frame
	await process_frame
	var help := scene.find_child("HelpOverlay", true, false)
	if help != null:
		help.call("close_help")
	await process_frame
	_check(scene.size.is_equal_approx(Vector2(viewport_size)), "%s root must fill its viewport, got %s" % [label, scene.size])
	for node_name: String in REQUIRED_CONTROLS:
		var control := scene.find_child(node_name, true, false) as Control
		_check(control != null, "%s must contain %s" % [label, node_name])
		if control != null:
			_check(control.is_visible_in_tree(), "%s %s must be visible" % [label, node_name])
			_check(_rect_inside(control.get_global_rect(), Rect2(Vector2.ZERO, Vector2(viewport_size))), "%s %s must stay inside the viewport: %s" % [label, node_name, control.get_global_rect()])
	var sidebar := scene.find_child("Sidebar", true, false) as Control
	var candidate_box := scene.find_child("CandidateBox", true, false) as Control
	var header := scene.find_child("Header", true, false) as Control
	var pipeline_board := scene.find_child("PipelineBoard", true, false) as Control
	if sidebar != null and candidate_box != null:
		_check(candidate_box.get_global_rect().end.x <= sidebar.get_global_rect().position.x, "%s candidate area must not overlap the sidebar" % label)
	if header != null and pipeline_board != null:
		_check(header.get_global_rect().end.y <= pipeline_board.get_global_rect().position.y, "%s header must stay above the pipeline board" % label)
	if pipeline_board != null and candidate_box != null:
		_check(pipeline_board.get_global_rect().end.y <= candidate_box.get_global_rect().position.y, "%s pipeline board must stay above candidates" % label)
	if candidate_box != null:
		for candidate: Node in candidate_box.get_children():
			if candidate is Control:
				_check((candidate as Control).is_visible_in_tree(), "%s candidate must be visible" % label)
				_check(_rect_inside((candidate as Control).get_global_rect(), candidate_box.get_global_rect()), "%s candidate must remain inside its container" % label)
	if sidebar != null:
		for button_name: String in ["RunButton", "SkipButton"]:
			var button := scene.find_child(button_name, true, false) as Control
			if button != null:
				_check(_rect_inside(button.get_global_rect(), sidebar.get_global_rect()), "%s %s must remain inside the sidebar" % [label, button_name])
	await _check_long_result(scene, label, viewport_size)
	viewport.queue_free()
	await process_frame

func _check_long_result(scene: Node, label: String, viewport_size: Vector2i) -> void:
	var overlay := scene.find_child("ResultOverlay", true, false) as Control
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 43
	state.technical_debt = 9
	state.total_triggers = 58
	state.highest_combo = 3
	state.highest_daily_progress = 24
	var long_topic := {
		"title": "跨学科复现实验与超长图表积累验证课题（用于响应式布局压力测试）",
		"progress": 2,
		"target": 3,
		"status": &"missed",
	}
	var history: Array[Dictionary] = []
	overlay.present(state, false, 240731, history, long_topic)
	await process_frame
	var panel := overlay.find_child("ResultPanel", true, false) as Control
	var scroll := overlay.find_child("ResultSummaryScroll", true, false) as ScrollContainer
	var retry := overlay.find_child("RetryButton", true, false) as Button
	var fresh := overlay.find_child("FreshSeedButton", true, false) as Button
	var archive_header := overlay.find_child("ArchiveHeader", true, false) as HBoxContainer
	var archive_stamp := overlay.find_child("ResultStamp", true, false) as PanelContainer
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	_check(panel != null and _rect_inside(panel.get_global_rect(), viewport_rect), "%s long result panel must stay inside the viewport" % label)
	_check(scroll != null and scroll.is_visible_in_tree(), "%s long result must expose a visible summary scroller" % label)
	_check(archive_header != null and panel != null and _rect_inside(archive_header.get_global_rect(), panel.get_global_rect()), "%s archive header must remain inside the result panel" % label)
	_check(archive_stamp != null and archive_header != null and _rect_inside(archive_stamp.get_global_rect(), archive_header.get_global_rect()), "%s archive stamp must remain container-driven inside the header" % label)
	_check(scroll != null and scroll.focus_mode == Control.FOCUS_ALL, "%s result summary scroller must be keyboard focusable" % label)
	_check(retry != null and panel != null and _rect_inside(retry.get_global_rect(), panel.get_global_rect()), "%s retry button must remain inside the result panel" % label)
	_check(fresh != null and panel != null and _rect_inside(fresh.get_global_rect(), panel.get_global_rect()), "%s fresh-seed button must remain inside the result panel" % label)
	if scroll != null and retry != null and fresh != null:
		_check(retry.find_valid_focus_neighbor(SIDE_TOP) == scroll, "%s retry focus-up must reach the result summary" % label)
		_check(scroll.find_valid_focus_neighbor(SIDE_BOTTOM) == retry, "%s summary focus-down must return to retry" % label)
		var bar := scroll.get_v_scroll_bar()
		_check(bar.max_value > bar.page, "%s pressure-test summary must have a real scroll range" % label)
		var retry_rect_before := retry.get_global_rect()
		var fresh_rect_before := fresh.get_global_rect()
		scroll.scroll_vertical = int(bar.max_value)
		await process_frame
		_check(scroll.scroll_vertical > 0, "%s result summary must scroll toward its final content" % label)
		_check(retry.get_global_rect().is_equal_approx(retry_rect_before), "%s scrolling must not move the retry button" % label)
		_check(fresh.get_global_rect().is_equal_approx(fresh_rect_before), "%s scrolling must not move the fresh-seed button" % label)
	overlay.reset()

func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	const TOLERANCE := 1.0
	return (
		inner.position.x >= outer.position.x - TOLERANCE
		and inner.position.y >= outer.position.y - TOLERANCE
		and inner.end.x <= outer.end.x + TOLERANCE
		and inner.end.y <= outer.end.y + TOLERANCE
	)

func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("LAB_RESPONSIVE_LAYOUT_SMOKE: PASS (%d sizes)" % TARGETS.size())
	quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("LAB_RESPONSIVE_LAYOUT_SMOKE: %s" % message)
