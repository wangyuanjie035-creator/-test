@tool
extends Node2D
class_name CampusOverworldScene

const CAMPUS_MAP_VIEW := preload("res://scripts/overworld/campus_map_view.gd")
const CAMPUS_PLAYER := preload("res://scripts/overworld/campus_player.gd")
const CAMPUS_INTERACTABLE := preload("res://scripts/overworld/campus_interactable.gd")
const CAMPUS_PICKUP_BURST := preload("res://scripts/overworld/campus_pickup_burst.gd")
const CAMPUS_TARGET_DIRECTION_INDICATOR := preload("res://scripts/overworld/campus_target_direction_indicator.gd")
const CAMPUS_TASK_TRACKER_MINIMAP := preload("res://scripts/overworld/campus_task_tracker_minimap.gd")
const GAME_DATA_CATALOG := preload("res://scripts/data/game_data_catalog.gd")
const BATTLE_TEST_SCENE := preload("res://scenes/battle_test_scene.tscn")

const MODE_OVERWORLD := &"overworld"
const MODE_BATTLE := &"battle"
const MODE_SAFEHOUSE := &"safehouse"
const CAMPUS_STAGE_MASTER1 := &"master1"
const CAMPUS_STAGE_MASTER2 := &"master2"
const CAMPUS_STAGE_DOCTOR1 := &"doctor1"
const CAMPUS_STAGE_DOCTOR2 := &"doctor2"
const CAMPUS_STAGE_DOCTOR3 := &"doctor3"
const CAMPUS_STAGE_DOCTOR4 := &"doctor4"
const MARKER_STATE_DEFAULT := &"default"
const MARKER_STATE_CONDITION_LOCKED := &"condition_locked"
const REQUIREMENT_INTERCEPT_WARN_ONLY := &"warn_only"
const REQUIREMENT_INTERCEPT_SOFT_GATE := &"soft_gate"
const REQUIREMENT_INTERCEPT_HARD_GATE := &"hard_gate"
const GUIDANCE_STORY_COLOR := Color(0.42, 0.88, 0.96)
const GUIDANCE_SUPPLY_COLOR := Color(0.98, 0.82, 0.32)
const GUIDANCE_LEGEND_TEXT := "青色=剧情目标；金色=建议补给点"
const FOCUS_TAG_STORY := "剧情目标"
const FOCUS_TAG_SUPPLY := "建议补给"
const HUD_Z_STATUS := 10
const HUD_Z_TASK_TRACKER := 15
const HUD_Z_DIRECTION_INDICATOR := 20
const HUD_Z_FOCUS_INFO := 25
const HUD_Z_PROMPT := 30
const HUD_Z_CARRY_CHOICE := 35
const HUD_Z_RETURN_SUMMARY := 40
const HUD_STATUS_PANEL_WIDTH := 384.0
const HUD_TASK_TRACKER_PANEL_WIDTH := 360.0
const HUD_TASK_TRACKER_MINIMAP_SIZE := Vector2(326, 74)
const HUD_FOCUS_INFO_PANEL_WIDTH := 536.0
const HUD_CARRY_CHOICE_PANEL_WIDTH := 580.0
const SAFEHOUSE_PANEL_WIDTH := 760.0
const SAFEHOUSE_PANEL_HEIGHT := 600.0
const CAMPUS_SEED_MAX := 2147483646
const CAMPUS_LAYOUT_MIN_UNIQUE_AREAS := 4
const CAMPUS_LAYOUT_REBALANCE_ATTEMPTS := 8
const CAMPUS_GENERATION_THEME_CHOICE_COUNT := 3
const CAMPUS_GENERATION_THEME_TAG_SCORE := 28
const CAMPUS_GENERATION_THEME_MATCH_BONUS := 8
const GENERATION_THEME_EXPERIMENT := &"experiment_day"
const GENERATION_THEME_WRITING := &"writing_day"
const GENERATION_THEME_SOCIAL := &"social_day"
const GENERATION_THEME_ADVISOR := &"advisor_day"
const GENERATION_THEME_RECOVERY := &"recovery_day"
const GENERATION_THEME_COMMITTEE := &"committee_day"
const GENERATION_THEME_TRANSFER := &"transfer_day"
const GENERATION_THEME_PROJECT := &"project_day"
const GENERATION_THEME_FUNDS := &"funds_day"
const GENERATION_THEME_SEMINAR := &"seminar_day"
const GENERATION_THEME_DEFENSE := &"defense_day"
const GENERATION_THEME_REVISION := &"revision_day"
const GENERATION_THEME_DATA_REPAIR := &"data_repair_day"
const SAFEHOUSE_INTERACTION_ID := &"SAFEHOUSE_ENTRANCE"
const SAFEHOUSE_INTERACTION_KIND := &"safehouse"
const SAFEHOUSE_ENTRANCE_FALLBACK_POSITION := Vector2(210, 284)
const SAFEHOUSE_ENTRANCE_COLOR := Color(0.74, 0.88, 0.70)
const SAFEHOUSE_PREP_ACTION_POINTS_PER_DAY := 2
const SAFEHOUSE_PREP_TAG_SCORE := 18
const SAFEHOUSE_CARRY_SLOT_COUNT := 2
const SAFEHOUSE_CARRY_TAG_SCORE := 22
const HUD_PANEL_BG_COLOR := Color(0.07, 0.09, 0.10, 0.84)
const HUD_PANEL_BORDER_COLOR := Color(0.20, 0.26, 0.28, 0.92)
const HUD_PRIMARY_TEXT_COLOR := Color(0.90, 0.94, 0.92)
const HUD_MUTED_TEXT_COLOR := Color(0.64, 0.70, 0.68)
const HUD_SECTION_TITLE_COLOR := Color(0.78, 0.84, 0.82)
const HUD_SECTION_RULE_COLOR := Color(0.26, 0.32, 0.34, 0.56)
const GUIDANCE_INDICATOR_HIDE_DISTANCE := 180.0
const GUIDANCE_INDICATOR_LEFT_INSET := 64.0
const GUIDANCE_INDICATOR_RIGHT_INSET := 64.0
const GUIDANCE_INDICATOR_TOP_CLEARANCE := 218.0
const GUIDANCE_INDICATOR_BOTTOM_INSET := 124.0
const GUIDANCE_INDICATOR_COMFORT_MARGIN := Vector2(112, 104)
const GUIDANCE_INDICATOR_DISCOVERY_DURATION := 2.4
const PLAYER_START_POSITION: Vector2 = Vector2(800, 536)
const INTERACTABLE_MIN_SPACING := 58.0
const INTERACTABLE_BUILDING_CLEARANCE := 24.0
const INTERACTABLE_MAP_EDGE_CLEARANCE := 28.0
const INTERACTABLE_SPAWN_CANDIDATE_ATTEMPTS := 18
const CAMPUS_TRACKED_RESOURCE_IDS := [
	&"inspiration",
	&"data",
	&"draft",
	&"funds",
	&"reputation",
	&"experience_lessons",
	&"methodology_notes",
	&"paper_fragments",
]

var campus_seed: int = 1
var campus_stage: StringName = CAMPUS_STAGE_MASTER1
var mode: StringName = MODE_OVERWORLD
var campus_resources: Dictionary = {}
var campus_stage_definitions: Dictionary = {}
var campus_route_requirements: Dictionary = {}
var interaction_log: Array[String] = []
var completed_interaction_ids: Array[StringName] = []

var world_root: Node2D
var map_view: Node2D
var interactable_root: Node2D
var feedback_root: Node2D
var player: CharacterBody2D
var focused_interactable: Variant = null

var hud_layer: CanvasLayer
var hud_root: Control
var status_panel: PanelContainer
var status_label: Label
var guidance_label: Label
var guidance_direction_indicator: Control
var task_tracker_panel: PanelContainer
var task_tracker_stage_label: Label
var task_tracker_objective_label: Label
var task_tracker_map_label: Label
var task_tracker_minimap: Control
var task_tracker_supply_label: Label
var task_tracker_progress_label: Label
var focus_info_panel: PanelContainer
var focus_info_title_label: Label
var focus_info_type_label: Label
var focus_info_route_label: Label
var focus_info_reward_label: Label
var focus_info_requirement_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var carry_choice_panel: PanelContainer
var carry_choice_title_label: Label
var carry_choice_detail_label: Label
var carry_choice_button_box: VBoxContainer
var carry_choice_buttons: Array[Button] = []
var resource_label: Label
var log_label: Label
var return_summary_panel: PanelContainer
var return_summary_result_label: Label
var return_summary_resource_label: Label
var return_summary_guidance_label: Label
var battle_layer: CanvasLayer
var battle_instance: Control
var transition_layer: CanvasLayer
var transition_root: Control
var transition_title_label: Label
var transition_subtitle_label: Label
var safehouse_layer: CanvasLayer
var safehouse_root: Control
var safehouse_panel: PanelContainer
var safehouse_day_label: Label
var safehouse_resource_label: Label
var safehouse_theme_label: Label
var safehouse_carry_label: Label
var safehouse_attribute_label: Label
var safehouse_prep_label: Label
var safehouse_effect_label: Label
var safehouse_theme_choice_buttons: Array[Button] = []
var safehouse_carry_item_buttons: Array[Button] = []
var safehouse_prep_action_buttons: Array[Button] = []
var safehouse_depart_button: Button
var safehouse_next_day_button: Button
var safehouse_day: int = 1
var safehouse_prep_action_points: int = SAFEHOUSE_PREP_ACTION_POINTS_PER_DAY
var safehouse_attribute_points: Dictionary = {}
var safehouse_active_prep_effects: Dictionary = {}
var safehouse_completed_prep_action_ids: Array[StringName] = []
var safehouse_selected_carry_item_ids: Array[StringName] = []
var safehouse_used_carry_trigger_keys: Array[String] = []
var safehouse_used_carry_option_keys: Array[String] = []
var stage_debug_buttons: Dictionary = {}
var generation_candidate_toggle: CheckButton
var reroll_seed_button: Button
var return_safehouse_button: Button
var generation_audit_label: Label
var marker_profile_legend_label: Label
var generation_theme_choice_buttons: Array[Button] = []
var generation_candidate_map_enabled: bool = true
var generation_selected_theme_id: StringName = &""

var _built: bool = false
var _active_interaction_id: StringName = &""
var _active_interaction_route_node_id: StringName = &""
var _active_interaction_summary: String = ""
var _active_battle_resource_snapshot: Dictionary = {}
var _pending_condition_override_interaction_id: StringName = &""
var _pending_carry_choice_interaction_id: StringName = &""
var _pending_carry_choice_options: Array[Dictionary] = []
var _pending_carry_battle_effect: Dictionary = {}
var _transition_tween: Tween
var _return_summary_tween: Tween
var _last_return_resource_parts: Array[String] = []
var _summary_guidance_target_interaction_id: StringName = &""
var _guidance_indicator_target_interaction_id: StringName = &""
var _guidance_indicator_discovery_time: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	initialize_campus()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-2000, -2000), Vector2(4000, 4000)), Color(0.13, 0.22, 0.19))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _built:
		return
	if _guidance_indicator_discovery_time > 0.0:
		_guidance_indicator_discovery_time = maxf(0.0, _guidance_indicator_discovery_time - delta)
	_refresh_guidance_direction_indicator()
	_refresh_task_tracker_minimap()


func initialize_campus(seed: int = 1, stage: StringName = CAMPUS_STAGE_MASTER1) -> void:
	_ensure_campus_data_loaded()
	campus_seed = max(1, seed)
	campus_stage = _normalize_campus_stage(stage)
	safehouse_day = 1
	_reset_safehouse_progression()
	_clear_generation_theme_choice()
	if not _built:
		_build_scene_tree()
		_built = true
	_reset_campus()
	_enter_safehouse(false)


func get_current_mode() -> StringName:
	return mode


func get_campus_stage() -> StringName:
	return campus_stage


func get_campus_stage_label() -> String:
	return _get_stage_label(campus_stage)


func get_campus_seed() -> int:
	return campus_seed


func get_safehouse_day() -> int:
	return safehouse_day


func is_safehouse_visible() -> bool:
	return safehouse_layer != null and safehouse_layer.visible


func get_safehouse_theme_choice_summary() -> String:
	return get_stage_generation_theme_choice_summary()


func get_safehouse_status_summary() -> String:
	return "mode=%s,day=%d,stage=%s,seed=%d,theme=%s,map=%s" % [
		String(mode),
		safehouse_day,
		String(campus_stage),
		campus_seed,
		String(_get_active_generation_theme_id()),
		_get_stage_spawn_source_id(),
	]


func get_safehouse_prep_action_points() -> int:
	return safehouse_prep_action_points


func get_safehouse_attribute_summary() -> String:
	return _format_safehouse_attribute_summary()


func get_safehouse_prep_effect_summary() -> String:
	return _format_safehouse_prep_effect_summary()


func get_safehouse_prep_effect_ids_summary() -> String:
	var ids: Array[String] = []
	for raw_effect_id: Variant in safehouse_active_prep_effects.keys():
		ids.append(String(raw_effect_id))
	ids.sort()
	return ",".join(ids)


func get_safehouse_carry_item_summary() -> String:
	return _format_safehouse_carry_item_summary()


func get_safehouse_selected_carry_item_ids_summary() -> String:
	var ids: Array[String] = []
	for item_id: StringName in safehouse_selected_carry_item_ids:
		ids.append(String(item_id))
	ids.sort()
	return ",".join(ids)


func get_safehouse_carry_trigger_hint_for_interaction(interaction_id: StringName) -> String:
	var interactable: Variant = _find_interactable(interaction_id)
	if not interactable is CampusInteractable:
		return ""
	return _format_safehouse_carry_trigger_hint(interactable as CampusInteractable)


func get_safehouse_carry_option_hint_for_interaction(interaction_id: StringName) -> String:
	var interactable: Variant = _find_interactable(interaction_id)
	if not interactable is CampusInteractable:
		return ""
	return _format_safehouse_carry_option_hint(interactable as CampusInteractable)


func is_carry_choice_panel_visible() -> bool:
	return carry_choice_panel != null and carry_choice_panel.visible


func get_pending_carry_choice_summary() -> String:
	return _format_pending_carry_choice_summary()


func get_pending_carry_choice_button_count() -> int:
	if carry_choice_button_box == null:
		return 0
	return carry_choice_button_box.get_child_count()


func choose_pending_carry_option_by_item_id(item_id: StringName) -> bool:
	return _choose_pending_carry_option(item_id)


func skip_pending_carry_choice() -> bool:
	return _skip_pending_carry_choice()


func cancel_pending_carry_choice() -> bool:
	return _cancel_pending_carry_choice()


func toggle_safehouse_carry_item(item_id: StringName) -> bool:
	return _toggle_safehouse_carry_item(item_id)


func apply_safehouse_prep_action(action_id: StringName) -> bool:
	return _apply_safehouse_prep_action(action_id)


func get_safehouse_entrance_interaction_id() -> StringName:
	return SAFEHOUSE_INTERACTION_ID


func get_safehouse_entrance_position() -> Vector2:
	return _get_safehouse_entrance_position()


func has_safehouse_entrance_interactable() -> bool:
	return _find_interactable(SAFEHOUSE_INTERACTION_ID) != null


func depart_safehouse_to_campus() -> void:
	_depart_safehouse_to_campus()


func return_to_safehouse() -> void:
	if mode == MODE_BATTLE:
		return
	_enter_safehouse(true)


func advance_safehouse_day() -> void:
	_advance_safehouse_day()


func set_campus_seed(seed: int, reset_current: bool = true) -> void:
	var normalized_seed: int = clampi(seed, 1, CAMPUS_SEED_MAX)
	if campus_seed == normalized_seed:
		_refresh_generation_candidate_toggle()
		return
	campus_seed = normalized_seed
	_clear_generation_theme_choice()
	_refresh_generation_candidate_toggle()
	if _built and reset_current:
		_reset_campus(true, true)
		_append_log("测试：切换 Seed %d。" % campus_seed)
		_refresh_hud()


func reroll_campus_seed(reset_current: bool = true) -> int:
	var next_seed: int = _generate_debug_campus_seed()
	if next_seed == campus_seed:
		next_seed = (next_seed % CAMPUS_SEED_MAX) + 1
	set_campus_seed(next_seed, reset_current)
	return campus_seed


func is_generation_candidate_map_enabled() -> bool:
	return generation_candidate_map_enabled


func set_generation_candidate_map_enabled(enabled: bool, reset_current: bool = true) -> void:
	if generation_candidate_map_enabled == enabled:
		_refresh_generation_candidate_toggle()
		_refresh_safehouse_panel()
		return
	generation_candidate_map_enabled = enabled
	_refresh_generation_candidate_toggle()
	if _built and reset_current:
		_reset_campus(true, true)
		_append_log("测试：%s候选池地图。" % ("启用" if generation_candidate_map_enabled else "关闭"))
		_refresh_hud()
	_refresh_safehouse_panel()


func set_generation_theme_choice(theme_id: StringName, reset_current: bool = true) -> bool:
	if not _get_stage_generation_theme_choice_ids().has(theme_id):
		_refresh_generation_theme_choice_buttons()
		_refresh_safehouse_panel()
		return false
	if generation_selected_theme_id == theme_id:
		_refresh_generation_theme_choice_buttons()
		_refresh_safehouse_panel()
		return true
	generation_selected_theme_id = theme_id
	_refresh_generation_theme_choice_buttons()
	if _built and reset_current and generation_candidate_map_enabled:
		_reset_campus(true, true)
		_append_log("测试：选择主题 %s。" % _get_generation_theme_display_name(theme_id))
		_refresh_hud()
	elif _built:
		var choice_log_prefix: String = "住屋：选择主题" if mode == MODE_SAFEHOUSE else "测试：预选主题"
		_append_log("%s %s。" % [choice_log_prefix, _get_generation_theme_display_name(theme_id)])
		_refresh_hud()
	_refresh_safehouse_panel()
	return true


func get_generation_theme_choice_id() -> StringName:
	return generation_selected_theme_id


func get_stage_generation_theme_choice_summary() -> String:
	var choices: Array[StringName] = _get_stage_generation_theme_choice_ids()
	if choices.is_empty():
		return "无"
	var choice_names: Array[String] = []
	for theme_id: StringName in choices:
		choice_names.append(_get_generation_theme_display_name(theme_id))
	var selected_text: String = "未选择" if generation_selected_theme_id == &"" else _get_generation_theme_display_name(_get_active_generation_theme_id())
	return "已选：%s；三选一：%s" % [
		selected_text,
		" / ".join(choice_names),
	]


func get_stage_spawn_source_summary() -> String:
	return "source=%s,count=%d,pool=%d,target=%d,selected=%d,missing_routes=%s" % [
		_get_stage_spawn_source_id(),
		_get_stage_spawn_interaction_definitions().size(),
		_get_stage_generation_candidate_definitions().size(),
		_get_stage_generation_target_interaction_count(),
		_get_stage_generation_selected_definitions().size(),
		get_stage_spawn_missing_route_node_summary(),
	]


func get_stage_spawn_interaction_ids_summary() -> String:
	var ids: Array[String] = []
	for definition: Resource in _get_stage_spawn_interaction_definitions():
		ids.append(String(definition.get("id")))
	return ",".join(ids)


func get_stage_spawn_missing_route_node_summary() -> String:
	var missing_routes: Array[String] = []
	var definitions: Array[Resource] = _get_stage_spawn_interaction_definitions()
	for route_node_id: StringName in _get_story_guidance_route_order():
		if not _definition_selection_has_route_node(definitions, route_node_id):
			missing_routes.append(String(route_node_id))
	return ",".join(missing_routes)


func get_stage_spawn_layout_summary() -> String:
	var definitions: Array[Resource] = _get_stage_spawn_interaction_definitions()
	var area_counts: Dictionary = _get_generation_layout_area_counts(definitions)
	return "areas=%s,unique=%d,max=%s,resources=%d,avg_route_dist=%d" % [
		_format_generation_layout_area_counts(area_counts),
		area_counts.size(),
		_format_generation_layout_max_area(area_counts),
		_get_generation_layout_resource_count(definitions),
		_get_generation_layout_average_route_distance(definitions),
	]


func get_stage_spawn_audit_panel_text() -> String:
	return "\n".join([
		"Seed %d · %s · %s" % [campus_seed, _get_stage_label(campus_stage), _get_stage_spawn_source_display_name()],
		"主题：%s" % get_stage_generation_theme_choice_summary(),
		"候选：%s" % get_stage_generation_selection_audit_summary(),
		"刷图：%s" % get_stage_spawn_source_summary(),
		"路线：%s" % _format_generation_audit_route_summary(),
		"布局：%s" % get_stage_spawn_layout_summary(),
	])


func get_generation_audit_panel_text() -> String:
	if generation_audit_label == null:
		return get_stage_spawn_audit_panel_text()
	return generation_audit_label.text


func get_player_position() -> Vector2:
	if player == null:
		return Vector2.ZERO
	return player.position


func get_focused_interactable_id() -> StringName:
	if focused_interactable == null:
		return &""
	return focused_interactable.interaction_id


func get_focus_prompt_text() -> String:
	if prompt_label == null:
		return ""
	return prompt_label.text


func get_interactable_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if interactable_root == null:
		return ids
	for child: Node in interactable_root.get_children():
		if _is_safehouse_entrance_node(child):
			continue
		if child.get("interaction_id") != null:
			ids.append(child.interaction_id)
	return ids


func get_available_interactable_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if interactable_root == null:
		return ids
	for child: Node in interactable_root.get_children():
		if _is_safehouse_entrance_node(child):
			continue
		if child.get("interaction_id") != null and not bool(child.collected):
			ids.append(child.interaction_id)
	return ids


func get_interactable_density_audit_summary() -> String:
	return "count=%d,min_spacing=%.1f,building_hits=%d,edge_hits=%d" % [
		_get_active_interactable_positions().size(),
		get_interactable_min_spacing(),
		get_interactable_building_overlap_count(),
		get_interactable_edge_violation_count(),
	]


func get_interactable_min_spacing() -> float:
	var positions: Array[Vector2] = _get_active_interactable_positions()
	if positions.size() < 2:
		return 0.0
	var min_distance: float = INF
	for i: int in range(positions.size()):
		for j: int in range(i + 1, positions.size()):
			min_distance = minf(min_distance, positions[i].distance_to(positions[j]))
	return min_distance if not is_inf(min_distance) else 0.0


func get_interactable_building_overlap_count() -> int:
	var blocked_rects: Array[Rect2] = _get_interactable_blocking_rects()
	var overlap_count: int = 0
	for position: Vector2 in _get_active_interactable_positions():
		for rect: Rect2 in blocked_rects:
			if rect.has_point(position):
				overlap_count += 1
				break
	return overlap_count


func get_interactable_edge_violation_count() -> int:
	var spawn_bounds: Rect2 = _get_interactable_spawn_bounds()
	var violation_count: int = 0
	for position: Vector2 in _get_active_interactable_positions():
		if not spawn_bounds.has_point(position):
			violation_count += 1
	return violation_count


func is_interaction_completed(interaction_id: StringName) -> bool:
	return completed_interaction_ids.has(interaction_id)


func get_completed_interaction_ids() -> Array[StringName]:
	return completed_interaction_ids.duplicate()


func get_active_interaction_id() -> StringName:
	return _active_interaction_id


func get_campus_resource(resource_id: StringName) -> int:
	return int(campus_resources.get(resource_id, 0))


func get_pickup_feedback_count() -> int:
	if feedback_root == null:
		return 0
	return feedback_root.get_child_count()


func get_transition_visible() -> bool:
	return transition_root != null and transition_root.visible


func get_transition_title_text() -> String:
	if transition_title_label == null:
		return ""
	return transition_title_label.text


func get_transition_subtitle_text() -> String:
	if transition_subtitle_label == null:
		return ""
	return transition_subtitle_label.text


func get_return_summary_visible() -> bool:
	return return_summary_panel != null and return_summary_panel.visible


func get_return_summary_result_text() -> String:
	if return_summary_result_label == null:
		return ""
	return return_summary_result_label.text


func get_return_summary_resource_text() -> String:
	if return_summary_resource_label == null:
		return ""
	return return_summary_resource_label.text


func get_return_summary_guidance_text() -> String:
	if return_summary_guidance_label == null:
		return ""
	return return_summary_guidance_label.text


func get_return_summary_guidance_target_interaction_id() -> StringName:
	return _summary_guidance_target_interaction_id


func get_guidance_direction_indicator_visible() -> bool:
	return guidance_direction_indicator != null and guidance_direction_indicator.visible


func get_guidance_direction_indicator_position() -> Vector2:
	if guidance_direction_indicator == null:
		return Vector2.ZERO
	return guidance_direction_indicator.position + guidance_direction_indicator.size * 0.5


func get_guidance_direction_indicator_direction() -> Vector2:
	if guidance_direction_indicator == null or not guidance_direction_indicator.has_method("get_indicator_direction"):
		return Vector2.ZERO
	var raw_direction: Variant = guidance_direction_indicator.call("get_indicator_direction")
	if raw_direction is Vector2:
		return raw_direction
	return Vector2.ZERO


func get_guidance_direction_indicator_target_interaction_id() -> StringName:
	return _guidance_indicator_target_interaction_id


func get_guidance_direction_indicator_discovery_active() -> bool:
	return _is_guidance_indicator_discovery_active()


func get_guidance_direction_indicator_center_safe_rect() -> Rect2:
	return _get_guidance_direction_indicator_center_safe_rect(get_viewport_rect().size)


func get_prompt_panel_rect() -> Rect2:
	if prompt_panel == null:
		return Rect2()
	return prompt_panel.get_global_rect()


func get_focus_info_panel_visible() -> bool:
	return focus_info_panel != null and focus_info_panel.visible


func get_focus_info_panel_rect() -> Rect2:
	if focus_info_panel == null:
		return Rect2()
	return focus_info_panel.get_global_rect()


func get_focus_info_title_text() -> String:
	if focus_info_title_label == null:
		return ""
	return focus_info_title_label.text


func get_focus_info_type_text() -> String:
	if focus_info_type_label == null:
		return ""
	return focus_info_type_label.text


func get_focus_info_route_text() -> String:
	if focus_info_route_label == null:
		return ""
	return focus_info_route_label.text


func get_focus_info_reward_text() -> String:
	if focus_info_reward_label == null:
		return ""
	return focus_info_reward_label.text


func get_focus_info_requirement_text() -> String:
	if focus_info_requirement_label == null:
		return ""
	return focus_info_requirement_label.text


func get_focus_info_summary_text() -> String:
	return "%s|%s|%s|%s|%s" % [
		get_focus_info_title_text(),
		get_focus_info_type_text(),
		get_focus_info_route_text(),
		get_focus_info_reward_text(),
		get_focus_info_requirement_text(),
	]


func get_task_tracker_panel_visible() -> bool:
	return task_tracker_panel != null and task_tracker_panel.visible


func get_task_tracker_panel_rect() -> Rect2:
	if task_tracker_panel == null:
		return Rect2()
	return task_tracker_panel.get_global_rect()


func get_task_tracker_stage_text() -> String:
	if task_tracker_stage_label == null:
		return ""
	return task_tracker_stage_label.text


func get_task_tracker_objective_text() -> String:
	if task_tracker_objective_label == null:
		return ""
	return task_tracker_objective_label.text


