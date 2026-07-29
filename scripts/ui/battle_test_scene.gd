@tool
extends Control
class_name BattleTestScene

const GAME_DATA_CATALOG := preload("res://scripts/data/game_data_catalog.gd")
const BATTLE_STATE := preload("res://scripts/battle/battle_state.gd")
const ROUTE_STATE := preload("res://scripts/run/route_state.gd")
const RUN_SETTLEMENT := preload("res://scripts/run/run_settlement.gd")
const META_PROGRESSION := preload("res://scripts/run/meta_progression_state.gd")
const SELF_CARE_UNLOCK_ID := &"self_care_seed"
const SELF_CARE_CARD_ID := &"U001"
const REVISION_STRATEGY_UNLOCK_ID := &"revision_strategy_seed"
const REVISION_STRATEGY_CARD_ID := &"U002"
const REVISION_MATRIX_UNLOCK_ID := &"revision_matrix_seed"
const REVISION_MATRIX_CARD_ID := &"U003"
const BOSS_REWARD_DIRECTION := &"boss_direction"
const BOSS_REWARD_FEEDBACK := &"boss_feedback"
const BOSS_REWARD_REMOVE_STATUS := &"boss_remove_status"
const B002_REWARD_ARCHIVE_MATERIALS := &"b002_archive_materials"
const B002_REWARD_REPLICATION_PROTOCOL := &"b002_replication_protocol"
const B002_REWARD_CLEANUP_NOISE := &"b002_cleanup_noise"
const B004_REWARD_PROBLEM_CHAIN := &"b004_problem_chain"
const B004_REWARD_COMMITTEE_BRIDGE := &"b004_committee_bridge"
const B004_REWARD_REMOVE_QUALIFICATION_NOISE := &"b004_remove_qualification_noise"
const B005_REWARD_PROJECT_LEDGER := &"b005_project_ledger"
const B005_REWARD_TIMELINE_PROTOCOL := &"b005_timeline_protocol"
const B005_REWARD_REMOVE_PROJECT_NOISE := &"b005_remove_project_noise"
const B006_REWARD_DEFENSE_NARRATIVE := &"b006_defense_narrative"
const B006_REWARD_REHEARSAL_ROUTINE := &"b006_rehearsal_routine"
const B006_REWARD_REMOVE_DEFENSE_NOISE := &"b006_remove_defense_noise"
const B008_REWARD_SUPPLEMENTARY_PASS := &"b008_supplementary_pass"
const B008_REWARD_REVISION_ARCHIVE := &"b008_revision_archive"
const B008_REWARD_REHEARSAL_LEGACY := &"b008_rehearsal_legacy"
const B003_ENDING_OUTSTANDING := &"b003_outstanding_graduation"
const B003_ENDING_STANDARD := &"b003_standard_graduation"
const B003_ENDING_NARROW := &"b003_narrow_graduation"
const B007_ENDING_OUTSTANDING := &"b007_outstanding_doctoral_graduation"
const B007_ENDING_STANDARD := &"b007_doctoral_graduation"
const B007_ENDING_DELAYED := &"b007_delayed_doctoral_graduation"
const PREBATTLE_EFFECT_CHIP_MAX_WIDTH := 248.0
const PREBATTLE_EFFECT_CHIP_TEXT_WIDTH := 204.0
const PREBATTLE_EFFECT_CHIP_MIN_HEIGHT := 30.0
const PREBATTLE_EFFECT_SFX_MIX_RATE := 22050
const PREBATTLE_EFFECT_SFX_DURATION := 0.14
const PREBATTLE_EFFECT_SFX_ATTACK := 0.018
const PREBATTLE_EFFECT_SFX_AMPLITUDE := 0.18
const TRACKED_EVENT_RESOURCE_IDS := [
	&"inspiration",
	&"data",
	&"draft",
	&"funds",
	&"reputation",
	&"experience_lessons",
	&"methodology_notes",
	&"paper_fragments",
]
const DOCTORAL_REWARD_POOLS := {
	&"N005": [&"C031", &"C032", &"C033"],
	&"N006": [&"C027", &"C036", &"C034"],
	&"N007": [&"C031", &"C033", &"C035"],
	&"N008": [&"C037", &"C033", &"C035"],
}
const MAX_CARD_REWARD_OPTIONS := 3
const REWARD_RNG_MODULUS := 2147483647
const ENCOUNTER_SEED_OFFSET := 1009
const BOSS_SEED_OFFSET := 2003
const TRANSFER_REQUIREMENT_REPUTATION: int = 2
const TRANSFER_REQUIREMENT_DRAFT: int = 4

var cards: Dictionary = {}
var decks: Dictionary = {}
var encounters: Dictionary = {}
var events: Dictionary = {}
var bosses: Dictionary = {}
var route_node_hints: Dictionary = {}
var battle: Variant = null
var route: Variant = null
var meta_progression: Variant = null
var settlement: Dictionary = {}
var settlement_save: Dictionary = {}
var log_lines: Array[String] = []

var status_label: Label
var meta_preview_label: Label
var route_map_label: Label
var enemy_label: Label
var prebattle_effect_label: Label
var prebattle_effect_chip_container: HFlowContainer
var prebattle_effect_feedback_label: Label
var prebattle_effect_audio_player: AudioStreamPlayer
var pile_label: Label
var reward_label: Label
var reward_container: HBoxContainer
var boss_reward_panel: PanelContainer
var boss_reward_title_label: Label
var boss_reward_description_label: Label
var boss_reward_container: HBoxContainer
var event_label: Label
var event_choice_container: HBoxContainer
var route_choice_label: Label
var route_choice_container: HBoxContainer
var route_detail_panel: PanelContainer
var route_detail_title_label: Label
var route_detail_meta_label: Label
var route_detail_description_label: Label
var route_detail_preview_label: Label
var route_detail_row_container: VBoxContainer
var settlement_panel: PanelContainer
var settlement_title_label: Label
var settlement_description_label: Label
var settlement_stats_label: Label
var settlement_resources_title_label: Label
var settlement_resources_list: VBoxContainer
var settlement_resources_label: Label
var settlement_unlock_title_label: Label
var settlement_unlock_list: VBoxContainer
var settlement_unlock_label: Label
var settlement_carryover_title_label: Label
var settlement_carryover_list: VBoxContainer
var settlement_carryover_label: Label
var settlement_label: Label
var hand_container: HBoxContainer
var log_box: TextEdit
var end_turn_button: Button
var next_node_button: Button
var clear_test_save_button: Button
var seed_input: LineEdit
var copy_seed_button: Button
var restart_seed_button: Button
var reward_options: Array[StringName] = []
var reward_taken: bool = false
var node_index: int = 1
var run_seed: int = 1
var meta_save_path: String = META_PROGRESSION.SAVE_PATH
var carried_unlock_cards: Array[StringName] = []
var last_clear_save_result: Dictionary = {}
var active_event: Variant = null
var event_choice_taken: bool = false
var active_event_choice_id: StringName = &""
var last_event_result_text: String = ""
var last_boss_reward_result_text: String = ""
var next_node_options: Array[StringName] = []
var route_detail_active_node_id: StringName = &""
var active_campus_prebattle_effects: Array[Dictionary] = []
var _prebattle_effect_feedback_queue: Array[Dictionary] = []
var _prebattle_effect_feedback_tween: Tween
var _prebattle_effect_sfx_play_count: int = 0
var _last_prebattle_effect_sfx_id: StringName = &""
var _last_prebattle_effect_sfx_frequency: float = 0.0
var _last_prebattle_effect_sfx_frame_count: int = 0
var _ui_built: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	initialize_battle_ui()


func initialize_battle_ui() -> void:
	if _ui_built:
		return
	_build_ui()
	_ui_built = true
	var vision_run: Node = get_node_or_null("/root/VisionRun")
	if vision_run != null and bool(vision_run.get("has_active_run")):
		start_new_battle_with_seed(int(vision_run.get("run_seed")))
	else:
		start_new_battle()


func start_new_battle() -> void:
	_start_new_battle_with_seed(_generate_run_seed())


func start_new_battle_with_seed(seed: int) -> void:
	_start_new_battle_with_seed(seed)


func get_run_seed() -> int:
	return run_seed


func _generate_run_seed() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, REWARD_RNG_MODULUS - 1)


func _get_encounter_battle_seed() -> int:
	return _mix_reward_seed(run_seed, ENCOUNTER_SEED_OFFSET + max(1, node_index))


func _get_boss_battle_seed() -> int:
	return _mix_reward_seed(run_seed, BOSS_SEED_OFFSET + max(1, node_index))


func _build_vision_inclination_deck(base_deck: Resource) -> Resource:
	var vision_run: Node = get_node_or_null("/root/VisionRun")
	if vision_run == null or not bool(vision_run.get("has_active_run")):
		return base_deck

	var inclination_id := StringName(vision_run.get("inclination_id"))
	var definition_path := ""
	match inclination_id:
		&"literature":
			definition_path = "res://data/inclinations/literature.tres"
		&"experiment":
			definition_path = "res://data/inclinations/experiment.tres"
		&"sprint":
			definition_path = "res://data/inclinations/sprint.tres"
		_:
			push_error("BattleTestScene: unknown inclination '%s'." % inclination_id)
			return base_deck

	var inclination: Resource = load(definition_path)
	if inclination == null or not inclination.is_valid_definition():
		push_error("BattleTestScene: invalid inclination resource '%s'." % definition_path)
		return base_deck

	var tailored_deck: Resource = base_deck.duplicate(true)
	var tailored_ids := PackedStringArray(tailored_deck.card_ids)
	for card_id: String in inclination.remove_card_ids:
		var remove_index := tailored_ids.find(card_id)
		if remove_index < 0:
			push_error("BattleTestScene: starter deck cannot remove '%s'." % card_id)
			return base_deck
		tailored_ids.remove_at(remove_index)
	for card_id: String in inclination.add_card_ids:
		if not cards.has(StringName(card_id)):
			push_error("BattleTestScene: inclination card '%s' is missing." % card_id)
			return base_deck
		tailored_ids.append(card_id)

	tailored_deck.card_ids = tailored_ids
	return tailored_deck


func _start_new_battle_with_seed(seed: int) -> void:
	if not _ui_built:
		_build_ui()
		_ui_built = true

	run_seed = max(1, seed)
	cards = GAME_DATA_CATALOG.load_cards_by_id()
	decks = GAME_DATA_CATALOG.load_decks_by_id()
	encounters = GAME_DATA_CATALOG.load_encounters_by_id()
	events = GAME_DATA_CATALOG.load_events_by_id()
	bosses = GAME_DATA_CATALOG.load_bosses_by_id()
	route_node_hints = GAME_DATA_CATALOG.load_route_node_hints_by_id()
	meta_progression = META_PROGRESSION.new()
	meta_progression.load_from_disk(meta_save_path)
	var deck: Variant = decks.get(&"D001")
	if deck == null:
		_append_log("缺少 D001 初始牌组。")
		_refresh_ui()
		return
	deck = _build_vision_inclination_deck(deck)

	route = ROUTE_STATE.new()
	var planned_nodes: Array[StringName] = []
	route.setup(encounters, run_seed, planned_nodes, events, bosses)
	var encounter: Variant = route.get_current_encounter(encounters)
	if encounter == null:
		_append_log("缺少可用的路线节点。")
		_refresh_ui()
		return

	battle = BATTLE_STATE.new()
	node_index = int(route.get_current_node_number())
	battle.setup(cards, deck, _get_encounter_battle_seed())
	carried_unlock_cards.clear()
	var added_unlock_names: Array[String] = []
	var vision_run: Node = get_node_or_null("/root/VisionRun")
	if vision_run == null or not bool(vision_run.get("has_active_run")):
		added_unlock_names = _apply_meta_unlocks_to_starting_deck()
	battle.set_encounter(encounter)
	battle.start_battle()
	reward_options.clear()
	reward_taken = false
	active_event = null
	event_choice_taken = false
	active_event_choice_id = &""
	last_event_result_text = ""
	last_boss_reward_result_text = ""
	next_node_options.clear()
	active_campus_prebattle_effects.clear()
	_clear_prebattle_effect_feedback()
	settlement.clear()
	settlement_save.clear()
	log_lines.clear()
	_append_log("新的研究生旅程开始：Seed %d，节点 %d/%d，%s。" % [run_seed, node_index, route.get_total_nodes(), encounter.display_name])
	if not added_unlock_names.is_empty():
		_append_log("局外解锁加入初始牌组：%s。" % "、".join(added_unlock_names))
	_refresh_ui()


func get_hand_button_count() -> int:
	if hand_container == null:
		return 0
	return hand_container.get_child_count()


func get_reward_button_count() -> int:
	var count: int = 0
	if reward_container == null:
		return count
	count += reward_container.get_child_count()
	if boss_reward_container != null:
		count += boss_reward_container.get_child_count()
	return count


func was_reward_taken() -> bool:
	return reward_taken


func get_boss_reward_panel_visible() -> bool:
	return boss_reward_panel != null and boss_reward_panel.visible


func get_boss_reward_title_text() -> String:
	if boss_reward_title_label == null:
		return ""
	return boss_reward_title_label.text


func get_boss_reward_description_text() -> String:
	if boss_reward_description_label == null:
		return ""
	return boss_reward_description_label.text


func get_event_button_count() -> int:
	if event_choice_container == null:
		return 0
	return event_choice_container.get_child_count()


func get_route_choice_button_count() -> int:
	if route_choice_container == null:
		return 0
	return route_choice_container.get_child_count()


func get_active_event_id() -> String:
	if active_event == null:
		return ""
	return String(active_event.id)


func was_event_choice_taken() -> bool:
	return event_choice_taken


func get_active_event_choice_id() -> String:
	return String(active_event_choice_id)


func get_last_event_result_text() -> String:
	return last_event_result_text


func get_last_boss_reward_result_text() -> String:
	return last_boss_reward_result_text


func get_prebattle_effect_text() -> String:
	return _format_prebattle_effect_text()


func get_prebattle_effect_feedback_text() -> String:
	if prebattle_effect_feedback_label == null:
		return ""
	return prebattle_effect_feedback_label.text


func is_prebattle_effect_feedback_visible() -> bool:
	return prebattle_effect_feedback_label != null and prebattle_effect_feedback_label.visible


func get_prebattle_effect_chip_count() -> int:
	if prebattle_effect_chip_container == null:
		return 0
	return prebattle_effect_chip_container.get_child_count()


func get_prebattle_effect_chip_layout_summary() -> String:
	if prebattle_effect_chip_container == null:
		return ""
	var widths: Array[String] = []
	for child: Node in prebattle_effect_chip_container.get_children():
		if child is Control:
			var chip: Control = child as Control
			widths.append(str(int(chip.custom_minimum_size.x)))
	return "container=%s,count=%d,widths=%s" % [
		prebattle_effect_chip_container.get_class(),
		prebattle_effect_chip_container.get_child_count(),
		",".join(widths),
	]


func get_prebattle_effect_sfx_summary() -> String:
	var stream_class: String = ""
	if prebattle_effect_audio_player != null and prebattle_effect_audio_player.stream != null:
		stream_class = prebattle_effect_audio_player.stream.get_class()
	return "player=%s,count=%d,last=%s,freq=%d,frames=%d,stream=%s" % [
		str(prebattle_effect_audio_player != null),
		_prebattle_effect_sfx_play_count,
		String(_last_prebattle_effect_sfx_id),
		int(_last_prebattle_effect_sfx_frequency),
		_last_prebattle_effect_sfx_frame_count,
		stream_class,
	]


func get_prebattle_effect_sfx_play_count() -> int:
	return _prebattle_effect_sfx_play_count


func get_prebattle_effect_feedback_queue_count() -> int:
	return _prebattle_effect_feedback_queue.size()


func get_next_node_available() -> bool:
	return get_route_choice_button_count() > 0 or (next_node_button != null and next_node_button.visible and not next_node_button.disabled)


func get_next_node_option_ids() -> Array[String]:
	var output: Array[String] = []
	for node_id: StringName in next_node_options:
		output.append(String(node_id))
	return output


func select_first_next_node_option() -> bool:
	if next_node_options.is_empty():
		_prepare_next_node_options()
	if next_node_options.is_empty():
		return false
	return _select_next_node_option(next_node_options[0])


func select_next_node_option(node_id: StringName) -> bool:
	return _select_next_node_option(node_id)


func get_route_choice_text() -> String:
	if route_choice_label == null:
		return ""
	return route_choice_label.text


func get_route_detail_visible() -> bool:
	return route_detail_panel != null and route_detail_panel.visible


func get_route_detail_text() -> String:
	if route_detail_panel == null:
		return ""
	var parts: Array[String] = []
	if route_detail_title_label != null and route_detail_title_label.text != "":
		parts.append(route_detail_title_label.text)
	if route_detail_meta_label != null and route_detail_meta_label.text != "":
		parts.append(route_detail_meta_label.text)
	if route_detail_description_label != null and route_detail_description_label.text != "":
		parts.append(route_detail_description_label.text)
	if route_detail_preview_label != null and route_detail_preview_label.text != "":
		parts.append(route_detail_preview_label.text)
	if route_detail_row_container != null:
		parts.append_array(_collect_route_detail_row_texts())
	return "\n".join(parts)


func get_settlement_visible() -> bool:
	return settlement_panel != null and settlement_panel.visible


func get_settlement_summary() -> String:
	return String(settlement.get("summary_text", ""))


func get_settlement_outcome_id() -> String:
	return String(settlement.get("outcome_id", ""))


func get_settlement_resource(resource_id: String) -> int:
	var resources: Dictionary = settlement.get("resources", {})
	return int(resources.get(resource_id, 0))


func get_settlement_title_text() -> String:
	if settlement_title_label == null:
		return ""
	return settlement_title_label.text


func get_settlement_resource_text() -> String:
	if settlement_resources_label == null:
		return ""
	return settlement_resources_label.text


func get_settlement_unlock_text() -> String:
	if settlement_unlock_label == null:
		return ""
	return settlement_unlock_label.text


func get_settlement_carryover_text() -> String:
	if settlement_carryover_label == null:
		return ""
	return settlement_carryover_label.text


func get_settlement_save_error() -> int:
	return int(settlement_save.get("save_error", -1))


func get_meta_runs_completed() -> int:
	if meta_progression == null:
		return 0
	return int(meta_progression.runs_completed)


func get_meta_resource(resource_id: String) -> int:
	if meta_progression == null:
		return 0
	return meta_progression.get_resource(resource_id)


func get_meta_unlocks() -> Array[String]:
	if meta_progression == null:
		var empty: Array[String] = []
		return empty
	return meta_progression.to_unlock_strings()


func get_meta_preview_text() -> String:
	if meta_preview_label == null:
		return ""
	return meta_preview_label.text


func get_route_map_text() -> String:
	if route_map_label == null:
		return ""
	return route_map_label.text


func get_carried_unlock_card_ids() -> Array[String]:
	var output: Array[String] = []
	for card_id: StringName in carried_unlock_cards:
		output.append(String(card_id))
	return output


func get_last_clear_save_error() -> int:
	return int(last_clear_save_result.get("clear_error", -1))


func was_last_clear_save_successful() -> bool:
	return bool(last_clear_save_result.get("cleared", false))


func has_card_in_deck(card_id: StringName) -> bool:
	return battle != null and battle.deck_card_ids.has(card_id)


func get_route_node_ids() -> Array[String]:
	if route == null:
		var empty: Array[String] = []
		return empty
	return route.to_id_strings()