func get_task_tracker_map_text() -> String:
	if task_tracker_map_label == null:
		return ""
	return task_tracker_map_label.text


func get_task_tracker_minimap_rect() -> Rect2:
	if task_tracker_minimap == null:
		return Rect2()
	return task_tracker_minimap.get_global_rect()


func get_task_tracker_minimap_point_count() -> int:
	if task_tracker_minimap == null or not task_tracker_minimap.has_method("get_point_count"):
		return 0
	return int(task_tracker_minimap.call("get_point_count"))


func get_task_tracker_minimap_summary_text() -> String:
	if task_tracker_minimap == null or not task_tracker_minimap.has_method("get_marker_summary"):
		return ""
	return str(task_tracker_minimap.call("get_marker_summary"))


func get_task_tracker_supply_text() -> String:
	if task_tracker_supply_label == null:
		return ""
	return task_tracker_supply_label.text


func get_task_tracker_progress_text() -> String:
	if task_tracker_progress_label == null:
		return ""
	return task_tracker_progress_label.text


func get_task_tracker_summary_text() -> String:
	return "%s|%s|%s|%s|%s" % [
		get_task_tracker_stage_text(),
		get_task_tracker_objective_text(),
		get_task_tracker_map_text(),
		get_task_tracker_supply_text(),
		get_task_tracker_progress_text(),
	]


func get_return_summary_panel_rect() -> Rect2:
	if return_summary_panel == null:
		return Rect2()
	return return_summary_panel.get_global_rect()


func get_hud_z_order_summary() -> String:
	if status_panel == null or task_tracker_panel == null or guidance_direction_indicator == null or prompt_panel == null or return_summary_panel == null:
		return ""
	return "status=%d,task=%d,direction=%d,prompt=%d,summary=%d" % [
		status_panel.z_index,
		task_tracker_panel.z_index,
		guidance_direction_indicator.z_index,
		prompt_panel.z_index,
		return_summary_panel.z_index,
	]


func get_status_panel_rect() -> Rect2:
	if status_panel == null:
		return Rect2()
	return status_panel.get_global_rect()


func get_hud_status_section_summary() -> String:
	if status_panel == null or status_panel.get_child_count() <= 0:
		return ""
	var status_box: Node = status_panel.get_child(0)
	var sections: Array[String] = []
	for child: Node in status_box.get_children():
		if child is ColorRect or String(child.name) == "SectionRule":
			continue
		sections.append(String(child.name))
	return ",".join(sections)


func get_interactable_marker_state(interaction_id: StringName) -> StringName:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null or not interactable.has_method("get_marker_state"):
		return &""
	return interactable.get_marker_state()


func get_interactable_marker_visual_profile(interaction_id: StringName) -> StringName:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null or not interactable.has_method("get_marker_visual_profile"):
		return &""
	return interactable.get_marker_visual_profile()


func get_interactable_content_tag_summary(interaction_id: StringName) -> String:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null or not interactable is CampusInteractable:
		return ""
	return _format_content_tags(_get_interactable_content_tags(interactable as CampusInteractable), 99)


func get_content_tag_distribution_summary() -> String:
	if interactable_root == null:
		return ""
	return _format_content_tag_distribution(_get_current_content_tag_counts())


func get_stage_generation_profile_summary() -> String:
	return "target=%d,focus=%s,required=%s" % [
		_get_stage_generation_target_interaction_count(),
		_format_content_tags(_get_stage_generation_focus_tags(), 99),
		_format_content_tags(_get_stage_generation_required_tags(), 99),
	]


func get_stage_generation_focus_mix_summary() -> String:
	return _format_generation_tag_count_summary(_get_stage_generation_focus_tags(), _get_current_content_tag_counts())


func get_stage_generation_missing_tag_summary() -> String:
	return _format_content_tags(_get_missing_generation_required_tags(), 99)


func get_stage_generation_tag_audit_summary() -> String:
	var required_tags: Array[StringName] = _get_stage_generation_required_tags()
	var focus_tags: Array[StringName] = _get_stage_generation_focus_tags()
	var counts: Dictionary = _get_current_content_tag_counts()
	var missing_tags: Array[StringName] = _get_missing_generation_required_tags()
	var focus_hits: int = 0
	for tag: StringName in focus_tags:
		if int(counts.get(tag, 0)) > 0:
			focus_hits += 1
	return "target=%d,current=%d,required=%d,missing=%d,focus_hits=%d/%d" % [
		_get_stage_generation_target_interaction_count(),
		get_interactable_ids().size(),
		required_tags.size(),
		missing_tags.size(),
		focus_hits,
		focus_tags.size(),
	]


func get_stage_generation_candidate_pool_summary() -> String:
	return "pool=%d,target=%d,seed=%d,theme=%s" % [
		_get_stage_generation_candidate_definitions().size(),
		_get_stage_generation_target_interaction_count(),
		_get_stage_seed(),
		String(_get_active_generation_theme_id()),
	]


func get_stage_generation_theme_summary() -> String:
	var theme_id: StringName = _get_active_generation_theme_id()
	if theme_id == &"":
		return "无"
	return "%s｜%s" % [
		_get_generation_theme_display_name(theme_id),
		_format_content_tags(_get_generation_theme_tags(theme_id), 99),
	]


func get_stage_generation_selected_interaction_ids_summary() -> String:
	var ids: Array[String] = []
	for definition: Resource in _get_stage_generation_selected_definitions():
		ids.append(String(definition.get("id")))
	return ",".join(ids)


func get_stage_generation_selected_tag_mix_summary() -> String:
	return _format_generation_tag_count_summary(
		_get_stage_generation_focus_tags(),
		_get_content_tag_counts_for_definitions(_get_stage_generation_selected_definitions())
	)


func get_stage_generation_selection_missing_tag_summary() -> String:
	return _format_content_tags(
		_get_missing_generation_required_tags_for_counts(_get_content_tag_counts_for_definitions(_get_stage_generation_selected_definitions())),
		99
	)


func get_stage_generation_selection_audit_summary() -> String:
	var selected_definitions: Array[Resource] = _get_stage_generation_selected_definitions()
	var counts: Dictionary = _get_content_tag_counts_for_definitions(selected_definitions)
	var missing_tags: Array[StringName] = _get_missing_generation_required_tags_for_counts(counts)
	var focus_tags: Array[StringName] = _get_stage_generation_focus_tags()
	var theme_tags: Array[StringName] = _get_stage_generation_theme_tags()
	var prep_tags: Array[StringName] = _get_safehouse_prep_effect_tags()
	var carry_tags: Array[StringName] = _get_safehouse_carry_item_tags()
	var focus_hits: int = 0
	for tag: StringName in focus_tags:
		if int(counts.get(tag, 0)) > 0:
			focus_hits += 1
	var theme_hits: int = _count_generation_theme_matches(selected_definitions, theme_tags)
	var prep_hits: int = _count_generation_theme_matches(selected_definitions, prep_tags)
	var carry_hits: int = _count_generation_theme_matches(selected_definitions, carry_tags)
	return "pool=%d,target=%d,selected=%d,missing=%d,focus_hits=%d/%d,theme=%s,theme_hits=%d/%d,prep=%s,prep_hits=%d/%d,carry=%s,carry_hits=%d/%d" % [
		_get_stage_generation_candidate_definitions().size(),
		_get_stage_generation_target_interaction_count(),
		selected_definitions.size(),
		missing_tags.size(),
		focus_hits,
		focus_tags.size(),
		String(_get_active_generation_theme_id()),
		theme_hits,
		selected_definitions.size(),
		_format_content_tags(prep_tags, 99),
		prep_hits,
		selected_definitions.size(),
		_format_content_tags(carry_tags, 99),
		carry_hits,
		selected_definitions.size(),
	]


func get_marker_visual_profile_summary() -> String:
	var counts: Dictionary = _get_marker_visual_profile_counts()
	var keys: Array[String] = []
	for raw_key: Variant in counts.keys():
		keys.append(String(raw_key))
	keys.sort()

	var parts: Array[String] = []
	for key: String in keys:
		parts.append("%s=%d" % [key, int(counts.get(StringName(key), 0))])
	return ",".join(parts)


func get_marker_visual_profile_legend_text() -> String:
	var counts: Dictionary = _get_marker_visual_profile_counts()
	if counts.is_empty():
		return "图例：暂无点位"
	var parts: Array[String] = []
	for profile: StringName in _get_marker_visual_profile_legend_order():
		var count: int = int(counts.get(profile, 0))
		if count <= 0:
			continue
		parts.append("%s=%s×%d" % [
			_get_marker_visual_profile_short_name(profile),
			_get_marker_visual_profile_shape_name(profile),
			count,
		])
	return "图例：" + " / ".join(parts)


func _get_marker_visual_profile_counts() -> Dictionary:
	var counts: Dictionary = {}
	if interactable_root == null:
		return counts
	for child: Node in interactable_root.get_children():
		if not child is CampusInteractable:
			continue
		var profile: StringName = (child as CampusInteractable).get_marker_visual_profile()
		counts[profile] = int(counts.get(profile, 0)) + 1
	return counts


func _get_marker_visual_profile_legend_order() -> Array[StringName]:
	return [
		&"advisor_npc",
		&"advisor_notice",
		&"peer_npc",
		&"lab_equipment",
		&"library_stack",
		&"committee_panel",
		&"challenge_gate",
		&"committee_gate",
		&"defense_gate",
		&"notice_board",
		&"admin_notice",
		&"revision_notice",
		&"data_cache",
		&"draft_cache",
		&"funds_cache",
		&"inspiration_cache",
		&"notes_cache",
		&"paper_cache",
		&"resource_cache",
		&"safehouse_gate",
		&"rest_corner",
		&"npc_scholar",
	]


func _get_marker_visual_profile_short_name(profile: StringName) -> String:
	match profile:
		&"advisor_npc", &"advisor_notice":
			return "导师"
		&"peer_npc":
			return "同门"
		&"lab_equipment":
			return "设备"
		&"library_stack":
			return "资料"
		&"committee_panel", &"committee_gate":
			return "委员会"
		&"challenge_gate":
			return "Boss"
		&"defense_gate":
			return "答辩"
		&"notice_board":
			return "事件"
		&"admin_notice":
			return "行政"
		&"revision_notice":
			return "返修"
		&"data_cache":
			return "数据"
		&"draft_cache":
			return "草稿"
		&"funds_cache":
			return "经费"
		&"inspiration_cache":
			return "灵感"
		&"notes_cache":
			return "笔记"
		&"paper_cache":
			return "论文"
		&"resource_cache":
			return "补给"
		&"safehouse_gate":
			return "住屋"
		&"rest_corner":
			return "休息"
		_:
			return "交流"


func _get_marker_visual_profile_shape_name(profile: StringName) -> String:
	match profile:
		&"advisor_npc":
			return "讲义"
		&"advisor_notice":
			return "便签"
		&"peer_npc":
			return "双人"
		&"lab_equipment":
			return "仪器"
		&"library_stack":
			return "书堆"
		&"committee_panel":
			return "评审席"
		&"challenge_gate", &"committee_gate", &"defense_gate":
			return "门"
		&"notice_board", &"admin_notice", &"revision_notice":
			return "公告"
		&"data_cache":
			return "样本"
		&"draft_cache":
			return "纸页"
		&"funds_cache":
			return "票据"
		&"inspiration_cache":
			return "灯泡"
		&"notes_cache":
			return "本子"
		&"paper_cache":
			return "碎片"
		&"rest_corner":
			return "长椅"
		&"resource_cache":
			return "箱"
		&"safehouse_gate":
			return "门"
		_:
			return "NPC"


func get_interactable_requirement_summary(interaction_id: StringName) -> String:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null:
		return ""
	return str(interactable.get("requirement_summary"))


func get_interactable_requirement_intercept_mode(interaction_id: StringName) -> StringName:
	var interactable: Variant = _find_interactable(interaction_id)
	if not interactable is CampusInteractable:
		return &""
	return _get_interactable_requirement_intercept_mode(interactable as CampusInteractable)


func get_story_guidance_text() -> String:
	if guidance_label == null:
		return _format_story_guidance_text()
	return guidance_label.text


func get_guidance_legend_text() -> String:
	return GUIDANCE_LEGEND_TEXT


func get_story_guidance_supply_hint_text() -> String:
	var target: CampusInteractable = _get_story_guidance_target()
	if target == null:
		return ""
	return _format_requirement_supply_advice_for_interactable(target)


func get_supply_hint_target_interaction_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if interactable_root == null:
		return ids
	for child: Node in interactable_root.get_children():
		if child is CampusInteractable:
			var interactable: CampusInteractable = child as CampusInteractable
			if interactable.is_supply_hint_target():
				ids.append(interactable.interaction_id)
	return ids


func get_story_guidance_target_interaction_id() -> StringName:
	var interactable: CampusInteractable = _get_story_guidance_target()
	if interactable == null:
		return &""
	return interactable.interaction_id


func get_story_guidance_target_route_node_id() -> StringName:
	var interactable: CampusInteractable = _get_story_guidance_target()
	if interactable == null:
		return &""
	return interactable.route_node_id


func is_interactable_guidance_target(interaction_id: StringName) -> bool:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null or not interactable.has_method("is_guidance_target"):
		return false
	return interactable.is_guidance_target()


func is_interactable_summary_guidance_target(interaction_id: StringName) -> bool:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null or not interactable.has_method("is_summary_guidance_target"):
		return false
	return interactable.is_summary_guidance_target()


func is_interactable_focused_target(interaction_id: StringName) -> bool:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null or not interactable.has_method("is_focused_target"):
		return false
	return interactable.is_focused_target()


func get_interactable_focus_role_tag(interaction_id: StringName) -> String:
	var interactable: Variant = _find_interactable(interaction_id)
	if not interactable is CampusInteractable:
		return ""
	return _format_interactable_focus_role_tag(interactable as CampusInteractable)


func get_pending_condition_override_interaction_id() -> StringName:
	return _pending_condition_override_interaction_id


func get_stage_debug_button_count() -> int:
	return stage_debug_buttons.size()


func is_stage_debug_button_disabled(stage: StringName) -> bool:
	var normalized_stage: StringName = _normalize_campus_stage(stage)
	var button: Button = stage_debug_buttons.get(normalized_stage, null)
	if button == null:
		return false
	return button.disabled


func set_campus_stage(stage: StringName) -> void:
	campus_stage = _normalize_campus_stage(stage)
	_clear_generation_theme_choice()
	if _built:
		_reset_campus()


func get_campus_stage_for_route_node(route_node_id: StringName) -> StringName:
	return _get_campus_stage_for_route_node(route_node_id)


func get_active_route_node_id() -> StringName:
	if battle_instance == null:
		return &""
	if battle_instance.route == null:
		return &""
	return battle_instance.route.get_current_node_id()


func try_start_focused_interaction() -> bool:
	if focused_interactable == null:
		return false
	return _start_interaction(focused_interactable)


func try_start_interaction_by_id(interaction_id: StringName) -> bool:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null:
		return false
	return _start_interaction(interactable)


func return_to_campus() -> void:
	var resolution_log: String = _resolve_active_battle_interaction()
	var next_story_stage: StringName = _get_campus_stage_for_route_node(get_active_route_node_id())
	_hide_battle_transition()
	_clear_battle_layer()
	mode = MODE_OVERWORLD
	if world_root != null:
		world_root.visible = true
	if hud_root != null:
		hud_root.visible = true
	if battle_layer != null:
		battle_layer.visible = false
	if player != null:
		player.set_movement_enabled(true)
	if resolution_log == "":
		resolution_log = "回到校园。"
	_append_log(resolution_log)
	var stage_advanced: bool = _advance_campus_stage_from_story(next_story_stage)
	if not stage_advanced:
		_refresh_condition_marker_states()
		_refresh_story_guidance()
		_clear_active_interaction_context()
		_refresh_hud()
	_show_return_summary_panel(resolution_log)
	_show_campus_return_transition(resolution_log)


func _unhandled_input(event: InputEvent) -> void:
	if mode != MODE_OVERWORLD:
		return
	if _has_pending_carry_choice():
		if event.is_action_pressed("ui_cancel"):
			_cancel_pending_carry_choice()
		return
	if event.is_action_pressed("ui_accept"):
		try_start_focused_interaction()


func _build_scene_tree() -> void:
	world_root = Node2D.new()
	world_root.name = "World"
	add_child(world_root)

	map_view = CAMPUS_MAP_VIEW.new()
	map_view.name = "CampusMap"
	world_root.add_child(map_view)

	_add_site_labels()

	interactable_root = Node2D.new()
	interactable_root.name = "Interactables"
	world_root.add_child(interactable_root)

	feedback_root = Node2D.new()
	feedback_root.name = "WorldFeedback"
	feedback_root.z_index = 80
	world_root.add_child(feedback_root)

	player = CAMPUS_PLAYER.new()
	player.name = "Player"
	player.position = PLAYER_START_POSITION
	player.map_bounds = map_view.get_map_bounds()
	player._ensure_collision_shape()
	world_root.add_child(player)

	var camera: Camera2D = Camera2D.new()
	camera.name = "CampusCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.zoom = Vector2.ONE
	var map_size: Vector2 = map_view.get_map_size()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_size.x)
	camera.limit_bottom = int(map_size.y)
	player.add_child(camera)

	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	hud_layer.layer = 1
	add_child(hud_layer)
	_build_hud()

	battle_layer = CanvasLayer.new()
	battle_layer.name = "BattleLayer"
	battle_layer.layer = 2
	battle_layer.visible = false
	add_child(battle_layer)

	transition_layer = CanvasLayer.new()
	transition_layer.name = "TransitionLayer"
	transition_layer.layer = 5
	add_child(transition_layer)
	_build_transition_layer()

	safehouse_layer = CanvasLayer.new()
	safehouse_layer.name = "SafehouseLayer"
	safehouse_layer.layer = 4
	safehouse_layer.visible = false
	add_child(safehouse_layer)
	_build_safehouse_layer()


func _reset_campus(preserve_resources: bool = false, preserve_log: bool = false) -> void:
	mode = MODE_OVERWORLD
	if not preserve_resources:
		campus_resources.clear()
	if not preserve_log:
		interaction_log.clear()
	completed_interaction_ids.clear()
	safehouse_used_carry_trigger_keys.clear()
	safehouse_used_carry_option_keys.clear()
	focused_interactable = null
	_pending_condition_override_interaction_id = &""
	_pending_carry_battle_effect.clear()
	_clear_pending_carry_choice(false)
	_summary_guidance_target_interaction_id = &""
	_guidance_indicator_target_interaction_id = &""
	_guidance_indicator_discovery_time = 0.0
	_clear_active_interaction_context()
	_clear_container_children(interactable_root)
	_clear_container_children(feedback_root)
	_spawn_interactables()
	_refresh_condition_marker_states()
	_refresh_story_guidance()
	if player != null:
		player.position = PLAYER_START_POSITION
		player.set_movement_enabled(true)
	if world_root != null:
		world_root.visible = true
	if hud_root != null:
		hud_root.visible = true
	if battle_layer != null:
		battle_layer.visible = false
	if safehouse_layer != null:
		safehouse_layer.visible = false
	_hide_battle_transition()
	_hide_return_summary_panel()
	_clear_battle_layer()
	_append_log("新的%s校园日程开始：Seed %d。" % [_get_stage_label(campus_stage), campus_seed])
	_refresh_hud()
	_refresh_safehouse_panel()


func _reset_safehouse_progression() -> void:
	safehouse_prep_action_points = SAFEHOUSE_PREP_ACTION_POINTS_PER_DAY
	safehouse_active_prep_effects.clear()
	safehouse_completed_prep_action_ids.clear()
	safehouse_attribute_points.clear()
	safehouse_used_carry_trigger_keys.clear()
	safehouse_used_carry_option_keys.clear()
	for attribute_id: StringName in _get_safehouse_attribute_ids():
		safehouse_attribute_points[attribute_id] = 0


func _get_safehouse_prep_action_definitions() -> Array[Dictionary]:
	return [
		{
			"id": &"rest_reset",
			"name": "休息调整",
			"purpose": "压住压力波动，避免下一次探索被坏状态拖垮",
			"growth": {&"emotional_resilience": 1},
			"resources": {&"inspiration": 1},
			"effect_id": &"mental_buffer",
			"effect_name": "缓冲心态",
			"effect_tags": [&"self_care", &"inspiration", &"recovery"],
			"effect_summary": "校园更偏灵感、休息和自我照护点",
		},
		{
			"id": &"literature_reading",
			"name": "文献阅读",
			"purpose": "建立研究问题感，让图书馆和论文线索更有价值",
			"growth": {&"academic_understanding": 1},
			"resources": {&"paper_fragments": 1},
			"effect_id": &"literature_clue",
			"effect_name": "文献线索",
			"effect_tags": [&"reading", &"library", &"paper_fragments", &"writing"],
			"effect_summary": "校园更偏阅读、图书馆、论文碎片和写作点",
		},
		{
			"id": &"pilot_experiment",
			"name": "预实验",
			"purpose": "提前排雷，让实验楼和设备相关收益更稳定",
			"growth": {&"experimental_engineering": 1},
			"resources": {&"data": 1},
			"effect_id": &"equipment_hands",
			"effect_name": "设备手感",
			"effect_tags": [&"lab", &"equipment", &"data"],
			"effect_summary": "校园更偏实验楼、设备和数据点",
		},
		{
			"id": &"mock_presentation",
			"name": "模拟汇报",
			"purpose": "练习表达结构，为组会、导师和委员会场合做准备",
			"growth": {&"expression_control": 1},
			"resources": {&"reputation": 1},
			"effect_id": &"presentation_script",
			"effect_name": "汇报底稿",
			"effect_tags": [&"meeting", &"advisor", &"committee"],
			"effect_summary": "校园更偏导师、会议和委员会点",
		},
		{
			"id": &"reflection_log",
			"name": "复盘日志",
			"purpose": "把失败和混乱整理成方法，下次少走弯路",
			"growth": {&"methodology": 1},
			"resources": {&"experience_lessons": 1},
			"effect_id": &"reflection_frame",
			"effect_name": "复盘框架",
			"effect_tags": [&"reflection", &"method", &"revision"],
			"effect_summary": "校园更偏方法、复盘和返修修正点",
		},
		{
			"id": &"deck_tuning",
			"name": "整理卡组",
			"purpose": "明确这次构筑方向，减少无效卡和摇摆路线",
			"growth": {&"writing_structure": 1},
			"resources": {&"draft": 1},
			"effect_id": &"deck_focus",
			"effect_name": "构筑焦点",
			"effect_tags": [&"draft", &"writing", &"method"],
			"effect_summary": "校园更偏草稿、写作和方法点",
		},
		{
			"id": &"material_index",
			"name": "材料归档",
			"purpose": "把数据、草稿和方法笔记整理成能快速调用的资料",
			"growth": {&"presence_judgment": 1},
			"resources": {&"methodology_notes": 1},
			"effect_id": &"field_notes",
			"effect_name": "资料索引",
			"effect_tags": [&"supply", &"resource", &"methodology_notes", &"draft", &"data"],
			"effect_summary": "校园更偏补给、方法笔记、数据和草稿点",
		},
		{
			"id": &"peer_contact",
			"name": "联系同门",
			"purpose": "提前约人交流，把孤立探索变成协作机会",
			"growth": {&"relationship_sense": 1},
			"resources": {&"experience_lessons": 1},
			"effect_id": &"peer_window",
			"effect_name": "同门窗口",
			"effect_tags": [&"peer", &"collaboration", &"social"],
			"effect_summary": "校园更偏同门、合作和社交点",
		},
	]


func _get_safehouse_prep_action_definition(action_id: StringName) -> Dictionary:
	for action_def: Dictionary in _get_safehouse_prep_action_definitions():
		if StringName(action_def.get("id", &"")) == action_id:
			return action_def
	return {}


func _get_safehouse_carry_item_definitions() -> Array[Dictionary]:
	return [
		{
			"id": &"laptop",
			"name": "笔记本电脑",
			"purpose": "现场处理数据、草稿和文献，适合写作/数据路线",
			"tags": [&"data", &"draft", &"writing", &"method"],
			"summary": "偏数据、草稿、写作和方法点",
			"trigger_resource": &"draft",
			"trigger_amount": 1,
			"trigger_summary": "现场整理材料",
			"option_label": "现场补写记录",
			"option_resource": &"methodology_notes",
			"option_amount": 1,
			"option_summary": "把临场信息整理成方法笔记",
			"battle_effect_id": &"opening_draw",
			"battle_effect_amount": 1,
			"battle_effect_summary": "开局额外抽 1 张牌",
		},
		{
			"id": &"lab_consumables",
			"name": "实验耗材包",
			"purpose": "临时补齐实验耗材，适合实验楼和设备路线",
			"tags": [&"lab", &"equipment", &"data"],
			"summary": "偏实验楼、设备和数据点",
			"trigger_resource": &"data",
			"trigger_amount": 1,
			"trigger_summary": "补齐实验材料",
			"option_label": "用耗材兜底误差",
			"option_resource": &"data",
			"option_amount": 1,
			"option_summary": "把一次实验风险转成可用数据",
			"battle_effect_id": &"starting_block",
			"battle_effect_amount": 4,
			"battle_effect_summary": "开局获得 4 防护",
		},
		{
			"id": &"formal_jacket",
			"name": "正装外套",
			"purpose": "应对汇报、行政窗口和委员会场合，降低第一印象风险",
			"tags": [&"meeting", &"advisor", &"committee", &"administration", &"reputation"],
			"summary": "偏会议、导师、委员会和行政点",
			"trigger_resource": &"reputation",
			"trigger_amount": 1,
			"trigger_summary": "稳住正式场合",
			"option_label": "稳住正式场合",
			"option_resource": &"reputation",
			"option_amount": 1,
			"option_summary": "用得体表现换取声望余量",
			"battle_effect_id": &"pressure_reduction",
			"battle_effect_amount": 1,
			"battle_effect_summary": "普通交流每回合压力 -1；Boss 场合改为开局防护",
		},
		{
			"id": &"coffee_snack",
			"name": "咖啡零食",
			"purpose": "支撑长时间探索，给休息、食堂和灵感事件留余地",
			"tags": [&"self_care", &"inspiration", &"canteen", &"recovery"],
			"summary": "偏照护、灵感、食堂和恢复点",
			"trigger_resource": &"inspiration",
			"trigger_amount": 1,
			"trigger_summary": "补一点精神余量",
			"option_label": "补充状态再继续",
			"option_resource": &"inspiration",
			"option_amount": 1,
			"option_summary": "把疲惫节点转成灵感余量",
			"battle_effect_id": &"first_turn_action_point",
			"battle_effect_amount": 1,
			"battle_effect_summary": "首回合行动点 +1",
		},
		{
			"id": &"annotated_draft",
			"name": "导师批注稿",
			"purpose": "带着关键批注出门，适合导师、写作和返修路线",
			"tags": [&"advisor", &"draft", &"writing", &"revision"],
			"summary": "偏导师、草稿、写作和返修点",
			"trigger_resource": &"draft",
			"trigger_amount": 1,
			"trigger_summary": "对照批注修稿",
			"option_label": "按批注重排材料",
			"option_resource": &"draft",
			"option_amount": 1,
			"option_summary": "把导师意见转成可提交草稿",
			"battle_effect_id": &"starting_progress",
			"battle_effect_amount": 5,
			"battle_effect_summary": "开局获得 5 进度",
		},
		{
			"id": &"peer_contact_list",
			"name": "同门联络表",
			"purpose": "提前准备协作窗口，适合同门、合作和社交路线",
			"tags": [&"peer", &"collaboration", &"social"],
			"summary": "偏同门、合作和社交点",
			"trigger_resource": &"experience_lessons",
			"trigger_amount": 1,
			"trigger_summary": "交换一手经验",
			"option_label": "先问同门借经验",
			"option_resource": &"experience_lessons",
			"option_amount": 1,
			"option_summary": "用协作关系换取经验教训",
			"battle_effect_id": &"target_progress_reduction",
			"battle_effect_amount": 4,
			"battle_effect_summary": "本场目标进度 -4",
		},
	]


func _get_safehouse_carry_item_definition(item_id: StringName) -> Dictionary:
	for item_def: Dictionary in _get_safehouse_carry_item_definitions():
		if StringName(item_def.get("id", &"")) == item_id:
			return item_def
	return {}


func _toggle_safehouse_carry_item(item_id: StringName) -> bool:
	if mode != MODE_SAFEHOUSE:
		return false
	var item_def: Dictionary = _get_safehouse_carry_item_definition(item_id)
	if item_def.is_empty():
		return false
	if safehouse_selected_carry_item_ids.has(item_id):
		safehouse_selected_carry_item_ids.erase(item_id)
		_append_log("住屋携带：取下%s。" % str(item_def.get("name", "")))
		_refresh_safehouse_panel()
		return true
	if safehouse_selected_carry_item_ids.size() >= SAFEHOUSE_CARRY_SLOT_COUNT:
		return false
	safehouse_selected_carry_item_ids.append(item_id)
	_append_log("住屋携带：带上%s。%s" % [str(item_def.get("name", "")), str(item_def.get("summary", ""))])
	_refresh_safehouse_panel()
	return true


func _apply_safehouse_prep_action(action_id: StringName) -> bool:
	if mode != MODE_SAFEHOUSE:
		return false
	if safehouse_prep_action_points <= 0:
		return false
	if safehouse_completed_prep_action_ids.has(action_id):
		return false
	var action_def: Dictionary = _get_safehouse_prep_action_definition(action_id)
	if action_def.is_empty():
		return false

	safehouse_prep_action_points -= 1
	safehouse_completed_prep_action_ids.append(action_id)

	var growth: Dictionary = action_def.get("growth", {})
	for raw_attribute_id: Variant in growth.keys():
		var attribute_id: StringName = StringName(raw_attribute_id)
		safehouse_attribute_points[attribute_id] = int(safehouse_attribute_points.get(attribute_id, 0)) + int(growth.get(raw_attribute_id, 0))

	var resources: Dictionary = action_def.get("resources", {})
	for raw_resource_id: Variant in resources.keys():
		var resource_id: StringName = StringName(raw_resource_id)
		var amount: int = int(resources.get(raw_resource_id, 0))
		if amount <= 0:
			continue
		campus_resources[resource_id] = int(campus_resources.get(resource_id, 0)) + amount

	var effect_id: StringName = StringName(action_def.get("effect_id", &""))
	if effect_id != &"":
		safehouse_active_prep_effects[effect_id] = action_def.duplicate(true)

	_append_log("住屋准备：%s。%s" % [str(action_def.get("name", "")), str(action_def.get("effect_summary", ""))])
	_refresh_safehouse_panel()
	return true


func _apply_safehouse_carry_triggers_for_interactable(interactable: CampusInteractable) -> Array[String]:
	var triggered_parts: Array[String] = []
	if interactable == null or safehouse_selected_carry_item_ids.is_empty():
		return triggered_parts
	if interactable.interaction_kind != &"resource":
		return triggered_parts
	var interactable_tags: Array[StringName] = _get_interactable_content_tags(interactable)
	for item_id: StringName in safehouse_selected_carry_item_ids:
		var trigger_key: String = "%s:%s" % [String(interactable.interaction_id), String(item_id)]
		if safehouse_used_carry_trigger_keys.has(trigger_key):
			continue
		var item_def: Dictionary = _get_safehouse_carry_item_definition(item_id)
		if item_def.is_empty():
			continue
		if not _has_any_content_tag(interactable_tags, _normalize_content_tags(item_def.get("tags", []))):
			continue
		var resource_id: StringName = StringName(item_def.get("trigger_resource", &""))
		var amount: int = int(item_def.get("trigger_amount", 0))
		if resource_id == &"" or amount <= 0:
			continue
		campus_resources[resource_id] = int(campus_resources.get(resource_id, 0)) + amount
		safehouse_used_carry_trigger_keys.append(trigger_key)
		triggered_parts.append("%s：%s +%d" % [
			str(item_def.get("name", String(item_id))),
			_get_resource_display_name(resource_id),
			amount,
		])
	if not triggered_parts.is_empty():
		_append_log("携带物触发：%s。" % "；".join(triggered_parts))
	return triggered_parts


func _format_safehouse_carry_trigger_hint(interactable: CampusInteractable) -> String:
	if interactable == null or safehouse_selected_carry_item_ids.is_empty():
		return ""
	if interactable.interaction_kind != &"resource":
		return ""
	var interactable_tags: Array[StringName] = _get_interactable_content_tags(interactable)
	var parts: Array[String] = []
	for item_id: StringName in safehouse_selected_carry_item_ids:
		var item_def: Dictionary = _get_safehouse_carry_item_definition(item_id)
		if item_def.is_empty():
			continue
		if not _has_any_content_tag(interactable_tags, _normalize_content_tags(item_def.get("tags", []))):
			continue
		var resource_id: StringName = StringName(item_def.get("trigger_resource", &""))
		var amount: int = int(item_def.get("trigger_amount", 0))
		if resource_id == &"" or amount <= 0:
			continue
		parts.append("%s：%s +%d" % [
			str(item_def.get("name", String(item_id))),
			_get_resource_display_name(resource_id),
			amount,
		])
	return " / ".join(parts)


func _apply_safehouse_carry_options_for_interactable(interactable: CampusInteractable) -> Array[String]:
	var option_parts: Array[String] = []
	for option: Dictionary in _get_available_safehouse_carry_options_for_interactable(interactable):
		option_parts.append(_apply_safehouse_carry_option(option, interactable))
	if not option_parts.is_empty():
		_append_log("携带选项：%s。" % "；".join(option_parts))
	return option_parts


func _format_safehouse_carry_option_hint(interactable: CampusInteractable) -> String:
	var parts: Array[String] = []
	for option: Dictionary in _get_available_safehouse_carry_options_for_interactable(interactable):
		parts.append(_format_safehouse_carry_option_entry(option))
	return " / ".join(parts)


func _get_available_safehouse_carry_options_for_interactable(interactable: CampusInteractable) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if interactable == null or safehouse_selected_carry_item_ids.is_empty():
		return options
	if interactable.interaction_kind == &"resource" or interactable.interaction_kind == SAFEHOUSE_INTERACTION_KIND:
		return options
	var interactable_tags: Array[StringName] = _get_interactable_content_tags(interactable)
	for item_id: StringName in safehouse_selected_carry_item_ids:
		var option_key: String = "%s:%s" % [String(interactable.interaction_id), String(item_id)]
		if safehouse_used_carry_option_keys.has(option_key):
			continue
		var item_def: Dictionary = _get_safehouse_carry_item_definition(item_id)
		if item_def.is_empty():
			continue
		var option_tags: Array[StringName] = _normalize_content_tags(item_def.get("option_tags", item_def.get("tags", [])))
		if not _has_any_content_tag(interactable_tags, option_tags):
			continue
		var resource_id: StringName = StringName(item_def.get("option_resource", item_def.get("trigger_resource", &"")))
		var amount: int = int(item_def.get("option_amount", item_def.get("trigger_amount", 0)))
		if resource_id == &"" or amount <= 0:
			continue
		options.append({
			"item_id": item_id,
			"item_name": str(item_def.get("name", String(item_id))),
			"option_label": str(item_def.get("option_label", item_def.get("trigger_summary", ""))),
			"option_summary": str(item_def.get("option_summary", "")),
			"resource_id": resource_id,
			"amount": amount,
			"battle_effect_id": StringName(item_def.get("battle_effect_id", &"")),
			"battle_effect_amount": int(item_def.get("battle_effect_amount", 0)),
			"battle_effect_summary": str(item_def.get("battle_effect_summary", "")),
		})
	return options


func _apply_safehouse_carry_option_for_interactable(interactable: CampusInteractable, item_id: StringName) -> bool:
	for option: Dictionary in _get_available_safehouse_carry_options_for_interactable(interactable):
		if StringName(option.get("item_id", &"")) != item_id:
			continue
		var option_text: String = _apply_safehouse_carry_option(option, interactable)
		_append_log("携带选项：%s。" % option_text)
		return true
	return false


func _apply_safehouse_carry_option(option: Dictionary, interactable: CampusInteractable) -> String:
	var item_id: StringName = StringName(option.get("item_id", &""))
	var resource_id: StringName = StringName(option.get("resource_id", &""))
	var amount: int = int(option.get("amount", 0))
	if interactable == null or item_id == &"" or resource_id == &"" or amount <= 0:
		return ""
	var option_key: String = "%s:%s" % [String(interactable.interaction_id), String(item_id)]
	if safehouse_used_carry_option_keys.has(option_key):
		return ""
	campus_resources[resource_id] = int(campus_resources.get(resource_id, 0)) + amount
	safehouse_used_carry_option_keys.append(option_key)
	return _format_safehouse_carry_option_entry(option)


func _format_safehouse_carry_option_entry(option: Dictionary) -> String:
	var resource_id: StringName = StringName(option.get("resource_id", &""))
	var text: String = "%s「%s」：%s +%d" % [
		str(option.get("item_name", String(option.get("item_id", &"")))),
		str(option.get("option_label", "")),
		_get_resource_display_name(resource_id),
		int(option.get("amount", 0)),
	]
	var battle_summary: String = str(option.get("battle_effect_summary", ""))
	if battle_summary != "":
		text += "，%s" % battle_summary
	return text


func _has_any_content_tag(source_tags: Array[StringName], query_tags: Array[StringName]) -> bool:
	for tag: StringName in query_tags:
		if source_tags.has(tag):
			return true
	return false


func _get_safehouse_attribute_ids() -> Array[StringName]:
	return [
		&"academic_understanding",
		&"methodology",
		&"experimental_engineering",
		&"writing_structure",
		&"expression_control",
		&"relationship_sense",
		&"emotional_resilience",
		&"presence_judgment",
	]


func _format_safehouse_attribute_summary() -> String:
	return "智性：%s\n情性：%s" % [
		_format_safehouse_attribute_category_summary([
			&"academic_understanding",
			&"methodology",
			&"experimental_engineering",
			&"writing_structure",
		]),
		_format_safehouse_attribute_category_summary([
			&"expression_control",
			&"relationship_sense",
			&"emotional_resilience",
			&"presence_judgment",
		]),
	]


func _format_safehouse_attribute_category_summary(attribute_ids: Array[StringName]) -> String:
	var parts: Array[String] = []
	for attribute_id: StringName in attribute_ids:
		parts.append("%s %d" % [_get_safehouse_attribute_display_name(attribute_id), int(safehouse_attribute_points.get(attribute_id, 0))])
	return " / ".join(parts)


func _get_safehouse_attribute_display_name(attribute_id: StringName) -> String:
	match attribute_id:
		&"academic_understanding":
			return "学术理解"
		&"methodology":
			return "方法论"
		&"experimental_engineering":
			return "实验工程"
		&"writing_structure":
			return "写作建模"
		&"expression_control":
			return "表达控场"
		&"relationship_sense":
			return "关系经营"
		&"emotional_resilience":
			return "情绪韧性"
		&"presence_judgment":
			return "场面判断"
		_:
			return String(attribute_id)


func _format_safehouse_prep_effect_summary() -> String:
	if safehouse_active_prep_effects.is_empty():
		return "无"
	var keys: Array[String] = []
	for raw_effect_id: Variant in safehouse_active_prep_effects.keys():
		keys.append(String(raw_effect_id))
	keys.sort()
	var parts: Array[String] = []
	for raw_key: String in keys:
		var effect_def: Dictionary = safehouse_active_prep_effects.get(StringName(raw_key), {})
		parts.append(str(effect_def.get("effect_name", raw_key)))
	return " / ".join(parts)


func _get_safehouse_prep_effect_tags() -> Array[StringName]:
	var tags: Array[StringName] = []
	for raw_effect_def: Variant in safehouse_active_prep_effects.values():
		if not raw_effect_def is Dictionary:
			continue
		var effect_def: Dictionary = raw_effect_def
		for raw_tag: Variant in effect_def.get("effect_tags", []):
			_append_unique_content_tag(tags, StringName(raw_tag))
	return tags


func _get_safehouse_carry_item_tags() -> Array[StringName]:
	var tags: Array[StringName] = []
	for item_id: StringName in safehouse_selected_carry_item_ids:
		var item_def: Dictionary = _get_safehouse_carry_item_definition(item_id)
		for raw_tag: Variant in item_def.get("tags", []):
			_append_unique_content_tag(tags, StringName(raw_tag))
	return tags


func _format_safehouse_carry_item_summary() -> String:
	if safehouse_selected_carry_item_ids.is_empty():
		return "无"
	var parts: Array[String] = []
	for item_id: StringName in safehouse_selected_carry_item_ids:
		var item_def: Dictionary = _get_safehouse_carry_item_definition(item_id)
		parts.append(str(item_def.get("name", String(item_id))))
	return " / ".join(parts)


func _format_safehouse_carry_item_button_text(item_def: Dictionary) -> String:
	return "%s\n%s" % [
		str(item_def.get("name", "")),
		str(item_def.get("summary", "")),
	]


func _format_safehouse_carry_item_tooltip(item_def: Dictionary) -> String:
	var trigger_resource: StringName = StringName(item_def.get("trigger_resource", &""))
	var trigger_amount: int = int(item_def.get("trigger_amount", 0))
	var option_resource: StringName = StringName(item_def.get("option_resource", &""))
	var option_amount: int = int(item_def.get("option_amount", 0))
	var battle_summary: String = str(item_def.get("battle_effect_summary", ""))
	var trigger_text: String = "资源点：无"
	var option_text: String = "非资源点：无"
	if trigger_resource != &"" and trigger_amount > 0:
		trigger_text = "资源点：%s，%s +%d" % [
			str(item_def.get("trigger_summary", "触发")),
			_get_resource_display_name(trigger_resource),
			trigger_amount,
		]
	if option_resource != &"" and option_amount > 0:
		option_text = "非资源点：%s，%s +%d" % [
			str(item_def.get("option_label", "专属选项")),
			_get_resource_display_name(option_resource),
			option_amount,
		]
		if battle_summary != "":
			option_text += "；%s" % battle_summary
	return "目的：%s\n倾向：%s\n%s\n%s" % [
		str(item_def.get("purpose", "")),
		_format_content_tags(_normalize_content_tags(item_def.get("tags", [])), 99),
		trigger_text,
		option_text,
	]


func _format_safehouse_prep_action_button_text(action_def: Dictionary) -> String:
	return "%s\n%s" % [
		str(action_def.get("name", "")),
		str(action_def.get("purpose", "")),
	]


func _format_safehouse_prep_action_tooltip(action_def: Dictionary) -> String:
	return "目的：%s\n成长：%s\n获得：%s\n带出：%s - %s" % [
		str(action_def.get("purpose", "")),
		_format_safehouse_growth_summary(action_def.get("growth", {})),
		_format_safehouse_resource_delta_summary(action_def.get("resources", {})),
		str(action_def.get("effect_name", "")),
		str(action_def.get("effect_summary", "")),
	]


func _format_safehouse_growth_summary(growth: Dictionary) -> String:
	if growth.is_empty():
		return "无"
	var parts: Array[String] = []
	for raw_attribute_id: Variant in growth.keys():
		parts.append("%s +%d" % [_get_safehouse_attribute_display_name(StringName(raw_attribute_id)), int(growth.get(raw_attribute_id, 0))])
	return "、".join(parts)


func _format_safehouse_resource_delta_summary(resources: Dictionary) -> String:
	if resources.is_empty():
		return "无"
	var parts: Array[String] = []
	for raw_resource_id: Variant in resources.keys():
		parts.append("%s +%d" % [_get_resource_display_name(StringName(raw_resource_id)), int(resources.get(raw_resource_id, 0))])
	return "、".join(parts)


func _enter_safehouse(record_return: bool = false, keep_transition: bool = false) -> void:
	mode = MODE_SAFEHOUSE
	focused_interactable = null
	_pending_condition_override_interaction_id = &""
	_clear_active_interaction_context()
	_stop_guidance_indicator_discovery()
	_hide_guidance_direction_indicator()
	if not keep_transition:
		_hide_battle_transition()
	_hide_return_summary_panel()
	if player != null:
		player.set_movement_enabled(false)
	if world_root != null:
		world_root.visible = false
	if hud_root != null:
		hud_root.visible = false
	if battle_layer != null:
		battle_layer.visible = false
	if safehouse_layer != null:
		safehouse_layer.visible = true
	if safehouse_root != null:
		safehouse_root.visible = true
	if record_return:
		_append_log("安全返回住屋。")
	_refresh_safehouse_panel()


func _depart_safehouse_to_campus() -> void:
	if mode != MODE_SAFEHOUSE:
		return
	generation_candidate_map_enabled = true
	var choices: Array[StringName] = _get_stage_generation_theme_choice_ids()
	if generation_selected_theme_id == &"" and not choices.is_empty():
		generation_selected_theme_id = choices[0]
	var depart_theme_name: String = _get_generation_theme_display_name(_get_active_generation_theme_id())
	var prep_summary: String = _format_safehouse_prep_effect_summary()
	var carry_summary: String = _format_safehouse_carry_item_summary()
	_reset_campus(true, true)
	_append_log("从住屋出发：第 %d 天，%s，准备：%s，携带：%s。" % [safehouse_day, depart_theme_name, prep_summary, carry_summary])
	_refresh_hud()


func _advance_safehouse_day() -> void:
	if mode != MODE_SAFEHOUSE:
		return
	safehouse_day += 1
	var next_seed: int = _generate_debug_campus_seed()
	if next_seed == campus_seed:
		next_seed = (next_seed % CAMPUS_SEED_MAX) + 1
	campus_seed = next_seed
	generation_candidate_map_enabled = true
	safehouse_prep_action_points = SAFEHOUSE_PREP_ACTION_POINTS_PER_DAY
	safehouse_active_prep_effects.clear()
	safehouse_completed_prep_action_ids.clear()
	safehouse_selected_carry_item_ids.clear()
	_clear_generation_theme_choice()
	_append_log("住屋：进入第 %d 天，重新规划校园。" % safehouse_day)
	_refresh_generation_candidate_toggle()
	_refresh_safehouse_panel()


func _add_site_labels() -> void:
	var label_defs: Array[Dictionary] = [
		{"text": "宿舍", "pos": Vector2(150, 128)},
		{"text": "图书馆", "pos": Vector2(642, 126)},
		{"text": "实验楼", "pos": Vector2(1204, 132)},
		{"text": "食堂", "pos": Vector2(242, 660)},
		{"text": "导师办公室", "pos": Vector2(760, 650)},
		{"text": "会议室", "pos": Vector2(1260, 652)},
	]
	for label_def: Dictionary in label_defs:
		var label: Label = Label.new()
		label.text = label_def.get("text", "")
		label.position = label_def.get("pos", Vector2.ZERO)
		label.add_theme_color_override("font_color", Color(0.92, 0.93, 0.84))
		label.add_theme_font_size_override("font_size", 16)
		world_root.add_child(label)


func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.name = "CampusHUD"
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(hud_root)

	status_panel = PanelContainer.new()
	status_panel.name = "StatusPanel"
	status_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	status_panel.position = Vector2(12, 12)
	status_panel.custom_minimum_size = Vector2(HUD_STATUS_PANEL_WIDTH, 0)
	status_panel.z_index = HUD_Z_STATUS
	status_panel.add_theme_stylebox_override("panel", _create_hud_panel_style())
	hud_root.add_child(status_panel)

	var status_box: VBoxContainer = VBoxContainer.new()
	status_box.name = "StatusPanelSections"
	status_box.add_theme_constant_override("separation", 8)
	status_panel.add_child(status_box)

	var overview_section: VBoxContainer = _create_hud_section(status_box, "OverviewSection", "状态")
	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_color_override("font_color", HUD_PRIMARY_TEXT_COLOR)
	status_label.add_theme_font_size_override("font_size", 15)
	overview_section.add_child(status_label)

	var resource_section: VBoxContainer = _create_hud_section(status_box, "ResourceSection", "资源")
	resource_label = Label.new()
	resource_label.text = ""
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resource_label.custom_minimum_size = Vector2(HUD_STATUS_PANEL_WIDTH - 36.0, 0)
	resource_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.46))
	resource_label.add_theme_font_size_override("font_size", 14)
	resource_section.add_child(resource_label)

	var guidance_section: VBoxContainer = _create_hud_section(status_box, "GuidanceSection", "目标")
	guidance_label = Label.new()
	guidance_label.text = ""
	guidance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance_label.custom_minimum_size = Vector2(HUD_STATUS_PANEL_WIDTH - 36.0, 0)
	guidance_label.add_theme_color_override("font_color", Color(0.76, 0.90, 0.94))
	guidance_label.add_theme_font_size_override("font_size", 14)
	guidance_section.add_child(guidance_label)

	_build_guidance_legend(guidance_section)

	var log_section: VBoxContainer = _create_hud_section(status_box, "LogSection", "日志")
	log_label = Label.new()
	log_label.text = ""
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size = Vector2(HUD_STATUS_PANEL_WIDTH - 36.0, 0)
	log_label.add_theme_color_override("font_color", HUD_MUTED_TEXT_COLOR)
	log_label.add_theme_font_size_override("font_size", 13)
	log_section.add_child(log_label)

	_build_stage_debug_controls(status_box)
	_build_task_tracker_panel()
	_build_focus_info_panel()
	_build_carry_choice_panel()

	prompt_panel = PanelContainer.new()
	prompt_panel.name = "PromptPanel"
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_left = -220
	prompt_panel.offset_right = 220
	prompt_panel.offset_top = -76
	prompt_panel.offset_bottom = -18
	prompt_panel.z_index = HUD_Z_PROMPT
	hud_root.add_child(prompt_panel)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_panel.add_child(prompt_label)

	_build_guidance_direction_indicator()
	_build_return_summary_panel()


func _build_task_tracker_panel() -> void:
	task_tracker_panel = PanelContainer.new()
	task_tracker_panel.name = "TaskTrackerPanel"
	task_tracker_panel.anchor_left = 1.0
	task_tracker_panel.anchor_right = 1.0
	task_tracker_panel.anchor_top = 0.0
	task_tracker_panel.anchor_bottom = 0.0
	task_tracker_panel.offset_left = -HUD_TASK_TRACKER_PANEL_WIDTH - 12.0
	task_tracker_panel.offset_right = -12.0
	task_tracker_panel.offset_top = 12.0
	task_tracker_panel.offset_bottom = 260.0
	task_tracker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	task_tracker_panel.z_index = HUD_Z_TASK_TRACKER
	task_tracker_panel.add_theme_stylebox_override("panel", _create_hud_panel_style())
	hud_root.add_child(task_tracker_panel)

	var task_box: VBoxContainer = VBoxContainer.new()
	task_box.name = "TaskTrackerRows"
	task_box.add_theme_constant_override("separation", 4)
	task_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	task_tracker_panel.add_child(task_box)

	var title_label: Label = _create_task_tracker_label(HUD_SECTION_TITLE_COLOR, 12)
	title_label.name = "Title"
	title_label.text = "任务视图"
	task_box.add_child(title_label)

	task_tracker_stage_label = _create_task_tracker_label(HUD_PRIMARY_TEXT_COLOR, 13)
	task_tracker_stage_label.name = "Stage"
	task_box.add_child(task_tracker_stage_label)

	task_tracker_objective_label = _create_task_tracker_label(Color(0.76, 0.90, 0.94), 13)
	task_tracker_objective_label.name = "Objective"
	task_box.add_child(task_tracker_objective_label)

	task_tracker_map_label = _create_task_tracker_label(Color(0.82, 0.86, 0.84), 12)
	task_tracker_map_label.name = "Map"
	task_box.add_child(task_tracker_map_label)

	task_tracker_minimap = CAMPUS_TASK_TRACKER_MINIMAP.new()
	task_tracker_minimap.name = "MiniMap"
	task_tracker_minimap.custom_minimum_size = HUD_TASK_TRACKER_MINIMAP_SIZE
	task_tracker_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	task_box.add_child(task_tracker_minimap)

	task_tracker_supply_label = _create_task_tracker_label(Color(0.98, 0.86, 0.46), 12)
	task_tracker_supply_label.name = "Supply"
	task_box.add_child(task_tracker_supply_label)

	task_tracker_progress_label = _create_task_tracker_label(HUD_MUTED_TEXT_COLOR, 12)
	task_tracker_progress_label.name = "Progress"
	task_box.add_child(task_tracker_progress_label)