func play_first_available_card() -> bool:
	if battle == null:
		return false

	for index in range(battle.hand.size()):
		var card_id: StringName = battle.hand[index]
		var card: Variant = cards.get(card_id)
		if card != null and card.cost >= 0 and battle.action_points >= card.cost:
			return _play_card_at(index)
	return false


func select_first_reward() -> bool:
	if reward_options.is_empty():
		return false
	for reward_id: StringName in reward_options:
		if battle != null and battle.is_boss_encounter and not _is_boss_reward_available(reward_id):
			continue
		return _select_reward(reward_id)
	return false


func select_first_event_choice() -> bool:
	if active_event == null:
		return false

	for choice: EventChoiceDefinition in active_event.choices:
		if _is_event_choice_available(choice):
			return _select_event_choice(choice.id)
	return false


func select_event_choice(choice_id: StringName) -> bool:
	return _select_event_choice(choice_id)


func apply_campus_prebattle_effect(effect_id: StringName, amount: int, source_label: String, summary: String) -> bool:
	if battle == null:
		return false
	var applied: bool = battle.apply_prebattle_modifier(effect_id, amount, source_label)
	if not applied:
		return false
	var detail_text: String = summary if summary != "" else "已调整开局状态"
	active_campus_prebattle_effects.append({
		"effect_id": effect_id,
		"amount": amount,
		"source_label": source_label,
		"summary": detail_text,
	})
	_append_log("携带物开局：%s。%s。" % [source_label, detail_text])
	_refresh_ui()
	_enqueue_prebattle_effect_feedback(effect_id, source_label, detail_text)
	return true


func end_current_turn() -> void:
	if battle == null:
		return

	battle.end_turn()
	if battle.is_victory():
		_append_log("节点已通过，请先选择奖励。")
		_refresh_ui()
		return

	var enemy_result: Dictionary = battle.resolve_enemy_turn()
	_append_log("承受 %d 点压力。" % int(enemy_result.get("pressure", 0)))
	if battle.vitality <= 0:
		_handle_vitality_depleted()
		_refresh_ui()
		return

	battle.start_turn()
	_append_log("进入第 %d 回合。" % battle.turn)
	_refresh_ui()


func start_next_node() -> bool:
	if battle == null or route == null or not _is_current_route_node_completed() or not settlement.is_empty():
		return false

	if next_node_options.is_empty():
		_prepare_next_node_options()
	if next_node_options.is_empty():
		_append_log("当前测试路线已完成。")
		_refresh_ui()
		return false

	return _select_next_node_option(next_node_options[0])


func _advance_from_event_node() -> bool:
	if route == null or not event_choice_taken or not settlement.is_empty():
		return false

	if not route.has_next_node():
		_append_log("当前测试路线已完成。")
		_refresh_ui()
		return false

	var advanced: bool = route.advance_to_next_node()
	if not advanced:
		_append_log("当前测试路线已完成。")
		_refresh_ui()
		return false

	return _enter_current_route_node()


func _enter_current_route_node() -> bool:
	if route == null:
		return false

	node_index = int(route.get_current_node_number())
	if route.is_current_event_node():
		active_event = route.get_current_event(events)
		event_choice_taken = false
		active_event_choice_id = &""
		last_event_result_text = ""
		last_boss_reward_result_text = ""
		reward_options.clear()
		reward_taken = false
		if active_event == null:
			_append_log("路线事件节点缺少对应事件数据。")
			_refresh_ui()
			return false
		_append_log("进入事件节点 %d/%d：%s。" % [node_index, route.get_total_nodes(), active_event.display_name])
		_refresh_ui()
		return true

	if route.is_current_boss_node():
		var boss: Variant = route.get_current_boss(bosses)
		if boss == null:
			_append_log("路线 Boss 节点缺少对应 Boss 数据。")
			_refresh_ui()
			return false

		active_event = null
		event_choice_taken = false
		active_event_choice_id = &""
		last_event_result_text = ""
		last_boss_reward_result_text = ""
		battle.start_next_boss(boss, _get_boss_battle_seed(), true)
		reward_options.clear()
		reward_taken = false
		_append_log("进入 Boss 节点 %d/%d：%s。" % [node_index, route.get_total_nodes(), boss.display_name])
		_refresh_ui()
		return true

	var encounter: Variant = route.get_current_encounter(encounters)
	if encounter == null:
		_append_log("路线节点缺少对应遭遇数据。")
		_refresh_ui()
		return false

	active_event = null
	event_choice_taken = false
	active_event_choice_id = &""
	last_event_result_text = ""
	last_boss_reward_result_text = ""
	battle.start_next_encounter(encounter, _get_encounter_battle_seed(), true)
	reward_options.clear()
	reward_taken = false
	_append_log("进入节点 %d/%d：%s。" % [node_index, route.get_total_nodes(), encounter.display_name])
	_refresh_ui()
	return true


func _apply_meta_unlocks_to_starting_deck() -> Array[String]:
	var added_names: Array[String] = []
	_try_add_meta_unlock_card(SELF_CARE_UNLOCK_ID, SELF_CARE_CARD_ID, added_names)
	_try_add_meta_unlock_card(REVISION_STRATEGY_UNLOCK_ID, REVISION_STRATEGY_CARD_ID, added_names)
	_try_add_meta_unlock_card(REVISION_MATRIX_UNLOCK_ID, REVISION_MATRIX_CARD_ID, added_names)
	return added_names


func _try_add_meta_unlock_card(unlock_id: StringName, card_id: StringName, added_names: Array[String]) -> void:
	if meta_progression == null or battle == null:
		return
	if not meta_progression.has_unlock(unlock_id):
		return

	var added: bool = battle.add_card_to_starting_deck(card_id)
	if added:
		carried_unlock_cards.append(card_id)
		var card: Variant = cards.get(card_id)
		if card == null:
			added_names.append(String(card_id))
		else:
			added_names.append(card.display_name)


func _build_ui() -> void:
	prebattle_effect_audio_player = AudioStreamPlayer.new()
	prebattle_effect_audio_player.name = "PrebattleEffectAudioPlayer"
	prebattle_effect_audio_player.bus = _get_available_audio_bus("SFX")
	prebattle_effect_audio_player.volume_db = -15.0
	add_child(prebattle_effect_audio_player)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = "博三之前 - 战斗测试"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	meta_preview_label = Label.new()
	meta_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(meta_preview_label)

	route_map_label = Label.new()
	route_map_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(route_map_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)

	enemy_label = Label.new()
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(enemy_label)

	prebattle_effect_label = Label.new()
	prebattle_effect_label.visible = false
	prebattle_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prebattle_effect_label.add_theme_color_override("font_color", Color(0.66, 0.92, 0.78))
	prebattle_effect_label.add_theme_font_size_override("font_size", 13)
	root.add_child(prebattle_effect_label)

	prebattle_effect_chip_container = HFlowContainer.new()
	prebattle_effect_chip_container.visible = false
	prebattle_effect_chip_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prebattle_effect_chip_container.add_theme_constant_override("h_separation", 6)
	prebattle_effect_chip_container.add_theme_constant_override("v_separation", 5)
	root.add_child(prebattle_effect_chip_container)

	pile_label = Label.new()
	pile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(pile_label)

	reward_label = Label.new()
	reward_label.text = ""
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(reward_label)

	reward_container = HBoxContainer.new()
	reward_container.add_theme_constant_override("separation", 8)
	root.add_child(reward_container)

	boss_reward_panel = PanelContainer.new()
	boss_reward_panel.visible = false
	boss_reward_panel.add_theme_stylebox_override("panel", _create_boss_reward_panel_style())
	root.add_child(boss_reward_panel)

	var boss_reward_margin: MarginContainer = MarginContainer.new()
	boss_reward_margin.add_theme_constant_override("margin_left", 12)
	boss_reward_margin.add_theme_constant_override("margin_top", 10)
	boss_reward_margin.add_theme_constant_override("margin_right", 12)
	boss_reward_margin.add_theme_constant_override("margin_bottom", 10)
	boss_reward_panel.add_child(boss_reward_margin)

	var boss_reward_stack: VBoxContainer = VBoxContainer.new()
	boss_reward_stack.add_theme_constant_override("separation", 8)
	boss_reward_margin.add_child(boss_reward_stack)

	boss_reward_title_label = Label.new()
	boss_reward_title_label.add_theme_font_size_override("font_size", 19)
	boss_reward_title_label.add_theme_color_override("font_color", Color(0.96, 0.78, 0.42))
	boss_reward_stack.add_child(boss_reward_title_label)

	boss_reward_description_label = Label.new()
	boss_reward_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_reward_description_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.90))
	boss_reward_stack.add_child(boss_reward_description_label)

	boss_reward_container = HBoxContainer.new()
	boss_reward_container.add_theme_constant_override("separation", 8)
	boss_reward_stack.add_child(boss_reward_container)

	event_label = Label.new()
	event_label.text = ""
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(event_label)

	event_choice_container = HBoxContainer.new()
	event_choice_container.add_theme_constant_override("separation", 8)
	root.add_child(event_choice_container)

	route_choice_label = Label.new()
	route_choice_label.text = ""
	route_choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(route_choice_label)

	route_choice_container = HBoxContainer.new()
	route_choice_container.add_theme_constant_override("separation", 8)
	root.add_child(route_choice_container)

	route_detail_panel = PanelContainer.new()
	route_detail_panel.visible = false
	root.add_child(route_detail_panel)

	var route_detail_margin: MarginContainer = MarginContainer.new()
	route_detail_margin.add_theme_constant_override("margin_left", 12)
	route_detail_margin.add_theme_constant_override("margin_top", 10)
	route_detail_margin.add_theme_constant_override("margin_right", 12)
	route_detail_margin.add_theme_constant_override("margin_bottom", 10)
	route_detail_panel.add_child(route_detail_margin)

	var route_detail_stack: VBoxContainer = VBoxContainer.new()
	route_detail_stack.add_theme_constant_override("separation", 5)
	route_detail_margin.add_child(route_detail_stack)

	route_detail_title_label = Label.new()
	route_detail_title_label.add_theme_font_size_override("font_size", 17)
	route_detail_stack.add_child(route_detail_title_label)

	route_detail_meta_label = Label.new()
	route_detail_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_detail_meta_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.90))
	route_detail_stack.add_child(route_detail_meta_label)

	route_detail_description_label = Label.new()
	route_detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_detail_description_label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.92))
	route_detail_stack.add_child(route_detail_description_label)

	route_detail_preview_label = Label.new()
	route_detail_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_detail_preview_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.78))
	route_detail_stack.add_child(route_detail_preview_label)

	route_detail_row_container = VBoxContainer.new()
	route_detail_row_container.add_theme_constant_override("separation", 4)
	route_detail_stack.add_child(route_detail_row_container)

	settlement_panel = PanelContainer.new()
	settlement_panel.visible = false
	root.add_child(settlement_panel)

	var settlement_margin: MarginContainer = MarginContainer.new()
	settlement_margin.add_theme_constant_override("margin_left", 12)
	settlement_margin.add_theme_constant_override("margin_top", 10)
	settlement_margin.add_theme_constant_override("margin_right", 12)
	settlement_margin.add_theme_constant_override("margin_bottom", 10)
	settlement_panel.add_child(settlement_margin)

	var settlement_stack: VBoxContainer = VBoxContainer.new()
	settlement_stack.add_theme_constant_override("separation", 6)
	settlement_margin.add_child(settlement_stack)

	settlement_title_label = Label.new()
	settlement_title_label.add_theme_font_size_override("font_size", 20)
	settlement_stack.add_child(settlement_title_label)

	settlement_description_label = Label.new()
	settlement_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settlement_stack.add_child(settlement_description_label)

	settlement_stats_label = Label.new()
	settlement_stats_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.87))
	settlement_stack.add_child(settlement_stats_label)

	settlement_resources_title_label = Label.new()
	settlement_resources_title_label.text = "资源变化"
	settlement_resources_title_label.add_theme_font_size_override("font_size", 13)
	settlement_resources_title_label.add_theme_color_override("font_color", Color(0.62, 0.70, 0.78))
	settlement_stack.add_child(settlement_resources_title_label)

	settlement_resources_label = Label.new()
	settlement_resources_label.visible = false
	settlement_resources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settlement_resources_label.add_theme_font_size_override("font_size", 15)
	settlement_stack.add_child(settlement_resources_label)

	settlement_resources_list = VBoxContainer.new()
	settlement_resources_list.add_theme_constant_override("separation", 4)
	settlement_stack.add_child(settlement_resources_list)

	settlement_unlock_title_label = Label.new()
	settlement_unlock_title_label.visible = false
	settlement_unlock_title_label.text = "新解锁"
	settlement_unlock_title_label.add_theme_font_size_override("font_size", 13)
	settlement_unlock_title_label.add_theme_color_override("font_color", Color(0.80, 0.68, 0.36))
	settlement_stack.add_child(settlement_unlock_title_label)

	settlement_unlock_label = Label.new()
	settlement_unlock_label.visible = false
	settlement_unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settlement_unlock_label.add_theme_font_size_override("font_size", 17)
	settlement_unlock_label.add_theme_color_override("font_color", Color(1.00, 0.84, 0.42))
	settlement_stack.add_child(settlement_unlock_label)

	settlement_unlock_list = VBoxContainer.new()
	settlement_unlock_list.visible = false
	settlement_unlock_list.add_theme_constant_override("separation", 4)
	settlement_stack.add_child(settlement_unlock_list)

	settlement_carryover_title_label = Label.new()
	settlement_carryover_title_label.visible = false
	settlement_carryover_title_label.text = "下局带入"
	settlement_carryover_title_label.add_theme_font_size_override("font_size", 13)
	settlement_carryover_title_label.add_theme_color_override("font_color", Color(0.56, 0.76, 0.68))
	settlement_stack.add_child(settlement_carryover_title_label)

	settlement_carryover_label = Label.new()
	settlement_carryover_label.visible = false
	settlement_carryover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settlement_carryover_label.add_theme_font_size_override("font_size", 16)
	settlement_carryover_label.add_theme_color_override("font_color", Color(0.66, 0.92, 0.80))
	settlement_stack.add_child(settlement_carryover_label)

	settlement_carryover_list = VBoxContainer.new()
	settlement_carryover_list.visible = false
	settlement_carryover_list.add_theme_constant_override("separation", 4)
	settlement_stack.add_child(settlement_carryover_list)

	settlement_label = Label.new()
	settlement_label.visible = false
	settlement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settlement_label.add_theme_color_override("font_color", Color(0.70, 0.74, 0.80))
	settlement_stack.add_child(settlement_label)

	var control_row: HBoxContainer = HBoxContainer.new()
	control_row.add_theme_constant_override("separation", 8)
	root.add_child(control_row)

	end_turn_button = Button.new()
	end_turn_button.text = "结束回合"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	control_row.add_child(end_turn_button)

	next_node_button = Button.new()
	next_node_button.text = "下一节点"
	next_node_button.disabled = true
	next_node_button.visible = false
	next_node_button.pressed.connect(_on_next_node_pressed)
	control_row.add_child(next_node_button)

	clear_test_save_button = Button.new()
	clear_test_save_button.text = "清空测试存档"
	clear_test_save_button.pressed.connect(_on_clear_test_save_pressed)
	control_row.add_child(clear_test_save_button)

	var restart_button: Button = Button.new()
	restart_button.text = "重开测试"
	restart_button.pressed.connect(_on_restart_pressed)
	control_row.add_child(restart_button)

	seed_input = LineEdit.new()
	seed_input.custom_minimum_size = Vector2(130, 0)
	seed_input.placeholder_text = "Seed"
	seed_input.tooltip_text = "输入 Seed 后可复现同一局"
	control_row.add_child(seed_input)

	copy_seed_button = Button.new()
	copy_seed_button.text = "复制 Seed"
	copy_seed_button.pressed.connect(_on_copy_seed_pressed)
	control_row.add_child(copy_seed_button)

	restart_seed_button = Button.new()
	restart_seed_button.text = "按 Seed 重开"
	restart_seed_button.pressed.connect(_on_restart_with_seed_pressed)
	control_row.add_child(restart_seed_button)

	var content: VSplitContainer = VSplitContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	var hand_panel: PanelContainer = PanelContainer.new()
	hand_panel.custom_minimum_size = Vector2(0, 190)
	content.add_child(hand_panel)

	var hand_margin: MarginContainer = MarginContainer.new()
	hand_margin.add_theme_constant_override("margin_left", 8)
	hand_margin.add_theme_constant_override("margin_top", 8)
	hand_margin.add_theme_constant_override("margin_right", 8)
	hand_margin.add_theme_constant_override("margin_bottom", 8)
	hand_panel.add_child(hand_margin)

	hand_container = HBoxContainer.new()
	hand_container.add_theme_constant_override("separation", 8)
	hand_margin.add_child(hand_container)

	log_box = TextEdit.new()
	log_box.editable = false
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(log_box)

	_build_prebattle_effect_feedback()


func _build_prebattle_effect_feedback() -> void:
	prebattle_effect_feedback_label = Label.new()
	prebattle_effect_feedback_label.name = "PrebattleEffectFeedback"
	prebattle_effect_feedback_label.anchor_left = 0.5
	prebattle_effect_feedback_label.anchor_right = 0.5
	prebattle_effect_feedback_label.anchor_top = 0.0
	prebattle_effect_feedback_label.anchor_bottom = 0.0
	prebattle_effect_feedback_label.offset_left = -280.0
	prebattle_effect_feedback_label.offset_right = 280.0
	prebattle_effect_feedback_label.offset_top = 86.0
	prebattle_effect_feedback_label.offset_bottom = 136.0
	prebattle_effect_feedback_label.visible = false
	prebattle_effect_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prebattle_effect_feedback_label.z_index = 20
	prebattle_effect_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prebattle_effect_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prebattle_effect_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prebattle_effect_feedback_label.add_theme_color_override("font_color", Color(0.72, 1.00, 0.78))
	prebattle_effect_feedback_label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.06, 0.92))
	prebattle_effect_feedback_label.add_theme_constant_override("outline_size", 3)
	prebattle_effect_feedback_label.add_theme_font_size_override("font_size", 15)
	add_child(prebattle_effect_feedback_label)