func _create_task_tracker_label(font_color: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(HUD_TASK_TRACKER_PANEL_WIDTH - 34.0, 0)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_focus_info_panel() -> void:
	focus_info_panel = PanelContainer.new()
	focus_info_panel.name = "FocusInfoPanel"
	focus_info_panel.anchor_left = 0.5
	focus_info_panel.anchor_right = 0.5
	focus_info_panel.anchor_top = 1.0
	focus_info_panel.anchor_bottom = 1.0
	focus_info_panel.offset_left = -HUD_FOCUS_INFO_PANEL_WIDTH * 0.5
	focus_info_panel.offset_right = HUD_FOCUS_INFO_PANEL_WIDTH * 0.5
	focus_info_panel.offset_top = -294
	focus_info_panel.offset_bottom = -106
	focus_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_info_panel.visible = false
	focus_info_panel.z_index = HUD_Z_FOCUS_INFO
	focus_info_panel.add_theme_stylebox_override("panel", _create_hud_panel_style())
	hud_root.add_child(focus_info_panel)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.name = "FocusInfoRows"
	info_box.add_theme_constant_override("separation", 3)
	info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_info_panel.add_child(info_box)

	focus_info_title_label = _create_focus_info_label(HUD_PRIMARY_TEXT_COLOR, 14)
	focus_info_title_label.name = "Title"
	info_box.add_child(focus_info_title_label)

	focus_info_type_label = _create_focus_info_label(Color(0.76, 0.90, 0.94), 12)
	focus_info_type_label.name = "Type"
	info_box.add_child(focus_info_type_label)

	focus_info_route_label = _create_focus_info_label(Color(0.82, 0.86, 0.84), 12)
	focus_info_route_label.name = "Route"
	info_box.add_child(focus_info_route_label)

	focus_info_reward_label = _create_focus_info_label(Color(0.98, 0.86, 0.46), 12)
	focus_info_reward_label.name = "Reward"
	info_box.add_child(focus_info_reward_label)

	focus_info_requirement_label = _create_focus_info_label(HUD_MUTED_TEXT_COLOR, 12)
	focus_info_requirement_label.name = "Requirement"
	info_box.add_child(focus_info_requirement_label)


func _create_focus_info_label(font_color: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(HUD_FOCUS_INFO_PANEL_WIDTH - 34.0, 0)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_carry_choice_panel() -> void:
	carry_choice_panel = PanelContainer.new()
	carry_choice_panel.name = "CarryChoicePanel"
	carry_choice_panel.anchor_left = 0.5
	carry_choice_panel.anchor_right = 0.5
	carry_choice_panel.anchor_top = 0.5
	carry_choice_panel.anchor_bottom = 0.5
	carry_choice_panel.offset_left = -HUD_CARRY_CHOICE_PANEL_WIDTH * 0.5
	carry_choice_panel.offset_right = HUD_CARRY_CHOICE_PANEL_WIDTH * 0.5
	carry_choice_panel.offset_top = -138
	carry_choice_panel.offset_bottom = 154
	carry_choice_panel.visible = false
	carry_choice_panel.z_index = HUD_Z_CARRY_CHOICE
	carry_choice_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	carry_choice_panel.add_theme_stylebox_override("panel", _create_hud_panel_style())
	hud_root.add_child(carry_choice_panel)

	var panel_box: VBoxContainer = VBoxContainer.new()
	panel_box.name = "CarryChoiceRows"
	panel_box.add_theme_constant_override("separation", 8)
	carry_choice_panel.add_child(panel_box)

	carry_choice_title_label = _create_carry_choice_label(HUD_PRIMARY_TEXT_COLOR, 15)
	carry_choice_title_label.name = "Title"
	panel_box.add_child(carry_choice_title_label)

	carry_choice_detail_label = _create_carry_choice_label(Color(0.78, 0.86, 0.84), 12)
	carry_choice_detail_label.name = "Detail"
	panel_box.add_child(carry_choice_detail_label)

	carry_choice_button_box = VBoxContainer.new()
	carry_choice_button_box.name = "Buttons"
	carry_choice_button_box.add_theme_constant_override("separation", 6)
	panel_box.add_child(carry_choice_button_box)


func _create_carry_choice_label(font_color: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(HUD_CARRY_CHOICE_PANEL_WIDTH - 34.0, 0)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _create_hud_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = HUD_PANEL_BG_COLOR
	style.border_color = HUD_PANEL_BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	return style


func _create_hud_section(parent: VBoxContainer, section_name: String, title: String) -> VBoxContainer:
	if parent.get_child_count() > 0:
		_add_hud_section_rule(parent)

	var section: VBoxContainer = VBoxContainer.new()
	section.name = section_name
	section.add_theme_constant_override("separation", 3)
	parent.add_child(section)

	var title_label: Label = Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", HUD_SECTION_TITLE_COLOR)
	title_label.add_theme_font_size_override("font_size", 11)
	section.add_child(title_label)
	return section


func _add_hud_section_rule(parent: VBoxContainer) -> void:
	var rule: ColorRect = ColorRect.new()
	rule.name = "SectionRule"
	rule.color = HUD_SECTION_RULE_COLOR
	rule.custom_minimum_size = Vector2(0, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(rule)
	rule.name = "SectionRule"


func _build_guidance_direction_indicator() -> void:
	guidance_direction_indicator = CAMPUS_TARGET_DIRECTION_INDICATOR.new()
	guidance_direction_indicator.name = "GuidanceDirectionIndicator"
	guidance_direction_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance_direction_indicator.visible = false
	guidance_direction_indicator.z_index = HUD_Z_DIRECTION_INDICATOR
	hud_root.add_child(guidance_direction_indicator)


func _build_guidance_legend(parent: VBoxContainer) -> void:
	var legend_row: HBoxContainer = HBoxContainer.new()
	legend_row.name = "GuidanceLegend"
	legend_row.add_theme_constant_override("separation", 10)
	parent.add_child(legend_row)
	_add_guidance_legend_item(legend_row, GUIDANCE_STORY_COLOR, "剧情目标")
	_add_guidance_legend_item(legend_row, GUIDANCE_SUPPLY_COLOR, "建议补给")


func _add_guidance_legend_item(parent: HBoxContainer, color: Color, text: String) -> void:
	var item_row: HBoxContainer = HBoxContainer.new()
	item_row.add_theme_constant_override("separation", 4)
	parent.add_child(item_row)

	var swatch: ColorRect = ColorRect.new()
	swatch.custom_minimum_size = Vector2(10, 10)
	swatch.color = color
	item_row.add_child(swatch)

	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.80, 0.84, 0.82))
	label.add_theme_font_size_override("font_size", 12)
	item_row.add_child(label)


func _build_transition_layer() -> void:
	transition_root = Control.new()
	transition_root.name = "BattleTransition"
	transition_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_root.visible = false
	transition_layer.add_child(transition_root)

	var scrim: ColorRect = ColorRect.new()
	scrim.name = "TransitionScrim"
	scrim.color = Color(0.04, 0.06, 0.08, 0.72)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_root.add_child(scrim)

	var center: CenterContainer = CenterContainer.new()
	center.name = "TransitionCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_root.add_child(center)

	var text_stack: VBoxContainer = VBoxContainer.new()
	text_stack.name = "TransitionText"
	text_stack.add_theme_constant_override("separation", 8)
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(text_stack)

	transition_title_label = Label.new()
	transition_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_title_label.text = "进入学术交流"
	transition_title_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	transition_title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.95))
	transition_title_label.add_theme_constant_override("outline_size", 5)
	transition_title_label.add_theme_font_size_override("font_size", 28)
	text_stack.add_child(transition_title_label)

	transition_subtitle_label = Label.new()
	transition_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_subtitle_label.text = ""
	transition_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transition_subtitle_label.custom_minimum_size = Vector2(520, 0)
	transition_subtitle_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.88))
	transition_subtitle_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.95))
	transition_subtitle_label.add_theme_constant_override("outline_size", 4)
	transition_subtitle_label.add_theme_font_size_override("font_size", 17)
	text_stack.add_child(transition_subtitle_label)


func _build_safehouse_layer() -> void:
	safehouse_root = Control.new()
	safehouse_root.name = "SafehouseRoot"
	safehouse_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safehouse_layer.add_child(safehouse_root)

	var background: ColorRect = ColorRect.new()
	background.name = "SafehouseBackground"
	background.color = Color(0.09, 0.11, 0.12, 0.96)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	safehouse_root.add_child(background)

	safehouse_panel = PanelContainer.new()
	safehouse_panel.name = "SafehousePanel"
	safehouse_panel.anchor_left = 0.5
	safehouse_panel.anchor_top = 0.5
	safehouse_panel.anchor_right = 0.5
	safehouse_panel.anchor_bottom = 0.5
	safehouse_panel.offset_left = -SAFEHOUSE_PANEL_WIDTH * 0.5
	safehouse_panel.offset_right = SAFEHOUSE_PANEL_WIDTH * 0.5
	safehouse_panel.offset_top = -SAFEHOUSE_PANEL_HEIGHT * 0.5
	safehouse_panel.offset_bottom = SAFEHOUSE_PANEL_HEIGHT * 0.5
	safehouse_panel.add_theme_stylebox_override("panel", _create_hud_panel_style())
	safehouse_root.add_child(safehouse_panel)

	var panel_box: VBoxContainer = VBoxContainer.new()
	panel_box.name = "SafehousePanelBox"
	panel_box.add_theme_constant_override("separation", 10)
	safehouse_panel.add_child(panel_box)

	var title_label: Label = Label.new()
	title_label.text = "住屋"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.92))
	title_label.add_theme_font_size_override("font_size", 24)
	panel_box.add_child(title_label)

	safehouse_day_label = Label.new()
	safehouse_day_label.name = "SafehouseDayLabel"
	safehouse_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	safehouse_day_label.add_theme_color_override("font_color", Color(0.76, 0.86, 0.82))
	safehouse_day_label.add_theme_font_size_override("font_size", 14)
	panel_box.add_child(safehouse_day_label)

	safehouse_resource_label = Label.new()
	safehouse_resource_label.name = "SafehouseResourceLabel"
	safehouse_resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safehouse_resource_label.custom_minimum_size = Vector2(SAFEHOUSE_PANEL_WIDTH - 34.0, 0)
	safehouse_resource_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.54))
	safehouse_resource_label.add_theme_font_size_override("font_size", 13)
	panel_box.add_child(safehouse_resource_label)

	safehouse_theme_label = Label.new()
	safehouse_theme_label.name = "SafehouseThemeLabel"
	safehouse_theme_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safehouse_theme_label.custom_minimum_size = Vector2(SAFEHOUSE_PANEL_WIDTH - 34.0, 0)
	safehouse_theme_label.add_theme_color_override("font_color", Color(0.74, 0.86, 0.88))
	safehouse_theme_label.add_theme_font_size_override("font_size", 13)
	panel_box.add_child(safehouse_theme_label)

	var theme_row: HBoxContainer = HBoxContainer.new()
	theme_row.name = "SafehouseThemeChoices"
	theme_row.add_theme_constant_override("separation", 8)
	panel_box.add_child(theme_row)

	safehouse_theme_choice_buttons.clear()
	for index: int in range(CAMPUS_GENERATION_THEME_CHOICE_COUNT):
		var theme_button: Button = Button.new()
		theme_button.name = "SafehouseThemeChoice%d" % (index + 1)
		theme_button.text = "主题"
		theme_button.toggle_mode = true
		theme_button.custom_minimum_size = Vector2(164, 38)
		theme_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		theme_button.add_theme_font_size_override("font_size", 13)
		theme_button.focus_mode = Control.FOCUS_ALL
		theme_button.pressed.connect(_on_safehouse_theme_choice_button_pressed.bind(index))
		theme_row.add_child(theme_button)
		safehouse_theme_choice_buttons.append(theme_button)

	safehouse_carry_label = Label.new()
	safehouse_carry_label.name = "SafehouseCarryLabel"
	safehouse_carry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safehouse_carry_label.custom_minimum_size = Vector2(SAFEHOUSE_PANEL_WIDTH - 34.0, 0)
	safehouse_carry_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.80))
	safehouse_carry_label.add_theme_font_size_override("font_size", 13)
	panel_box.add_child(safehouse_carry_label)

	var carry_grid: GridContainer = GridContainer.new()
	carry_grid.name = "SafehouseCarryGrid"
	carry_grid.columns = 3
	carry_grid.add_theme_constant_override("h_separation", 8)
	carry_grid.add_theme_constant_override("v_separation", 6)
	carry_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_box.add_child(carry_grid)

	safehouse_carry_item_buttons.clear()
	for item_def: Dictionary in _get_safehouse_carry_item_definitions():
		var carry_button: Button = Button.new()
		carry_button.name = "SafehouseCarry_%s" % String(item_def.get("id", &""))
		carry_button.text = _format_safehouse_carry_item_button_text(item_def)
		carry_button.toggle_mode = true
		carry_button.custom_minimum_size = Vector2(230, 50)
		carry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		carry_button.add_theme_font_size_override("font_size", 11)
		carry_button.focus_mode = Control.FOCUS_ALL
		carry_button.pressed.connect(_on_safehouse_carry_item_button_pressed.bind(StringName(item_def.get("id", &""))))
		carry_grid.add_child(carry_button)
		safehouse_carry_item_buttons.append(carry_button)

	safehouse_attribute_label = Label.new()
	safehouse_attribute_label.name = "SafehouseAttributeLabel"
	safehouse_attribute_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safehouse_attribute_label.custom_minimum_size = Vector2(SAFEHOUSE_PANEL_WIDTH - 34.0, 0)
	safehouse_attribute_label.add_theme_color_override("font_color", Color(0.86, 0.90, 0.82))
	safehouse_attribute_label.add_theme_font_size_override("font_size", 13)
	panel_box.add_child(safehouse_attribute_label)

	safehouse_prep_label = Label.new()
	safehouse_prep_label.name = "SafehousePrepLabel"
	safehouse_prep_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safehouse_prep_label.custom_minimum_size = Vector2(SAFEHOUSE_PANEL_WIDTH - 34.0, 0)
	safehouse_prep_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.62))
	safehouse_prep_label.add_theme_font_size_override("font_size", 13)
	panel_box.add_child(safehouse_prep_label)

	safehouse_effect_label = Label.new()
	safehouse_effect_label.name = "SafehouseEffectLabel"
	safehouse_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safehouse_effect_label.custom_minimum_size = Vector2(SAFEHOUSE_PANEL_WIDTH - 34.0, 0)
	safehouse_effect_label.add_theme_color_override("font_color", Color(0.72, 0.88, 0.76))
	safehouse_effect_label.add_theme_font_size_override("font_size", 13)
	panel_box.add_child(safehouse_effect_label)

	var prep_scroll: ScrollContainer = ScrollContainer.new()
	prep_scroll.name = "SafehousePrepScroll"
	prep_scroll.custom_minimum_size = Vector2(SAFEHOUSE_PANEL_WIDTH - 34.0, 126)
	prep_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_box.add_child(prep_scroll)

	var prep_grid: GridContainer = GridContainer.new()
	prep_grid.name = "SafehousePrepGrid"
	prep_grid.columns = 2
	prep_grid.add_theme_constant_override("h_separation", 8)
	prep_grid.add_theme_constant_override("v_separation", 8)
	prep_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prep_scroll.add_child(prep_grid)

	safehouse_prep_action_buttons.clear()
	for action_def: Dictionary in _get_safehouse_prep_action_definitions():
		var prep_button: Button = Button.new()
		prep_button.name = "SafehousePrep_%s" % String(action_def.get("id", &""))
		prep_button.text = _format_safehouse_prep_action_button_text(action_def)
		prep_button.custom_minimum_size = Vector2(350, 64)
		prep_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prep_button.add_theme_font_size_override("font_size", 12)
		prep_button.focus_mode = Control.FOCUS_ALL
		prep_button.pressed.connect(_on_safehouse_prep_action_button_pressed.bind(StringName(action_def.get("id", &""))))
		prep_grid.add_child(prep_button)
		safehouse_prep_action_buttons.append(prep_button)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.name = "SafehouseActions"
	action_row.add_theme_constant_override("separation", 10)
	panel_box.add_child(action_row)

	safehouse_depart_button = Button.new()
	safehouse_depart_button.name = "DepartCampusButton"
	safehouse_depart_button.text = "出门去校园"
	safehouse_depart_button.custom_minimum_size = Vector2(220, 42)
	safehouse_depart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safehouse_depart_button.add_theme_font_size_override("font_size", 15)
	safehouse_depart_button.focus_mode = Control.FOCUS_ALL
	safehouse_depart_button.pressed.connect(_on_safehouse_depart_button_pressed)
	action_row.add_child(safehouse_depart_button)

	safehouse_next_day_button = Button.new()
	safehouse_next_day_button.name = "NextSafehouseDayButton"
	safehouse_next_day_button.text = "下一天"
	safehouse_next_day_button.custom_minimum_size = Vector2(160, 42)
	safehouse_next_day_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safehouse_next_day_button.add_theme_font_size_override("font_size", 15)
	safehouse_next_day_button.focus_mode = Control.FOCUS_ALL
	safehouse_next_day_button.pressed.connect(_on_safehouse_next_day_button_pressed)
	action_row.add_child(safehouse_next_day_button)


func _build_return_summary_panel() -> void:
	return_summary_panel = PanelContainer.new()
	return_summary_panel.name = "ReturnSummaryPanel"
	return_summary_panel.anchor_left = 1.0
	return_summary_panel.anchor_right = 1.0
	return_summary_panel.offset_left = -388
	return_summary_panel.offset_right = -12
	return_summary_panel.offset_top = 64
	return_summary_panel.offset_bottom = 204
	return_summary_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return_summary_panel.visible = false
	return_summary_panel.z_index = HUD_Z_RETURN_SUMMARY
	hud_root.add_child(return_summary_panel)

	var summary_box: VBoxContainer = VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 6)
	summary_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return_summary_panel.add_child(summary_box)

	var title_label: Label = Label.new()
	title_label.text = "返回摘要"
	title_label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.98))
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_box.add_child(title_label)

	return_summary_result_label = _create_return_summary_label(Color(0.82, 0.88, 0.92))
	summary_box.add_child(return_summary_result_label)

	return_summary_resource_label = _create_return_summary_label(Color(0.98, 0.86, 0.46))
	summary_box.add_child(return_summary_resource_label)

	return_summary_guidance_label = _create_return_summary_label(Color(0.66, 0.90, 0.96))
	summary_box.add_child(return_summary_guidance_label)


func _create_return_summary_label(font_color: Color) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(340, 0)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", 13)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_stage_debug_controls(parent: VBoxContainer) -> void:
	var debug_section: VBoxContainer = _create_hud_section(parent, "DebugSection", "测试")

	var caption_label: Label = Label.new()
	caption_label.text = "阶段切换仅用于原型验证"
	caption_label.add_theme_color_override("font_color", HUD_MUTED_TEXT_COLOR)
	caption_label.add_theme_font_size_override("font_size", 12)
	debug_section.add_child(caption_label)

	var stage_row: HBoxContainer = HBoxContainer.new()
	stage_row.name = "StageDebugControls"
	stage_row.add_theme_constant_override("separation", 4)
	debug_section.add_child(stage_row)

	stage_debug_buttons.clear()
	for stage_def: Resource in _get_ordered_campus_stage_definitions():
		var stage: StringName = stage_def.get("id")
		var button: Button = Button.new()
		var debug_label: String = str(stage_def.get("debug_label"))
		button.text = debug_label if debug_label != "" else str(stage_def.get("display_name"))
		button.tooltip_text = "调试切换到%s校园" % button.text
		button.custom_minimum_size = Vector2(44, 26)
		button.add_theme_font_size_override("font_size", 12)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_stage_debug_button_pressed.bind(stage))
		stage_row.add_child(button)
		stage_debug_buttons[stage] = button

	var generation_row: HBoxContainer = HBoxContainer.new()
	generation_row.name = "GenerationDebugControls"
	generation_row.add_theme_constant_override("separation", 4)
	debug_section.add_child(generation_row)

	generation_candidate_toggle = CheckButton.new()
	generation_candidate_toggle.name = "GenerationCandidateToggle"
	generation_candidate_toggle.text = "候选池地图"
	generation_candidate_toggle.tooltip_text = "调试开关：用候选池选择器实际生成当前校园点位"
	generation_candidate_toggle.custom_minimum_size = Vector2(128, 26)
	generation_candidate_toggle.add_theme_font_size_override("font_size", 12)
	generation_candidate_toggle.focus_mode = Control.FOCUS_NONE
	generation_candidate_toggle.set_pressed_no_signal(generation_candidate_map_enabled)
	generation_candidate_toggle.toggled.connect(_on_generation_candidate_toggle_toggled)
	generation_row.add_child(generation_candidate_toggle)

	reroll_seed_button = Button.new()
	reroll_seed_button.name = "RerollCampusSeedButton"
	reroll_seed_button.text = "重随 Seed"
	reroll_seed_button.tooltip_text = "调试：生成新 Seed 并重刷当前校园"
	reroll_seed_button.custom_minimum_size = Vector2(88, 26)
	reroll_seed_button.add_theme_font_size_override("font_size", 12)
	reroll_seed_button.focus_mode = Control.FOCUS_NONE
	reroll_seed_button.pressed.connect(_on_reroll_seed_button_pressed)
	generation_row.add_child(reroll_seed_button)

	var theme_row: HBoxContainer = HBoxContainer.new()
	theme_row.name = "GenerationThemeChoiceControls"
	theme_row.add_theme_constant_override("separation", 4)
	debug_section.add_child(theme_row)

	generation_theme_choice_buttons.clear()
	for index: int in range(CAMPUS_GENERATION_THEME_CHOICE_COUNT):
		var theme_button: Button = Button.new()
		theme_button.name = "GenerationThemeChoice%d" % (index + 1)
		theme_button.text = "主题"
		theme_button.toggle_mode = true
		theme_button.custom_minimum_size = Vector2(112, 26)
		theme_button.add_theme_font_size_override("font_size", 11)
		theme_button.focus_mode = Control.FOCUS_NONE
		theme_button.pressed.connect(_on_generation_theme_choice_button_pressed.bind(index))
		theme_row.add_child(theme_button)
		generation_theme_choice_buttons.append(theme_button)

	return_safehouse_button = Button.new()
	return_safehouse_button.name = "ReturnSafehouseButton"
	return_safehouse_button.text = "调试返回住屋"
	return_safehouse_button.tooltip_text = "调试兜底：地图上也有住屋入口"
	return_safehouse_button.custom_minimum_size = Vector2(HUD_STATUS_PANEL_WIDTH - 36.0, 28)
	return_safehouse_button.add_theme_font_size_override("font_size", 12)
	return_safehouse_button.focus_mode = Control.FOCUS_NONE
	return_safehouse_button.pressed.connect(_on_return_safehouse_button_pressed)
	debug_section.add_child(return_safehouse_button)

	generation_audit_label = Label.new()
	generation_audit_label.name = "GenerationAuditLabel"
	generation_audit_label.text = ""
	generation_audit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	generation_audit_label.custom_minimum_size = Vector2(HUD_STATUS_PANEL_WIDTH - 36.0, 0)
	generation_audit_label.add_theme_color_override("font_color", Color(0.66, 0.78, 0.76))
	generation_audit_label.add_theme_font_size_override("font_size", 11)
	generation_audit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_section.add_child(generation_audit_label)

	marker_profile_legend_label = Label.new()
	marker_profile_legend_label.name = "MarkerProfileLegendLabel"
	marker_profile_legend_label.text = ""
	marker_profile_legend_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marker_profile_legend_label.custom_minimum_size = Vector2(HUD_STATUS_PANEL_WIDTH - 36.0, 0)
	marker_profile_legend_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.64))
	marker_profile_legend_label.add_theme_font_size_override("font_size", 11)
	marker_profile_legend_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_section.add_child(marker_profile_legend_label)


func _spawn_interactables() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _get_stage_seed()
	var safehouse_position: Vector2 = _get_safehouse_entrance_position()
	var used_positions: Array[Vector2] = [safehouse_position]

	for definition: Resource in _get_stage_spawn_interaction_definitions():
		var base_position: Vector2 = definition.get("position")
		var jitter_radius: int = int(definition.get("jitter_radius"))
		var spawn_position: Vector2 = _resolve_interactable_spawn_position(base_position, rng, jitter_radius, used_positions)
		used_positions.append(spawn_position)
		_add_interactable(definition, spawn_position)
	_add_safehouse_entrance_interactable(safehouse_position)


func _get_stage_spawn_interaction_definitions() -> Array[Resource]:
	if generation_candidate_map_enabled:
		return _get_stage_generation_spawn_definitions()
	return _get_stage_interaction_definitions()


func _get_stage_spawn_source_id() -> String:
	return "candidate" if generation_candidate_map_enabled else "fixed"


func _get_stage_spawn_source_display_name() -> String:
	return "候选池地图" if generation_candidate_map_enabled else "固定地图"


func _get_stage_interaction_definitions() -> Array[Resource]:
	var stage_def: Resource = _get_campus_stage_definition(campus_stage)
	var definitions: Array[Resource] = []
	if stage_def == null:
		return definitions
	var raw_interactions: Array = stage_def.get("interactions")
	for definition: Resource in raw_interactions:
		if definition != null:
			definitions.append(definition)
	return definitions


func _ensure_campus_data_loaded() -> void:
	if campus_stage_definitions.is_empty():
		campus_stage_definitions = GAME_DATA_CATALOG.load_campus_stages_by_id()
	if campus_route_requirements.is_empty():
		campus_route_requirements = GAME_DATA_CATALOG.load_campus_route_requirements_by_id()


func _get_campus_stage_definition(stage: StringName) -> Resource:
	_ensure_campus_data_loaded()
	var raw_stage_def: Variant = campus_stage_definitions.get(stage, null)
	if raw_stage_def is Resource:
		return raw_stage_def
	return null


func _get_ordered_campus_stage_definitions() -> Array[Resource]:
	_ensure_campus_data_loaded()
	var ordered_stages: Array[Resource] = []
	for raw_stage_def: Variant in campus_stage_definitions.values():
		if raw_stage_def is Resource:
			ordered_stages.append(raw_stage_def)
	ordered_stages.sort_custom(func(a: Resource, b: Resource) -> bool:
		return int(a.get("sort_order")) < int(b.get("sort_order"))
	)
	return ordered_stages


func _get_stage_seed() -> int:
	return max(1, campus_seed + abs(String(campus_stage).hash()) % 100000)


func _generate_debug_campus_seed() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, CAMPUS_SEED_MAX)


func _jitter_position(base_position: Vector2, rng: RandomNumberGenerator, radius: int) -> Vector2:
	return base_position + Vector2(rng.randi_range(-radius, radius), rng.randi_range(-radius, radius))


func _resolve_interactable_spawn_position(
	base_position: Vector2,
	rng: RandomNumberGenerator,
	jitter_radius: int,
	used_positions: Array[Vector2]
) -> Vector2:
	var candidates: Array[Vector2] = [base_position]
	for i: int in range(INTERACTABLE_SPAWN_CANDIDATE_ATTEMPTS):
		candidates.append(_jitter_position(base_position, rng, jitter_radius))

	var fallback_radius: float = maxf(float(jitter_radius), INTERACTABLE_MIN_SPACING)
	var fallback_directions: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.DOWN,
		Vector2.UP,
		Vector2(1, 1).normalized(),
		Vector2(-1, 1).normalized(),
		Vector2(1, -1).normalized(),
		Vector2(-1, -1).normalized(),
	]
	for direction: Vector2 in fallback_directions:
		candidates.append(base_position + direction * fallback_radius)
		candidates.append(base_position + direction * (fallback_radius + 28.0))

	var best_position: Vector2 = _sanitize_interactable_spawn_position(base_position)
	var best_score: float = INF
	for candidate: Vector2 in candidates:
		var sanitized_candidate: Vector2 = _sanitize_interactable_spawn_position(candidate)
		var score: float = _score_interactable_spawn_position(sanitized_candidate, base_position, used_positions)
		if score < best_score:
			best_score = score
			best_position = sanitized_candidate
		if _is_interactable_spawn_position_clear(sanitized_candidate, used_positions):
			return sanitized_candidate
	return best_position


func _sanitize_interactable_spawn_position(raw_position: Vector2) -> Vector2:
	var sanitized_position: Vector2 = _clamp_to_interactable_spawn_bounds(raw_position)
	for i: int in range(3):
		var pushed_position: Vector2 = sanitized_position
		for rect: Rect2 in _get_interactable_blocking_rects():
			if rect.has_point(pushed_position):
				pushed_position = _push_point_out_of_rect(pushed_position, rect)
		sanitized_position = _clamp_to_interactable_spawn_bounds(pushed_position)
	return sanitized_position


func _score_interactable_spawn_position(candidate: Vector2, base_position: Vector2, used_positions: Array[Vector2]) -> float:
	var score: float = candidate.distance_to(base_position) * 0.25
	if not _get_interactable_spawn_bounds().has_point(candidate):
		score += 100000.0
	for rect: Rect2 in _get_interactable_blocking_rects():
		if rect.has_point(candidate):
			score += 100000.0
			break
	for used_position: Vector2 in used_positions:
		var distance: float = candidate.distance_to(used_position)
		if distance < INTERACTABLE_MIN_SPACING:
			score += pow(INTERACTABLE_MIN_SPACING - distance, 2.0) * 10.0
	return score