func _refresh_ui() -> void:
	if status_label == null or meta_preview_label == null or route_map_label == null or enemy_label == null or prebattle_effect_label == null or prebattle_effect_chip_container == null or pile_label == null or reward_label == null or reward_container == null or boss_reward_panel == null or boss_reward_title_label == null or boss_reward_description_label == null or boss_reward_container == null or event_label == null or event_choice_container == null or route_choice_label == null or route_choice_container == null or route_detail_panel == null or route_detail_title_label == null or route_detail_meta_label == null or route_detail_description_label == null or route_detail_preview_label == null or route_detail_row_container == null or settlement_panel == null or settlement_title_label == null or settlement_description_label == null or settlement_stats_label == null or settlement_resources_title_label == null or settlement_resources_list == null or settlement_resources_label == null or settlement_unlock_title_label == null or settlement_unlock_list == null or settlement_unlock_label == null or settlement_carryover_title_label == null or settlement_carryover_list == null or settlement_carryover_label == null or settlement_label == null or hand_container == null or next_node_button == null or clear_test_save_button == null or seed_input == null or copy_seed_button == null or restart_seed_button == null:
		return

	if battle == null:
		meta_preview_label.text = ""
		route_map_label.text = ""
		status_label.text = "未初始化战斗。"
		enemy_label.text = ""
		prebattle_effect_label.text = ""
		prebattle_effect_label.visible = false
		_clear_container_children(prebattle_effect_chip_container)
		prebattle_effect_chip_container.visible = false
		pile_label.text = ""
		reward_label.text = ""
		_clear_reward_buttons()
		_clear_boss_reward_view()
		event_label.text = ""
		_clear_event_choice_buttons()
		route_choice_label.text = ""
		_clear_route_choice_buttons()
		_clear_route_detail()
		_clear_hand_buttons()
		meta_progression = null
		settlement.clear()
		settlement_save.clear()
		active_event = null
		event_choice_taken = false
		active_event_choice_id = &""
		last_event_result_text = ""
		last_boss_reward_result_text = ""
		next_node_options.clear()
		_clear_settlement_view()
		route = null
		next_node_button.disabled = true
		next_node_button.visible = false
		clear_test_save_button.disabled = meta_save_path == META_PROGRESSION.SAVE_PATH
		copy_seed_button.disabled = true
		restart_seed_button.disabled = true
		return

	_refresh_meta_preview()

	var total_nodes: int = 1
	if route != null:
		total_nodes = max(1, int(route.get_total_nodes()))

	status_label.text = "Seed %d | 节点 %d/%d | 回合 %d | 精力 %d/%d | 防护 %d | 行动点 %d | 进度 %d | 灵感 %d | 数据 %d | 草稿 %d | 经费 %d | 声望 %d | 论文碎片 %d | 经验教训 %d" % [
		run_seed,
		node_index,
		total_nodes,
		battle.turn,
		battle.vitality,
		battle.max_vitality,
		battle.block,
		battle.action_points,
		battle.progress,
		battle.get_resource(&"inspiration"),
		battle.get_resource(&"data"),
		battle.get_resource(&"draft"),
		battle.get_resource(&"funds"),
		battle.get_resource(&"reputation"),
		battle.get_resource(&"paper_fragments"),
		battle.get_resource(&"experience_lessons"),
	]

	if active_event != null:
		enemy_label.text = "事件：%s" % active_event.display_name
	elif battle.is_boss_encounter:
		var boss_detail: String = battle.get_boss_readability_text()
		enemy_label.text = "%s | Boss 目标进度 %d/%d" % [
			battle.encounter_name,
			battle.progress,
			battle.target_progress,
		]
		if boss_detail != "":
			enemy_label.text += "\n" + boss_detail
	else:
		enemy_label.text = "%s | 目标进度 %d/%d | 意图：%s" % [
			battle.encounter_name,
			battle.progress,
			battle.target_progress,
			battle.get_enemy_intent_text(),
		]

	_refresh_prebattle_effect_label()

	pile_label.text = "抽牌堆 %d | 手牌 %d | 弃牌堆 %d | 消耗堆 %d" % [
		battle.draw_pile.size(),
		battle.hand.size(),
		battle.discard_pile.size(),
		battle.exhaust_pile.size(),
	]

	_refresh_rewards()
	_refresh_event_choices()
	_refresh_route_choices()
	_refresh_route_map()
	_refresh_settlement()

	_clear_hand_buttons()
	for index in range(battle.hand.size()):
		var card_id: StringName = battle.hand[index]
		var card: Variant = cards.get(card_id)
		var button: Button = _create_card_button(card_id, card, index)
		hand_container.add_child(button)

	var run_ended := not settlement.is_empty()
	var event_active := active_event != null and not event_choice_taken
	end_turn_button.disabled = run_ended or event_active or battle.vitality <= 0 or battle.is_victory()
	next_node_button.text = "自动选择下一节点"
	next_node_button.visible = false
	next_node_button.disabled = true
	clear_test_save_button.disabled = meta_save_path == META_PROGRESSION.SAVE_PATH
	copy_seed_button.disabled = false
	restart_seed_button.disabled = false
	if not seed_input.has_focus():
		seed_input.text = str(run_seed)


func _refresh_meta_preview() -> void:
	if meta_progression == null:
		meta_preview_label.text = "局外带入：暂无 | 累计结算 0 次"
		return

	var carried_names: Array[String] = []
	for card_id: StringName in carried_unlock_cards:
		var card: Variant = cards.get(card_id)
		if card == null:
			carried_names.append(String(card_id))
		else:
			carried_names.append(card.display_name)

	var unlock_names: Array[String] = meta_progression.get_unlock_display_names()
	var carry_text := "暂无"
	if not carried_names.is_empty():
		carry_text = "、".join(carried_names)
	elif not unlock_names.is_empty():
		carry_text = "已解锁：" + "、".join(unlock_names)

	meta_preview_label.text = "局外带入：%s | 累计结算 %d 次 | 经验教训 %d | 心理韧性 %d" % [
		carry_text,
		int(meta_progression.runs_completed),
		meta_progression.get_resource("experience_lessons"),
		meta_progression.get_resource("psychological_resilience"),
	]


func _refresh_prebattle_effect_label() -> void:
	if prebattle_effect_label == null or prebattle_effect_chip_container == null:
		return
	_clear_container_children(prebattle_effect_chip_container)
	if active_campus_prebattle_effects.is_empty():
		prebattle_effect_label.text = ""
		prebattle_effect_label.visible = false
		prebattle_effect_chip_container.visible = false
		return

	for effect: Dictionary in active_campus_prebattle_effects:
		prebattle_effect_chip_container.add_child(_create_prebattle_effect_chip(effect))
	prebattle_effect_label.text = "携带开局："
	prebattle_effect_label.visible = true
	prebattle_effect_chip_container.visible = true


func _format_prebattle_effect_text() -> String:
	if active_campus_prebattle_effects.is_empty():
		return ""
	var parts: Array[String] = []
	for effect: Dictionary in active_campus_prebattle_effects:
		parts.append(_format_prebattle_effect_chip(effect))
	return "携带开局：" + "  ".join(parts)


func _format_prebattle_effect_chip(effect: Dictionary) -> String:
	var effect_id: StringName = StringName(effect.get("effect_id", &""))
	var source_label: String = str(effect.get("source_label", "携带物"))
	var summary: String = str(effect.get("summary", ""))
	return "[%s] %s · %s" % [_get_prebattle_effect_icon_text(effect_id), source_label, summary]


func _create_prebattle_effect_chip(effect: Dictionary) -> PanelContainer:
	var effect_id: StringName = StringName(effect.get("effect_id", &""))
	var style: Dictionary = _get_prebattle_effect_style(effect_id)

	var chip: PanelContainer = PanelContainer.new()
	chip.name = "PrebattleEffectChip_%s" % String(effect_id)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.custom_minimum_size = Vector2(PREBATTLE_EFFECT_CHIP_MAX_WIDTH, PREBATTLE_EFFECT_CHIP_MIN_HEIGHT)
	chip.add_theme_stylebox_override("panel", _create_prebattle_effect_chip_style(style))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	chip.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)

	var icon: ColorRect = ColorRect.new()
	icon.custom_minimum_size = Vector2(12, 12)
	icon.color = style.get("color", Color(0.70, 0.90, 0.78))
	row.add_child(icon)

	var label: Label = Label.new()
	label.text = "%s %s" % [
		_get_prebattle_effect_icon_text(effect_id),
		str(effect.get("summary", "")),
	]
	label.custom_minimum_size = Vector2(PREBATTLE_EFFECT_CHIP_TEXT_WIDTH, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	label.add_theme_color_override("font_color", style.get("text_color", Color(0.88, 0.96, 0.90)))
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)

	chip.tooltip_text = _format_prebattle_effect_chip(effect)
	return chip


func _create_prebattle_effect_chip_style(style: Dictionary) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = style.get("bg_color", Color(0.08, 0.12, 0.10, 0.86))
	box.border_color = style.get("color", Color(0.70, 0.90, 0.78))
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	return box


func _get_prebattle_effect_style(effect_id: StringName) -> Dictionary:
	match effect_id:
		&"opening_draw":
			return {
				"color": Color(0.50, 0.78, 1.00),
				"bg_color": Color(0.06, 0.12, 0.18, 0.88),
				"text_color": Color(0.82, 0.94, 1.00),
			}
		&"starting_block":
			return {
				"color": Color(0.58, 0.92, 0.66),
				"bg_color": Color(0.07, 0.16, 0.10, 0.88),
				"text_color": Color(0.82, 1.00, 0.84),
			}
		&"starting_progress":
			return {
				"color": Color(1.00, 0.82, 0.38),
				"bg_color": Color(0.18, 0.13, 0.05, 0.88),
				"text_color": Color(1.00, 0.92, 0.70),
			}
		&"first_turn_action_point":
			return {
				"color": Color(0.92, 0.68, 1.00),
				"bg_color": Color(0.15, 0.08, 0.18, 0.88),
				"text_color": Color(0.96, 0.84, 1.00),
			}
		&"pressure_reduction":
			return {
				"color": Color(0.62, 0.92, 0.94),
				"bg_color": Color(0.06, 0.15, 0.16, 0.88),
				"text_color": Color(0.82, 0.98, 0.98),
			}
		&"target_progress_reduction":
			return {
				"color": Color(1.00, 0.66, 0.48),
				"bg_color": Color(0.18, 0.09, 0.06, 0.88),
				"text_color": Color(1.00, 0.84, 0.74),
			}
		_:
			return {
				"color": Color(0.70, 0.90, 0.78),
				"bg_color": Color(0.08, 0.12, 0.10, 0.88),
				"text_color": Color(0.88, 0.96, 0.90),
			}


func _get_prebattle_effect_icon_text(effect_id: StringName) -> String:
	match effect_id:
		&"opening_draw":
			return "抽"
		&"starting_block":
			return "防"
		&"starting_progress":
			return "进"
		&"first_turn_action_point":
			return "行"
		&"pressure_reduction":
			return "压"
		&"target_progress_reduction":
			return "标"
		_:
			return "携"


func _get_available_audio_bus(preferred_bus: String) -> StringName:
	if AudioServer.get_bus_index(preferred_bus) >= 0:
		return StringName(preferred_bus)
	return &"Master"


func _play_prebattle_effect_sfx(effect_id: StringName) -> void:
	if prebattle_effect_audio_player == null:
		return
	var frequency: float = _get_prebattle_effect_sfx_frequency(effect_id)
	var stream: AudioStreamWAV = _create_prebattle_effect_sfx_stream(frequency)
	prebattle_effect_audio_player.stream = stream
	prebattle_effect_audio_player.pitch_scale = 1.0
	prebattle_effect_audio_player.volume_db = -15.0
	prebattle_effect_audio_player.play()
	_prebattle_effect_sfx_play_count += 1
	_last_prebattle_effect_sfx_id = effect_id
	_last_prebattle_effect_sfx_frequency = frequency
	_last_prebattle_effect_sfx_frame_count = int(PREBATTLE_EFFECT_SFX_DURATION * PREBATTLE_EFFECT_SFX_MIX_RATE)


func _get_prebattle_effect_sfx_frequency(effect_id: StringName) -> float:
	match effect_id:
		&"opening_draw":
			return 880.0
		&"starting_block":
			return 660.0
		&"starting_progress":
			return 740.0
		&"first_turn_action_point":
			return 990.0
		&"pressure_reduction":
			return 590.0
		&"target_progress_reduction":
			return 700.0
		_:
			return 760.0


func _create_prebattle_effect_sfx_stream(frequency: float) -> AudioStreamWAV:
	var frame_count: int = int(PREBATTLE_EFFECT_SFX_DURATION * PREBATTLE_EFFECT_SFX_MIX_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(frame_count * 2)

	for frame_index: int in range(frame_count):
		var time: float = float(frame_index) / float(PREBATTLE_EFFECT_SFX_MIX_RATE)
		var attack: float = minf(1.0, time / PREBATTLE_EFFECT_SFX_ATTACK)
		var release: float = maxf(0.0, 1.0 - (time / PREBATTLE_EFFECT_SFX_DURATION))
		var envelope: float = attack * release * release
		var wave: float = (sin(TAU * frequency * time) * 0.72) + (sin(TAU * frequency * 1.5 * time) * 0.28)
		var sample: int = int(clampf(wave * envelope * PREBATTLE_EFFECT_SFX_AMPLITUDE, -1.0, 1.0) * 32767.0)
		if sample < 0:
			sample += 65536
		var byte_index: int = frame_index * 2
		data[byte_index] = sample & 0xff
		data[byte_index + 1] = (sample >> 8) & 0xff

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = PREBATTLE_EFFECT_SFX_MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream


func _enqueue_prebattle_effect_feedback(effect_id: StringName, source_label: String, summary: String) -> void:
	_prebattle_effect_feedback_queue.append({
		"effect_id": effect_id,
		"source_label": source_label,
		"summary": summary,
	})
	if _prebattle_effect_feedback_tween == null or not is_instance_valid(_prebattle_effect_feedback_tween):
		_play_next_prebattle_effect_feedback()


func _play_next_prebattle_effect_feedback() -> void:
	if _prebattle_effect_feedback_queue.is_empty():
		return
	var next_feedback: Dictionary = _prebattle_effect_feedback_queue.pop_front()
	_show_prebattle_effect_feedback(
		StringName(next_feedback.get("effect_id", &"")),
		str(next_feedback.get("source_label", "")),
		str(next_feedback.get("summary", ""))
	)


func _show_prebattle_effect_feedback(effect_id: StringName, source_label: String, summary: String) -> void:
	if prebattle_effect_feedback_label == null:
		return
	if _prebattle_effect_feedback_tween != null and is_instance_valid(_prebattle_effect_feedback_tween):
		_prebattle_effect_feedback_tween.kill()

	var style: Dictionary = _get_prebattle_effect_style(effect_id)
	var feedback_color: Color = style.get("color", Color(0.72, 1.00, 0.78))
	prebattle_effect_feedback_label.text = "[%s] %s\n%s" % [
		_get_prebattle_effect_icon_text(effect_id),
		source_label,
		summary,
	]
	prebattle_effect_feedback_label.visible = true
	prebattle_effect_feedback_label.modulate = Color(feedback_color.r, feedback_color.g, feedback_color.b, 0.0)
	prebattle_effect_feedback_label.scale = Vector2(0.96, 0.96)
	prebattle_effect_feedback_label.pivot_offset = prebattle_effect_feedback_label.size * 0.5
	_play_prebattle_effect_sfx(effect_id)

	_prebattle_effect_feedback_tween = create_tween()
	_prebattle_effect_feedback_tween.tween_property(prebattle_effect_feedback_label, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_prebattle_effect_feedback_tween.parallel().tween_property(prebattle_effect_feedback_label, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_prebattle_effect_feedback_tween.tween_interval(0.52)
	_prebattle_effect_feedback_tween.tween_property(prebattle_effect_feedback_label, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_prebattle_effect_feedback_tween.parallel().tween_property(prebattle_effect_feedback_label, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_prebattle_effect_feedback_tween.tween_callback(_on_prebattle_effect_feedback_finished)


func _hide_prebattle_effect_feedback() -> void:
	if prebattle_effect_feedback_label == null:
		return
	prebattle_effect_feedback_label.visible = false
	prebattle_effect_feedback_label.modulate = Color(1, 1, 1, 1)
	prebattle_effect_feedback_label.scale = Vector2.ONE


func _on_prebattle_effect_feedback_finished() -> void:
	_hide_prebattle_effect_feedback()
	_prebattle_effect_feedback_tween = null
	_play_next_prebattle_effect_feedback()


func _clear_prebattle_effect_feedback() -> void:
	_prebattle_effect_feedback_queue.clear()
	if _prebattle_effect_feedback_tween != null and is_instance_valid(_prebattle_effect_feedback_tween):
		_prebattle_effect_feedback_tween.kill()
	_prebattle_effect_feedback_tween = null
	if prebattle_effect_audio_player != null:
		prebattle_effect_audio_player.stop()
	_prebattle_effect_sfx_play_count = 0
	_last_prebattle_effect_sfx_id = &""
	_last_prebattle_effect_sfx_frequency = 0.0
	_last_prebattle_effect_sfx_frame_count = 0
	_hide_prebattle_effect_feedback()


func _refresh_route_map() -> void:
	if route == null:
		route_map_label.text = ""
		return

	var parts: Array[String] = []
	for index in range(route.node_ids.size()):
		var node_id: StringName = route.node_ids[index]
		var prefix := "[未]"
		if route.completed_node_ids.has(node_id):
			prefix = "[已]"
		elif index == route.current_index:
			prefix = "[当前]"

		parts.append("%s%d %s" % [prefix, index + 1, _get_route_node_display_name(node_id)])

	route_map_label.text = "路线：" + " -> ".join(parts)
	if not next_node_options.is_empty():
		var option_names: Array[String] = []
		for node_id: StringName in next_node_options:
			option_names.append(_get_route_node_display_name(node_id))
		route_map_label.text += " | 可选下一节点：" + " / ".join(option_names)


func _get_route_node_display_name(node_id: StringName) -> String:
	if encounters.has(node_id):
		var encounter: Variant = encounters.get(node_id)
		return String(encounter.display_name)
	if events.has(node_id):
		var event: Variant = events.get(node_id)
		return String(event.display_name)
	if bosses.has(node_id):
		var boss: Variant = bosses.get(node_id)
		return String(boss.display_name)
	return String(node_id)


func _create_card_button(card_id: StringName, card: Variant, hand_index: int) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(150, 150)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if card == null:
		button.text = "%s\n缺失数据" % card_id
		button.disabled = true
		return button

	button.text = "%s\n费用 %d\n%s" % [card.display_name, card.cost, card.description]
	button.tooltip_text = card.description
	button.clip_text = true
	button.disabled = active_event != null or not settlement.is_empty() or card.cost < 0 or battle.action_points < card.cost or battle.vitality <= 0 or battle.is_victory()
	button.pressed.connect(_on_card_pressed.bind(hand_index))
	return button


func _clear_hand_buttons() -> void:
	for child: Node in hand_container.get_children():
		hand_container.remove_child(child)
		child.queue_free()


func _on_card_pressed(hand_index: int) -> void:
	_play_card_at(hand_index)


func _play_card_at(hand_index: int) -> bool:
	if battle == null:
		return false
	if hand_index < 0 or hand_index >= battle.hand.size():
		return false

	var card_id: StringName = battle.hand[hand_index]
	var card: Variant = cards.get(card_id)
	var played: bool = battle.play_card_by_index(hand_index)
	if played and card != null:
		_append_log("打出：%s。" % card.display_name)
		if battle.is_victory():
			_append_log("节点通过：%d/%d。" % [battle.progress, battle.target_progress])
			_prepare_reward_options()
	elif not played:
		_append_log("无法打出：%s。" % card_id)
	_refresh_ui()
	return played


func _prepare_reward_options() -> void:
	if reward_taken or not reward_options.is_empty():
		return

	if battle != null and battle.is_boss_encounter and battle.is_victory():
		for reward_id: StringName in _get_current_boss_reward_options():
			reward_options.append(reward_id)
		return

	if _append_doctoral_reward_options():
		return

	if _append_encounter_reward_options():
		return

	var candidate_ids: Array[String] = []
	for raw_id: Variant in cards.keys():
		var card_id := StringName(raw_id)
		var card: Variant = cards.get(card_id)
		if card == null:
			continue
		if card.rarity != &"common":
			continue
		if card.card_type == &"status":
			continue
		candidate_ids.append(String(card_id))

	candidate_ids.sort()
	for index in range(min(MAX_CARD_REWARD_OPTIONS, candidate_ids.size())):
		reward_options.append(StringName(candidate_ids[index]))


func _append_doctoral_reward_options() -> bool:
	if route == null or battle == null:
		return false
	if battle.is_boss_encounter:
		return false

	var node_id: StringName = route.get_current_node_id()
	if not DOCTORAL_REWARD_POOLS.has(node_id):
		return false

	for raw_card_id: Variant in DOCTORAL_REWARD_POOLS[node_id]:
		var card_id := StringName(raw_card_id)
		if cards.has(card_id):
			reward_options.append(card_id)

	return not reward_options.is_empty()


func _append_encounter_reward_options() -> bool:
	if battle == null:
		return false

	var encounter: Variant = encounters.get(battle.encounter_id)
	if encounter == null:
		return false
	if encounter.victory_rewards.is_empty():
		return false

	var candidate_pool: Array[StringName] = []
	for raw_card_id: String in encounter.victory_rewards:
		var card_id := StringName(raw_card_id)
		if cards.has(card_id):
			candidate_pool.append(card_id)

	for card_id: StringName in _select_weighted_reward_options(candidate_pool, MAX_CARD_REWARD_OPTIONS):
		reward_options.append(card_id)

	return not reward_options.is_empty()


func _select_weighted_reward_options(candidate_pool: Array[StringName], max_count: int, seed_override: int = -1) -> Array[StringName]:
	var selected_ids: Array[StringName] = []
	if max_count <= 0:
		return selected_ids
	if candidate_pool.size() <= max_count:
		selected_ids.append_array(candidate_pool)
		return selected_ids

	var deck_tag_counts: Dictionary = _get_deck_tag_counts()
	var has_experiment_noise: bool = _deck_has_status_tag("experiment_noise")
	var scored_candidates: Array[Dictionary] = []
	for index in range(candidate_pool.size()):
		var card_id: StringName = candidate_pool[index]
		scored_candidates.append({
			"card_id": card_id,
			"score": _score_reward_candidate(card_id, deck_tag_counts, has_experiment_noise),
			"index": index,
		})

	if _reward_scores_are_equal(scored_candidates):
		for index in range(min(max_count, scored_candidates.size())):
			selected_ids.append(StringName(scored_candidates[index].get("card_id", &"")))
		return selected_ids

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if seed_override >= 0:
		rng.seed = seed_override
	else:
		rng.seed = _get_reward_selection_seed(candidate_pool)

	var selected_candidates: Array[Dictionary] = _select_reward_candidates_by_weight(scored_candidates, max_count, rng)
	selected_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("index", 0)) < int(b.get("index", 0))
	)

	for candidate: Dictionary in selected_candidates:
		selected_ids.append(StringName(candidate.get("card_id", &"")))
	return selected_ids


func _reward_scores_are_equal(scored_candidates: Array[Dictionary]) -> bool:
	if scored_candidates.size() <= 1:
		return true

	var first_score: int = int(scored_candidates[0].get("score", 0))
	for candidate: Dictionary in scored_candidates:
		if int(candidate.get("score", 0)) != first_score:
			return false
	return true


func _select_reward_candidates_by_weight(scored_candidates: Array[Dictionary], max_count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var selectable: Array[Dictionary] = []
	selectable.append_array(scored_candidates)
	var selected: Array[Dictionary] = []
	while selected.size() < max_count and not selectable.is_empty():
		var total_weight := 0
		for candidate: Dictionary in selectable:
			total_weight += _get_reward_candidate_weight(candidate)

		var roll: int = rng.randi_range(1, max(1, total_weight))
		var accumulated := 0
		var selected_index := selectable.size() - 1
		for index in range(selectable.size()):
			accumulated += _get_reward_candidate_weight(selectable[index])
			if roll <= accumulated:
				selected_index = index
				break

		selected.append(selectable[selected_index])
		selectable.remove_at(selected_index)
	return selected


func _get_reward_candidate_weight(candidate: Dictionary) -> int:
	var score: int = max(1, int(candidate.get("score", 0)))
	return score * score


func _get_reward_selection_seed(candidate_pool: Array[StringName]) -> int:
	var seed := 17
	if route != null:
		seed = _mix_reward_seed(seed, int(route.seed))
		seed = _mix_reward_seed(seed, int(route.get_current_node_number()))
	if battle != null:
		seed = _mix_reward_seed(seed, _hash_reward_text(String(battle.encounter_id)))
		seed = _mix_reward_seed(seed, int(battle.deck_card_ids.size()))
		for card_id: StringName in battle.deck_card_ids:
			seed = _mix_reward_seed(seed, _hash_reward_text(String(card_id)))
	for card_id: StringName in candidate_pool:
		seed = _mix_reward_seed(seed, _hash_reward_text(String(card_id)))
	return max(1, seed)


func _mix_reward_seed(seed: int, value: int) -> int:
	var mixed: int = (seed * 1103515245 + value + 12345) % REWARD_RNG_MODULUS
	if mixed < 0:
		mixed += REWARD_RNG_MODULUS
	return mixed


func _hash_reward_text(text: String) -> int:
	var value := 0
	for index in range(text.length()):
		value = _mix_reward_seed(value, text.unicode_at(index))
	return value


func _score_reward_candidate(card_id: StringName, deck_tag_counts: Dictionary, has_experiment_noise: bool) -> int:
	var card: Variant = cards.get(card_id)
	if card == null:
		return 0

	var score := 10
	for raw_tag: String in card.tags:
		score += min(6, int(deck_tag_counts.get(raw_tag, 0)) * 2)

	if has_experiment_noise:
		if card_id == &"C028":
			score += 10
		elif card_id == &"C014":
			score += 6

	if battle != null and battle.get_resource(&"funds") > 0 and card.tags.has("funds"):
		score += 5

	return score


func _get_deck_tag_counts() -> Dictionary:
	var tag_counts: Dictionary = {}
	if battle == null:
		return tag_counts

	for card_id: StringName in battle.deck_card_ids:
		var card: Variant = cards.get(card_id)
		if card == null:
			continue
		if card.rarity == &"starter":
			continue
		for raw_tag: String in card.tags:
			tag_counts[raw_tag] = int(tag_counts.get(raw_tag, 0)) + 1
	return tag_counts


func _deck_has_status_tag(tag: String) -> bool:
	if battle == null:
		return false

	for card_id: StringName in battle.deck_card_ids:
		var card: Variant = cards.get(card_id)
		if card == null:
			continue
		if card.card_type == &"status" and card.tags.has(tag):
			return true
	return false


func _refresh_rewards() -> void:
	_clear_reward_buttons()
	_clear_boss_reward_view()

	if active_event != null:
		reward_label.text = ""
		return

	if not battle.is_victory():
		reward_label.text = ""
		return

	if reward_taken:
		if battle.is_boss_encounter:
			reward_label.text = ""
			_show_boss_reward_result()
			return
		if route != null and not route.has_next_node():
			reward_label.text = "奖励已选择，当前牌组 %d 张。当前测试路线已完成。" % battle.deck_card_ids.size()
		else:
			reward_label.text = "奖励已选择，当前牌组 %d 张。点击下一节点继续。" % battle.deck_card_ids.size()
		return

	_prepare_reward_options()
	if battle.is_boss_encounter:
		reward_label.text = ""
		_show_boss_reward_options()
		return

	if route != null and DOCTORAL_REWARD_POOLS.has(route.get_current_node_id()):
		reward_label.text = "博士线节点通过。选择 1 张博士线卡加入牌组："
	else:
		reward_label.text = "节点通过。选择 1 张卡加入牌组："
	for card_id: StringName in reward_options:
		var card: Variant = cards.get(card_id)
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(200, 150)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if card == null:
			button.text = "%s\n缺失数据" % card_id
			button.disabled = true
		else:
			button.text = _format_reward_card_button_text(card)
			button.tooltip_text = _format_reward_card_tooltip(card)
			button.clip_text = true
			button.pressed.connect(_on_reward_pressed.bind(card_id))
		reward_container.add_child(button)


func _format_reward_card_button_text(card: Variant) -> String:
	var archetype_hint: String = _format_card_archetype_hint(card)
	if archetype_hint == "":
		return "%s\n费用 %d\n%s" % [card.display_name, card.cost, card.description]
	return "%s\n费用 %d\n流派：%s\n%s" % [card.display_name, card.cost, archetype_hint, card.description]


func _format_reward_card_tooltip(card: Variant) -> String:
	var parts: Array[String] = []
	parts.append(String(card.description))

	var archetype_hint: String = _format_card_archetype_hint(card)
	if archetype_hint != "":
		parts.append("流派：" + archetype_hint)

	var recommendation_hint: String = _format_reward_recommendation_hint(card)
	if recommendation_hint != "":
		parts.append("推荐：" + recommendation_hint)

	var tag_hint: String = _format_card_tag_hint(card)
	if tag_hint != "":
		parts.append("标签：" + tag_hint)

	return "\n".join(parts)


func _format_reward_recommendation_hint(card: Variant) -> String:
	if card == null or battle == null:
		return ""
	if not _current_reward_pool_needs_weighting():
		return ""

	var reasons: Array[String] = []
	if _deck_has_status_tag("experiment_noise"):
		if card.id == &"C028":
			_append_reward_reason(reasons, "牌组已有实验噪音，可转化为数据和灵感")
		elif card.id == &"C014":
			_append_reward_reason(reasons, "牌组已有实验噪音，可清理实验风险")

	if battle.get_resource(&"funds") > 0 and card.tags.has("funds"):
		_append_reward_reason(reasons, "当前有经费，可触发资源转化")

	var tag_reason: String = _format_matching_reward_tag_reason(card)
	if tag_reason != "":
		_append_reward_reason(reasons, tag_reason)

	return "；".join(reasons)


func _current_reward_pool_needs_weighting() -> bool:
	if battle == null or battle.is_boss_encounter:
		return false
	if route != null and DOCTORAL_REWARD_POOLS.has(route.get_current_node_id()):
		return false

	var encounter: Variant = encounters.get(battle.encounter_id)
	return encounter != null and encounter.victory_rewards.size() > MAX_CARD_REWARD_OPTIONS


func _format_matching_reward_tag_reason(card: Variant) -> String:
	var deck_tag_counts: Dictionary = _get_deck_tag_counts()
	var tag_names: Array[String] = []
	for raw_tag: String in card.tags:
		if int(deck_tag_counts.get(raw_tag, 0)) <= 0:
			continue
		var tag_name: String = _get_card_tag_display_name(raw_tag)
		if not tag_names.has(tag_name):
			tag_names.append(tag_name)
		if tag_names.size() >= 2:
			break
	if tag_names.is_empty():
		return ""
	return "已有%s相关牌" % "、".join(tag_names)


func _append_reward_reason(reasons: Array[String], reason: String) -> void:
	if reason == "" or reasons.has(reason) or reasons.size() >= 2:
		return
	reasons.append(reason)


func _format_card_archetype_hint(card: Variant) -> String:
	var names: Array[String] = []
	if _card_has_tag(card, "revision") or _card_has_tag(card, "delay"):
		_append_unique_archetype(names, "返修延毕")
	if _card_has_tag(card, "project"):
		_append_unique_archetype(names, "项目经费")
	if _card_has_tag(card, "mentor") or _card_has_tag(card, "network") or _card_has_tag(card, "cooperation"):
		_append_unique_archetype(names, "导师人脉")
	if _card_has_tag(card, "equipment") or _card_has_tag(card, "experiment") or _card_has_tag(card, "replication") or _card_has_tag(card, "data"):
		_append_unique_archetype(names, "实验设备")
	if _card_has_tag(card, "rush"):
		_append_unique_archetype(names, "DDL 爆发")
	if _card_has_tag(card, "care") or _card_has_tag(card, "resilience"):
		_append_unique_archetype(names, "心态照护")
	if not _card_has_tag(card, "rush") and (_card_has_tag(card, "literature") or _card_has_tag(card, "paper") or _card_has_tag(card, "draft") or _card_has_tag(card, "inspiration")):
		_append_unique_archetype(names, "文献论文")
	if _card_has_tag(card, "doctor") and names.is_empty():
		_append_unique_archetype(names, "博士线")

	return " / ".join(names)


func _append_unique_archetype(names: Array[String], value: String) -> void:
	if names.size() >= 2:
		return
	if not names.has(value):
		names.append(value)


func _format_card_tag_hint(card: Variant) -> String:
	if card == null:
		return ""
	var tag_names: Array[String] = []
	for raw_tag: String in card.tags:
		tag_names.append(_get_card_tag_display_name(raw_tag))
	return "、".join(tag_names)


func _get_card_tag_display_name(tag: String) -> String:
	match tag:
		"literature":
			return "文献"
		"inspiration":
			return "灵感"
		"draft":
			return "草稿"
		"paper":
			return "论文"
		"methodology":
			return "方法论"
		"experiment":
			return "实验"
		"experiment_noise":
			return "实验噪音"
		"data":
			return "数据"
		"replication":
			return "复现"
		"equipment":
			return "设备"
		"mentor":
			return "导师"
		"network":
			return "人脉"
		"cooperation":
			return "合作"
		"reputation":
			return "声望"
		"project":
			return "项目"
		"funds":
			return "经费"
		"care":
			return "照护"
		"resilience":
			return "心理韧性"
		"block":
			return "防护"
		"rush":
			return "冲刺"
		"risk":
			return "风险"
		"revision":
			return "返修"
		"delay":
			return "延毕/拖延"
		"doctor":
			return "博士"
		"discover":
			return "发现"
		_:
			return tag


func _card_has_tag(card: Variant, tag: String) -> bool:
	return card != null and card.tags.has(tag)


func _show_boss_reward_options() -> void:
	boss_reward_panel.visible = true
	if battle.encounter_id == &"B003":
		boss_reward_title_label.text = "毕业结局选择"
		boss_reward_description_label.text = "选择 1 个毕业结局。未满足条件的结局会暂时锁定，擦线毕业始终可选。"
	elif battle.encounter_id == &"B007":
		boss_reward_title_label.text = "博士毕业结局选择"
		boss_reward_description_label.text = "选择 1 个博士毕业结局。优秀博士毕业和博士毕业需要满足状态与材料条件，延毕后毕业始终可选。"
	elif battle.encounter_id == &"B008":
		boss_reward_title_label.text = "补答辩结局选择"
		boss_reward_description_label.text = "选择 1 个延毕后毕业收束方式。不同选择会把返修经验沉淀成不同局外资源或牌组能力。"
	else:
		boss_reward_title_label.text = "%s通过" % battle.encounter_name
		boss_reward_description_label.text = "选择 1 项阶段奖励。局外成长会进入本次结算，牌组净化会立刻生效。"
	boss_reward_container.visible = true
	_clear_boss_reward_buttons()
	for reward_id: StringName in reward_options:
		boss_reward_container.add_child(_create_boss_reward_button(reward_id))


func _show_boss_reward_result() -> void:
	boss_reward_panel.visible = true
	boss_reward_title_label.text = "Boss 奖励已选择"
	boss_reward_description_label.text = last_boss_reward_result_text
	boss_reward_container.visible = false
	_clear_boss_reward_buttons()


func _create_boss_reward_button(reward_id: StringName) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(210, 132)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = _format_boss_reward_button_text(reward_id)
	button.tooltip_text = _format_boss_reward_tooltip(reward_id)
	button.disabled = not _is_boss_reward_available(reward_id)
	button.clip_text = true
	button.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	_apply_boss_reward_button_style(button, reward_id)
	button.pressed.connect(_on_reward_pressed.bind(reward_id))
	return button


func _apply_boss_reward_button_style(button: Button, reward_id: StringName) -> void:
	var accent: Color = _get_boss_reward_accent_color(reward_id)
	var normal: StyleBoxFlat = _create_boss_reward_button_style(Color(0.11, 0.13, 0.16), accent, 1)
	var hover: StyleBoxFlat = _create_boss_reward_button_style(Color(0.15, 0.18, 0.22), accent.lightened(0.18), 2)
	var pressed: StyleBoxFlat = _create_boss_reward_button_style(Color(0.08, 0.10, 0.13), accent.darkened(0.08), 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)


func _create_boss_reward_button_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _get_boss_reward_accent_color(reward_id: StringName) -> Color:
	match reward_id:
		BOSS_REWARD_DIRECTION:
			return Color(0.35, 0.74, 0.95)
		BOSS_REWARD_FEEDBACK:
			return Color(0.46, 0.82, 0.55)
		BOSS_REWARD_REMOVE_STATUS:
			return Color(0.96, 0.63, 0.29)
		B002_REWARD_ARCHIVE_MATERIALS:
			return Color(0.62, 0.72, 0.96)
		B002_REWARD_REPLICATION_PROTOCOL:
			return Color(0.42, 0.82, 0.74)
		B002_REWARD_CLEANUP_NOISE:
			return Color(0.96, 0.63, 0.29)
		B004_REWARD_PROBLEM_CHAIN:
			return Color(0.58, 0.78, 0.96)
		B004_REWARD_COMMITTEE_BRIDGE:
			return Color(0.42, 0.82, 0.74)
		B004_REWARD_REMOVE_QUALIFICATION_NOISE:
			return Color(0.96, 0.63, 0.29)
		B005_REWARD_PROJECT_LEDGER:
			return Color(0.76, 0.78, 0.48)
		B005_REWARD_TIMELINE_PROTOCOL:
			return Color(0.42, 0.82, 0.74)
		B005_REWARD_REMOVE_PROJECT_NOISE:
			return Color(0.96, 0.63, 0.29)
		B006_REWARD_DEFENSE_NARRATIVE:
			return Color(0.62, 0.72, 0.96)
		B006_REWARD_REHEARSAL_ROUTINE:
			return Color(0.42, 0.82, 0.74)
		B006_REWARD_REMOVE_DEFENSE_NOISE:
			return Color(0.96, 0.63, 0.29)
		B008_REWARD_SUPPLEMENTARY_PASS:
			return Color(0.42, 0.92, 0.70)
		B008_REWARD_REVISION_ARCHIVE:
			return Color(0.72, 0.64, 0.96)
		B008_REWARD_REHEARSAL_LEGACY:
			return Color(0.42, 0.82, 0.74)
		B003_ENDING_OUTSTANDING:
			return Color(0.98, 0.78, 0.30)
		B003_ENDING_STANDARD:
			return Color(0.42, 0.82, 0.58)
		B003_ENDING_NARROW:
			return Color(0.62, 0.72, 0.96)
		B007_ENDING_OUTSTANDING:
			return Color(0.98, 0.82, 0.32)
		B007_ENDING_STANDARD:
			return Color(0.42, 0.92, 0.70)
		B007_ENDING_DELAYED:
			return Color(0.72, 0.64, 0.96)
		_:
			return Color(0.58, 0.66, 0.78)


func _create_boss_reward_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12)
	style.border_color = Color(0.96, 0.78, 0.42)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style


func _clear_boss_reward_view() -> void:
	boss_reward_panel.visible = false
	boss_reward_title_label.text = ""
	boss_reward_description_label.text = ""
	boss_reward_container.visible = true
	_clear_boss_reward_buttons()


func _clear_boss_reward_buttons() -> void:
	for child: Node in boss_reward_container.get_children():
		boss_reward_container.remove_child(child)
		child.queue_free()


func _refresh_event_choices() -> void:
	_clear_event_choice_buttons()

	if active_event == null:
		event_label.text = ""
		return

	if event_choice_taken:
		if settlement.is_empty():
			event_label.text = "事件已处理：%s。\n结果：%s\n请从下方选择下一节点。" % [active_event.display_name, last_event_result_text]
		else:
			event_label.text = "事件已处理：%s。\n结果：%s\n已进入阶段结算。" % [active_event.display_name, last_event_result_text]
		return

	event_label.text = "%s\n%s" % [active_event.display_name, active_event.description]
	for choice: EventChoiceDefinition in active_event.choices:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(180, 110)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s\n%s" % [choice.label, choice.preview]
		button.tooltip_text = choice.preview
		button.disabled = not _is_event_choice_available(choice)
		button.pressed.connect(_on_event_choice_pressed.bind(choice.id))
		event_choice_container.add_child(button)


func _clear_event_choice_buttons() -> void:
	for child: Node in event_choice_container.get_children():
		event_choice_container.remove_child(child)
		child.queue_free()


func _refresh_route_choices() -> void:
	_clear_route_choice_buttons()
	_clear_route_detail()

	if route == null or not settlement.is_empty():
		route_choice_label.text = ""
		next_node_options.clear()
		return
	if not _is_current_route_node_completed():
		route_choice_label.text = ""
		next_node_options.clear()
		return

	_prepare_next_node_options()
	if next_node_options.is_empty():
		route_choice_label.text = "当前路线已完成。"
		return

	route_choice_label.text = "选择下一节点："
	for node_id: StringName in next_node_options:
		route_choice_container.add_child(_create_next_node_option_button(node_id))
	_refresh_route_detail(next_node_options[0])


func _prepare_next_node_options() -> void:
	next_node_options.clear()
	if route == null:
		return
	if not route.has_next_node():
		return
	next_node_options = route.get_next_node_choices(encounters, events, bosses, 3, _get_route_choice_weights())


func _get_route_choice_weights() -> Dictionary:
	var weights: Dictionary = {}
	if battle == null:
		return weights

	_ensure_route_node_hints_loaded()
	var deck_tag_counts: Dictionary = _get_deck_tag_counts()
	var has_experiment_focus: bool = _deck_has_any_tag(deck_tag_counts, PackedStringArray(["equipment", "experiment", "replication", "data"]))
	var has_paper_focus: bool = _deck_has_any_tag(deck_tag_counts, PackedStringArray(["literature", "paper", "draft", "inspiration", "rush"]))
	var has_mentor_focus: bool = _deck_has_any_tag(deck_tag_counts, PackedStringArray(["mentor", "network", "cooperation", "reputation"]))
	var has_project_focus: bool = _deck_has_any_tag(deck_tag_counts, PackedStringArray(["project", "funds"])) or battle.get_resource(&"funds") > 0

	for hint: Variant in route_node_hints.values():
		if has_experiment_focus:
			_add_route_choice_weight(weights, hint.id, hint.experiment_focus_weight)
		if _deck_has_status_tag("experiment_noise"):
			_add_route_choice_weight(weights, hint.id, hint.experiment_noise_weight)
		if battle.get_resource(&"funds") > 0:
			_add_route_choice_weight(weights, hint.id, hint.funds_weight)
		if has_mentor_focus:
			_add_route_choice_weight(weights, hint.id, hint.mentor_focus_weight)
		if battle.get_resource(&"reputation") > 0:
			_add_route_choice_weight(weights, hint.id, hint.reputation_weight)
		if has_paper_focus:
			_add_route_choice_weight(weights, hint.id, hint.paper_focus_weight)
		if battle.get_resource(&"paper_fragments") > 0:
			_add_route_choice_weight(weights, hint.id, hint.paper_fragments_weight)
		if has_project_focus:
			_add_route_choice_weight(weights, hint.id, hint.project_focus_weight)

	return weights


func _ensure_route_node_hints_loaded() -> void:
	if route_node_hints.is_empty():
		route_node_hints = GAME_DATA_CATALOG.load_route_node_hints_by_id()


func _get_route_node_hint(node_id: StringName) -> Variant:
	_ensure_route_node_hints_loaded()
	var hint: Variant = route_node_hints.get(node_id)
	return hint


func _deck_has_any_tag(deck_tag_counts: Dictionary, tags: PackedStringArray) -> bool:
	for tag: String in tags:
		if int(deck_tag_counts.get(tag, 0)) > 0:
			return true
	return false


func _add_route_choice_weight(weights: Dictionary, node_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	weights[node_id] = int(weights.get(node_id, 0)) + amount


func _clear_route_choice_buttons() -> void:
	for child: Node in route_choice_container.get_children():
		route_choice_container.remove_child(child)
		child.queue_free()


func _on_next_node_option_pressed(node_id: StringName) -> void:
	_select_next_node_option(node_id)


func _select_next_node_option(node_id: StringName) -> bool:
	if route == null or not _is_current_route_node_completed() or not next_node_options.has(node_id):
		return false

	var advanced: bool = route.advance_to_node(node_id, encounters, events, bosses)
	if not advanced:
		_append_log("无法进入下一节点：%s。" % node_id)
		_refresh_ui()
		return false

	next_node_options.clear()
	_append_log("选择下一节点：%s。" % _get_route_node_display_name(node_id))
	return _enter_current_route_node()


func _is_current_route_node_completed() -> bool:
	if route == null or not route.has_current_node():
		return false
	return route.completed_node_ids.has(route.get_current_node_id())


func _create_next_node_option_button(node_id: StringName) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(220, 132)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.text = _format_next_node_option_text(node_id)
	button.tooltip_text = _format_next_node_option_tooltip(node_id)
	button.clip_text = true
	button.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	_apply_next_node_option_button_style(button, node_id)
	button.mouse_entered.connect(_on_next_node_option_hovered.bind(node_id))
	button.mouse_exited.connect(_on_next_node_option_unhovered.bind(node_id))
	button.focus_entered.connect(_on_next_node_option_hovered.bind(node_id))
	button.pressed.connect(_on_next_node_option_pressed.bind(node_id))
	return button


func _on_next_node_option_hovered(node_id: StringName) -> void:
	if next_node_options.has(node_id):
		_refresh_route_detail(node_id)


func _on_next_node_option_unhovered(node_id: StringName) -> void:
	if route_detail_active_node_id == node_id and not next_node_options.is_empty():
		_refresh_route_detail(next_node_options[0])


func _refresh_route_detail(node_id: StringName) -> void:
	if route_detail_panel == null or node_id == &"":
		_clear_route_detail()
		return

	route_detail_active_node_id = node_id
	var accent: Color = _get_next_node_option_accent_color(node_id)
	route_detail_panel.visible = true
	route_detail_panel.add_theme_stylebox_override("panel", _create_route_detail_panel_style(accent))
	route_detail_title_label.text = "%s  ·  %s" % [_get_route_node_display_name(node_id), String(node_id)]
	route_detail_title_label.add_theme_color_override("font_color", accent.lightened(0.20))
	route_detail_meta_label.text = "类型：%s | 风险：%s | 倾向：%s" % [
		_get_next_node_type_label(node_id),
		_get_next_node_risk_label(node_id),
		_get_next_node_reward_tendency(node_id),
	]
	route_detail_description_label.text = _format_route_detail_description(node_id)
	route_detail_preview_label.text = _get_route_detail_section_title(node_id)
	_populate_route_detail_rows(node_id, accent)


func _clear_route_detail() -> void:
	route_detail_active_node_id = &""
	if route_detail_panel == null:
		return
	route_detail_panel.visible = false
	if route_detail_title_label != null:
		route_detail_title_label.text = ""
	if route_detail_meta_label != null:
		route_detail_meta_label.text = ""
	if route_detail_description_label != null:
		route_detail_description_label.text = ""
	if route_detail_preview_label != null:
		route_detail_preview_label.text = ""
	if route_detail_row_container != null:
		_clear_container_children(route_detail_row_container)


func _create_route_detail_panel_style(accent: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.09, 0.11)
	style.border_color = accent.darkened(0.05)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _format_route_detail_description(node_id: StringName) -> String:
	if encounters.has(node_id):
		var encounter: Variant = encounters.get(node_id)
		return encounter.description
	if events.has(node_id):
		var event: Variant = events.get(node_id)
		return event.description
	if bosses.has(node_id):
		var boss: Variant = bosses.get(node_id)
		return _format_route_detail_boss_description(boss)
	return String(node_id)


func _get_route_detail_section_title(node_id: StringName) -> String:
	if encounters.has(node_id):
		return "可能奖励"
	if events.has(node_id):
		return "选项预览"
	if bosses.has(node_id):
		return "Boss 检查"
	return ""


func _populate_route_detail_rows(node_id: StringName, accent: Color) -> void:
	if route_detail_row_container == null:
		return

	_clear_container_children(route_detail_row_container)
	if encounters.has(node_id):
		_populate_route_detail_encounter_rows(encounters.get(node_id), accent)
	elif events.has(node_id):
		_populate_route_detail_event_rows(events.get(node_id), accent)
	elif bosses.has(node_id):
		_populate_route_detail_boss_rows(bosses.get(node_id), accent)


func _populate_route_detail_encounter_rows(encounter: Variant, accent: Color) -> void:
	if encounter == null:
		_add_route_detail_row("数据缺失", "", "", accent)
		return

	_add_route_detail_row("意图", "压力 %d" % int(encounter.pressure_per_turn), encounter.get_intent_text(), accent)
	if encounter.victory_rewards.is_empty():
		_add_route_detail_row("奖励", "", "暂无", accent)
		return

	for raw_id: String in encounter.victory_rewards:
		var card_id: StringName = StringName(raw_id)
		var card: Variant = cards.get(card_id)
		if card == null:
			_add_route_detail_row(String(card_id), "", "卡牌数据缺失", accent)
			continue
		_add_route_detail_row(
			card.display_name,
			"%d费" % int(card.cost),
			card.description,
			accent
		)


func _populate_route_detail_event_rows(event: Variant, accent: Color) -> void:
	if event == null or event.choices.is_empty():
		_add_route_detail_row("选项", "", "暂无", accent)
		return

	if event.id == ROUTE_STATE.POST_MIDTERM_TRANSFER_EVENT:
		var transfer_row_color: Color = accent if _is_transfer_requirement_met() else Color(0.56, 0.60, 0.64)
		_add_route_detail_row(
			"转博资格",
			_format_transfer_requirement_status(),
			_format_transfer_requirement_detail(),
			transfer_row_color
		)

	for choice: EventChoiceDefinition in event.choices:
		var availability: String = "可选" if _is_event_choice_available(choice) else "暂不可选"
		var row_color: Color = accent if _is_event_choice_available(choice) else Color(0.56, 0.60, 0.64)
		_add_route_detail_row(
			choice.label,
			availability,
			"%s；%s" % [_get_event_choice_requirement_label(choice.requirement), choice.preview],
			row_color
		)


func _populate_route_detail_boss_rows(boss: Variant, accent: Color) -> void:
	if boss == null:
		_add_route_detail_row("Boss", "", "数据缺失", accent)
		return

	_add_route_detail_row("目标进度", str(int(boss.target_progress)), "阶段 Boss", accent)
	for passive_rule: String in boss.passive_rules:
		_add_route_detail_row("规则", "", passive_rule, accent)
	for intent: BossIntentDefinition in boss.intents:
		_add_route_detail_row(
			intent.display_name,
			_format_boss_intent_value(intent),
			_format_boss_intent_detail(intent),
			accent
		)
	if int(boss.phase_trigger_progress) > 0:
		_add_route_detail_row(
			"阶段检查",
			"进度 %d" % int(boss.phase_trigger_progress),
			_get_boss_phase_condition_label(boss.phase_condition),
			accent
		)
	if not boss.victory_rewards.is_empty():
		_add_route_detail_row("结算资源", "", _format_route_detail_resource_names(boss.victory_rewards), accent)


func _format_boss_intent_value(intent: BossIntentDefinition) -> String:
	if intent == null:
		return ""
	if int(intent.pressure) > 0:
		return "压力 %d" % int(intent.pressure)
	return _get_boss_intent_type_label(intent.intent_type)


func _format_boss_intent_detail(intent: BossIntentDefinition) -> String:
	if intent == null:
		return ""

	var parts: Array[String] = []
	var type_label: String = _get_boss_intent_type_label(intent.intent_type)
	if type_label != "":
		parts.append(type_label)
	if intent.condition != &"":
		parts.append(_get_boss_phase_condition_label(intent.condition))
	return "；".join(parts)


func _get_boss_intent_type_label(intent_type: StringName) -> String:
	match intent_type:
		&"pressure":
			return "压力"
		&"check":
			return "检查"
		&"interference":
			return "干扰"
		_:
			return String(intent_type)


func _add_route_detail_row(name_text: String, value_text: String, detail_text: String, accent_color: Color) -> void:
	if route_detail_row_container == null:
		return

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label: Label = Label.new()
	name_label.custom_minimum_size = Vector2(128, 0)
	name_label.text = name_text
	name_label.add_theme_color_override("font_color", accent_color)
	name_label.add_theme_font_size_override("font_size", 14)
	row.add_child(name_label)

	if value_text != "":
		var value_label: Label = Label.new()
		value_label.custom_minimum_size = Vector2(88, 0)
		value_label.text = value_text
		value_label.add_theme_color_override("font_color", Color(0.90, 0.94, 0.98))
		value_label.add_theme_font_size_override("font_size", 14)
		row.add_child(value_label)

	if detail_text != "":
		var detail_label: Label = Label.new()
		detail_label.text = detail_text
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.84))
		detail_label.add_theme_font_size_override("font_size", 13)
		row.add_child(detail_label)

	route_detail_row_container.add_child(row)


func _collect_route_detail_row_texts() -> Array[String]:
	var lines: Array[String] = []
	if route_detail_row_container == null:
		return lines

	for row: Node in route_detail_row_container.get_children():
		var parts: Array[String] = []
		for child: Node in row.get_children():
			if child is Label:
				var label: Label = child as Label
				if label.text != "":
					parts.append(label.text)
		if not parts.is_empty():
			lines.append(" | ".join(parts))
	return lines


func _get_event_choice_requirement_label(requirement: StringName) -> String:
	match requirement:
		&"", &"always":
			return "无条件"
		&"has_1_reputation":
			return _format_resource_requirement(&"reputation", 1)
		&"has_2_draft":
			return _format_resource_requirement(&"draft", 2)
		&"has_2_inspiration":
			return _format_resource_requirement(&"inspiration", 2)
		&"has_2_reputation":
			return _format_resource_requirement(&"reputation", 2)
		&"has_3_methodology_notes":
			return _format_resource_requirement(&"methodology_notes", 3)
		&"has_2_paper_fragments":
			return _format_resource_requirement(&"paper_fragments", 2)
		&"has_4_draft":
			return _format_resource_requirement(&"draft", 4)
		&"has_2_reputation_or_4_draft":
			return _format_alternative_resource_requirement(&"reputation", 2, &"draft", 4)
		&"has_3_methodology_notes_or_2_paper_fragments":
			return _format_alternative_resource_requirement(&"methodology_notes", 3, &"paper_fragments", 2)
		&"has_2_funds":
			return _format_resource_requirement(&"funds", 2)
		_:
			return "未知条件"


func _format_resource_requirement(resource_id: StringName, required_count: int) -> String:
	var current_count: int = 0
	if battle != null:
		current_count = battle.get_resource(resource_id)
	return "%s %d/%d" % [_get_resource_display_name(resource_id), current_count, required_count]


func _format_alternative_resource_requirement(
	first_resource_id: StringName,
	first_required_count: int,
	second_resource_id: StringName,
	second_required_count: int
) -> String:
	return "%s 或%s" % [
		_format_resource_requirement(first_resource_id, first_required_count),
		_format_resource_requirement(second_resource_id, second_required_count),
	]


func _is_transfer_requirement_met() -> bool:
	if battle == null:
		return false
	return battle.get_resource(&"reputation") >= TRANSFER_REQUIREMENT_REPUTATION or battle.get_resource(&"draft") >= TRANSFER_REQUIREMENT_DRAFT


func _format_transfer_requirement_status() -> String:
	if _is_transfer_requirement_met():
		return "已满足"
	return "未满足"


func _format_transfer_requirement_detail() -> String:
	if battle == null:
		return _format_transfer_requirement_progress()
	if _is_transfer_requirement_met():
		return "%s，可提交转博申请。" % _format_transfer_requirement_progress()
	return "%s，继续积累声望或草稿。" % _format_transfer_requirement_progress()


func _format_transfer_requirement_progress() -> String:
	return _format_alternative_resource_requirement(
		&"reputation",
		TRANSFER_REQUIREMENT_REPUTATION,
		&"draft",
		TRANSFER_REQUIREMENT_DRAFT
	)


func _format_route_detail_boss_description(boss: Variant) -> String:
	if boss == null:
		return "Boss 数据缺失。"

	return "阶段 Boss：目标进度 %d。" % int(boss.target_progress)


func _get_boss_phase_condition_label(condition: StringName) -> String:
	match condition:
		&"gained_2_data_and_3_draft":
			return "本战累计 2 数据且 3 草稿"
		&"gained_2_data_or_3_draft":
			return "本战累计 2 数据或 3 草稿"
		&"has_inspiration":
			return "持有灵感"
		&"has_data":
			return "持有数据"
		&"has_2_data":
			return "持有 2 数据"
		&"has_1_reputation":
			return "持有 1 声望"
		&"has_2_reputation":
			return "持有 2 声望"
		&"has_2_inspiration":
			return "持有 2 灵感"
		&"has_2_draft":
			return "持有 2 草稿"
		&"has_4_draft":
			return "持有 4 草稿"
		&"has_2_funds":
			return "持有 2 经费"
		&"has_3_methodology_notes":
			return "持有 3 方法论笔记"
		&"has_4_methodology_notes":
			return "持有 4 方法论笔记"
		&"has_2_paper_fragments":
			return "持有 2 论文碎片"
		&"has_3_paper_fragments":
			return "持有 3 论文碎片"
		&"has_2_draft_or_2_data":
			return "持有 2 草稿或 2 数据"
		&"has_2_reputation_or_4_draft":
			return "持有 2 声望或 4 草稿"
		&"has_3_methodology_notes_or_2_paper_fragments":
			return "持有 3 方法论笔记或 2 论文碎片"
		&"has_2_funds_or_2_paper_fragments":
			return "持有 2 经费或 2 论文碎片"
		&"has_3_paper_fragments_or_2_reputation":
			return "持有 3 论文碎片或 2 声望"
		&"has_4_paper_fragments_or_2_reputation":
			return "持有 4 论文碎片或 2 声望"
		_:
			if condition == &"":
				return "无额外条件"
			return String(condition)


func _format_route_detail_resource_names(resource_ids: PackedStringArray) -> String:
	var names: Array[String] = []
	for raw_id: String in resource_ids:
		names.append(_get_resource_display_name(StringName(raw_id)))
	if names.is_empty():
		return "暂无"
	return "、".join(names)


func _format_next_node_option_text(node_id: StringName) -> String:
	return "%s\n%s | 风险：%s\n倾向：%s\n%s" % [
		_get_route_node_display_name(node_id),
		_get_next_node_type_label(node_id),
		_get_next_node_risk_label(node_id),
		_get_next_node_reward_tendency(node_id),
		_format_next_node_option_summary(node_id),
	]


func _get_next_node_type_label(node_id: StringName) -> String:
	if encounters.has(node_id):
		return "战斗节点"
	if events.has(node_id):
		return "事件节点"
	if bosses.has(node_id):
		return "Boss 节点"
	return "未知节点"


func _get_next_node_risk_label(node_id: StringName) -> String:
	var hint: Variant = _get_route_node_hint(node_id)
	if hint != null and hint.risk_label != "":
		return hint.risk_label

	if encounters.has(node_id):
		var encounter: Variant = encounters.get(node_id)
		var target_progress: int = int(encounter.target_progress)
		var pressure_per_turn: int = int(encounter.pressure_per_turn)
		if pressure_per_turn >= 8 or target_progress >= 44:
			return "高压"
		if pressure_per_turn <= 5 and target_progress <= 36:
			return "稳健"
		return "标准"
	if events.has(node_id):
		return "变数"
	if bosses.has(node_id):
		return "考核"
	return "未知"


func _get_next_node_reward_tendency(node_id: StringName) -> String:
	var hint: Variant = _get_route_node_hint(node_id)
	if hint != null and hint.reward_tendency != "":
		return hint.reward_tendency
	return "综合成长"


func _apply_next_node_option_button_style(button: Button, node_id: StringName) -> void:
	var accent: Color = _get_next_node_option_accent_color(node_id)
	var normal: StyleBoxFlat = _create_next_node_option_button_style(Color(0.09, 0.11, 0.14), accent, 1)
	var hover: StyleBoxFlat = _create_next_node_option_button_style(Color(0.13, 0.16, 0.19), accent.lightened(0.18), 2)
	var pressed: StyleBoxFlat = _create_next_node_option_button_style(Color(0.07, 0.09, 0.12), accent.darkened(0.08), 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)


func _create_next_node_option_button_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _get_next_node_option_accent_color(node_id: StringName) -> Color:
	var hint: Variant = _get_route_node_hint(node_id)
	if hint != null:
		return hint.accent_color

	if bosses.has(node_id):
		return Color(0.96, 0.74, 0.34)
	if events.has(node_id):
		return Color(0.46, 0.82, 0.62)
	if encounters.has(node_id):
		return Color(0.52, 0.68, 0.92)
	return Color(0.58, 0.66, 0.78)


func _format_next_node_option_tooltip(node_id: StringName) -> String:
	var parts: Array[String] = []
	if encounters.has(node_id):
		var encounter: Variant = encounters.get(node_id)
		parts.append("%s\n目标进度 %d，每回合压力 %d。" % [encounter.description, encounter.target_progress, encounter.pressure_per_turn])
	elif events.has(node_id):
		var event: Variant = events.get(node_id)
		parts.append(event.description)
	elif bosses.has(node_id):
		var boss: Variant = bosses.get(node_id)
		parts.append("阶段 Boss：目标进度 %d。通过后进入下一阶段或阶段结算。" % boss.target_progress)
	else:
		parts.append(String(node_id))

	var recommendation_hint: String = _format_route_choice_recommendation_hint(node_id)
	if recommendation_hint != "":
		parts.append("推荐：" + recommendation_hint)

	return "\n".join(parts)


func _format_route_choice_recommendation_hint(node_id: StringName) -> String:
	if battle == null or bosses.has(node_id):
		return ""

	var hint: Variant = _get_route_node_hint(node_id)
	if hint == null:
		return ""

	var deck_tag_counts: Dictionary = _get_deck_tag_counts()
	var reasons: Array[String] = []
	var has_experiment_focus: bool = _deck_has_any_tag(deck_tag_counts, PackedStringArray(["equipment", "experiment", "replication", "data"]))
	var has_paper_focus: bool = _deck_has_any_tag(deck_tag_counts, PackedStringArray(["literature", "paper", "draft", "inspiration", "rush"]))
	var has_mentor_focus: bool = _deck_has_any_tag(deck_tag_counts, PackedStringArray(["mentor", "network", "cooperation", "reputation"]))
	var has_project_focus: bool = _deck_has_any_tag(deck_tag_counts, PackedStringArray(["project", "funds"])) or battle.get_resource(&"funds") > 0

	if hint.experiment_focus_weight > 0 and has_experiment_focus:
		_append_route_choice_reason(reasons, "已有实验、设备或数据相关牌")
	if hint.experiment_noise_weight > 0 and _deck_has_status_tag("experiment_noise"):
		_append_route_choice_reason(reasons, "牌组已有实验噪音")
	if hint.funds_weight > 0 and battle.get_resource(&"funds") > 0:
		_append_route_choice_reason(reasons, "当前有经费可支撑设备路线")
	if hint.mentor_focus_weight > 0 and has_mentor_focus:
		_append_route_choice_reason(reasons, "已有导师、人脉或合作相关牌")
	if hint.reputation_weight > 0 and battle.get_resource(&"reputation") > 0:
		_append_route_choice_reason(reasons, "当前有声望资源")
	if hint.paper_focus_weight > 0 and has_paper_focus:
		_append_route_choice_reason(reasons, "已有论文、草稿或 DDL 相关牌")
	if hint.paper_fragments_weight > 0 and battle.get_resource(&"paper_fragments") > 0:
		_append_route_choice_reason(reasons, "已有论文碎片")
	if hint.project_focus_weight > 0 and has_project_focus:
		_append_route_choice_reason(reasons, "已有项目或经费倾向")

	return "；".join(reasons)


func _append_route_choice_reason(reasons: Array[String], reason: String) -> void:
	if reason == "" or reasons.has(reason) or reasons.size() >= 2:
		return
	reasons.append(reason)


func _format_next_node_option_summary(node_id: StringName) -> String:
	if encounters.has(node_id):
		var encounter: Variant = encounters.get(node_id)
		return "目标 %d / 压力 %d" % [encounter.target_progress, encounter.pressure_per_turn]
	if events.has(node_id):
		return "选项事件"
	if bosses.has(node_id):
		var boss: Variant = bosses.get(node_id)
		return "目标 %d / 阶段 Boss" % boss.target_progress
	return String(node_id)


func _refresh_settlement() -> void:
	if settlement.is_empty():
		_clear_settlement_view()
		return

	var outcome_id: String = String(settlement.get("outcome_id", ""))
	settlement_panel.add_theme_stylebox_override("panel", _create_settlement_panel_style(outcome_id))
	settlement_title_label.add_theme_color_override("font_color", _get_settlement_accent_color(outcome_id))
	settlement_title_label.text = String(settlement.get("title", "阶段结算"))
	settlement_description_label.text = String(settlement.get("description", ""))
	settlement_stats_label.text = _format_settlement_stats()
	settlement_resources_label.text = _format_settlement_resources()
	_populate_settlement_resource_rows()

	var unlock_summary: String = _format_settlement_new_unlocks()
	if unlock_summary == "":
		settlement_unlock_title_label.visible = false
		settlement_unlock_list.visible = false
		_clear_container_children(settlement_unlock_list)
		settlement_unlock_label.text = ""
		settlement_unlock_label.visible = false
	else:
		settlement_unlock_title_label.visible = true
		settlement_unlock_list.visible = true
		_populate_settlement_unlock_rows()
		settlement_unlock_label.text = unlock_summary
		settlement_unlock_label.visible = false

	var carryover_summary: String = _format_settlement_new_carryover()
	if carryover_summary == "":
		settlement_carryover_title_label.visible = false
		settlement_carryover_list.visible = false
		_clear_container_children(settlement_carryover_list)
		settlement_carryover_label.text = ""
		settlement_carryover_label.visible = false
	else:
		settlement_carryover_title_label.visible = true
		settlement_carryover_list.visible = true
		_populate_settlement_carryover_rows()
		settlement_carryover_label.text = carryover_summary
		settlement_carryover_label.visible = false

	var save_summary: String = ""
	if not settlement_save.is_empty():
		save_summary = String(settlement_save.get("summary_text", ""))
	if save_summary == "":
		settlement_label.text = ""
		settlement_label.visible = false
	else:
		settlement_label.text = "存档：" + save_summary
		settlement_label.visible = true

	settlement_panel.visible = true


func _clear_settlement_view() -> void:
	settlement_panel.visible = false
	settlement_title_label.text = ""
	settlement_description_label.text = ""
	settlement_stats_label.text = ""
	settlement_resources_label.text = ""
	_clear_container_children(settlement_resources_list)
	settlement_unlock_title_label.visible = false
	settlement_unlock_list.visible = false
	_clear_container_children(settlement_unlock_list)
	settlement_unlock_label.text = ""
	settlement_unlock_label.visible = false
	settlement_carryover_title_label.visible = false
	settlement_carryover_list.visible = false
	_clear_container_children(settlement_carryover_list)
	settlement_carryover_label.text = ""
	settlement_carryover_label.visible = false
	settlement_label.text = ""
	settlement_label.visible = false


func _create_settlement_panel_style(outcome_id: String) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = _get_settlement_background_color(outcome_id)
	style.border_color = _get_settlement_accent_color(outcome_id)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style


func _get_settlement_background_color(outcome_id: String) -> Color:
	match outcome_id:
		"route_completed":
			return Color(0.07, 0.14, 0.12)
		"master_graduated":
			return Color(0.07, 0.14, 0.12)
		"outstanding_graduation":
			return Color(0.16, 0.13, 0.06)
		"narrow_graduation":
			return Color(0.12, 0.13, 0.08)
		"outstanding_doctoral_graduation":
			return Color(0.15, 0.13, 0.06)
		"doctoral_graduated":
			return Color(0.06, 0.13, 0.12)
		"delayed_doctoral_graduation":
			return Color(0.11, 0.11, 0.17)
		"transfer_admitted":
			return Color(0.08, 0.13, 0.16)
		"qualification_failed":
			return Color(0.14, 0.09, 0.17)
		"project_midterm_failed":
			return Color(0.16, 0.10, 0.11)
		"predefense_failed":
			return Color(0.10, 0.10, 0.18)
		"doctoral_defense_delayed":
			return Color(0.12, 0.10, 0.17)
		"supplementary_defense_failed":
			return Color(0.13, 0.10, 0.16)
		"proposal_delayed":
			return Color(0.17, 0.13, 0.08)
		"midterm_warning":
			return Color(0.14, 0.11, 0.16)
		"blind_review_failed":
			return Color(0.10, 0.12, 0.18)
		"burnout":
			return Color(0.17, 0.09, 0.10)
		_:
			return Color(0.10, 0.11, 0.14)


func _get_settlement_accent_color(outcome_id: String) -> Color:
	match outcome_id:
		"route_completed":
			return Color(0.31, 0.78, 0.53)
		"master_graduated":
			return Color(0.34, 0.82, 0.54)
		"outstanding_graduation":
			return Color(0.98, 0.78, 0.30)
		"narrow_graduation":
			return Color(0.74, 0.78, 0.42)
		"outstanding_doctoral_graduation":
			return Color(1.00, 0.82, 0.32)
		"doctoral_graduated":
			return Color(0.42, 0.92, 0.70)
		"delayed_doctoral_graduation":
			return Color(0.72, 0.64, 0.96)
		"transfer_admitted":
			return Color(0.36, 0.78, 0.88)
		"qualification_failed":
			return Color(0.82, 0.48, 0.92)
		"project_midterm_failed":
			return Color(0.93, 0.48, 0.38)
		"predefense_failed":
			return Color(0.60, 0.64, 0.96)
		"doctoral_defense_delayed":
			return Color(0.72, 0.58, 0.96)
		"supplementary_defense_failed":
			return Color(0.78, 0.55, 0.96)
		"proposal_delayed":
			return Color(0.95, 0.63, 0.24)
		"midterm_warning":
			return Color(0.76, 0.52, 0.95)
		"blind_review_failed":
			return Color(0.48, 0.68, 0.96)
		"burnout":
			return Color(0.88, 0.35, 0.40)
		_:
			return Color(0.58, 0.66, 0.78)


func _format_settlement_stats() -> String:
	return "Seed %d | 节点 %d/%d | 牌组 %d 张 | 精力 %d/%d" % [
		int(settlement.get("run_seed", run_seed)),
		int(settlement.get("completed_nodes", 0)),
		int(settlement.get("total_nodes", 0)),
		int(settlement.get("deck_size", 0)),
		int(settlement.get("vitality", 0)),
		int(settlement.get("max_vitality", 0)),
	]


func _populate_settlement_resource_rows() -> void:
	_clear_container_children(settlement_resources_list)
	var entries: Array = _get_settlement_resource_entries()
	if entries.is_empty():
		_add_settlement_entry_row(settlement_resources_list, "暂无", "", "", Color(0.66, 0.72, 0.78))
		return

	for entry: Dictionary in entries:
		_add_settlement_entry_row(
			settlement_resources_list,
			String(entry.get("name", "")),
			String(entry.get("value", "")),
			"",
			Color(0.86, 0.90, 0.95)
		)


func _populate_settlement_unlock_rows() -> void:
	_clear_container_children(settlement_unlock_list)
	for unlock_id: StringName in _get_settlement_new_unlock_ids():
		_add_settlement_entry_row(
			settlement_unlock_list,
			META_PROGRESSION.get_unlock_display_name(unlock_id),
			"",
			"新局外成长",
			Color(1.00, 0.84, 0.42)
		)


func _populate_settlement_carryover_rows() -> void:
	_clear_container_children(settlement_carryover_list)
	var seen_card_ids: Array[StringName] = []
	for unlock_id: StringName in _get_settlement_new_unlock_ids():
		var card_id: StringName = _get_unlock_carry_card_id(unlock_id)
		if card_id == &"" or seen_card_ids.has(card_id):
			continue
		seen_card_ids.append(card_id)
		var card: Variant = cards.get(card_id)
		if card == null:
			_add_settlement_entry_row(settlement_carryover_list, String(card_id), "", "", Color(0.66, 0.92, 0.80))
			continue
		_add_settlement_entry_row(
			settlement_carryover_list,
			card.display_name,
			"%d费" % int(card.cost),
			String(card.description),
			Color(0.66, 0.92, 0.80)
		)


func _add_settlement_entry_row(container: VBoxContainer, name_text: String, value_text: String, detail_text: String, accent_color: Color) -> void:
	if container == null:
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(128, 0)
	name_label.text = name_text
	name_label.add_theme_color_override("font_color", accent_color)
	name_label.add_theme_font_size_override("font_size", 15)
	row.add_child(name_label)

	if value_text != "":
		var value_label := Label.new()
		value_label.custom_minimum_size = Vector2(48, 0)
		value_label.text = value_text
		value_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))
		value_label.add_theme_font_size_override("font_size", 15)
		row.add_child(value_label)

	if detail_text != "":
		var detail_label := Label.new()
		detail_label.text = detail_text
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.84))
		detail_label.add_theme_font_size_override("font_size", 14)
		row.add_child(detail_label)

	container.add_child(row)