func _is_interactable_spawn_position_clear(candidate: Vector2, used_positions: Array[Vector2]) -> bool:
	if not _get_interactable_spawn_bounds().has_point(candidate):
		return false
	for rect: Rect2 in _get_interactable_blocking_rects():
		if rect.has_point(candidate):
			return false
	for used_position: Vector2 in used_positions:
		if candidate.distance_to(used_position) < INTERACTABLE_MIN_SPACING:
			return false
	return true


func _clamp_to_interactable_spawn_bounds(position: Vector2) -> Vector2:
	var spawn_bounds: Rect2 = _get_interactable_spawn_bounds()
	var max_position: Vector2 = spawn_bounds.position + spawn_bounds.size
	return Vector2(
		clampf(position.x, spawn_bounds.position.x, max_position.x),
		clampf(position.y, spawn_bounds.position.y, max_position.y)
	)


func _get_interactable_spawn_bounds() -> Rect2:
	var bounds: Rect2 = Rect2(Vector2(32, 32), Vector2(1536, 896))
	if map_view != null and map_view.has_method("get_map_bounds"):
		bounds = map_view.get_map_bounds()
	var inset: Vector2 = Vector2(INTERACTABLE_MAP_EDGE_CLEARANCE, INTERACTABLE_MAP_EDGE_CLEARANCE)
	var size: Vector2 = Vector2(
		maxf(1.0, bounds.size.x - inset.x * 2.0),
		maxf(1.0, bounds.size.y - inset.y * 2.0)
	)
	return Rect2(bounds.position + inset, size)


func _get_interactable_blocking_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if map_view == null:
		return rects
	var raw_buildings: Variant = map_view.get("building_defs")
	if not raw_buildings is Array:
		return rects
	for raw_building: Variant in raw_buildings:
		if not raw_building is Dictionary:
			continue
		var rect: Rect2 = raw_building.get("rect", Rect2())
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			rects.append(rect.grow(INTERACTABLE_BUILDING_CLEARANCE))
	return rects


func _push_point_out_of_rect(point: Vector2, rect: Rect2) -> Vector2:
	var left_distance: float = absf(point.x - rect.position.x)
	var right_distance: float = absf(rect.end.x - point.x)
	var top_distance: float = absf(point.y - rect.position.y)
	var bottom_distance: float = absf(rect.end.y - point.y)
	var nearest_distance: float = minf(minf(left_distance, right_distance), minf(top_distance, bottom_distance))
	if is_equal_approx(nearest_distance, left_distance):
		return Vector2(rect.position.x - 1.0, point.y)
	if is_equal_approx(nearest_distance, right_distance):
		return Vector2(rect.end.x + 1.0, point.y)
	if is_equal_approx(nearest_distance, top_distance):
		return Vector2(point.x, rect.position.y - 1.0)
	return Vector2(point.x, rect.end.y + 1.0)


func _get_active_interactable_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if interactable_root == null:
		return positions
	for child: Node in interactable_root.get_children():
		if _is_safehouse_entrance_node(child):
			continue
		if child is Node2D and child.get("collected") != true:
			positions.append((child as Node2D).position)
	return positions


func _is_safehouse_entrance_node(node: Node) -> bool:
	if not node is CampusInteractable:
		return false
	return (node as CampusInteractable).interaction_id == SAFEHOUSE_INTERACTION_ID


func _add_interactable(definition: Resource, spawn_position: Vector2) -> void:
	var interactable: Area2D = CAMPUS_INTERACTABLE.new()
	interactable.name = String(definition.get("id"))
	interactable.position = spawn_position
	interactable.interaction_id = definition.get("id")
	interactable.display_name = str(definition.get("display_name"))
	interactable.interaction_kind = definition.get("interaction_kind")
	interactable.route_node_id = definition.get("route_node_id")
	interactable.resource_id = definition.get("resource_id")
	interactable.resource_amount = int(definition.get("resource_amount"))
	interactable.content_tags = _normalize_content_tags(definition.get("content_tags"))
	if interactable.content_tags.is_empty():
		interactable.content_tags = _infer_content_tags_from_fields(
			interactable.interaction_kind,
			interactable.route_node_id,
			interactable.resource_id
		)
	interactable.base_marker_state = definition.get("marker_state")
	interactable.marker_state = interactable.base_marker_state
	interactable.accent_color = definition.get("accent_color")
	interactable._ensure_collision_shape()
	interactable.refresh_marker()
	interactable.body_entered.connect(_on_interactable_body_entered.bind(interactable))
	interactable.body_exited.connect(_on_interactable_body_exited.bind(interactable))
	interactable.interaction_requested.connect(_on_interactable_requested)
	interactable_root.add_child(interactable)


func _add_safehouse_entrance_interactable(spawn_position: Vector2) -> void:
	var interactable: CampusInteractable = CAMPUS_INTERACTABLE.new()
	interactable.name = String(SAFEHOUSE_INTERACTION_ID)
	interactable.position = spawn_position
	interactable.interaction_id = SAFEHOUSE_INTERACTION_ID
	interactable.display_name = "住屋入口"
	interactable.interaction_kind = SAFEHOUSE_INTERACTION_KIND
	interactable.route_node_id = &""
	interactable.resource_id = &""
	interactable.resource_amount = 0
	interactable.content_tags = [&"safehouse", &"dormitory", &"self_care"]
	interactable.base_marker_state = MARKER_STATE_DEFAULT
	interactable.marker_state = MARKER_STATE_DEFAULT
	interactable.accent_color = SAFEHOUSE_ENTRANCE_COLOR
	interactable._ensure_collision_shape()
	interactable.refresh_marker()
	interactable.body_entered.connect(_on_interactable_body_entered.bind(interactable))
	interactable.body_exited.connect(_on_interactable_body_exited.bind(interactable))
	interactable.interaction_requested.connect(_on_interactable_requested)
	interactable_root.add_child(interactable)


func _get_safehouse_entrance_position() -> Vector2:
	if map_view != null and map_view.has_method("get_site_positions"):
		var site_positions: Dictionary = map_view.call("get_site_positions")
		if site_positions.has(&"dorm"):
			var dorm_position: Variant = site_positions[&"dorm"]
			if dorm_position is Vector2:
				return _sanitize_interactable_spawn_position(dorm_position)
	return _sanitize_interactable_spawn_position(SAFEHOUSE_ENTRANCE_FALLBACK_POSITION)


func _refresh_condition_marker_states() -> void:
	if interactable_root == null:
		return
	var pending_requirement_resolved: bool = false
	for child: Node in interactable_root.get_children():
		if not child is CampusInteractable:
			continue
		var interactable: CampusInteractable = child as CampusInteractable
		if interactable.collected:
			interactable.set_requirement_summary("")
			if interactable.interaction_id == _pending_condition_override_interaction_id:
				pending_requirement_resolved = true
			continue

		var requirement_groups: Array[Resource] = _get_interactable_requirement_groups(interactable)
		if requirement_groups.is_empty() or _are_requirement_groups_met(requirement_groups):
			interactable.set_requirement_summary("")
			interactable.set_marker_state(interactable.base_marker_state)
			if interactable.interaction_id == _pending_condition_override_interaction_id:
				pending_requirement_resolved = true
		else:
			var intercept_mode: StringName = _get_interactable_requirement_intercept_mode(interactable)
			interactable.set_requirement_summary(_format_requirement_groups(requirement_groups))
			interactable.set_marker_state(MARKER_STATE_CONDITION_LOCKED)
			if interactable.interaction_id == _pending_condition_override_interaction_id and intercept_mode != REQUIREMENT_INTERCEPT_SOFT_GATE:
				pending_requirement_resolved = true
	if pending_requirement_resolved:
		_pending_condition_override_interaction_id = &""


func _refresh_story_guidance() -> void:
	if interactable_root == null:
		return
	_clear_summary_guidance_target()
	for child: Node in interactable_root.get_children():
		if child is CampusInteractable:
			var interactable: CampusInteractable = child as CampusInteractable
			interactable.set_guidance_target(false)
			interactable.set_supply_hint_target(false)
			interactable.set_summary_guidance_target(false)

	var target: CampusInteractable = _get_story_guidance_target()
	if target != null:
		target.set_guidance_target(true)
		for source: CampusInteractable in _get_requirement_supply_source_interactables_for_interactable(target):
			if source != target:
				source.set_supply_hint_target(true)
	if return_summary_panel != null and return_summary_panel.visible:
		_set_summary_guidance_target_from_current_story()


func _get_story_guidance_target() -> CampusInteractable:
	for route_node_id: StringName in _get_story_guidance_route_order():
		var route_target: CampusInteractable = _find_available_interactable_by_route_node(route_node_id)
		if route_target != null:
			return route_target
	return _find_available_story_or_boss_interactable()


func _get_story_guidance_route_order() -> Array[StringName]:
	match campus_stage:
		CAMPUS_STAGE_MASTER1:
			return [&"B001", &"E008"]
		CAMPUS_STAGE_MASTER2:
			return [&"B002", &"E005", &"B003"]
		CAMPUS_STAGE_DOCTOR1:
			return [&"N005", &"B004"]
		CAMPUS_STAGE_DOCTOR2:
			return [&"N006", &"E006", &"B005"]
		CAMPUS_STAGE_DOCTOR3:
			return [&"N007", &"B006", &"B007"]
		CAMPUS_STAGE_DOCTOR4:
			return [&"E007", &"N008", &"B008"]
	return []


func _find_available_interactable_by_route_node(route_node_id: StringName) -> CampusInteractable:
	if interactable_root == null or route_node_id == &"":
		return null
	for child: Node in interactable_root.get_children():
		if not child is CampusInteractable:
			continue
		var interactable: CampusInteractable = child as CampusInteractable
		if interactable.collected:
			continue
		if interactable.route_node_id == route_node_id:
			return interactable
	return null


func _find_available_story_or_boss_interactable() -> CampusInteractable:
	if interactable_root == null:
		return null
	for child: Node in interactable_root.get_children():
		if not child is CampusInteractable:
			continue
		var interactable: CampusInteractable = child as CampusInteractable
		if interactable.collected:
			continue
		if interactable.base_marker_state == &"story_key" or interactable.base_marker_state == &"boss_available":
			return interactable
	return null


func _get_interactable_requirement_groups(interactable: CampusInteractable) -> Array[Resource]:
	var requirement_groups: Array[Resource] = []
	var requirement: Resource = _get_interactable_requirement_definition(interactable)
	if requirement == null:
		return requirement_groups
	var raw_groups: Array = requirement.get("requirement_groups")
	for group: Resource in raw_groups:
		if group != null:
			requirement_groups.append(group)
	return requirement_groups


func _get_interactable_requirement_definition(interactable: CampusInteractable) -> Resource:
	if interactable == null:
		return null
	var raw_requirement: Variant = campus_route_requirements.get(interactable.route_node_id, null)
	if not raw_requirement is Resource:
		return null
	return raw_requirement as Resource


func _get_interactable_requirement_intercept_mode(interactable: CampusInteractable) -> StringName:
	var requirement: Resource = _get_interactable_requirement_definition(interactable)
	if requirement == null:
		return REQUIREMENT_INTERCEPT_WARN_ONLY
	var raw_mode: Variant = requirement.get("intercept_mode")
	if raw_mode == null:
		return REQUIREMENT_INTERCEPT_SOFT_GATE
	var intercept_mode: StringName = StringName(raw_mode)
	match intercept_mode:
		REQUIREMENT_INTERCEPT_WARN_ONLY, REQUIREMENT_INTERCEPT_SOFT_GATE, REQUIREMENT_INTERCEPT_HARD_GATE:
			return intercept_mode
	return REQUIREMENT_INTERCEPT_SOFT_GATE


func _are_requirement_groups_met(requirement_groups: Array[Resource]) -> bool:
	if requirement_groups.is_empty():
		return true
	for group: Resource in requirement_groups:
		if _is_requirement_group_met(group):
			return true
	return false


func _is_requirement_group_met(group: Resource) -> bool:
	if group == null:
		return true
	var items: Array = group.get("items")
	if items.is_empty():
		return true
	if group.get("mode") == &"any":
		for item: Resource in items:
			if _is_requirement_item_met(item):
				return true
		return false
	for item: Resource in items:
		if not _is_requirement_item_met(item):
			return false
	return true


func _is_requirement_item_met(item: Resource) -> bool:
	if item == null:
		return true
	var resource_id: StringName = item.get("resource_id")
	return int(campus_resources.get(resource_id, 0)) >= int(item.get("amount"))


func _format_requirement_groups(requirement_groups: Array[Resource]) -> String:
	var group_texts: Array[String] = []
	for group: Resource in requirement_groups:
		group_texts.append(_format_requirement_group(group))
	return " 或 ".join(group_texts)


func _format_requirement_group(group: Resource) -> String:
	if group == null:
		return ""
	var separator: String = " 或 " if group.get("mode") == &"any" else "、"
	var item_texts: Array[String] = []
	for item: Resource in group.get("items"):
		item_texts.append(_format_requirement_item(item))
	return separator.join(item_texts)


func _format_requirement_item(item: Resource) -> String:
	if item == null:
		return ""
	var resource_id: StringName = item.get("resource_id")
	var required_amount: int = int(item.get("amount"))
	var current_amount: int = int(campus_resources.get(resource_id, 0))
	return "%s %d/%d" % [_get_resource_display_name(resource_id), current_amount, required_amount]


func _format_requirement_supply_advice_for_interactable(interactable: CampusInteractable) -> String:
	if interactable == null or interactable.requirement_summary == "":
		return ""
	var requirement_groups: Array[Resource] = _get_interactable_requirement_groups(interactable)
	if requirement_groups.is_empty():
		return ""
	var group: Resource = _select_requirement_advice_group(requirement_groups)
	if group == null:
		return ""
	var advice_parts: Array[String] = []
	var has_fallback_advice: bool = false
	for item: Resource in _get_requirement_advice_items(group):
		var item_advice: String = _format_requirement_item_supply_advice(item)
		if item_advice != "":
			if item_advice.begins_with("补足"):
				has_fallback_advice = true
			advice_parts.append(item_advice)
	if advice_parts.is_empty():
		return ""
	var separator: String = " 或 " if group.get("mode") == &"any" else "、"
	var joined_advice: String = separator.join(advice_parts)
	if has_fallback_advice:
		return "建议：%s" % joined_advice
	return "建议：前往%s" % joined_advice


func _get_requirement_supply_source_interactables_for_interactable(interactable: CampusInteractable) -> Array[CampusInteractable]:
	var sources: Array[CampusInteractable] = []
	if interactable == null or interactable.requirement_summary == "":
		return sources
	var requirement_groups: Array[Resource] = _get_interactable_requirement_groups(interactable)
	if requirement_groups.is_empty():
		return sources
	var group: Resource = _select_requirement_advice_group(requirement_groups)
	if group == null:
		return sources
	for item: Resource in _get_requirement_advice_items(group):
		for source: CampusInteractable in _get_requirement_item_supply_sources(item):
			if not sources.has(source):
				sources.append(source)
	return sources


func _select_requirement_advice_group(requirement_groups: Array[Resource]) -> Resource:
	var selected_group: Resource = null
	var selected_count: int = 999
	for group: Resource in requirement_groups:
		var advice_items: Array[Resource] = _get_requirement_advice_items(group)
		if advice_items.is_empty():
			continue
		if selected_group == null or advice_items.size() < selected_count:
			selected_group = group
			selected_count = advice_items.size()
	return selected_group


func _get_requirement_advice_items(group: Resource) -> Array[Resource]:
	var advice_items: Array[Resource] = []
	if group == null:
		return advice_items
	var items: Array = group.get("items")
	if items.is_empty():
		return advice_items
	if group.get("mode") == &"any":
		for item: Resource in items:
			if _is_requirement_item_met(item):
				return []
		for item: Resource in items:
			if item != null:
				advice_items.append(item)
		return advice_items
	for item: Resource in items:
		if item != null and not _is_requirement_item_met(item):
			advice_items.append(item)
	return advice_items


func _format_requirement_item_supply_advice(item: Resource) -> String:
	if item == null:
		return ""
	var resource_id: StringName = item.get("resource_id")
	var required_amount: int = int(item.get("amount"))
	var current_amount: int = int(campus_resources.get(resource_id, 0))
	var missing_amount: int = max(1, required_amount - current_amount)
	var source_names: Array[String] = _get_available_resource_source_names(resource_id, missing_amount)
	if source_names.is_empty():
		return "补足%s" % _get_resource_display_name(resource_id)
	return "、".join(source_names)


func _get_requirement_item_supply_sources(item: Resource) -> Array[CampusInteractable]:
	var sources: Array[CampusInteractable] = []
	if item == null:
		return sources
	var resource_id: StringName = item.get("resource_id")
	var required_amount: int = int(item.get("amount"))
	var current_amount: int = int(campus_resources.get(resource_id, 0))
	var missing_amount: int = max(1, required_amount - current_amount)
	return _get_available_resource_source_interactables(resource_id, missing_amount)


func _get_available_resource_source_names(resource_id: StringName, missing_amount: int) -> Array[String]:
	var source_names: Array[String] = []
	for source: CampusInteractable in _get_available_resource_source_interactables(resource_id, missing_amount):
		source_names.append(source.display_name)
	return source_names


func _get_available_resource_source_interactables(resource_id: StringName, missing_amount: int) -> Array[CampusInteractable]:
	var sources: Array[CampusInteractable] = []
	if interactable_root == null:
		return sources
	var collected_amount: int = 0
	for child: Node in interactable_root.get_children():
		if not child is CampusInteractable:
			continue
		var interactable: CampusInteractable = child as CampusInteractable
		if interactable.collected:
			continue
		if interactable.interaction_kind != &"resource":
			continue
		if interactable.resource_id != resource_id:
			continue
		sources.append(interactable)
		collected_amount += max(0, int(interactable.resource_amount))
		if collected_amount >= missing_amount:
			break
	return sources


func _on_interactable_body_entered(body: Node2D, interactable: Variant) -> void:
	if body != player:
		return
	if focused_interactable != null and focused_interactable != interactable and focused_interactable is CampusInteractable:
		(focused_interactable as CampusInteractable).set_focused_target(false)
	focused_interactable = interactable
	if interactable is CampusInteractable:
		(interactable as CampusInteractable).set_focused_target(true)
	_refresh_hud()


func _on_interactable_body_exited(body: Node2D, interactable: Variant) -> void:
	if body != player:
		return
	if focused_interactable == interactable:
		if interactable is CampusInteractable:
			(interactable as CampusInteractable).set_focused_target(false)
		focused_interactable = null
	if interactable != null and interactable.interaction_id == _pending_condition_override_interaction_id:
		_pending_condition_override_interaction_id = &""
	_refresh_hud()


func _on_interactable_requested(interaction_id: StringName) -> void:
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable != null:
		_start_interaction(interactable)


func _on_stage_debug_button_pressed(stage: StringName) -> void:
	if mode != MODE_OVERWORLD:
		return
	set_campus_stage(stage)


func _on_generation_candidate_toggle_toggled(enabled: bool) -> void:
	if mode != MODE_OVERWORLD:
		_refresh_generation_candidate_toggle()
		return
	set_generation_candidate_map_enabled(enabled)


func _on_reroll_seed_button_pressed() -> void:
	if mode != MODE_OVERWORLD:
		_refresh_generation_candidate_toggle()
		return
	reroll_campus_seed()


func _on_return_safehouse_button_pressed() -> void:
	if mode != MODE_OVERWORLD:
		_refresh_generation_candidate_toggle()
		return
	return_to_safehouse()


func _on_generation_theme_choice_button_pressed(choice_index: int) -> void:
	if mode != MODE_OVERWORLD:
		_refresh_generation_theme_choice_buttons()
		return
	var choices: Array[StringName] = _get_stage_generation_theme_choice_ids()
	if choice_index < 0 or choice_index >= choices.size():
		_refresh_generation_theme_choice_buttons()
		return
	set_generation_theme_choice(choices[choice_index])


func _on_safehouse_theme_choice_button_pressed(choice_index: int) -> void:
	if mode != MODE_SAFEHOUSE:
		_refresh_safehouse_panel()
		return
	var choices: Array[StringName] = _get_stage_generation_theme_choice_ids()
	if choice_index < 0 or choice_index >= choices.size():
		_refresh_safehouse_panel()
		return
	set_generation_theme_choice(choices[choice_index], false)


func _on_safehouse_prep_action_button_pressed(action_id: StringName) -> void:
	_apply_safehouse_prep_action(action_id)


func _on_safehouse_carry_item_button_pressed(item_id: StringName) -> void:
	_toggle_safehouse_carry_item(item_id)


func _on_safehouse_depart_button_pressed() -> void:
	_depart_safehouse_to_campus()


func _on_safehouse_next_day_button_pressed() -> void:
	_advance_safehouse_day()


func _on_carry_choice_option_button_pressed(item_id: StringName) -> void:
	_choose_pending_carry_option(item_id)


func _on_carry_choice_skip_button_pressed() -> void:
	_skip_pending_carry_choice()


func _on_carry_choice_cancel_button_pressed() -> void:
	_cancel_pending_carry_choice()


func _advance_campus_stage_from_story(next_stage: StringName) -> bool:
	var normalized_stage: StringName = _normalize_campus_stage(next_stage)
	if next_stage == &"" or normalized_stage == campus_stage:
		return false
	_append_log("剧情推进：进入%s校园。" % _get_stage_label(normalized_stage))
	campus_stage = normalized_stage
	_clear_generation_theme_choice()
	_reset_campus(true, true)
	return true


func _get_campus_stage_for_route_node(route_node_id: StringName) -> StringName:
	match route_node_id:
		&"N001", &"E001", &"N002", &"E004", &"N003", &"N004", &"E003", &"E008", &"B001":
			return CAMPUS_STAGE_MASTER1
		&"N009", &"B002", &"B003", &"E005":
			return CAMPUS_STAGE_MASTER2
		&"N005", &"B004":
			return CAMPUS_STAGE_DOCTOR1
		&"N006", &"E006", &"B005":
			return CAMPUS_STAGE_DOCTOR2
		&"N007", &"B006", &"B007":
			return CAMPUS_STAGE_DOCTOR3
		&"E007", &"N008", &"B008":
			return CAMPUS_STAGE_DOCTOR4
	return &""


func _start_interaction(interactable: Variant) -> bool:
	if mode != MODE_OVERWORLD:
		return false
	if _has_pending_carry_choice():
		return false
	if not interactable is CampusInteractable:
		return false
	var campus_interactable: CampusInteractable = interactable as CampusInteractable
	if campus_interactable.collected:
		return false
	if campus_interactable.interaction_kind == SAFEHOUSE_INTERACTION_KIND:
		_return_to_safehouse_from_entrance(campus_interactable)
		return true
	if campus_interactable.interaction_kind == &"resource":
		_pending_condition_override_interaction_id = &""
		_apply_safehouse_carry_triggers_for_interactable(campus_interactable)
		_collect_resource(campus_interactable)
		return true
	var intercept_mode: StringName = _get_interactable_requirement_intercept_mode(campus_interactable)
	if intercept_mode != REQUIREMENT_INTERCEPT_SOFT_GATE and _pending_condition_override_interaction_id == campus_interactable.interaction_id:
		_pending_condition_override_interaction_id = &""
	if _should_hard_block_interaction(campus_interactable, intercept_mode):
		_pending_condition_override_interaction_id = &""
		_append_log("准备不足：%s 需要 %s。补足材料后才能进入。" % [campus_interactable.display_name, campus_interactable.requirement_summary])
		_refresh_hud()
		return false
	if _should_soft_block_interaction(campus_interactable, intercept_mode):
		_pending_condition_override_interaction_id = campus_interactable.interaction_id
		_append_log("准备不足：%s 需要 %s。再次确认可进入调试挑战。" % [campus_interactable.display_name, campus_interactable.requirement_summary])
		_refresh_hud()
		return false
	if _has_unmet_interaction_requirement(campus_interactable) and intercept_mode == REQUIREMENT_INTERCEPT_WARN_ONLY:
		_append_log("准备不足：%s 需要 %s。当前为仅提示模式，仍进入挑战。" % [campus_interactable.display_name, campus_interactable.requirement_summary])
	if _pending_condition_override_interaction_id == campus_interactable.interaction_id and campus_interactable.requirement_summary != "":
		_append_log("已确认：材料不足，仍进入 %s。" % campus_interactable.display_name)
	_pending_condition_override_interaction_id = &""
	var carry_options: Array[Dictionary] = _get_available_safehouse_carry_options_for_interactable(campus_interactable)
	if not carry_options.is_empty():
		_show_carry_choice_panel(campus_interactable, carry_options)
		return true
	_open_battle_for_interactable(campus_interactable)
	return true


func _return_to_safehouse_from_entrance(interactable: CampusInteractable) -> void:
	_pending_condition_override_interaction_id = &""
	_append_log("从%s安全返回住屋。" % interactable.display_name)
	_show_safehouse_return_transition(interactable)


func _show_carry_choice_panel(interactable: CampusInteractable, options: Array[Dictionary]) -> void:
	if interactable == null or options.is_empty():
		return
	_pending_carry_choice_interaction_id = interactable.interaction_id
	_pending_carry_choice_options = options.duplicate(true)
	if player != null:
		player.set_movement_enabled(false)
	if carry_choice_panel == null or carry_choice_button_box == null:
		return
	carry_choice_title_label.text = "%s：选择携带物处理" % interactable.display_name
	carry_choice_detail_label.text = "本次交流前可以使用一件携带物，也可以按原计划直接进入。"
	_clear_container_children(carry_choice_button_box)
	carry_choice_buttons.clear()
	for option: Dictionary in options:
		var option_button: Button = _create_carry_choice_button(_format_carry_choice_button_text(option))
		option_button.name = "CarryChoice_%s" % String(option.get("item_id", &""))
		option_button.tooltip_text = str(option.get("option_summary", ""))
		option_button.pressed.connect(_on_carry_choice_option_button_pressed.bind(StringName(option.get("item_id", &""))))
		carry_choice_button_box.add_child(option_button)
		carry_choice_buttons.append(option_button)

	var skip_button: Button = _create_carry_choice_button("直接进入交流\n不使用携带物选项")
	skip_button.name = "CarryChoiceSkip"
	skip_button.tooltip_text = "保留携带物状态，直接进入当前点位的卡牌战斗。"
	skip_button.pressed.connect(_on_carry_choice_skip_button_pressed)
	carry_choice_button_box.add_child(skip_button)
	carry_choice_buttons.append(skip_button)

	var cancel_button: Button = _create_carry_choice_button("返回地图\n稍后再决定")
	cancel_button.name = "CarryChoiceCancel"
	cancel_button.tooltip_text = "关闭选择面板，回到校园探索。"
	cancel_button.pressed.connect(_on_carry_choice_cancel_button_pressed)
	carry_choice_button_box.add_child(cancel_button)
	carry_choice_buttons.append(cancel_button)

	carry_choice_panel.visible = true
	if not carry_choice_buttons.is_empty():
		carry_choice_buttons[0].call_deferred("grab_focus")
	_refresh_hud()