func _format_settlement_resources() -> String:
	var parts: Array[String] = []
	for entry: Dictionary in _get_settlement_resource_entries():
		parts.append("%s %s" % [String(entry.get("name", "")), String(entry.get("value", ""))])

	if parts.is_empty():
		return "暂无"
	return "\n".join(parts)


func _get_settlement_resource_entries() -> Array:
	var entries: Array = []
	var resources: Dictionary = settlement.get("resources", {})
	var resource_ids: Array[String] = [
		"experience_lessons",
		"methodology_notes",
		"psychological_resilience",
		"paper_fragments",
		"black_history_archive",
	]
	for resource_id: String in resource_ids:
		var amount: int = int(resources.get(resource_id, 0))
		if amount <= 0:
			continue
		entries.append({
			"name": _get_settlement_resource_display_name(resource_id),
			"value": "+%d" % amount,
		})
	return entries


func _format_settlement_new_unlocks() -> String:
	var unlock_ids: Array[StringName] = _get_settlement_new_unlock_ids()
	if unlock_ids.is_empty():
		return ""

	var unlock_names: Array[String] = []
	for unlock_id: StringName in unlock_ids:
		unlock_names.append(META_PROGRESSION.get_unlock_display_name(unlock_id))

	return "\n".join(unlock_names)


func _format_settlement_new_carryover() -> String:
	var unlock_ids: Array[StringName] = _get_settlement_new_unlock_ids()
	if unlock_ids.is_empty():
		return ""

	var carry_names: Array[String] = []
	for unlock_id: StringName in unlock_ids:
		var carry_name: String = _format_unlock_carry_card_summary(unlock_id)
		if carry_name != "" and not carry_names.has(carry_name):
			carry_names.append(carry_name)

	return "\n".join(carry_names)


func _get_settlement_new_unlock_ids() -> Array[StringName]:
	var unlock_ids: Array[StringName] = []
	if settlement_save.is_empty():
		return unlock_ids

	var raw_unlocks: Array = settlement_save.get("new_unlocks", [])
	for raw_unlock: Variant in raw_unlocks:
		var unlock_id := StringName(raw_unlock)
		if not unlock_ids.has(unlock_id):
			unlock_ids.append(unlock_id)
	return unlock_ids


func _get_unlock_carry_card_display_name(unlock_id: StringName) -> String:
	var card_id: StringName = _get_unlock_carry_card_id(unlock_id)
	if card_id == &"":
		return ""

	return _get_card_display_name(card_id)


func _format_unlock_carry_card_summary(unlock_id: StringName) -> String:
	var card_id: StringName = _get_unlock_carry_card_id(unlock_id)
	if card_id == &"":
		return ""

	var card: Variant = cards.get(card_id)
	if card == null:
		return String(card_id)

	var description := String(card.description)
	if description == "":
		return "%s（%d费）" % [card.display_name, int(card.cost)]

	return "%s（%d费）：%s" % [card.display_name, int(card.cost), description]


func _get_unlock_carry_card_id(unlock_id: StringName) -> StringName:
	var card_id: StringName = &""
	match unlock_id:
		SELF_CARE_UNLOCK_ID:
			card_id = SELF_CARE_CARD_ID
		REVISION_STRATEGY_UNLOCK_ID:
			card_id = REVISION_STRATEGY_CARD_ID
		REVISION_MATRIX_UNLOCK_ID:
			card_id = REVISION_MATRIX_CARD_ID
		_:
			return &""

	return card_id


func _get_settlement_resource_display_name(resource_id: String) -> String:
	match resource_id:
		"experience_lessons":
			return "经验教训"
		"methodology_notes":
			return "方法论笔记"
		"psychological_resilience":
			return "心理韧性"
		"paper_fragments":
			return "论文碎片"
		"black_history_archive":
			return "黑历史档案"
		_:
			return resource_id


func _clear_container_children(container: Node) -> void:
	if container == null:
		return
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _clear_reward_buttons() -> void:
	for child: Node in reward_container.get_children():
		reward_container.remove_child(child)
		child.queue_free()


func _on_reward_pressed(card_id: StringName) -> void:
	_select_reward(card_id)


func _on_event_choice_pressed(choice_id: StringName) -> void:
	_select_event_choice(choice_id)


func _select_event_choice(choice_id: StringName) -> bool:
	if active_event == null or event_choice_taken or battle == null:
		return false

	for choice: EventChoiceDefinition in active_event.choices:
		if choice.id != choice_id:
			continue
		if not _is_event_choice_available(choice):
			_append_log("事件选项条件不足：%s。" % choice.label)
			_refresh_ui()
			return false

		var before_state := _snapshot_battle_state()
		battle.apply_event_effects(choice.effects)
		var after_state := _snapshot_battle_state()
		last_event_result_text = _format_event_result(before_state, after_state)
		event_choice_taken = true
		active_event_choice_id = choice_id
		if route != null:
			route.complete_current_node()
		_append_log("事件选择：%s。结果：%s" % [choice.label, last_event_result_text])
		if active_event.id == ROUTE_STATE.POST_DOCTORAL_DELAY_REPAIR_EVENT:
			if _resolve_doctoral_route_after_event_choice(active_event.id):
				return true
			_complete_run(&"doctoral_defense_delayed")
		elif battle.vitality <= 0:
			_handle_vitality_depleted()
		elif _resolve_transfer_application_choice(choice.id):
			return true
		elif _resolve_doctoral_route_after_event_choice(active_event.id):
			return true
		elif route != null and not route.has_next_node():
			_complete_run(&"route_completed")
		_refresh_ui()
		return true

	return false