func _create_carry_choice_button(button_text: String) -> Button:
	var button: Button = Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(HUD_CARRY_CHOICE_PANEL_WIDTH - 34.0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	button.focus_mode = Control.FOCUS_ALL
	return button


func _format_carry_choice_button_text(option: Dictionary) -> String:
	var resource_id: StringName = StringName(option.get("resource_id", &""))
	var resource_text: String = "%s +%d" % [
		_get_resource_display_name(resource_id),
		int(option.get("amount", 0)),
	]
	var battle_summary: String = str(option.get("battle_effect_summary", ""))
	var effect_text: String = resource_text if battle_summary == "" else "%s；%s" % [resource_text, battle_summary]
	return "%s：%s\n%s" % [
		str(option.get("item_name", "")),
		str(option.get("option_label", "")),
		effect_text,
	]


func _choose_pending_carry_option(item_id: StringName) -> bool:
	if not _has_pending_carry_choice():
		return false
	var interactable: Variant = _find_interactable(_pending_carry_choice_interaction_id)
	if not interactable is CampusInteractable:
		_pending_carry_battle_effect.clear()
		_clear_pending_carry_choice(true)
		return false
	var campus_interactable: CampusInteractable = interactable as CampusInteractable
	if not _apply_safehouse_carry_option_for_interactable(campus_interactable, item_id):
		return false
	for option: Dictionary in _pending_carry_choice_options:
		if StringName(option.get("item_id", &"")) == item_id:
			_pending_carry_battle_effect = option.duplicate(true)
			break
	_clear_pending_carry_choice(false)
	_open_battle_for_interactable(campus_interactable)
	return true


func _skip_pending_carry_choice() -> bool:
	if not _has_pending_carry_choice():
		return false
	var interactable: Variant = _find_interactable(_pending_carry_choice_interaction_id)
	if not interactable is CampusInteractable:
		_pending_carry_battle_effect.clear()
		_clear_pending_carry_choice(true)
		return false
	_pending_carry_battle_effect.clear()
	_clear_pending_carry_choice(false)
	_open_battle_for_interactable(interactable)
	return true


func _cancel_pending_carry_choice() -> bool:
	if not _has_pending_carry_choice():
		return false
	_pending_carry_battle_effect.clear()
	_clear_pending_carry_choice(true)
	_append_log("已取消携带物处理选择。")
	_refresh_hud()
	return true


func _clear_pending_carry_choice(restore_player_control: bool) -> void:
	_pending_carry_choice_interaction_id = &""
	_pending_carry_choice_options.clear()
	if carry_choice_panel != null:
		carry_choice_panel.visible = false
	if carry_choice_button_box != null:
		_clear_container_children(carry_choice_button_box)
	carry_choice_buttons.clear()
	if restore_player_control and mode == MODE_OVERWORLD and player != null:
		player.set_movement_enabled(true)


func _has_pending_carry_choice() -> bool:
	return _pending_carry_choice_interaction_id != &""


func _format_pending_carry_choice_summary() -> String:
	if not _has_pending_carry_choice():
		return ""
	var parts: Array[String] = []
	for option: Dictionary in _pending_carry_choice_options:
		parts.append(_format_safehouse_carry_option_entry(option))
	return "%s：%s" % [String(_pending_carry_choice_interaction_id), " / ".join(parts)]


func _has_unmet_interaction_requirement(interactable: CampusInteractable) -> bool:
	if interactable == null:
		return false
	if interactable.interaction_kind == SAFEHOUSE_INTERACTION_KIND:
		return false
	if interactable.interaction_kind == &"resource":
		return false
	return interactable.requirement_summary != ""


func _should_hard_block_interaction(interactable: CampusInteractable, intercept_mode: StringName) -> bool:
	if intercept_mode != REQUIREMENT_INTERCEPT_HARD_GATE:
		return false
	return _has_unmet_interaction_requirement(interactable)


func _should_soft_block_interaction(interactable: CampusInteractable, intercept_mode: StringName) -> bool:
	if intercept_mode != REQUIREMENT_INTERCEPT_SOFT_GATE:
		return false
	if not _has_unmet_interaction_requirement(interactable):
		return false
	return _pending_condition_override_interaction_id != interactable.interaction_id


func _collect_resource(interactable: Variant) -> void:
	var resource_id: StringName = interactable.resource_id
	var resource_amount: int = int(interactable.resource_amount)
	var pickup_text: String = "+%d %s" % [resource_amount, _get_resource_display_name(resource_id)]
	var pickup_position: Vector2 = interactable.position
	var pickup_color: Color = interactable.accent_color
	campus_resources[resource_id] = int(campus_resources.get(resource_id, 0)) + int(interactable.resource_amount)
	_mark_interaction_completed(interactable.interaction_id)
	_refresh_condition_marker_states()
	_refresh_story_guidance()
	_show_pickup_feedback(pickup_text, pickup_position, pickup_color)
	_append_log("收集：%s。" % interactable.get_interaction_summary())
	_refresh_hud()


func _show_pickup_feedback(text: String, world_position: Vector2, accent_color: Color) -> void:
	if feedback_root == null or not is_inside_tree():
		return
	var burst: Node2D = CAMPUS_PICKUP_BURST.new()
	burst.name = "PickupBurst"
	burst.position = world_position + Vector2(0, -18)
	burst.z_index = 89
	burst.call("configure", accent_color)
	feedback_root.add_child(burst)

	var popup: Label = Label.new()
	popup.name = "PickupText"
	popup.text = text
	popup.position = world_position + Vector2(-34, -52)
	popup.z_index = 90
	popup.modulate = Color(1.0, 1.0, 1.0, 1.0)
	popup.add_theme_color_override("font_color", accent_color.lightened(0.24))
	popup.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.08, 0.90))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", 15)
	feedback_root.add_child(popup)

	var tween: Tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 28.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(popup.queue_free)


func _open_battle_for_interactable(interactable: Variant) -> void:
	_clear_pending_carry_choice(false)
	_hide_return_summary_panel()
	mode = MODE_BATTLE
	_active_interaction_id = interactable.interaction_id
	_active_interaction_route_node_id = interactable.route_node_id
	_active_interaction_summary = interactable.get_interaction_summary()
	if player != null:
		player.set_movement_enabled(false)
	if world_root != null:
		world_root.visible = false
	if hud_root != null:
		hud_root.visible = false
	if battle_layer != null:
		battle_layer.visible = true

	_clear_battle_layer()
	battle_instance = BATTLE_TEST_SCENE.instantiate()
	battle_layer.add_child(battle_instance)
	battle_instance.initialize_battle_ui()
	battle_instance.start_new_battle_with_seed(_mix_interaction_seed(interactable.interaction_id))
	_enter_battle_route_node(interactable.route_node_id)
	_apply_campus_resources_to_active_battle()
	_apply_pending_carry_battle_effect_to_active_battle()
	_active_battle_resource_snapshot = _snapshot_active_battle_resources()
	if battle_instance.has_method("_refresh_ui"):
		battle_instance._refresh_ui()
	_add_battle_return_button()
	_show_battle_transition(interactable)
	_append_log("进入学术交流：%s。" % interactable.get_interaction_summary())


func _show_battle_transition(interactable: CampusInteractable) -> void:
	_show_transition_message("进入学术交流", _format_battle_transition_subtitle(interactable), 0.12, 0.38, 0.32)


func _show_campus_return_transition(resolution_text: String) -> void:
	_show_transition_message("回到校园", _format_campus_return_transition_subtitle(resolution_text), 0.10, 0.56, 0.30)


func _show_safehouse_return_transition(interactable: CampusInteractable) -> void:
	if transition_root == null:
		_enter_safehouse(false)
		return
	if _transition_tween != null and is_instance_valid(_transition_tween):
		_transition_tween.kill()
	if player != null:
		player.set_movement_enabled(false)
	if focused_interactable is CampusInteractable:
		(focused_interactable as CampusInteractable).set_focused_target(false)
	focused_interactable = null
	_refresh_hud()

	transition_title_label.text = "安全返回住屋"
	transition_subtitle_label.text = _format_safehouse_return_transition_subtitle(interactable)
	transition_root.visible = true
	transition_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_transition_tween = transition_root.create_tween()
	_transition_tween.tween_property(transition_root, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_interval(0.34)
	_transition_tween.tween_callback(_finish_safehouse_return_transition)
	_transition_tween.tween_interval(0.12)
	_transition_tween.tween_property(transition_root, "modulate:a", 0.0, 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.tween_callback(_finish_battle_transition)


func _show_transition_message(title: String, subtitle: String, fade_in_seconds: float, hold_seconds: float, fade_out_seconds: float) -> void:
	if transition_root == null:
		return
	if _transition_tween != null and is_instance_valid(_transition_tween):
		_transition_tween.kill()
	transition_title_label.text = title
	transition_subtitle_label.text = subtitle
	transition_root.visible = true
	transition_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_transition_tween = transition_root.create_tween()
	_transition_tween.tween_property(transition_root, "modulate:a", 1.0, fade_in_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_interval(hold_seconds)
	_transition_tween.tween_property(transition_root, "modulate:a", 0.0, fade_out_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.tween_callback(_finish_battle_transition)


func _finish_safehouse_return_transition() -> void:
	_enter_safehouse(false, true)


func _hide_battle_transition() -> void:
	if _transition_tween != null and is_instance_valid(_transition_tween):
		_transition_tween.kill()
	_finish_battle_transition()


func _finish_battle_transition() -> void:
	_transition_tween = null
	if transition_root == null:
		return
	transition_root.visible = false
	transition_root.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _format_battle_transition_subtitle(interactable: CampusInteractable) -> String:
	if interactable == null:
		return ""
	if interactable.route_node_id == &"":
		return interactable.display_name
	return "%s · %s" % [interactable.display_name, String(interactable.route_node_id)]


func _format_campus_return_transition_subtitle(resolution_text: String) -> String:
	return resolution_text.trim_suffix("。")


func _format_safehouse_return_transition_subtitle(interactable: CampusInteractable) -> String:
	var source_name: String = "住屋入口" if interactable == null else interactable.display_name
	return "%s · 带回当前资源" % source_name


func _show_return_summary_panel(resolution_text: String) -> void:
	if return_summary_panel == null:
		return
	if _return_summary_tween != null and is_instance_valid(_return_summary_tween):
		_return_summary_tween.kill()
	return_summary_result_label.text = "结果：%s" % _format_return_summary_result(resolution_text)
	return_summary_resource_label.text = "资源：%s" % _format_return_summary_resources()
	return_summary_guidance_label.text = "下一步：%s" % _format_return_summary_guidance()
	_set_summary_guidance_target_from_current_story()
	if task_tracker_panel != null:
		task_tracker_panel.visible = false
	return_summary_panel.visible = true
	return_summary_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_return_summary_tween = return_summary_panel.create_tween()
	_return_summary_tween.tween_property(return_summary_panel, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_return_summary_tween.tween_interval(5.0)
	_return_summary_tween.tween_property(return_summary_panel, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_return_summary_tween.tween_callback(_finish_return_summary_panel)


func _hide_return_summary_panel() -> void:
	if _return_summary_tween != null and is_instance_valid(_return_summary_tween):
		_return_summary_tween.kill()
	_finish_return_summary_panel()


func _finish_return_summary_panel() -> void:
	_return_summary_tween = null
	_clear_summary_guidance_target()
	if return_summary_panel == null:
		return
	return_summary_panel.visible = false
	return_summary_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_refresh_task_tracker_panel()


func _set_summary_guidance_target_from_current_story() -> void:
	_clear_summary_guidance_target()
	var target: CampusInteractable = _get_story_guidance_target()
	if target == null:
		return
	_summary_guidance_target_interaction_id = target.interaction_id
	target.set_summary_guidance_target(true)
	_start_guidance_indicator_discovery()


func _clear_summary_guidance_target() -> void:
	_stop_guidance_indicator_discovery()
	if _summary_guidance_target_interaction_id == &"":
		return
	var interactable: Variant = _find_interactable(_summary_guidance_target_interaction_id)
	if interactable != null and interactable.has_method("set_summary_guidance_target"):
		interactable.set_summary_guidance_target(false)
	_summary_guidance_target_interaction_id = &""


func _format_return_summary_resources() -> String:
	if _last_return_resource_parts.is_empty():
		return "无变化"
	return "、".join(_last_return_resource_parts)


func _format_return_summary_result(resolution_text: String) -> String:
	var result_text: String = _format_campus_return_transition_subtitle(resolution_text)
	var resource_separator_index: int = result_text.find("。带回：")
	if resource_separator_index >= 0:
		return result_text.substr(0, resource_separator_index)
	return result_text


func _format_return_summary_guidance() -> String:
	var guidance_text: String = get_story_guidance_text()
	if guidance_text.begins_with("下一步："):
		return guidance_text.trim_prefix("下一步：")
	return guidance_text


func _enter_battle_route_node(route_node_id: StringName) -> void:
	if battle_instance == null or route_node_id == &"":
		return
	if route_node_id == &"N001":
		return
	if battle_instance.route == null:
		return
	var advanced: bool = battle_instance.route.advance_to_node(
		route_node_id,
		battle_instance.encounters,
		battle_instance.events,
		battle_instance.bosses
	)
	if advanced:
		battle_instance._enter_current_route_node()


func _add_battle_return_button() -> void:
	var return_button: Button = Button.new()
	return_button.name = "ReturnToCampusButton"
	return_button.text = "返回校园"
	return_button.anchor_left = 1.0
	return_button.anchor_right = 1.0
	return_button.offset_left = -132
	return_button.offset_right = -16
	return_button.offset_top = 12
	return_button.offset_bottom = 44
	return_button.pressed.connect(return_to_campus)
	battle_layer.add_child(return_button)


func _mix_interaction_seed(interaction_id: StringName) -> int:
	var hash_value: int = abs(String(interaction_id).hash())
	return max(1, (campus_seed * 1103515245 + hash_value) % 2147483647)


func _find_interactable(interaction_id: StringName) -> Variant:
	if interactable_root == null:
		return null
	for child: Node in interactable_root.get_children():
		if child.get("interaction_id") != null and child.interaction_id == interaction_id:
			return child
	return null


func _resolve_active_battle_interaction() -> String:
	_last_return_resource_parts.clear()
	if _active_interaction_id == &"" or battle_instance == null:
		return ""

	if not _is_active_battle_interaction_complete():
		return "回到校园，%s 暂未完成。" % _active_interaction_summary

	var resource_parts: Array[String] = _apply_battle_resource_deltas_to_campus()
	_last_return_resource_parts = resource_parts.duplicate()
	_mark_interaction_completed(_active_interaction_id)
	if resource_parts.is_empty():
		return "完成：%s。" % _active_interaction_summary
	return "完成：%s。带回：%s。" % [_active_interaction_summary, "、".join(resource_parts)]


func _is_active_battle_interaction_complete() -> bool:
	if battle_instance == null:
		return false
	if battle_instance.was_event_choice_taken():
		return true
	if battle_instance.was_reward_taken():
		return true
	if battle_instance.get_settlement_visible():
		return true
	var current_node_id: StringName = get_active_route_node_id()
	return _active_interaction_route_node_id != &"" and current_node_id != &"" and current_node_id != _active_interaction_route_node_id


func _snapshot_active_battle_resources() -> Dictionary:
	var snapshot: Dictionary = {}
	if battle_instance == null or battle_instance.battle == null:
		return snapshot
	for resource_id: StringName in CAMPUS_TRACKED_RESOURCE_IDS:
		snapshot[resource_id] = battle_instance.battle.get_resource(resource_id)
	return snapshot


func _apply_campus_resources_to_active_battle() -> void:
	if battle_instance == null or battle_instance.battle == null:
		return
	for resource_id: StringName in CAMPUS_TRACKED_RESOURCE_IDS:
		var amount: int = int(campus_resources.get(resource_id, 0))
		if amount <= 0:
			continue
		battle_instance.battle.resources[resource_id] = amount


func _apply_pending_carry_battle_effect_to_active_battle() -> void:
	if _pending_carry_battle_effect.is_empty():
		return
	if battle_instance == null or not battle_instance.has_method("apply_campus_prebattle_effect"):
		_pending_carry_battle_effect.clear()
		return
	var effect_id: StringName = StringName(_pending_carry_battle_effect.get("battle_effect_id", &""))
	var amount: int = int(_pending_carry_battle_effect.get("battle_effect_amount", 0))
	var source_label: String = "%s「%s」" % [
		str(_pending_carry_battle_effect.get("item_name", "")),
		str(_pending_carry_battle_effect.get("option_label", "")),
	]
	var summary: String = str(_pending_carry_battle_effect.get("battle_effect_summary", ""))
	if effect_id != &"" and amount > 0:
		battle_instance.call("apply_campus_prebattle_effect", effect_id, amount, source_label, summary)
	_pending_carry_battle_effect.clear()


func _apply_battle_resource_deltas_to_campus() -> Array[String]:
	var parts: Array[String] = []
	if battle_instance == null or battle_instance.battle == null:
		return parts
	for resource_id: StringName in CAMPUS_TRACKED_RESOURCE_IDS:
		var before_count: int = int(_active_battle_resource_snapshot.get(resource_id, 0))
		var after_count: int = battle_instance.battle.get_resource(resource_id)
		var delta: int = after_count - before_count
		if delta == 0:
			continue
		var updated_count: int = max(0, int(campus_resources.get(resource_id, 0)) + delta)
		if updated_count == 0:
			campus_resources.erase(resource_id)
		else:
			campus_resources[resource_id] = updated_count
		parts.append("%s %s%d" % [_get_resource_display_name(resource_id), "+" if delta > 0 else "", delta])
	return parts


func _mark_interaction_completed(interaction_id: StringName) -> void:
	if not completed_interaction_ids.has(interaction_id):
		completed_interaction_ids.append(interaction_id)
	var interactable: Variant = _find_interactable(interaction_id)
	if interactable == null:
		return
	interactable.mark_collected()
	if focused_interactable == interactable:
		focused_interactable = null


func _clear_active_interaction_context() -> void:
	_active_interaction_id = &""
	_active_interaction_route_node_id = &""
	_active_interaction_summary = ""
	_active_battle_resource_snapshot.clear()
	_pending_carry_battle_effect.clear()


func _refresh_hud() -> void:
	if status_label == null:
		return
	var generation_suffix: String = " · 候选池" if generation_candidate_map_enabled else ""
	var prep_suffix: String = "" if safehouse_active_prep_effects.is_empty() else " · 准备%d" % safehouse_active_prep_effects.size()
	var carry_suffix: String = "" if safehouse_selected_carry_item_ids.is_empty() else " · 携带%d" % safehouse_selected_carry_item_ids.size()
	status_label.text = "%s校园 · Seed %d · %s%s%s%s" % [_get_stage_label(campus_stage), campus_seed, _get_mode_label(), generation_suffix, prep_suffix, carry_suffix]
	resource_label.text = _format_campus_resources()
	guidance_label.text = _format_story_guidance_text()
	log_label.text = _format_recent_log()
	_refresh_stage_debug_buttons()
	_refresh_task_tracker_panel()
	_refresh_guidance_direction_indicator()
	if _has_pending_carry_choice():
		prompt_label.text = "选择携带物处理"
	elif focused_interactable == null:
		prompt_label.text = "校园中庭"
	else:
		prompt_label.text = _format_focused_interaction_prompt()
	_refresh_focus_info_panel()


func _refresh_task_tracker_panel() -> void:
	if task_tracker_panel == null:
		return
	if mode != MODE_OVERWORLD or hud_root == null or not hud_root.visible:
		task_tracker_panel.visible = false
		return
	if return_summary_panel != null and return_summary_panel.visible:
		task_tracker_panel.visible = false
		return

	task_tracker_stage_label.text = _format_task_tracker_stage()
	task_tracker_objective_label.text = _format_task_tracker_objective()
	task_tracker_map_label.text = _format_task_tracker_map()
	task_tracker_supply_label.text = _format_task_tracker_supply()
	task_tracker_progress_label.text = _format_task_tracker_progress()
	task_tracker_panel.visible = true
	_refresh_task_tracker_minimap()


func _refresh_task_tracker_minimap() -> void:
	if task_tracker_minimap == null or task_tracker_panel == null or not task_tracker_panel.visible:
		return
	if not task_tracker_minimap.has_method("configure"):
		return
	var current_player_position: Vector2 = PLAYER_START_POSITION
	if player != null:
		current_player_position = player.position
	task_tracker_minimap.call(
		"configure",
		_get_task_tracker_minimap_bounds(),
		current_player_position,
		_get_task_tracker_minimap_entries()
	)


func _get_task_tracker_minimap_bounds() -> Rect2:
	if map_view != null and map_view.has_method("get_map_bounds"):
		return map_view.call("get_map_bounds")
	return Rect2(Vector2(32, 32), Vector2(1536, 896))


func _get_task_tracker_minimap_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if interactable_root == null:
		return entries
	for child: Node in interactable_root.get_children():
		if not child is CampusInteractable:
			continue
		var interactable: CampusInteractable = child as CampusInteractable
		if interactable.collected:
			continue
		entries.append({
			"id": interactable.interaction_id,
			"position": interactable.position,
			"role": _get_task_tracker_minimap_role(interactable),
		})
	return entries


func _get_task_tracker_minimap_role(interactable: CampusInteractable) -> StringName:
	if interactable.is_guidance_target():
		return &"story"
	if interactable.is_supply_hint_target():
		return &"supply"
	if interactable.interaction_kind == SAFEHOUSE_INTERACTION_KIND:
		return &"safehouse"
	match interactable.interaction_kind:
		&"boss":
			return &"boss"
		&"resource":
			return &"resource"
		&"event":
			return &"event"
		_:
			return &"encounter"


func _format_task_tracker_stage() -> String:
	var generation_suffix: String = " · 候选池" if generation_candidate_map_enabled else ""
	return "阶段：%s校园 · Seed %d%s" % [_get_stage_label(campus_stage), campus_seed, generation_suffix]


func _format_task_tracker_objective() -> String:
	var target: CampusInteractable = _get_story_guidance_target()
	if target == null:
		return "目标：自由探索"
	var route_text: String = ""
	if target.route_node_id != &"":
		route_text = " · %s" % String(target.route_node_id)
	var requirement_text: String = ""
	if target.requirement_summary != "":
		requirement_text = " · 缺%s" % target.requirement_summary
	return "目标：%s · %s%s%s" % [
		_get_campus_area_hint(target.position),
		target.display_name,
		route_text,
		requirement_text,
	]


func _format_task_tracker_map() -> String:
	var target: CampusInteractable = _get_story_guidance_target()
	var target_area: String = "无"
	if target != null:
		target_area = _get_campus_area_hint(target.position)
	var supply_count: int = get_supply_hint_target_interaction_ids().size()
	return "点位图：主线%s · 补给%d · 剩余%d" % [
		target_area,
		supply_count,
		get_available_interactable_ids().size(),
	]


func _format_task_tracker_supply() -> String:
	var target: CampusInteractable = _get_story_guidance_target()
	if target == null:
		return "补给：暂无缺口"
	var advice_text: String = _format_requirement_supply_advice_for_interactable(target)
	if advice_text == "":
		return "补给：暂无缺口"
	if advice_text.begins_with("建议："):
		advice_text = advice_text.substr("建议：".length())
	return "补给：%s" % advice_text


func _format_task_tracker_progress() -> String:
	return "进度：已处理 %d/%d · 可互动 %d" % [
		completed_interaction_ids.size(),
		get_interactable_ids().size(),
		get_available_interactable_ids().size(),
	]


func _format_generation_audit_route_summary() -> String:
	var route_parts: Array[String] = []
	for route_node_id: StringName in _get_story_guidance_route_order():
		route_parts.append(String(route_node_id))
	var route_text: String = "无" if route_parts.is_empty() else "/".join(route_parts)
	var missing_text: String = get_stage_spawn_missing_route_node_summary()
	if missing_text == "":
		missing_text = "无"
	return "%s · 缺失%s" % [route_text, missing_text]


func _refresh_focus_info_panel() -> void:
	if focus_info_panel == null:
		return
	if mode != MODE_OVERWORLD or _has_pending_carry_choice() or focused_interactable == null or not (focused_interactable is CampusInteractable):
		focus_info_panel.visible = false
		return

	var interactable: CampusInteractable = focused_interactable as CampusInteractable
	focus_info_title_label.text = _format_focus_info_title(interactable)
	focus_info_type_label.text = _format_focus_info_type(interactable)
	focus_info_route_label.text = _format_focus_info_route(interactable)
	focus_info_reward_label.text = _format_focus_info_reward(interactable)
	focus_info_requirement_label.text = _format_focus_info_requirement(interactable)
	focus_info_panel.visible = true


func _format_focus_info_title(interactable: CampusInteractable) -> String:
	var role_tag: String = _format_interactable_focus_role_tag(interactable)
	if role_tag == "":
		return interactable.display_name
	return "%s · %s" % [role_tag, interactable.display_name]


func _format_focus_info_type(interactable: CampusInteractable) -> String:
	var type_text: String = ""
	match interactable.interaction_kind:
		SAFEHOUSE_INTERACTION_KIND:
			type_text = "类型：住屋入口 · 安全撤回"
		&"resource":
			type_text = "类型：补给点 · 校园拾取"
		&"boss":
			type_text = "类型：剧情考核 · Boss"
		&"event":
			type_text = "类型：校园事件 · 选项处理"
		_:
			type_text = "类型：学术交流 · 卡牌构筑"

	var tag_text: String = _format_content_tags(_get_interactable_content_tags(interactable), 3)
	if tag_text == "":
		return type_text
	return "%s | 标签：%s" % [type_text, tag_text]


func _format_focus_info_route(interactable: CampusInteractable) -> String:
	if interactable.interaction_kind == SAFEHOUSE_INTERACTION_KIND:
		return "路线：安全屋 · 返回住屋"
	if interactable.interaction_kind == &"resource":
		return "路线：无 · 直接获得资源"
	if interactable.route_node_id == &"":
		return "路线：未绑定"
	return "路线：%s" % String(interactable.route_node_id)


func _format_focus_info_reward(interactable: CampusInteractable) -> String:
	var reward_text: String = ""
	match interactable.interaction_kind:
		SAFEHOUSE_INTERACTION_KIND:
			reward_text = "收益：保留当前资源并结束本次校园探索"
		&"resource":
			reward_text = "收益：+%d %s" % [
				interactable.resource_amount,
				_get_resource_display_name(interactable.resource_id),
			]
		&"boss":
			reward_text = "收益：Boss 奖励 / 剧情推进"
		&"event":
			reward_text = "收益：事件选项 / 资源转换"
		_:
			reward_text = "收益：卡牌奖励 / 路线推进"
	var carry_hint: String = _format_safehouse_carry_trigger_hint(interactable)
	var carry_option_hint: String = _format_safehouse_carry_option_hint(interactable)
	var carry_lines: Array[String] = []
	if carry_hint != "":
		carry_lines.append("携带：%s" % carry_hint)
	if carry_option_hint != "":
		carry_lines.append("携带选项：%s" % carry_option_hint)
	if not carry_lines.is_empty():
		return "%s\n%s" % [reward_text, "\n".join(carry_lines)]
	return reward_text


func _format_focus_info_requirement(interactable: CampusInteractable) -> String:
	if interactable.interaction_kind == SAFEHOUSE_INTERACTION_KIND:
		return "准备：随时可以返回"
	if interactable.interaction_kind == &"resource":
		return "准备：无需准备"
	if interactable.requirement_summary == "":
		return "准备：当前无额外门槛"
	var intercept_mode: StringName = _get_interactable_requirement_intercept_mode(interactable)
	if interactable.interaction_id == _pending_condition_override_interaction_id:
		return "准备：%s · 再次确认进入" % interactable.requirement_summary
	if intercept_mode == REQUIREMENT_INTERCEPT_HARD_GATE:
		return "准备：%s · 不足时无法进入" % interactable.requirement_summary
	if intercept_mode == REQUIREMENT_INTERCEPT_WARN_ONLY:
		return "准备：%s · 仅提示" % interactable.requirement_summary
	return "准备：%s · 可二次确认" % interactable.requirement_summary


func _get_interactable_content_tags(interactable: CampusInteractable) -> Array[StringName]:
	var tags: Array[StringName] = _normalize_content_tags(interactable.get_content_tags())
	if tags.is_empty():
		tags = _infer_content_tags(interactable)
	return tags


func _get_interaction_definition_content_tags(definition: Resource) -> Array[StringName]:
	if definition == null:
		return []
	var tags: Array[StringName] = _normalize_content_tags(definition.get("content_tags"))
	if tags.is_empty():
		tags = _infer_content_tags_from_fields(
			definition.get("interaction_kind"),
			definition.get("route_node_id"),
			definition.get("resource_id")
		)
	return tags


func _get_stage_generation_target_interaction_count() -> int:
	var stage_def: Resource = _get_campus_stage_definition(campus_stage)
	if stage_def == null:
		return get_interactable_ids().size()
	return max(1, int(stage_def.get("generation_target_interaction_count")))


func _get_stage_generation_focus_tags() -> Array[StringName]:
	var stage_def: Resource = _get_campus_stage_definition(campus_stage)
	if stage_def == null:
		return []
	return _normalize_content_tags(stage_def.get("generation_focus_tags"))


func _get_stage_generation_required_tags() -> Array[StringName]:
	var stage_def: Resource = _get_campus_stage_definition(campus_stage)
	if stage_def == null:
		return []
	return _normalize_content_tags(stage_def.get("generation_required_tags"))


func _get_stage_generation_theme_ids() -> Array[StringName]:
	var stage_def: Resource = _get_campus_stage_definition(campus_stage)
	if stage_def == null:
		return []
	return _normalize_content_tags(stage_def.get("generation_theme_ids"))


func _get_stage_generation_theme_choice_ids() -> Array[StringName]:
	var theme_ids: Array[StringName] = _get_stage_generation_theme_ids()
	if theme_ids.size() <= CAMPUS_GENERATION_THEME_CHOICE_COUNT:
		return theme_ids
	var ordered_theme_ids: Array[StringName] = theme_ids.duplicate()
	ordered_theme_ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		var left_tie_breaker: int = _get_generation_theme_choice_tie_breaker(a)
		var right_tie_breaker: int = _get_generation_theme_choice_tie_breaker(b)
		if left_tie_breaker != right_tie_breaker:
			return left_tie_breaker < right_tie_breaker
		return String(a) < String(b)
	)
	return ordered_theme_ids.slice(0, CAMPUS_GENERATION_THEME_CHOICE_COUNT)


func _get_active_generation_theme_id() -> StringName:
	var theme_choices: Array[StringName] = _get_stage_generation_theme_choice_ids()
	if theme_choices.is_empty():
		return &""
	if generation_selected_theme_id != &"" and theme_choices.has(generation_selected_theme_id):
		return generation_selected_theme_id
	return theme_choices[0]


func _clear_generation_theme_choice() -> void:
	generation_selected_theme_id = &""


func _get_generation_theme_choice_tie_breaker(theme_id: StringName) -> int:
	return abs(("%d:%s:generation_theme_choice:%s" % [_get_stage_seed(), String(campus_stage), String(theme_id)]).hash())


func _get_stage_generation_theme_tags() -> Array[StringName]:
	return _get_generation_theme_tags(_get_active_generation_theme_id())


func _get_generation_theme_tags(theme_id: StringName) -> Array[StringName]:
	match theme_id:
		GENERATION_THEME_EXPERIMENT:
			return [&"lab", &"equipment", &"data"]
		GENERATION_THEME_WRITING:
			return [&"writing", &"draft", &"paper_fragments", &"library"]
		GENERATION_THEME_SOCIAL:
			return [&"peer", &"collaboration", &"social", &"meeting"]
		GENERATION_THEME_ADVISOR:
			return [&"advisor", &"direction", &"meeting", &"method"]
		GENERATION_THEME_RECOVERY:
			return [&"self_care", &"canteen", &"inspiration", &"peer"]
		GENERATION_THEME_COMMITTEE:
			return [&"committee", &"exam", &"method", &"reputation"]
		GENERATION_THEME_TRANSFER:
			return [&"advisor", &"committee", &"reputation", &"writing"]
		GENERATION_THEME_PROJECT:
			return [&"project", &"meeting", &"data", &"method"]
		GENERATION_THEME_FUNDS:
			return [&"funds", &"administration", &"project"]
		GENERATION_THEME_SEMINAR:
			return [&"seminar", &"peer", &"method", &"reputation"]
		GENERATION_THEME_DEFENSE:
			return [&"defense", &"committee", &"draft", &"method"]
		GENERATION_THEME_REVISION:
			return [&"revision", &"writing", &"committee", &"draft"]
		GENERATION_THEME_DATA_REPAIR:
			return [&"revision", &"data", &"lab", &"method"]
		_:
			return []


func _get_generation_theme_display_name(theme_id: StringName) -> String:
	match theme_id:
		GENERATION_THEME_EXPERIMENT:
			return "实验主题"
		GENERATION_THEME_WRITING:
			return "写作主题"
		GENERATION_THEME_SOCIAL:
			return "同门主题"
		GENERATION_THEME_ADVISOR:
			return "导师主题"
		GENERATION_THEME_RECOVERY:
			return "缓冲主题"
		GENERATION_THEME_COMMITTEE:
			return "委员会主题"
		GENERATION_THEME_TRANSFER:
			return "转博主题"
		GENERATION_THEME_PROJECT:
			return "项目主题"
		GENERATION_THEME_FUNDS:
			return "经费主题"
		GENERATION_THEME_SEMINAR:
			return "沙龙主题"
		GENERATION_THEME_DEFENSE:
			return "答辩主题"
		GENERATION_THEME_REVISION:
			return "返修主题"
		GENERATION_THEME_DATA_REPAIR:
			return "数据修补主题"
		_:
			return "无主题"


func _get_current_content_tag_counts() -> Dictionary:
	var counts: Dictionary = {}
	if interactable_root == null:
		return counts
	for child: Node in interactable_root.get_children():
		if not child is CampusInteractable:
			continue
		for tag: StringName in _get_interactable_content_tags(child as CampusInteractable):
			counts[tag] = int(counts.get(tag, 0)) + 1
	return counts


func _get_content_tag_counts_for_definitions(definitions: Array[Resource]) -> Dictionary:
	var counts: Dictionary = {}
	for definition: Resource in definitions:
		if definition == null:
			continue
		for tag: StringName in _get_interaction_definition_content_tags(definition):
			counts[tag] = int(counts.get(tag, 0)) + 1
	return counts


func _get_missing_generation_required_tags() -> Array[StringName]:
	return _get_missing_generation_required_tags_for_counts(_get_current_content_tag_counts())


func _get_missing_generation_required_tags_for_counts(counts: Dictionary) -> Array[StringName]:
	var missing_tags: Array[StringName] = []
	for tag: StringName in _get_stage_generation_required_tags():
		if int(counts.get(tag, 0)) <= 0:
			missing_tags.append(tag)
	return missing_tags


func _format_content_tag_distribution(counts: Dictionary) -> String:
	var keys: Array[String] = []
	for raw_key: Variant in counts.keys():
		keys.append(String(raw_key))
	keys.sort()

	var parts: Array[String] = []
	for key: String in keys:
		parts.append("%s=%d" % [key, int(counts.get(StringName(key), 0))])
	return ",".join(parts)


func _format_generation_tag_count_summary(tags: Array[StringName], counts: Dictionary) -> String:
	if tags.is_empty():
		return ""
	var parts: Array[String] = []
	for tag: StringName in tags:
		parts.append("%s=%d" % [_get_content_tag_display_name(tag), int(counts.get(tag, 0))])
	return "、".join(parts)


func _get_stage_generation_candidate_definitions() -> Array[Resource]:
	var stage_def: Resource = _get_campus_stage_definition(campus_stage)
	if stage_def == null:
		return []
	var candidate_definitions: Array[Resource] = []
	var raw_candidates: Array = stage_def.get("generation_candidate_interactions")
	if not raw_candidates.is_empty():
		for definition: Resource in raw_candidates:
			if definition != null:
				candidate_definitions.append(definition)
		return candidate_definitions
	return _get_stage_interaction_definitions()


func _get_stage_generation_selected_definitions() -> Array[Resource]:
	return _select_generation_candidate_definitions(
		_get_stage_generation_candidate_definitions(),
		_get_stage_generation_target_interaction_count(),
		_get_stage_generation_required_tags(),
		_get_stage_generation_focus_tags()
	)


func _get_stage_generation_spawn_definitions() -> Array[Resource]:
	var selected: Array[Resource] = _get_stage_generation_selected_definitions()
	var target_count: int = _get_stage_generation_target_interaction_count()
	var focus_tags: Array[StringName] = _get_stage_generation_focus_tags()
	var required_tags: Array[StringName] = _get_stage_generation_required_tags()
	var candidates: Array[Resource] = _get_stage_generation_candidate_definitions()
	var protected_ids: Dictionary = {}

	for definition: Resource in selected:
		if _get_story_guidance_route_order().has(StringName(definition.get("route_node_id"))):
			protected_ids[String(definition.get("id"))] = true

	for route_node_id: StringName in _get_story_guidance_route_order():
		if _definition_selection_has_route_node(selected, route_node_id):
			continue
		var route_candidate: Resource = _find_best_generation_candidate_with_route_node(candidates, route_node_id, focus_tags, required_tags)
		if route_candidate != null:
			selected.append(route_candidate)
			protected_ids[String(route_candidate.get("id"))] = true

	var clamped_target_count: int = min(max(0, target_count), max(candidates.size(), selected.size()))
	while selected.size() > clamped_target_count:
		var removal_index: int = _find_generation_selection_removal_index(selected, protected_ids, focus_tags, required_tags)
		if removal_index < 0:
			break
		selected.remove_at(removal_index)
	selected = _rebalance_generation_spawn_layout(selected, candidates, protected_ids, target_count, focus_tags, required_tags)
	return selected


func _select_generation_candidate_definitions(
	candidates: Array[Resource],
	target_count: int,
	required_tags: Array[StringName],
	focus_tags: Array[StringName]
) -> Array[Resource]:
	var selected: Array[Resource] = []
	var remaining: Array[Resource] = candidates.duplicate()
	var clamped_target_count: int = min(max(0, target_count), remaining.size())
	if clamped_target_count <= 0:
		return selected

	for required_tag: StringName in required_tags:
		if selected.size() >= clamped_target_count:
			break
		if _definition_selection_has_tag(selected, required_tag):
			continue
		var required_candidate: Resource = _find_best_generation_candidate_with_tag(remaining, required_tag, focus_tags, required_tags)
		if required_candidate != null:
			selected.append(required_candidate)
			remaining.erase(required_candidate)

	for focus_tag: StringName in focus_tags:
		if selected.size() >= clamped_target_count:
			break
		if _definition_selection_has_tag(selected, focus_tag):
			continue
		var focus_candidate: Resource = _find_best_generation_candidate_with_tag(remaining, focus_tag, focus_tags, required_tags)
		if focus_candidate != null:
			selected.append(focus_candidate)
			remaining.erase(focus_candidate)

	while selected.size() < clamped_target_count and not remaining.is_empty():
		var candidate: Resource = _find_best_generation_candidate(remaining, focus_tags, required_tags)
		if candidate == null:
			break
		selected.append(candidate)
		remaining.erase(candidate)
	return selected


func _rebalance_generation_spawn_layout(
	selected_definitions: Array[Resource],
	candidate_definitions: Array[Resource],
	protected_ids: Dictionary,
	target_count: int,
	focus_tags: Array[StringName],
	required_tags: Array[StringName]
) -> Array[Resource]:
	var balanced: Array[Resource] = selected_definitions.duplicate()
	if balanced.is_empty() or candidate_definitions.is_empty():
		return balanced

	var area_cap: int = _get_generation_layout_area_cap(target_count)
	var desired_unique_areas: int = min(
		CAMPUS_LAYOUT_MIN_UNIQUE_AREAS,
		min(_get_generation_layout_area_counts(candidate_definitions).size(), max(1, target_count))
	)
	for _attempt: int in range(CAMPUS_LAYOUT_REBALANCE_ATTEMPTS):
		var area_counts: Dictionary = _get_generation_layout_area_counts(balanced)
		var overrepresented_area: String = _get_generation_layout_overrepresented_area(area_counts, area_cap)
		var needs_more_unique_areas: bool = area_counts.size() < desired_unique_areas
		if overrepresented_area == "" and not needs_more_unique_areas:
			break

		var replacement: Resource = _find_generation_layout_replacement_candidate(
			candidate_definitions,
			balanced,
			area_counts,
			overrepresented_area,
			desired_unique_areas,
			area_cap,
			focus_tags,
			required_tags
		)
		if replacement == null:
			break

		var removal_index: int = _find_generation_layout_removal_index(
			balanced,
			protected_ids,
			area_counts,
			overrepresented_area,
			replacement,
			focus_tags,
			required_tags
		)
		if removal_index < 0:
			break

		balanced.remove_at(removal_index)
		balanced.append(replacement)
	return balanced


func _definition_selection_has_tag(definitions: Array[Resource], tag: StringName) -> bool:
	for definition: Resource in definitions:
		if _get_interaction_definition_content_tags(definition).has(tag):
			return true
	return false


func _definition_selection_has_route_node(definitions: Array[Resource], route_node_id: StringName) -> bool:
	if route_node_id == &"":
		return false
	for definition: Resource in definitions:
		if definition != null and definition.get("route_node_id") == route_node_id:
			return true
	return false


func _definition_selection_has_id(definitions: Array[Resource], interaction_id: String) -> bool:
	if interaction_id == "":
		return false
	for definition: Resource in definitions:
		if definition != null and String(definition.get("id")) == interaction_id:
			return true
	return false


func _find_best_generation_candidate_with_tag(
	candidates: Array[Resource],
	required_tag: StringName,
	focus_tags: Array[StringName],
	required_tags: Array[StringName]
) -> Resource:
	var best_candidate: Resource = null
	for candidate: Resource in candidates:
		if candidate == null or not _get_interaction_definition_content_tags(candidate).has(required_tag):
			continue
		if best_candidate == null or _is_generation_candidate_better(candidate, best_candidate, focus_tags, required_tags):
			best_candidate = candidate
	return best_candidate


func _find_best_generation_candidate_with_route_node(
	candidates: Array[Resource],
	route_node_id: StringName,
	focus_tags: Array[StringName],
	required_tags: Array[StringName]
) -> Resource:
	var best_candidate: Resource = null
	for candidate: Resource in candidates:
		if candidate == null or candidate.get("route_node_id") != route_node_id:
			continue
		if best_candidate == null or _is_generation_candidate_better(candidate, best_candidate, focus_tags, required_tags):
			best_candidate = candidate
	return best_candidate


func _find_best_generation_candidate(candidates: Array[Resource], focus_tags: Array[StringName], required_tags: Array[StringName]) -> Resource:
	var best_candidate: Resource = null
	for candidate: Resource in candidates:
		if candidate == null:
			continue
		if best_candidate == null or _is_generation_candidate_better(candidate, best_candidate, focus_tags, required_tags):
			best_candidate = candidate
	return best_candidate


func _find_generation_selection_removal_index(
	definitions: Array[Resource],
	protected_ids: Dictionary,
	focus_tags: Array[StringName],
	required_tags: Array[StringName]
) -> int:
	var worst_index: int = -1
	for index: int in range(definitions.size()):
		var definition: Resource = definitions[index]
		if definition == null:
			continue
		if protected_ids.has(String(definition.get("id"))):
			continue
		if worst_index < 0 or _is_generation_candidate_better(definitions[worst_index], definition, focus_tags, required_tags):
			worst_index = index
	return worst_index


func _find_generation_layout_replacement_candidate(
	candidates: Array[Resource],
	selected: Array[Resource],
	area_counts: Dictionary,
	overrepresented_area: String,
	desired_unique_areas: int,
	area_cap: int,
	focus_tags: Array[StringName],
	required_tags: Array[StringName]
) -> Resource:
	var best_candidate: Resource = null
	var needs_unique_area: bool = area_counts.size() < desired_unique_areas
	for candidate: Resource in candidates:
		if candidate == null or _definition_selection_has_id(selected, String(candidate.get("id"))):
			continue
		var area_id: String = _get_generation_layout_area_id(candidate)
		if needs_unique_area and area_counts.has(area_id):
			continue
		if overrepresented_area != "" and area_id == overrepresented_area:
			continue
		if overrepresented_area != "" and int(area_counts.get(area_id, 0)) >= area_cap:
			continue
		if best_candidate == null or _is_generation_layout_replacement_better(
			candidate,
			best_candidate,
			area_counts,
			desired_unique_areas,
			area_cap,
			focus_tags,
			required_tags
		):
			best_candidate = candidate
	return best_candidate


func _find_generation_layout_removal_index(
	selected: Array[Resource],
	protected_ids: Dictionary,
	area_counts: Dictionary,
	overrepresented_area: String,
	replacement: Resource,
	focus_tags: Array[StringName],
	required_tags: Array[StringName]
) -> int:
	var worst_index: int = -1
	var replacement_area: String = _get_generation_layout_area_id(replacement)
	for index: int in range(selected.size()):
		var definition: Resource = selected[index]
		if definition == null:
			continue
		if protected_ids.has(String(definition.get("id"))):
			continue
		var area_id: String = _get_generation_layout_area_id(definition)
		if overrepresented_area != "" and area_id != overrepresented_area:
			continue
		if overrepresented_area == "" and int(area_counts.get(area_id, 0)) <= 1:
			continue
		if area_id == replacement_area and int(area_counts.get(area_id, 0)) <= 1:
			continue
		if not _does_generation_replacement_preserve_tags(selected, index, replacement, required_tags):
			continue
		if not _does_generation_replacement_preserve_tags(selected, index, replacement, focus_tags):
			continue
		if worst_index < 0 or _is_generation_candidate_better(selected[worst_index], definition, focus_tags, required_tags):
			worst_index = index
	return worst_index


func _is_generation_layout_replacement_better(
	left: Resource,
	right: Resource,
	area_counts: Dictionary,
	desired_unique_areas: int,
	area_cap: int,
	focus_tags: Array[StringName],
	required_tags: Array[StringName]
) -> bool:
	var left_score: int = _score_generation_candidate(left, focus_tags, required_tags)
	left_score += _score_generation_layout_candidate(left, area_counts, desired_unique_areas, area_cap)
	var right_score: int = _score_generation_candidate(right, focus_tags, required_tags)
	right_score += _score_generation_layout_candidate(right, area_counts, desired_unique_areas, area_cap)
	if left_score != right_score:
		return left_score > right_score
	return _is_generation_candidate_better(left, right, focus_tags, required_tags)


func _score_generation_layout_candidate(
	definition: Resource,
	area_counts: Dictionary,
	desired_unique_areas: int,
	area_cap: int
) -> int:
	var area_id: String = _get_generation_layout_area_id(definition)
	var current_count: int = int(area_counts.get(area_id, 0))
	var score: int = 0
	if not area_counts.has(area_id) and area_counts.size() < desired_unique_areas:
		score += 90
	score += max(0, area_cap - current_count) * 18
	if current_count == 0:
		score += 24
	return score


func _does_generation_replacement_preserve_tags(
	selected: Array[Resource],
	removal_index: int,
	replacement: Resource,
	coverage_tags: Array[StringName]
) -> bool:
	if removal_index < 0 or removal_index >= selected.size():
		return false
	if coverage_tags.is_empty():
		return true
	var counts: Dictionary = _get_content_tag_counts_for_definitions(selected)
	var removal_tags: Array[StringName] = _get_interaction_definition_content_tags(selected[removal_index])
	var replacement_tags: Array[StringName] = _get_interaction_definition_content_tags(replacement)
	for tag: StringName in coverage_tags:
		var original_count: int = int(counts.get(tag, 0))
		if original_count <= 0:
			continue
		var next_count: int = original_count
		if removal_tags.has(tag):
			next_count -= 1
		if replacement_tags.has(tag):
			next_count += 1
		if next_count <= 0:
			return false
	return true


func _is_generation_candidate_better(left: Resource, right: Resource, focus_tags: Array[StringName], required_tags: Array[StringName]) -> bool:
	var left_score: int = _score_generation_candidate(left, focus_tags, required_tags)
	var right_score: int = _score_generation_candidate(right, focus_tags, required_tags)
	if left_score != right_score:
		return left_score > right_score
	var left_tie_breaker: int = _get_generation_candidate_tie_breaker(left)
	var right_tie_breaker: int = _get_generation_candidate_tie_breaker(right)
	if left_tie_breaker != right_tie_breaker:
		return left_tie_breaker < right_tie_breaker
	return String(left.get("id")) < String(right.get("id"))


func _score_generation_candidate(definition: Resource, focus_tags: Array[StringName], required_tags: Array[StringName]) -> int:
	var score: int = 0
	var tags: Array[StringName] = _get_interaction_definition_content_tags(definition)
	for tag: StringName in required_tags:
		if tags.has(tag):
			score += 100
	for tag: StringName in focus_tags:
		if tags.has(tag):
			score += 40
	score += _score_generation_theme_candidate(tags)
	score += _score_safehouse_prep_candidate(tags)
	score += _score_safehouse_carry_item_candidate(tags)
	match definition.get("interaction_kind"):
		&"boss":
			score += 18
		&"event":
			score += 12
		&"resource":
			score += 8
		_:
			score += 4
	return score


func _score_safehouse_prep_candidate(tags: Array[StringName]) -> int:
	var prep_tags: Array[StringName] = _get_safehouse_prep_effect_tags()
	if prep_tags.is_empty():
		return 0
	var score: int = 0
	for tag: StringName in prep_tags:
		if tags.has(tag):
			score += SAFEHOUSE_PREP_TAG_SCORE
	return score


func _score_safehouse_carry_item_candidate(tags: Array[StringName]) -> int:
	var carry_tags: Array[StringName] = _get_safehouse_carry_item_tags()
	if carry_tags.is_empty():
		return 0
	var score: int = 0
	for tag: StringName in carry_tags:
		if tags.has(tag):
			score += SAFEHOUSE_CARRY_TAG_SCORE
	return score


func _score_generation_theme_candidate(tags: Array[StringName]) -> int:
	var theme_tags: Array[StringName] = _get_stage_generation_theme_tags()
	if theme_tags.is_empty():
		return 0
	var score: int = 0
	for tag: StringName in theme_tags:
		if tags.has(tag):
			score += CAMPUS_GENERATION_THEME_TAG_SCORE
	if score > 0:
		score += CAMPUS_GENERATION_THEME_MATCH_BONUS
	return score


func _count_generation_theme_matches(definitions: Array[Resource], theme_tags: Array[StringName]) -> int:
	if theme_tags.is_empty():
		return 0
	var count: int = 0
	for definition: Resource in definitions:
		if definition == null:
			continue
		if _definition_has_any_content_tag(definition, theme_tags):
			count += 1
	return count


func _definition_has_any_content_tag(definition: Resource, tags: Array[StringName]) -> bool:
	var definition_tags: Array[StringName] = _get_interaction_definition_content_tags(definition)
	for tag: StringName in tags:
		if definition_tags.has(tag):
			return true
	return false


func _get_generation_candidate_tie_breaker(definition: Resource) -> int:
	var id_text: String = String(definition.get("id"))
	return abs(("%d:%s:%s" % [_get_stage_seed(), String(campus_stage), id_text]).hash())


func _get_generation_layout_area_cap(target_count: int) -> int:
	return max(2, ceili(float(max(1, target_count)) / 3.0))


func _get_generation_layout_area_id(definition: Resource) -> String:
	if definition == null:
		return ""
	return _get_campus_area_hint(definition.get("position"))


func _get_generation_layout_area_counts(definitions: Array[Resource]) -> Dictionary:
	var counts: Dictionary = {}
	for definition: Resource in definitions:
		if definition == null:
			continue
		var area_id: String = _get_generation_layout_area_id(definition)
		counts[area_id] = int(counts.get(area_id, 0)) + 1
	return counts


func _get_generation_layout_overrepresented_area(area_counts: Dictionary, area_cap: int) -> String:
	var worst_area: String = ""
	var worst_count: int = area_cap
	for raw_area: Variant in area_counts.keys():
		var area_id: String = String(raw_area)
		var count: int = int(area_counts.get(area_id, 0))
		if count > worst_count:
			worst_area = area_id
			worst_count = count
		elif count == worst_count and worst_area != "" and area_id < worst_area:
			worst_area = area_id
	return worst_area


func _format_generation_layout_area_counts(area_counts: Dictionary) -> String:
	if area_counts.is_empty():
		return "无"
	var area_order: Array[String] = ["宿舍", "图书馆", "实验楼", "校园中庭", "食堂", "导师办公室", "会议室"]
	var parts: Array[String] = []
	for area_id: String in area_order:
		var count: int = int(area_counts.get(area_id, 0))
		if count > 0:
			parts.append("%s%d" % [area_id, count])
	return "、".join(parts)


func _format_generation_layout_max_area(area_counts: Dictionary) -> String:
	if area_counts.is_empty():
		return "无"
	var worst_area: String = ""
	var worst_count: int = 0
	for raw_area: Variant in area_counts.keys():
		var area_id: String = String(raw_area)
		var count: int = int(area_counts.get(area_id, 0))
		if count > worst_count:
			worst_area = area_id
			worst_count = count
		elif count == worst_count and worst_area != "" and area_id < worst_area:
			worst_area = area_id
	return "%s%d" % [worst_area, worst_count]


func _get_generation_layout_resource_count(definitions: Array[Resource]) -> int:
	var count: int = 0
	for definition: Resource in definitions:
		if definition != null and definition.get("interaction_kind") == &"resource":
			count += 1
	return count


func _get_generation_layout_average_route_distance(definitions: Array[Resource]) -> int:
	var route_positions: Array[Vector2] = []
	for definition: Resource in definitions:
		if definition != null and _get_story_guidance_route_order().has(StringName(definition.get("route_node_id"))):
			route_positions.append(definition.get("position"))
	if route_positions.is_empty():
		return 0

	var total_distance: float = 0.0
	var measured_count: int = 0
	for definition: Resource in definitions:
		if definition == null:
			continue
		var position: Vector2 = definition.get("position")
		var best_distance: float = INF
		for route_position: Vector2 in route_positions:
			best_distance = minf(best_distance, position.distance_to(route_position))
		if best_distance < INF:
			total_distance += best_distance
			measured_count += 1
	if measured_count <= 0:
		return 0
	return int(round(total_distance / float(measured_count)))


func _normalize_content_tags(raw_tags: Variant) -> Array[StringName]:
	var tags: Array[StringName] = []
	if raw_tags == null:
		return tags
	if raw_tags is Array:
		for raw_tag: Variant in raw_tags:
			_append_unique_content_tag(tags, StringName(str(raw_tag)))
	else:
		_append_unique_content_tag(tags, StringName(str(raw_tags)))
	return tags


func _infer_content_tags(interactable: CampusInteractable) -> Array[StringName]:
	return _infer_content_tags_from_fields(
		interactable.interaction_kind,
		interactable.route_node_id,
		interactable.resource_id
	)


func _infer_content_tags_from_fields(interaction_kind: StringName, route_node_id: StringName, resource_id: StringName) -> Array[StringName]:
	var tags: Array[StringName] = []
	match interaction_kind:
		SAFEHOUSE_INTERACTION_KIND:
			_append_unique_content_tag(tags, &"safehouse")
			_append_unique_content_tag(tags, &"dormitory")
			_append_unique_content_tag(tags, &"self_care")
		&"resource":
			_append_unique_content_tag(tags, &"resource")
			_append_unique_content_tag(tags, &"supply")
		&"boss":
			_append_unique_content_tag(tags, &"boss")
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"exam")
		&"event":
			_append_unique_content_tag(tags, &"event")
			_append_unique_content_tag(tags, &"campus_notice")
		_:
			_append_unique_content_tag(tags, &"encounter")
			_append_unique_content_tag(tags, &"academic_exchange")

	match resource_id:
		&"inspiration":
			_append_unique_content_tag(tags, &"inspiration")
			_append_unique_content_tag(tags, &"self_care")
		&"data":
			_append_unique_content_tag(tags, &"data")
			_append_unique_content_tag(tags, &"lab")
		&"draft":
			_append_unique_content_tag(tags, &"draft")
			_append_unique_content_tag(tags, &"writing")
		&"funds":
			_append_unique_content_tag(tags, &"funds")
			_append_unique_content_tag(tags, &"administration")
		&"reputation":
			_append_unique_content_tag(tags, &"reputation")
			_append_unique_content_tag(tags, &"social")
		&"experience_lessons":
			_append_unique_content_tag(tags, &"experience_lessons")
			_append_unique_content_tag(tags, &"reflection")
		&"methodology_notes":
			_append_unique_content_tag(tags, &"methodology_notes")
			_append_unique_content_tag(tags, &"method")
		&"paper_fragments":
			_append_unique_content_tag(tags, &"paper_fragments")
			_append_unique_content_tag(tags, &"writing")

	var route_text: String = String(route_node_id)
	if route_text.begins_with("B"):
		_append_unique_content_tag(tags, &"story")
		_append_unique_content_tag(tags, &"exam")
	elif route_text.begins_with("E"):
		_append_unique_content_tag(tags, &"event")
	elif route_text.begins_with("N"):
		_append_unique_content_tag(tags, &"encounter")
	_append_route_content_tags(tags, route_node_id)
	return tags


func _append_route_content_tags(tags: Array[StringName], route_node_id: StringName) -> void:
	match route_node_id:
		&"N001":
			_append_unique_content_tag(tags, &"reading")
			_append_unique_content_tag(tags, &"peer")
		&"N002":
			_append_unique_content_tag(tags, &"peer")
			_append_unique_content_tag(tags, &"library")
			_append_unique_content_tag(tags, &"writing")
		&"N003":
			_append_unique_content_tag(tags, &"lab")
			_append_unique_content_tag(tags, &"equipment")
		&"N004":
			_append_unique_content_tag(tags, &"writing")
			_append_unique_content_tag(tags, &"draft")
		&"N005":
			_append_unique_content_tag(tags, &"project")
			_append_unique_content_tag(tags, &"method")
			_append_unique_content_tag(tags, &"writing")
		&"N006":
			_append_unique_content_tag(tags, &"project")
			_append_unique_content_tag(tags, &"collaboration")
			_append_unique_content_tag(tags, &"meeting")
		&"N007":
			_append_unique_content_tag(tags, &"defense")
			_append_unique_content_tag(tags, &"committee")
		&"N008":
			_append_unique_content_tag(tags, &"revision")
			_append_unique_content_tag(tags, &"writing")
			_append_unique_content_tag(tags, &"self_care")
		&"N009":
			_append_unique_content_tag(tags, &"data")
			_append_unique_content_tag(tags, &"lab")
			_append_unique_content_tag(tags, &"equipment")
		&"E001":
			_append_unique_content_tag(tags, &"canteen")
			_append_unique_content_tag(tags, &"self_care")
			_append_unique_content_tag(tags, &"social")
		&"E003":
			_append_unique_content_tag(tags, &"equipment")
			_append_unique_content_tag(tags, &"lab")
		&"E005":
			_append_unique_content_tag(tags, &"advisor")
			_append_unique_content_tag(tags, &"administration")
			_append_unique_content_tag(tags, &"exam")
		&"E006":
			_append_unique_content_tag(tags, &"funds")
			_append_unique_content_tag(tags, &"project")
			_append_unique_content_tag(tags, &"administration")
		&"E007":
			_append_unique_content_tag(tags, &"revision")
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"defense")
		&"E008":
			_append_unique_content_tag(tags, &"advisor")
			_append_unique_content_tag(tags, &"meeting")
		&"B001":
			_append_unique_content_tag(tags, &"advisor")
			_append_unique_content_tag(tags, &"committee")
		&"B002":
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"data")
			_append_unique_content_tag(tags, &"writing")
		&"B003":
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"writing")
			_append_unique_content_tag(tags, &"paper_fragments")
		&"B004":
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"method")
		&"B005":
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"project")
		&"B006":
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"defense")
		&"B007":
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"defense")
		&"B008":
			_append_unique_content_tag(tags, &"committee")
			_append_unique_content_tag(tags, &"defense")
			_append_unique_content_tag(tags, &"revision")