func _handle_vitality_depleted() -> void:
	var failure_reason: StringName = _get_failure_settlement_reason()
	if failure_reason == &"doctoral_defense_delayed" and _advance_to_doctoral_delay_repair_event():
		return
	_complete_run(failure_reason)


func _advance_to_doctoral_delay_repair_event() -> bool:
	if route == null:
		return false
	if route.get_current_node_id() != ROUTE_STATE.POST_DOCTORAL_DEFENSE_BOSS:
		return false

	var advanced: bool = route.advance_to_node(ROUTE_STATE.POST_DOCTORAL_DELAY_REPAIR_EVENT, encounters, events, bosses)
	if not advanced:
		return false

	_append_log("博士答辩延期，进入博四返修会：%s。" % _get_route_node_display_name(ROUTE_STATE.POST_DOCTORAL_DELAY_REPAIR_EVENT))
	_enter_current_route_node()
	return true


func _resolve_transfer_application_choice(choice_id: StringName) -> bool:
	if active_event == null or active_event.id != &"E005":
		return false

	match choice_id:
		&"submit_transfer_application":
			if route == null:
				_complete_run(&"transfer_admitted")
				_refresh_ui()
				return true
			var advanced: bool = route.advance_to_node(ROUTE_STATE.POST_TRANSFER_FIRST_ENCOUNTER, encounters, events, bosses)
			if not advanced:
				_append_log("博士线首个节点缺失，转入转博资格结算。")
				_complete_run(&"transfer_admitted")
				_refresh_ui()
				return true
			_append_log("转博申请通过，进入博士路线：%s。" % _get_route_node_display_name(ROUTE_STATE.POST_TRANSFER_FIRST_ENCOUNTER))
			_enter_current_route_node()
			return true
		&"continue_master_graduation":
			if route == null:
				return false
			var advanced: bool = route.advance_to_node(ROUTE_STATE.POST_MIDTERM_STANDARD_BOSS, encounters, events, bosses)
			if not advanced:
				_append_log("无法进入硕士毕业线：%s。" % ROUTE_STATE.POST_MIDTERM_STANDARD_BOSS)
				_refresh_ui()
				return true
			_append_log("转博暂缓，进入硕士毕业线：%s。" % _get_route_node_display_name(ROUTE_STATE.POST_MIDTERM_STANDARD_BOSS))
			_enter_current_route_node()
			return true
		_:
			return false


func _resolve_doctoral_route_after_event_choice(event_id: StringName) -> bool:
	if route == null:
		return false
	if event_id == ROUTE_STATE.POST_DOCTOR2_FUNDING_EVENT:
		var funding_advanced: bool = route.advance_to_node(ROUTE_STATE.POST_FUNDING_PROJECT_BOSS, encounters, events, bosses)
		if not funding_advanced:
			_append_log("项目中期检查节点缺失，当前博士线暂时结算。")
			return false

		_append_log("基金申请窗口处理完毕，进入项目中期检查：%s。" % _get_route_node_display_name(ROUTE_STATE.POST_FUNDING_PROJECT_BOSS))
		_enter_current_route_node()
		return true
	if event_id == ROUTE_STATE.POST_DOCTORAL_DELAY_REPAIR_EVENT:
		var repair_advanced: bool = route.advance_to_node(ROUTE_STATE.POST_DELAY_REPAIR_ENCOUNTER, encounters, events, bosses)
		if not repair_advanced:
			_append_log("返修长夜节点缺失，直接进入博士答辩延期结算。")
			return false

		_append_log("博四返修方向确定，进入返修长夜：%s。" % _get_route_node_display_name(ROUTE_STATE.POST_DELAY_REPAIR_ENCOUNTER))
		_enter_current_route_node()
		return true
	return false


func _snapshot_battle_state() -> Dictionary:
	if battle == null:
		return {}

	var tracked_resources: Dictionary = {}
	for resource_id: StringName in TRACKED_EVENT_RESOURCE_IDS:
		tracked_resources[resource_id] = battle.get_resource(resource_id)

	return {
		"vitality": battle.vitality,
		"progress": battle.progress,
		"block": battle.block,
		"resources": tracked_resources,
		"deck_counts": _count_ids(battle.deck_card_ids),
	}


func _format_event_result(before_state: Dictionary, after_state: Dictionary) -> String:
	var parts: Array[String] = []

	_append_delta(parts, "精力", int(after_state.get("vitality", 0)) - int(before_state.get("vitality", 0)))
	_append_delta(parts, "进度", int(after_state.get("progress", 0)) - int(before_state.get("progress", 0)))
	_append_delta(parts, "防护", int(after_state.get("block", 0)) - int(before_state.get("block", 0)))

	var before_resources: Dictionary = before_state.get("resources", {})
	var after_resources: Dictionary = after_state.get("resources", {})
	for resource_id: StringName in TRACKED_EVENT_RESOURCE_IDS:
		var delta := int(after_resources.get(resource_id, 0)) - int(before_resources.get(resource_id, 0))
		_append_delta(parts, _get_resource_display_name(resource_id), delta)

	var added_cards := _format_added_cards(before_state.get("deck_counts", {}), after_state.get("deck_counts", {}))
	if not added_cards.is_empty():
		parts.append("牌组新增：" + "、".join(added_cards))

	if parts.is_empty():
		return "没有明显变化。"
	return "；".join(parts) + "。"


func _append_delta(parts: Array[String], label: String, delta: int) -> void:
	if delta == 0:
		return

	var sign := "+"
	if delta < 0:
		sign = ""
	parts.append("%s %s%d" % [label, sign, delta])


func _format_added_cards(before_counts: Dictionary, after_counts: Dictionary) -> Array[String]:
	var added_cards: Array[String] = []
	var card_ids: Array[String] = []
	for raw_id: Variant in after_counts.keys():
		card_ids.append(String(raw_id))
	card_ids.sort()

	for raw_id: String in card_ids:
		var card_id := StringName(raw_id)
		var delta := int(after_counts.get(card_id, 0)) - int(before_counts.get(card_id, 0))
		if delta <= 0:
			continue

		var card_name := String(card_id)
		var card: Variant = cards.get(card_id)
		if card != null:
			card_name = card.display_name
		if delta == 1:
			added_cards.append(card_name)
		else:
			added_cards.append("%s x%d" % [card_name, delta])

	return added_cards


func _count_ids(ids: Array[StringName]) -> Dictionary:
	var counts: Dictionary = {}
	for id: StringName in ids:
		counts[id] = int(counts.get(id, 0)) + 1
	return counts


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


func _is_event_choice_available(choice: EventChoiceDefinition) -> bool:
	if choice == null:
		return false
	if battle == null:
		return false

	match choice.requirement:
		&"", &"always":
			return true
		&"has_1_reputation":
			return battle.get_resource(&"reputation") >= 1
		&"has_2_draft":
			return battle.get_resource(&"draft") >= 2
		&"has_2_inspiration":
			return battle.get_resource(&"inspiration") >= 2
		&"has_2_reputation":
			return battle.get_resource(&"reputation") >= 2
		&"has_3_methodology_notes":
			return battle.get_resource(&"methodology_notes") >= 3
		&"has_2_paper_fragments":
			return battle.get_resource(&"paper_fragments") >= 2
		&"has_4_draft":
			return battle.get_resource(&"draft") >= 4
		&"has_2_reputation_or_4_draft":
			return battle.get_resource(&"reputation") >= 2 or battle.get_resource(&"draft") >= 4
		&"has_3_methodology_notes_or_2_paper_fragments":
			return battle.get_resource(&"methodology_notes") >= 3 or battle.get_resource(&"paper_fragments") >= 2
		&"has_2_funds":
			return battle.get_resource(&"funds") >= 2
		_:
			return false


func _select_reward(card_id: StringName) -> bool:
	if battle == null or reward_taken:
		return false
	if not reward_options.has(card_id):
		return false

	if battle.is_boss_encounter:
		return _select_boss_reward(card_id)

	var card: Variant = cards.get(card_id)
	var added: bool = battle.add_card_to_deck(card_id, true)
	if not added:
		return false

	reward_taken = true
	var completed_node_id: StringName = &""
	if route != null:
		completed_node_id = route.get_current_node_id()
		route.complete_current_node()
	reward_options.clear()
	if card != null:
		_append_log("获得奖励：%s。" % card.display_name)
	else:
		_append_log("获得奖励：%s。" % card_id)
	if route != null and _resolve_doctoral_route_after_reward(completed_node_id):
		return true
	if route != null and not route.has_next_node():
		_complete_run(&"route_completed")
	_refresh_ui()
	return true


func _resolve_doctoral_route_after_reward(completed_node_id: StringName) -> bool:
	if route == null:
		return false
	var next_node_id: StringName = &""
	var log_text := ""
	if completed_node_id == ROUTE_STATE.POST_TRANSFER_FIRST_ENCOUNTER:
		next_node_id = ROUTE_STATE.POST_TRANSFER_QUALIFICATION_BOSS
		log_text = "博一开题重构完成，进入博士资格考核：%s。"
	elif completed_node_id == ROUTE_STATE.POST_QUALIFICATION_FIRST_ENCOUNTER:
		next_node_id = ROUTE_STATE.POST_DOCTOR2_FUNDING_EVENT
		log_text = "项目推进压力处理完毕，进入基金申请窗口：%s。"
	elif completed_node_id == ROUTE_STATE.POST_PROJECT_MIDTERM_FIRST_ENCOUNTER:
		next_node_id = ROUTE_STATE.POST_PREDEFENSE_BOSS
		log_text = "预答辩筹备完成，进入博士预答辩：%s。"
	elif completed_node_id == ROUTE_STATE.POST_DELAY_REPAIR_ENCOUNTER:
		next_node_id = ROUTE_STATE.POST_SUPPLEMENTARY_DEFENSE_BOSS
		log_text = "返修长夜完成，进入补答辩：%s。"
	else:
		return false

	var advanced: bool = route.advance_to_node(next_node_id, encounters, events, bosses)
	if not advanced:
		_append_log("博士线后续节点缺失，当前博士线暂时结算。")
		return false

	_append_log(log_text % _get_route_node_display_name(next_node_id))
	_enter_current_route_node()
	return true


func _select_boss_reward(reward_id: StringName) -> bool:
	if not _is_boss_reward_available(reward_id):
		_append_log("毕业结局条件不足：%s。" % _get_boss_reward_result_label(reward_id))
		_refresh_ui()
		return false

	match reward_id:
		BOSS_REWARD_DIRECTION:
			battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 2
			last_boss_reward_result_text = "%s：方法论笔记 +2。" % _get_boss_reward_result_label(reward_id)
		BOSS_REWARD_FEEDBACK:
			battle.resources[&"paper_fragments"] = battle.get_resource(&"paper_fragments") + 1
			battle.resources[&"experience_lessons"] = battle.get_resource(&"experience_lessons") + 1
			last_boss_reward_result_text = "%s：论文碎片 +1，经验教训 +1。" % _get_boss_reward_result_label(reward_id)
		BOSS_REWARD_REMOVE_STATUS:
			_select_boss_cleanup_reward()
		B002_REWARD_ARCHIVE_MATERIALS:
			battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 1
			battle.resources[&"paper_fragments"] = battle.get_resource(&"paper_fragments") + 1
			last_boss_reward_result_text = "归档材料清单：方法论笔记 +1，论文碎片 +1。"
		B002_REWARD_REPLICATION_PROTOCOL:
			var added: bool = battle.add_card_to_deck(&"C013", true)
			if added:
				last_boss_reward_result_text = "建立复现实验流程：获得 %s。" % _get_card_display_name(&"C013")
			else:
				battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 1
				last_boss_reward_result_text = "复现实验流程记录失败，改为方法论笔记 +1。"
		B002_REWARD_CLEANUP_NOISE:
			_select_boss_cleanup_reward()
		B004_REWARD_PROBLEM_CHAIN:
			battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 2
			battle.resources[&"paper_fragments"] = battle.get_resource(&"paper_fragments") + 1
			last_boss_reward_result_text = "确定博士问题链：方法论笔记 +2，论文碎片 +1。"
		B004_REWARD_COMMITTEE_BRIDGE:
			var b004_added: bool = battle.add_card_to_deck(&"C032", true)
			if b004_added:
				last_boss_reward_result_text = "建立委员会沟通：获得 %s。" % _get_card_display_name(&"C032")
			else:
				battle.resources[&"reputation"] = battle.get_resource(&"reputation") + 1
				last_boss_reward_result_text = "委员会沟通记录失败，改为声望 +1。"
		B004_REWARD_REMOVE_QUALIFICATION_NOISE:
			_select_boss_cleanup_reward()
		B005_REWARD_PROJECT_LEDGER:
			battle.resources[&"funds"] = battle.get_resource(&"funds") + 1
			battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 1
			battle.resources[&"paper_fragments"] = battle.get_resource(&"paper_fragments") + 1
			last_boss_reward_result_text = "项目台账归档：经费 +1，方法论笔记 +1，论文碎片 +1。"
		B005_REWARD_TIMELINE_PROTOCOL:
			var b005_added: bool = battle.add_card_to_deck(&"C034", true)
			if b005_added:
				last_boss_reward_result_text = "固化项目排期：获得 %s。" % _get_card_display_name(&"C034")
			else:
				battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 1
				last_boss_reward_result_text = "项目排期记录失败，改为方法论笔记 +1。"
		B005_REWARD_REMOVE_PROJECT_NOISE:
			_select_boss_cleanup_reward()
		B006_REWARD_DEFENSE_NARRATIVE:
			battle.resources[&"paper_fragments"] = battle.get_resource(&"paper_fragments") + 2
			battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 1
			last_boss_reward_result_text = "重排答辩叙事：论文碎片 +2，方法论笔记 +1。"
		B006_REWARD_REHEARSAL_ROUTINE:
			var b006_added: bool = battle.add_card_to_deck(&"C035", true)
			if b006_added:
				last_boss_reward_result_text = "固化答辩演练：获得 %s。" % _get_card_display_name(&"C035")
			else:
				battle.resources[&"reputation"] = battle.get_resource(&"reputation") + 1
				last_boss_reward_result_text = "答辩演练记录失败，改为声望 +1。"
		B006_REWARD_REMOVE_DEFENSE_NOISE:
			_select_boss_cleanup_reward()
		B008_REWARD_SUPPLEMENTARY_PASS:
			battle.resources[&"paper_fragments"] = battle.get_resource(&"paper_fragments") + 2
			battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 2
			last_boss_reward_result_text = "补答辩通过：论文碎片 +2，方法论笔记 +2。"
		B008_REWARD_REVISION_ARCHIVE:
			battle.resources[&"experience_lessons"] = battle.get_resource(&"experience_lessons") + 3
			battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 3
			last_boss_reward_result_text = "归档返修矩阵：经验教训 +3，方法论笔记 +3。"
		B008_REWARD_REHEARSAL_LEGACY:
			var b008_added: bool = battle.add_card_to_deck(&"C035", true)
			if b008_added:
				last_boss_reward_result_text = "带走补答辩演练：获得 %s。" % _get_card_display_name(&"C035")
			else:
				battle.resources[&"reputation"] = battle.get_resource(&"reputation") + 1
				last_boss_reward_result_text = "补答辩演练记录失败，改为声望 +1。"
		B003_ENDING_OUTSTANDING:
			last_boss_reward_result_text = "优秀毕业：论文质量、声望和状态都达到更高标准。"
		B003_ENDING_STANDARD:
			last_boss_reward_result_text = "顺利毕业：论文主线完整，完成硕士阶段。"
		B003_ENDING_NARROW:
			last_boss_reward_result_text = "擦线毕业：过程狼狈但成功收束，复盘价值更高。"
		B007_ENDING_OUTSTANDING:
			last_boss_reward_result_text = "优秀博士毕业：论文主线、答辩状态和学术认可都达到高质量标准。"
		B007_ENDING_STANDARD:
			last_boss_reward_result_text = "博士毕业：完成答辩，博士阶段正式收束。"
		B007_ENDING_DELAYED:
			last_boss_reward_result_text = "延毕后毕业：过程被拉长，但论文和答辩终于完成。"
		_:
			return false

	reward_taken = true
	var completed_node_id: StringName = &""
	if route != null:
		completed_node_id = route.get_current_node_id()
		route.complete_current_node()
	reward_options.clear()
	_append_log("Boss 奖励：%s" % last_boss_reward_result_text)
	var settlement_reason: StringName = _get_boss_reward_settlement_reason(reward_id)
	if settlement_reason != &"route_completed":
		_complete_run(settlement_reason)
		_refresh_ui()
		return true
	if route != null and _resolve_doctoral_route_after_boss_reward(completed_node_id):
		return true
	if route != null and not route.has_next_node():
		_complete_run(settlement_reason)
	_refresh_ui()
	return true


func _resolve_doctoral_route_after_boss_reward(completed_node_id: StringName) -> bool:
	if route == null:
		return false
	var next_node_id: StringName = &""
	var log_text := ""
	if completed_node_id == ROUTE_STATE.POST_TRANSFER_QUALIFICATION_BOSS:
		next_node_id = ROUTE_STATE.POST_QUALIFICATION_FIRST_ENCOUNTER
		log_text = "博士资格考核通过，进入博二项目推进：%s。"
	elif completed_node_id == ROUTE_STATE.POST_FUNDING_PROJECT_BOSS:
		next_node_id = ROUTE_STATE.POST_PROJECT_MIDTERM_FIRST_ENCOUNTER
		log_text = "项目中期检查通过，进入博三预答辩筹备：%s。"
	elif completed_node_id == ROUTE_STATE.POST_PREDEFENSE_BOSS:
		next_node_id = ROUTE_STATE.POST_DOCTORAL_DEFENSE_BOSS
		log_text = "博士预答辩通过，进入博士答辩：%s。"
	else:
		return false

	var advanced: bool = route.advance_to_node(next_node_id, encounters, events, bosses)
	if not advanced:
		_append_log("博士线后续节点缺失，当前博士线暂时结算。")
		return false

	_append_log(log_text % _get_route_node_display_name(next_node_id))
	_enter_current_route_node()
	return true


func _select_boss_cleanup_reward() -> void:
	var removed_card_id: StringName = &""
	var removed: int = 0
	for candidate_id: StringName in _get_boss_reward_remove_candidates():
		removed_card_id = candidate_id
		removed = battle.remove_card_everywhere(removed_card_id, 1)
		if removed > 0:
			break
	if removed > 0:
		last_boss_reward_result_text = "删除负面牌：移除 %s。" % _get_card_display_name(removed_card_id)
	else:
		battle.resources[&"methodology_notes"] = battle.get_resource(&"methodology_notes") + 1
		last_boss_reward_result_text = "没有可删除的指定负面牌，改为方法论笔记 +1。"


func _get_failure_settlement_reason() -> StringName:
	if battle != null and bool(battle.is_boss_encounter) and battle.boss_definition != null:
		var failure_result: StringName = battle.boss_definition.failure_result
		if failure_result != &"":
			return failure_result
	return &"burnout"