func _append_unique_content_tag(tags: Array[StringName], tag: StringName) -> void:
	if tag == &"" or tags.has(tag):
		return
	tags.append(tag)


func _format_content_tags(tags: Array[StringName], max_tags: int = 4) -> String:
	if tags.is_empty() or max_tags <= 0:
		return ""
	var parts: Array[String] = []
	var seen_display_names: Dictionary = {}
	var limit: int = min(tags.size(), max_tags)
	for index: int in range(limit):
		var display_name: String = _get_content_tag_display_name(tags[index])
		if seen_display_names.has(display_name):
			continue
		seen_display_names[display_name] = true
		parts.append(display_name)
	return " / ".join(parts)


func _get_content_tag_display_name(tag: StringName) -> String:
	match tag:
		&"academic_exchange":
			return "学术交流"
		&"administration":
			return "行政"
		&"advisor":
			return "导师"
		&"boss":
			return "Boss"
		&"campus_notice":
			return "公告"
		&"canteen":
			return "食堂"
		&"collaboration":
			return "合作"
		&"committee":
			return "委员会"
		&"data":
			return "数据"
		&"defense":
			return "答辩"
		&"direction":
			return "方向"
		&"draft":
			return "草稿"
		&"dormitory":
			return "宿舍"
		&"encounter":
			return "学术交流"
		&"equipment":
			return "设备"
		&"event":
			return "事件"
		&"exam":
			return "考核"
		&"experience_lessons":
			return "经验"
		&"funds":
			return "经费"
		&"inspiration":
			return "灵感"
		&"lab":
			return "实验室"
		&"library":
			return "图书馆"
		&"meeting":
			return "会议"
		&"method":
			return "方法"
		&"methodology_notes":
			return "方法笔记"
		&"paper_fragments":
			return "论文碎片"
		&"peer":
			return "同门"
		&"project":
			return "项目"
		&"reading":
			return "阅读"
		&"reflection":
			return "复盘"
		&"reputation":
			return "声望"
		&"resource":
			return "补给"
		&"recovery":
			return "恢复"
		&"revision":
			return "返修"
		&"safehouse":
			return "住屋"
		&"self_care":
			return "照护"
		&"seminar":
			return "沙龙"
		&"social":
			return "社交"
		&"story":
			return "主线"
		&"supply":
			return "补给"
		&"writing":
			return "写作"
		_:
			return String(tag)


func _refresh_guidance_direction_indicator() -> void:
	if guidance_direction_indicator == null:
		return
	if mode != MODE_OVERWORLD or hud_root == null or not hud_root.visible or player == null:
		_hide_guidance_direction_indicator()
		return

	var target: CampusInteractable = _get_story_guidance_target()
	if target == null:
		_hide_guidance_direction_indicator()
		return

	var target_direction: Vector2 = player.global_position.direction_to(target.global_position)
	var target_distance: float = player.global_position.distance_to(target.global_position)
	if target_distance < GUIDANCE_INDICATOR_HIDE_DISTANCE or target_direction.length_squared() <= 0.001:
		_hide_guidance_direction_indicator()
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		_hide_guidance_direction_indicator()
		return

	var discovery_active: bool = _is_guidance_indicator_discovery_active()
	var target_screen_position: Vector2 = _get_guidance_target_screen_position(target)
	var comfort_size: Vector2 = Vector2(
		maxf(1.0, viewport_size.x - GUIDANCE_INDICATOR_COMFORT_MARGIN.x * 2.0),
		maxf(1.0, viewport_size.y - GUIDANCE_INDICATOR_COMFORT_MARGIN.y * 2.0)
	)
	var comfort_rect: Rect2 = Rect2(
		GUIDANCE_INDICATOR_COMFORT_MARGIN,
		comfort_size
	)
	if comfort_rect.has_point(target_screen_position) and not discovery_active:
		_hide_guidance_direction_indicator()
		return

	var indicator_position: Vector2 = _get_guidance_indicator_edge_position(viewport_size, target_direction)
	guidance_direction_indicator.position = indicator_position - guidance_direction_indicator.size * 0.5
	_guidance_indicator_target_interaction_id = target.interaction_id
	guidance_direction_indicator.call("configure", true, target_direction, target.is_summary_guidance_target(), discovery_active)


func _hide_guidance_direction_indicator() -> void:
	_guidance_indicator_target_interaction_id = &""
	if guidance_direction_indicator != null and guidance_direction_indicator.has_method("configure"):
		guidance_direction_indicator.call("configure", false, Vector2.RIGHT, false, false)


func _start_guidance_indicator_discovery() -> void:
	_guidance_indicator_discovery_time = GUIDANCE_INDICATOR_DISCOVERY_DURATION
	_refresh_guidance_direction_indicator()


func _stop_guidance_indicator_discovery() -> void:
	_guidance_indicator_discovery_time = 0.0


func _is_guidance_indicator_discovery_active() -> bool:
	return _guidance_indicator_discovery_time > 0.0


func _get_guidance_target_screen_position(target: CampusInteractable) -> Vector2:
	if target != null and target.is_inside_tree():
		return target.get_global_transform_with_canvas().origin
	if player == null:
		return get_viewport_rect().size * 0.5
	return get_viewport_rect().size * 0.5 + (target.global_position - player.global_position)


func _get_guidance_indicator_edge_position(viewport_size: Vector2, direction: Vector2) -> Vector2:
	var normalized_direction: Vector2 = direction.normalized()
	var center: Vector2 = viewport_size * 0.5
	var safe_rect: Rect2 = _get_guidance_direction_indicator_center_safe_rect(viewport_size)
	var min_position: Vector2 = safe_rect.position
	var max_position: Vector2 = safe_rect.position + safe_rect.size
	var best_distance: float = INF
	if not is_zero_approx(normalized_direction.x):
		var x_edge: float = max_position.x if normalized_direction.x > 0.0 else min_position.x
		var x_distance: float = (x_edge - center.x) / normalized_direction.x
		if x_distance > 0.0:
			best_distance = minf(best_distance, x_distance)
	if not is_zero_approx(normalized_direction.y):
		var y_edge: float = max_position.y if normalized_direction.y > 0.0 else min_position.y
		var y_distance: float = (y_edge - center.y) / normalized_direction.y
		if y_distance > 0.0:
			best_distance = minf(best_distance, y_distance)
	if is_inf(best_distance):
		return center
	var edge_position: Vector2 = center + normalized_direction * best_distance
	return Vector2(
		clampf(edge_position.x, min_position.x, max_position.x),
		clampf(edge_position.y, min_position.y, max_position.y)
	)


func _get_guidance_direction_indicator_center_safe_rect(viewport_size: Vector2) -> Rect2:
	var min_position: Vector2 = Vector2(GUIDANCE_INDICATOR_LEFT_INSET, GUIDANCE_INDICATOR_TOP_CLEARANCE)
	var max_position: Vector2 = Vector2(
		maxf(min_position.x + 1.0, viewport_size.x - GUIDANCE_INDICATOR_RIGHT_INSET),
		maxf(min_position.y + 1.0, viewport_size.y - GUIDANCE_INDICATOR_BOTTOM_INSET)
	)
	return Rect2(min_position, max_position - min_position)


func _refresh_stage_debug_buttons() -> void:
	for raw_stage: Variant in stage_debug_buttons.keys():
		var stage: StringName = StringName(raw_stage)
		var button: Button = stage_debug_buttons.get(stage, null)
		if button == null:
			continue
		button.disabled = stage == campus_stage
		button.modulate = Color(0.70, 0.95, 0.82, 0.86) if button.disabled else Color(0.82, 0.86, 0.84, 0.64)
	_refresh_generation_candidate_toggle()
	_refresh_generation_audit_panel()
	_refresh_marker_profile_legend()


func _refresh_generation_candidate_toggle() -> void:
	if generation_candidate_toggle == null:
		return
	generation_candidate_toggle.set_pressed_no_signal(generation_candidate_map_enabled)
	generation_candidate_toggle.disabled = mode != MODE_OVERWORLD
	generation_candidate_toggle.modulate = Color(0.76, 0.92, 0.98, 0.92) if generation_candidate_map_enabled else Color(0.82, 0.86, 0.84, 0.68)
	generation_candidate_toggle.tooltip_text = "调试开关：用候选池选择器实际生成当前校园点位\n%s\n%s" % [
		get_stage_spawn_source_summary(),
		"主题：%s\n%s" % [get_stage_generation_theme_choice_summary(), get_stage_spawn_layout_summary()],
	]
	if reroll_seed_button != null:
		reroll_seed_button.disabled = mode != MODE_OVERWORLD
		reroll_seed_button.modulate = Color(0.90, 0.88, 0.72, 0.92) if mode == MODE_OVERWORLD else Color(0.64, 0.66, 0.62, 0.54)
		reroll_seed_button.tooltip_text = "调试：生成新 Seed 并重刷当前校园\n当前 Seed %d\n主题：%s\n%s\n%s" % [
			campus_seed,
			get_stage_generation_theme_choice_summary(),
			get_stage_spawn_source_summary(),
			get_stage_spawn_layout_summary(),
		]
	if return_safehouse_button != null:
		return_safehouse_button.disabled = mode != MODE_OVERWORLD
		return_safehouse_button.modulate = Color(0.88, 0.82, 0.58, 0.94) if mode == MODE_OVERWORLD else Color(0.62, 0.62, 0.56, 0.54)
		return_safehouse_button.tooltip_text = "调试兜底：正常流程请靠近宿舍旁的住屋入口"
	_refresh_generation_theme_choice_buttons()


func _refresh_generation_theme_choice_buttons() -> void:
	if generation_theme_choice_buttons.is_empty():
		return
	var choices: Array[StringName] = _get_stage_generation_theme_choice_ids()
	var active_theme_id: StringName = _get_active_generation_theme_id()
	for index: int in range(generation_theme_choice_buttons.size()):
		var button: Button = generation_theme_choice_buttons[index]
		if button == null:
			continue
		if index >= choices.size():
			button.visible = false
			continue
		var theme_id: StringName = choices[index]
		button.visible = true
		button.text = _get_generation_theme_display_name(theme_id)
		button.disabled = mode != MODE_OVERWORLD
		button.set_pressed_no_signal(theme_id == active_theme_id)
		button.modulate = Color(0.92, 0.86, 0.58, 0.96) if theme_id == active_theme_id else Color(0.72, 0.78, 0.76, 0.82)
		button.tooltip_text = "选择%s\n标签：%s\n%s" % [
			_get_generation_theme_display_name(theme_id),
			_format_content_tags(_get_generation_theme_tags(theme_id), 99),
			"当前生效" if theme_id == active_theme_id else "点击后按该主题重刷候选池地图",
		]


func _refresh_safehouse_panel() -> void:
	if safehouse_layer == null or safehouse_root == null:
		return
	var is_safehouse_mode: bool = mode == MODE_SAFEHOUSE
	safehouse_layer.visible = is_safehouse_mode
	safehouse_root.visible = is_safehouse_mode

	if safehouse_day_label != null:
		safehouse_day_label.text = "第 %d 天 · %s · Seed %d" % [safehouse_day, _get_stage_label(campus_stage), campus_seed]
	if safehouse_resource_label != null:
		safehouse_resource_label.text = _format_campus_resources()
	if safehouse_theme_label != null:
		safehouse_theme_label.text = "出门主题：%s" % get_stage_generation_theme_choice_summary()
	if safehouse_carry_label != null:
		safehouse_carry_label.text = "携带物：%d/%d · %s" % [
			safehouse_selected_carry_item_ids.size(),
			SAFEHOUSE_CARRY_SLOT_COUNT,
			_format_safehouse_carry_item_summary(),
		]
	if safehouse_attribute_label != null:
		safehouse_attribute_label.text = _format_safehouse_attribute_summary()
	if safehouse_prep_label != null:
		safehouse_prep_label.text = "准备行动：%d/%d" % [safehouse_prep_action_points, SAFEHOUSE_PREP_ACTION_POINTS_PER_DAY]
	if safehouse_effect_label != null:
		safehouse_effect_label.text = "本次带出：%s" % _format_safehouse_prep_effect_summary()

	var choices: Array[StringName] = _get_stage_generation_theme_choice_ids()
	var active_theme_id: StringName = _get_active_generation_theme_id()
	for index: int in range(safehouse_theme_choice_buttons.size()):
		var button: Button = safehouse_theme_choice_buttons[index]
		if button == null:
			continue
		if index >= choices.size():
			button.visible = false
			continue
		var theme_id: StringName = choices[index]
		var is_selected_theme: bool = generation_selected_theme_id != &"" and theme_id == active_theme_id
		button.visible = true
		button.disabled = not is_safehouse_mode
		button.text = _get_generation_theme_display_name(theme_id)
		button.set_pressed_no_signal(is_selected_theme)
		button.modulate = Color(0.96, 0.86, 0.56, 0.98) if is_selected_theme else Color(0.78, 0.86, 0.84, 0.88)
		button.tooltip_text = "%s\n标签：%s" % [
			_get_generation_theme_display_name(theme_id),
			_format_content_tags(_get_generation_theme_tags(theme_id), 99),
		]

	var carry_items: Array[Dictionary] = _get_safehouse_carry_item_definitions()
	for index: int in range(safehouse_carry_item_buttons.size()):
		var carry_button: Button = safehouse_carry_item_buttons[index]
		if carry_button == null:
			continue
		if index >= carry_items.size():
			carry_button.visible = false
			continue
		var item_def: Dictionary = carry_items[index]
		var item_id: StringName = StringName(item_def.get("id", &""))
		var selected: bool = safehouse_selected_carry_item_ids.has(item_id)
		var slot_full: bool = safehouse_selected_carry_item_ids.size() >= SAFEHOUSE_CARRY_SLOT_COUNT
		carry_button.visible = true
		carry_button.text = _format_safehouse_carry_item_button_text(item_def)
		carry_button.disabled = not is_safehouse_mode or (slot_full and not selected)
		carry_button.set_pressed_no_signal(selected)
		carry_button.modulate = Color(0.72, 0.92, 0.74, 0.98) if selected else Color(0.78, 0.84, 0.82, 0.86)
		carry_button.tooltip_text = _format_safehouse_carry_item_tooltip(item_def)

	var prep_actions: Array[Dictionary] = _get_safehouse_prep_action_definitions()
	for index: int in range(safehouse_prep_action_buttons.size()):
		var prep_button: Button = safehouse_prep_action_buttons[index]
		if prep_button == null:
			continue
		if index >= prep_actions.size():
			prep_button.visible = false
			continue
		var action_def: Dictionary = prep_actions[index]
		var action_id: StringName = StringName(action_def.get("id", &""))
		var completed: bool = safehouse_completed_prep_action_ids.has(action_id)
		prep_button.visible = true
		prep_button.text = _format_safehouse_prep_action_button_text(action_def)
		prep_button.disabled = not is_safehouse_mode or safehouse_prep_action_points <= 0 or completed
		prep_button.modulate = Color(0.70, 0.92, 0.74, 0.96) if completed else Color(0.82, 0.86, 0.84, 0.88)
		prep_button.tooltip_text = _format_safehouse_prep_action_tooltip(action_def)

	if safehouse_depart_button != null:
		safehouse_depart_button.disabled = not is_safehouse_mode
		safehouse_depart_button.tooltip_text = "按当前主题生成校园地图\n准备：%s\n携带：%s" % [_format_safehouse_prep_effect_summary(), _format_safehouse_carry_item_summary()]
	if safehouse_next_day_button != null:
		safehouse_next_day_button.disabled = not is_safehouse_mode
		safehouse_next_day_button.tooltip_text = "跳到下一天，重随 Seed 并刷新主题三选一"


func _refresh_generation_audit_panel() -> void:
	if generation_audit_label == null:
		return
	generation_audit_label.text = get_stage_spawn_audit_panel_text()
	generation_audit_label.add_theme_color_override(
		"font_color",
		Color(0.70, 0.88, 0.86) if generation_candidate_map_enabled else HUD_MUTED_TEXT_COLOR
	)


func _refresh_marker_profile_legend() -> void:
	if marker_profile_legend_label == null:
		return
	marker_profile_legend_label.text = get_marker_visual_profile_legend_text()
	marker_profile_legend_label.add_theme_color_override(
		"font_color",
		Color(0.78, 0.76, 0.62) if generation_candidate_map_enabled else Color(0.60, 0.62, 0.56)
	)


func _get_mode_label() -> String:
	if mode == MODE_SAFEHOUSE:
		return "住屋"
	if mode == MODE_BATTLE:
		return "学术交流"
	return "探索"


func _format_focused_interaction_prompt() -> String:
	if focused_interactable == null:
		return "校园中庭"
	if focused_interactable is CampusInteractable and focused_interactable.interaction_kind == SAFEHOUSE_INTERACTION_KIND:
		return "%s｜安全返回住屋" % focused_interactable.display_name
	var prompt_text: String = focused_interactable.get_interaction_summary()
	if focused_interactable is CampusInteractable:
		var role_tag: String = _format_interactable_focus_role_tag(focused_interactable as CampusInteractable)
		if role_tag != "":
			prompt_text = "%s｜%s" % [role_tag, prompt_text]
	if focused_interactable.interaction_id == _pending_condition_override_interaction_id:
		return "%s｜再次确认进入" % prompt_text
	if focused_interactable is CampusInteractable and focused_interactable.requirement_summary != "":
		var intercept_mode: StringName = _get_interactable_requirement_intercept_mode(focused_interactable as CampusInteractable)
		if intercept_mode == REQUIREMENT_INTERCEPT_HARD_GATE:
			return "%s｜材料不足，无法进入" % prompt_text
		if intercept_mode == REQUIREMENT_INTERCEPT_WARN_ONLY:
			return "%s｜仅提示" % prompt_text
	return prompt_text


func _format_interactable_focus_role_tag(interactable: CampusInteractable) -> String:
	if interactable == null:
		return ""
	var tags: Array[String] = []
	if interactable.is_guidance_target():
		tags.append(FOCUS_TAG_STORY)
	if interactable.is_supply_hint_target():
		tags.append(FOCUS_TAG_SUPPLY)
	return " / ".join(tags)


func _normalize_campus_stage(stage: StringName) -> StringName:
	_ensure_campus_data_loaded()
	if campus_stage_definitions.has(stage):
		return stage
	return CAMPUS_STAGE_MASTER1


func _get_stage_label(stage: StringName) -> String:
	var stage_def: Resource = _get_campus_stage_definition(stage)
	if stage_def != null and str(stage_def.get("display_name")) != "":
		return str(stage_def.get("display_name"))
	return "研一"


func _format_campus_resources() -> String:
	if campus_resources.is_empty():
		return "随身资源：暂无"
	var parts: Array[String] = []
	var keys: Array[String] = []
	for raw_key: Variant in campus_resources.keys():
		keys.append(String(raw_key))
	keys.sort()
	for raw_key: String in keys:
		var resource_id: StringName = StringName(raw_key)
		parts.append("%s %d" % [_get_resource_display_name(resource_id), int(campus_resources.get(resource_id, 0))])
	return "随身资源：" + "、".join(parts)


func _format_story_guidance_text() -> String:
	var target: CampusInteractable = _get_story_guidance_target()
	if target == null:
		return "下一步：自由探索，收集资源或检查阶段按钮。"

	var area_hint: String = _get_campus_area_hint(target.position)
	var route_text: String = ""
	if target.route_node_id != &"":
		route_text = " · %s" % String(target.route_node_id)

	var requirement_text: String = ""
	if target.requirement_summary != "":
		var advice_text: String = _format_requirement_supply_advice_for_interactable(target)
		if advice_text != "":
			requirement_text = "（准备不足：%s；%s）" % [target.requirement_summary, advice_text]
		else:
			requirement_text = "（准备不足：%s）" % target.requirement_summary

	return "下一步：%s方向 · %s%s%s" % [area_hint, target.display_name, route_text, requirement_text]


func _get_campus_area_hint(world_position: Vector2) -> String:
	if world_position.y < 460.0:
		if world_position.x < 430.0:
			return "宿舍"
		if world_position.x < 930.0:
			return "图书馆"
		return "实验楼"
	if world_position.y > 590.0:
		if world_position.x < 520.0:
			return "食堂"
		if world_position.x < 1030.0:
			return "导师办公室"
		return "会议室"
	return "校园中庭"


func _format_recent_log() -> String:
	if interaction_log.is_empty():
		return "今日记录：刚到校园。"
	var start_index: int = max(0, interaction_log.size() - 2)
	return "今日记录：" + " / ".join(interaction_log.slice(start_index, interaction_log.size()))


func _append_log(text: String) -> void:
	interaction_log.append(text)
	if interaction_log.size() > 6:
		interaction_log.remove_at(0)


func _get_resource_display_name(resource_id: StringName) -> String:
	match resource_id:
		&"inspiration":
			return "灵感"
		&"data":
			return "数据"
		&"draft":
			return "草稿"
		&"funds":
			return "经费"
		&"reputation":
			return "声望"
		&"experience_lessons":
			return "经验教训"
		&"methodology_notes":
			return "方法论笔记"
		&"paper_fragments":
			return "论文碎片"
		_:
			return String(resource_id)


func _clear_battle_layer() -> void:
	if battle_layer == null:
		return
	for child: Node in battle_layer.get_children():
		battle_layer.remove_child(child)
		child.queue_free()
	battle_instance = null


func _clear_container_children(container: Node) -> void:
	if container == null:
		return
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