func _format_boss_reward_button_text(reward_id: StringName) -> String:
	match reward_id:
		BOSS_REWARD_DIRECTION:
			return "%s\n局外资源\n方法论笔记 +2" % _get_boss_reward_result_label(reward_id)
		BOSS_REWARD_FEEDBACK:
			return "%s\n局外资源\n论文碎片 +1，经验教训 +1" % _get_boss_reward_result_label(reward_id)
		BOSS_REWARD_REMOVE_STATUS:
			return "%s\n牌组净化\n%s" % [_get_boss_reward_result_label(reward_id), _format_boss_reward_remove_summary()]
		B002_REWARD_ARCHIVE_MATERIALS:
			return "归档材料清单\n局外资源\n方法论笔记 +1，论文碎片 +1"
		B002_REWARD_REPLICATION_PROTOCOL:
			return "建立复现实验流程\n牌组构筑\n获得 1 张复现实验"
		B002_REWARD_CLEANUP_NOISE:
			return "清理实验噪音\n牌组净化\n%s" % _format_boss_reward_remove_summary()
		B004_REWARD_PROBLEM_CHAIN:
			return "确定博士问题链\n局外资源\n方法论笔记 +2，论文碎片 +1"
		B004_REWARD_COMMITTEE_BRIDGE:
			return "建立委员会沟通\n牌组构筑\n获得 1 张委员会沟通"
		B004_REWARD_REMOVE_QUALIFICATION_NOISE:
			return "删去资格焦虑\n牌组净化\n%s" % _format_boss_reward_remove_summary()
		B005_REWARD_PROJECT_LEDGER:
			return "项目台账归档\n局内/局外资源\n经费 +1，方法论笔记 +1，论文碎片 +1"
		B005_REWARD_TIMELINE_PROTOCOL:
			return "固化项目排期\n牌组构筑\n获得 1 张项目排期表"
		B005_REWARD_REMOVE_PROJECT_NOISE:
			return "清理项目噪音\n牌组净化\n%s" % _format_boss_reward_remove_summary()
		B006_REWARD_DEFENSE_NARRATIVE:
			return "重排答辩叙事\n局外资源\n论文碎片 +2，方法论笔记 +1"
		B006_REWARD_REHEARSAL_ROUTINE:
			return "固化答辩演练\n牌组构筑\n获得 1 张预答辩演练"
		B006_REWARD_REMOVE_DEFENSE_NOISE:
			return "清理答辩噪音\n牌组净化\n%s" % _format_boss_reward_remove_summary()
		B008_REWARD_SUPPLEMENTARY_PASS:
			return "补答辩通过\n延毕后毕业\n论文碎片 +2，方法论笔记 +2"
		B008_REWARD_REVISION_ARCHIVE:
			return "归档返修矩阵\n延毕后毕业\n经验教训 +3，方法论笔记 +3"
		B008_REWARD_REHEARSAL_LEGACY:
			return "带走补答辩演练\n延毕后毕业\n获得 1 张预答辩演练"
		B003_ENDING_OUTSTANDING:
			return "优秀毕业\n结局\n需要精力 20+ 且声望 2+"
		B003_ENDING_STANDARD:
			return "顺利毕业\n结局\n需要精力 10+，且声望或草稿达标"
		B003_ENDING_NARROW:
			return "擦线毕业\n结局\n始终可选，复盘资源更多"
		B007_ENDING_OUTSTANDING:
			return "优秀博士毕业\n结局\n需要精力 20+、声望 2+、论文碎片 4+、方法论笔记 4+"
		B007_ENDING_STANDARD:
			return "博士毕业\n结局\n需要精力 10+，且论文碎片或声望达标"
		B007_ENDING_DELAYED:
			return "延毕后毕业\n结局\n始终可选，复盘和韧性更多"
		_:
			return String(reward_id)


func _format_boss_reward_tooltip(reward_id: StringName) -> String:
	match reward_id:
		BOSS_REWARD_DIRECTION:
			return "把本次考核暴露出的方向和方法问题沉淀成方法论笔记。"
		BOSS_REWARD_FEEDBACK:
			return "把专家反馈整理成下局也能使用的论文经验。"
		BOSS_REWARD_REMOVE_STATUS:
			return "优先移除本 Boss 相关的负面牌。"
		B002_REWARD_ARCHIVE_MATERIALS:
			return "把中期材料整理成方法论笔记和论文碎片。"
		B002_REWARD_REPLICATION_PROTOCOL:
			return "把中期后的实验流程沉淀成复现实验牌。"
		B002_REWARD_CLEANUP_NOISE:
			return "优先移除恍惚、焦虑或拖延。"
		B004_REWARD_PROBLEM_CHAIN:
			return "把资格考核暴露的问题链沉淀成方法论笔记和论文碎片。"
		B004_REWARD_COMMITTEE_BRIDGE:
			return "把资格考核后的委员会沟通固化成博士线合作牌。"
		B004_REWARD_REMOVE_QUALIFICATION_NOISE:
			return "优先移除资格考核相关的自我怀疑、焦虑或信息过载。"
		B005_REWARD_PROJECT_LEDGER:
			return "把项目中期检查沉淀成经费、方法和论文管线资源。"
		B005_REWARD_TIMELINE_PROTOCOL:
			return "把项目推进节奏固化成项目排期表。"
		B005_REWARD_REMOVE_PROJECT_NOISE:
			return "优先移除项目推进中累积的信息过载、恍惚或焦虑。"
		B006_REWARD_DEFENSE_NARRATIVE:
			return "把预答辩意见整理成更完整的论文叙事和方法复盘。"
		B006_REWARD_REHEARSAL_ROUTINE:
			return "把预答辩前的演练流程固化成可加入牌组的答辩牌。"
		B006_REWARD_REMOVE_DEFENSE_NOISE:
			return "优先移除答辩阶段相关的自我怀疑、信息过载或焦虑。"
		B008_REWARD_SUPPLEMENTARY_PASS:
			return "补答辩完成后，把最终修改沉淀成论文碎片和方法论笔记。"
		B008_REWARD_REVISION_ARCHIVE:
			return "把延毕期间的返修矩阵归档成下一局也能复用的经验和方法。"
		B008_REWARD_REHEARSAL_LEGACY:
			return "把补答辩演练流程带进后续旅程，作为延毕后的稳定表达能力。"
		B003_ENDING_OUTSTANDING:
			return "需要精力至少 20，且声望至少 2。获得更高质量的毕业结算。"
		B003_ENDING_STANDARD:
			return "需要精力至少 10，且声望至少 1 或草稿至少 4。完成稳定的硕士毕业结算。"
		B003_ENDING_NARROW:
			return "始终可选。毕业成功，但结算更偏向经验教训和心理韧性。"
		B007_ENDING_OUTSTANDING:
			return "需要精力至少 20、声望至少 2、论文碎片至少 4、方法论笔记至少 4。获得最高质量的博士毕业结算。"
		B007_ENDING_STANDARD:
			return "需要精力至少 10，且论文碎片至少 3 或声望至少 1。完成稳定的博士毕业结算。"
		B007_ENDING_DELAYED:
			return "始终可选。博士毕业成功，但结算更偏向延毕复盘和心理韧性。"
		_:
			return String(reward_id)


func _get_boss_reward_result_label(reward_id: StringName) -> String:
	var boss_id: StringName = battle.encounter_id if battle != null else &""
	match reward_id:
		BOSS_REWARD_DIRECTION:
			if boss_id == &"B007":
				return "凝练答辩结论"
			if boss_id == &"B006":
				return "重排答辩叙事"
			if boss_id == &"B005":
				return "校准项目路线"
			if boss_id == &"B004":
				return "确定博士问题链"
			if boss_id == &"B003":
				return "凝练毕业主线"
			if boss_id == &"B002":
				return "补齐材料清单"
			return "确定研究方向"
		BOSS_REWARD_FEEDBACK:
			if boss_id == &"B007":
				return "归档答辩意见"
			if boss_id == &"B006":
				return "整理预答辩意见"
			if boss_id == &"B005":
				return "整理项目中期意见"
			if boss_id == &"B004":
				return "整理资格考核意见"
			if boss_id == &"B003":
				return "整理盲审意见"
			if boss_id == &"B002":
				return "整理中期反馈"
			return "整理开题反馈"
		BOSS_REWARD_REMOVE_STATUS:
			if boss_id == &"B007":
				return "清理毕业噪音"
			if boss_id == &"B006":
				return "清理答辩噪音"
			if boss_id == &"B005":
				return "清理项目噪音"
			if boss_id == &"B004":
				return "删去资格焦虑"
			if boss_id == &"B003":
				return "删去格式噪音"
			if boss_id == &"B002":
				return "清理实验噪音"
			return "删去质疑噪音"
		B002_REWARD_ARCHIVE_MATERIALS:
			return "归档材料清单"
		B002_REWARD_REPLICATION_PROTOCOL:
			return "建立复现实验流程"
		B002_REWARD_CLEANUP_NOISE:
			return "清理实验噪音"
		B004_REWARD_PROBLEM_CHAIN:
			return "确定博士问题链"
		B004_REWARD_COMMITTEE_BRIDGE:
			return "建立委员会沟通"
		B004_REWARD_REMOVE_QUALIFICATION_NOISE:
			return "删去资格焦虑"
		B005_REWARD_PROJECT_LEDGER:
			return "项目台账归档"
		B005_REWARD_TIMELINE_PROTOCOL:
			return "固化项目排期"
		B005_REWARD_REMOVE_PROJECT_NOISE:
			return "清理项目噪音"
		B006_REWARD_DEFENSE_NARRATIVE:
			return "重排答辩叙事"
		B006_REWARD_REHEARSAL_ROUTINE:
			return "固化答辩演练"
		B006_REWARD_REMOVE_DEFENSE_NOISE:
			return "清理答辩噪音"
		B008_REWARD_SUPPLEMENTARY_PASS:
			return "补答辩通过"
		B008_REWARD_REVISION_ARCHIVE:
			return "归档返修矩阵"
		B008_REWARD_REHEARSAL_LEGACY:
			return "带走补答辩演练"
		B003_ENDING_OUTSTANDING:
			return "优秀毕业"
		B003_ENDING_STANDARD:
			return "顺利毕业"
		B003_ENDING_NARROW:
			return "擦线毕业"
		B007_ENDING_OUTSTANDING:
			return "优秀博士毕业"
		B007_ENDING_STANDARD:
			return "博士毕业"
		B007_ENDING_DELAYED:
			return "延毕后毕业"
		_:
			return String(reward_id)


func _get_current_boss_reward_options() -> Array[StringName]:
	var boss_id: StringName = battle.encounter_id if battle != null else &""
	match boss_id:
		&"B002":
			return [
				B002_REWARD_ARCHIVE_MATERIALS,
				B002_REWARD_REPLICATION_PROTOCOL,
				B002_REWARD_CLEANUP_NOISE,
			]
		&"B003":
			return [
				B003_ENDING_OUTSTANDING,
				B003_ENDING_STANDARD,
				B003_ENDING_NARROW,
			]
		&"B004":
			return [
				B004_REWARD_PROBLEM_CHAIN,
				B004_REWARD_COMMITTEE_BRIDGE,
				B004_REWARD_REMOVE_QUALIFICATION_NOISE,
			]
		&"B005":
			return [
				B005_REWARD_PROJECT_LEDGER,
				B005_REWARD_TIMELINE_PROTOCOL,
				B005_REWARD_REMOVE_PROJECT_NOISE,
			]
		&"B006":
			return [
				B006_REWARD_DEFENSE_NARRATIVE,
				B006_REWARD_REHEARSAL_ROUTINE,
				B006_REWARD_REMOVE_DEFENSE_NOISE,
			]
		&"B007":
			return [
				B007_ENDING_OUTSTANDING,
				B007_ENDING_STANDARD,
				B007_ENDING_DELAYED,
			]
		&"B008":
			return [
				B008_REWARD_SUPPLEMENTARY_PASS,
				B008_REWARD_REVISION_ARCHIVE,
				B008_REWARD_REHEARSAL_LEGACY,
			]
		_:
			return [
				BOSS_REWARD_DIRECTION,
				BOSS_REWARD_FEEDBACK,
				BOSS_REWARD_REMOVE_STATUS,
			]


func _get_boss_reward_remove_candidates() -> Array[StringName]:
	var boss_id: StringName = battle.encounter_id if battle != null else &""
	match boss_id:
		&"B002":
			return [&"S005", &"S002", &"S001"]
		&"B003":
			return [&"S004", &"S010", &"S002", &"S001", &"S005"]
		&"B004":
			return [&"S010", &"S002", &"S004", &"S001", &"S005"]
		&"B005":
			return [&"S004", &"S005", &"S002", &"S001", &"S010"]
		&"B006":
			return [&"S010", &"S004", &"S002", &"S001", &"S005"]
		&"B007":
			return [&"S010", &"S002", &"S004", &"S001", &"S005"]
		_:
			return [&"S010", &"S004", &"S005", &"S002", &"S001"]


func _is_boss_reward_available(reward_id: StringName) -> bool:
	match reward_id:
		B003_ENDING_OUTSTANDING:
			return battle != null and battle.vitality >= 20 and battle.get_resource(&"reputation") >= 2
		B003_ENDING_STANDARD:
			return battle != null and battle.vitality >= 10 and (battle.get_resource(&"reputation") >= 1 or battle.get_resource(&"draft") >= 4)
		B003_ENDING_NARROW:
			return true
		B007_ENDING_OUTSTANDING:
			return battle != null and battle.vitality >= 20 and battle.get_resource(&"reputation") >= 2 and battle.get_resource(&"paper_fragments") >= 4 and battle.get_resource(&"methodology_notes") >= 4
		B007_ENDING_STANDARD:
			return battle != null and battle.vitality >= 10 and (battle.get_resource(&"paper_fragments") >= 3 or battle.get_resource(&"reputation") >= 1)
		B007_ENDING_DELAYED:
			return true
		_:
			return true


func _get_boss_reward_settlement_reason(reward_id: StringName) -> StringName:
	match reward_id:
		B003_ENDING_OUTSTANDING:
			return &"outstanding_graduation"
		B003_ENDING_STANDARD:
			return &"master_graduated"
		B003_ENDING_NARROW:
			return &"narrow_graduation"
		B007_ENDING_OUTSTANDING:
			return &"outstanding_doctoral_graduation"
		B007_ENDING_STANDARD:
			return &"doctoral_graduated"
		B007_ENDING_DELAYED:
			return &"delayed_doctoral_graduation"
		B008_REWARD_SUPPLEMENTARY_PASS, B008_REWARD_REVISION_ARCHIVE, B008_REWARD_REHEARSAL_LEGACY:
			return &"delayed_doctoral_graduation"
		_:
			return &"route_completed"


func _format_boss_reward_remove_summary() -> String:
	var names: Array[String] = []
	for card_id: StringName in _get_boss_reward_remove_candidates():
		names.append(_get_card_display_name(card_id))
	if names.is_empty():
		return "移除 1 张负面牌"
	return "移除 1 张%s" % "或".join(names)


func _get_card_display_name(card_id: StringName) -> String:
	var card: Variant = cards.get(card_id)
	if card != null:
		return card.display_name
	return String(card_id)


func _complete_run(reason: StringName) -> void:
	if not settlement.is_empty():
		return

	settlement = RUN_SETTLEMENT.build(route, battle, reason)
	settlement["run_seed"] = run_seed
	_apply_settlement_to_meta_progression()
	if reason == &"burnout":
		_append_log("精力归零，进入阶段结算。")
	elif reason == &"proposal_delayed":
		_append_log("开题延期，进入阶段结算。")
	elif reason == &"midterm_warning":
		_append_log("中期预警，进入阶段结算。")
	elif reason == &"blind_review_failed":
		_append_log("盲审未过，进入阶段结算。")
	elif reason == &"master_graduated":
		_append_log("顺利毕业，进入阶段结算。")
	elif reason == &"outstanding_graduation":
		_append_log("优秀毕业，进入阶段结算。")
	elif reason == &"narrow_graduation":
		_append_log("擦线毕业，进入阶段结算。")
	elif reason == &"outstanding_doctoral_graduation":
		_append_log("博士答辩高质量通过，进入优秀博士毕业结算。")
	elif reason == &"doctoral_graduated":
		_append_log("博士答辩通过，进入博士毕业结算。")
	elif reason == &"delayed_doctoral_graduation":
		_append_log("博士答辩通过，进入延毕后毕业结算。")
	elif reason == &"transfer_admitted":
		_append_log("转博资格确认，进入阶段结算。")
	elif reason == &"qualification_failed":
		_append_log("博士资格考核未过，进入阶段结算。")
	elif reason == &"project_midterm_failed":
		_append_log("项目中期检查未过，进入阶段结算。")
	elif reason == &"predefense_failed":
		_append_log("博士预答辩未过，进入阶段结算。")
	elif reason == &"doctoral_defense_delayed":
		_append_log("博士答辩延期，进入延毕复盘结算。")
	elif reason == &"supplementary_defense_failed":
		_append_log("补答辩再延期，进入延毕复盘结算。")
	elif reason == &"route_completed":
		_append_log("路线完成，进入阶段结算。")
	else:
		_append_log("进入阶段结算。")


func _apply_settlement_to_meta_progression() -> void:
	meta_progression = META_PROGRESSION.new()
	settlement_save = meta_progression.apply_settlement(settlement, meta_save_path)
	var save_error := int(settlement_save.get("save_error", ERR_CANT_CREATE))
	if save_error == OK:
		_append_log("局外资源已存档。")
		var new_unlocks: Array = settlement_save.get("new_unlocks", [])
		if not new_unlocks.is_empty():
			var unlock_names: Array[String] = []
			for raw_unlock: Variant in new_unlocks:
				unlock_names.append(String(raw_unlock))
			_append_log("获得新解锁：%s。" % ", ".join(unlock_names))
	else:
		_append_log("局外资源存档失败：%s。" % error_string(save_error))


func _on_end_turn_pressed() -> void:
	end_current_turn()


func _on_next_node_pressed() -> void:
	start_next_node()


func _on_clear_test_save_pressed() -> void:
	var clearer = META_PROGRESSION.new()
	last_clear_save_result = clearer.clear_save(meta_save_path, false)
	var clear_error := int(last_clear_save_result.get("clear_error", ERR_UNAUTHORIZED))
	_append_log(String(last_clear_save_result.get("summary_text", "")))
	if clear_error == OK:
		start_new_battle()
	else:
		_refresh_ui()


func _on_restart_pressed() -> void:
	start_new_battle()


func _on_copy_seed_pressed() -> void:
	var seed_text := str(run_seed)
	DisplayServer.clipboard_set(seed_text)
	if seed_input != null:
		seed_input.text = seed_text
	_append_log("已复制 Seed：%s。" % seed_text)


func _on_restart_with_seed_pressed() -> void:
	if seed_input == null:
		return
	var seed_text := seed_input.text.strip_edges()
	if not seed_text.is_valid_int():
		_append_log("Seed 无效：请输入整数。")
		return
	var requested_seed: int = max(1, int(seed_text))
	start_new_battle_with_seed(requested_seed)


func _append_log(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > 20:
		log_lines.remove_at(0)
	if log_box != null:
		log_box.text = "\n".join(log_lines)
		log_box.set_caret_line(max(0, log_box.get_line_count() - 1))
