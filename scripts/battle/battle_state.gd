@tool
extends RefCounted
class_name BattleState

const STARTING_VITALITY := 50
const STARTING_ACTION_POINTS := 3
const STARTING_HAND_SIZE := 5
const RUN_PERSISTENT_RESOURCE_IDS := [
	&"reputation",
	&"experience_lessons",
	&"methodology_notes",
	&"paper_fragments",
	&"funds",
]

var max_vitality: int = STARTING_VITALITY
var vitality: int = STARTING_VITALITY
var base_action_points: int = STARTING_ACTION_POINTS
var action_points: int = 0
var hand_size: int = STARTING_HAND_SIZE
var block: int = 0
var progress: int = 0
var turn: int = 0
var target_progress: int = 40
var pressure_per_turn: int = 6
var encounter_id: StringName = &""
var encounter_name: String = "普通压力"
var encounter_description: String = ""
var intent_name: String = "赶进度"
var is_boss_encounter: bool = false
var boss_definition: Variant = null
var boss_phase_triggered: bool = false

var resources: Dictionary = {
	&"inspiration": 0,
	&"data": 0,
	&"draft": 0,
	&"funds": 0,
	&"reputation": 0,
	&"experience_lessons": 0,
	&"methodology_notes": 0,
	&"paper_fragments": 0,
}

var cards_by_id: Dictionary = {}
var deck_card_ids: Array[StringName] = []
var draw_pile: Array[StringName] = []
var hand: Array[StringName] = []
var discard_pile: Array[StringName] = []
var exhaust_pile: Array[StringName] = []
var event_log: Array[String] = []
var pending_discoveries: Array[Dictionary] = []
var resource_gains_this_battle: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _next_progress_modifier: int = 0
var _next_tag_progress_modifiers: Dictionary = {}
var _played_tags_this_turn: Dictionary = {}
var _played_tags_last_turn: Dictionary = {}
var _victory_logged: bool = false


func setup(card_catalog: Dictionary, deck: Variant, seed: int = 1) -> void:
	cards_by_id = card_catalog
	deck_card_ids.clear()
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	event_log.clear()
	pending_discoveries.clear()
	_reset_resources(false)
	_reset_resource_gains_this_battle()

	for raw_card_id in deck.card_ids:
		var card_id := StringName(raw_card_id)
		deck_card_ids.append(card_id)
		draw_pile.append(card_id)

	_rng.seed = seed
	_shuffle(draw_pile)
	_log("setup deck=%s cards=%d" % [deck.id, draw_pile.size()])


func set_encounter(encounter: Variant) -> void:
	is_boss_encounter = false
	boss_definition = null
	boss_phase_triggered = false
	if encounter == null:
		encounter_id = &""
		encounter_name = "普通压力"
		encounter_description = ""
		target_progress = 40
		pressure_per_turn = 6
		intent_name = "赶进度"
		return

	encounter_id = encounter.id
	encounter_name = encounter.display_name
	encounter_description = encounter.description
	target_progress = encounter.target_progress
	pressure_per_turn = encounter.pressure_per_turn
	intent_name = encounter.intent_name
	_log("encounter id=%s target=%d pressure=%d" % [encounter_id, target_progress, pressure_per_turn])


func set_boss(boss: Variant) -> void:
	is_boss_encounter = boss != null
	boss_definition = boss
	boss_phase_triggered = false
	if boss == null:
		set_encounter(null)
		return

	encounter_id = boss.id
	encounter_name = boss.display_name
	encounter_description = "阶段 Boss：通过这场考核才能完成当前阶段。"
	target_progress = boss.target_progress
	pressure_per_turn = 0
	intent_name = "考核追问"
	_log("boss id=%s target=%d intents=%d" % [encounter_id, target_progress, boss.intents.size()])


func start_battle() -> void:
	vitality = max_vitality
	action_points = 0
	block = 0
	progress = 0
	turn = 0
	_next_progress_modifier = 0
	_next_tag_progress_modifiers.clear()
	_played_tags_this_turn.clear()
	_played_tags_last_turn.clear()
	_victory_logged = false
	boss_phase_triggered = false
	_reset_resources(false)
	_reset_resource_gains_this_battle()
	start_turn()


func start_next_encounter(encounter: Variant, seed: int = 1, preserve_vitality: bool = true) -> void:
	var saved_vitality: int = vitality
	set_encounter(encounter)
	_rng.seed = seed
	_rebuild_draw_pile_from_deck()
	action_points = 0
	block = 0
	progress = 0
	turn = 0
	_next_progress_modifier = 0
	_next_tag_progress_modifiers.clear()
	_played_tags_this_turn.clear()
	_played_tags_last_turn.clear()
	_victory_logged = false
	_reset_resources(true)
	_reset_resource_gains_this_battle()
	if preserve_vitality:
		vitality = clamp(saved_vitality, 0, max_vitality)
	else:
		vitality = max_vitality
	_log("next_encounter id=%s deck=%d vitality=%d" % [encounter_id, deck_card_ids.size(), vitality])
	start_turn()


func start_next_boss(boss: Variant, seed: int = 1, preserve_vitality: bool = true) -> void:
	var saved_vitality: int = vitality
	set_boss(boss)
	_rng.seed = seed
	_rebuild_draw_pile_from_deck()
	action_points = 0
	block = 0
	progress = 0
	turn = 0
	_next_progress_modifier = 0
	_next_tag_progress_modifiers.clear()
	_played_tags_this_turn.clear()
	_played_tags_last_turn.clear()
	_victory_logged = false
	boss_phase_triggered = false
	_reset_resources(true)
	_reset_resource_gains_this_battle()
	if preserve_vitality:
		vitality = clamp(saved_vitality, 0, max_vitality)
	else:
		vitality = max_vitality
	_apply_boss_starting_rules()
	_log("next_boss id=%s deck=%d vitality=%d" % [encounter_id, deck_card_ids.size(), vitality])
	start_turn()


func start_turn() -> void:
	turn += 1
	action_points = base_action_points
	block = 0
	_played_tags_this_turn.clear()
	draw_cards(hand_size)
	_log("start_turn turn=%d hand=%d draw=%d discard=%d" % [turn, hand.size(), draw_pile.size(), discard_pile.size()])


func end_turn() -> void:
	_apply_end_turn_statuses()
	while not hand.is_empty():
		discard_pile.append(hand.pop_front())
	action_points = 0
	_played_tags_last_turn = _played_tags_this_turn.duplicate()
	_log("end_turn turn=%d discard=%d" % [turn, discard_pile.size()])


func draw_cards(amount: int) -> void:
	for _i in range(amount):
		if draw_pile.is_empty():
			_refill_draw_pile()

		if draw_pile.is_empty():
			return

		var card_id: StringName = draw_pile.pop_front()
		hand.append(card_id)
		_apply_on_draw_status(card_id)


func play_card_by_index(hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= hand.size():
		_log("play_failed invalid_index=%d" % hand_index)
		return false

	var card_id: StringName = hand[hand_index]
	return play_card(card_id)


func play_card(card_id: StringName) -> bool:
	var hand_index: int = hand.find(card_id)
	if hand_index == -1:
		_log("play_failed not_in_hand=%s" % card_id)
		return false

	var card: Variant = cards_by_id.get(card_id)
	if card == null:
		_log("play_failed missing_card=%s" % card_id)
		return false

	if card.cost < 0:
		_log("play_failed unplayable=%s" % card_id)
		return false

	if action_points < card.cost:
		_log("play_failed no_ap=%s" % card_id)
		return false

	hand.remove_at(hand_index)
	action_points -= card.cost
	_register_played_tags(card.tags)
	_apply_effects(card.effects, card.tags)

	if card.exhausts or card.temporary:
		exhaust_pile.append(card_id)
	else:
		discard_pile.append(card_id)

	_log("played id=%s ap=%d progress=%d" % [card_id, action_points, progress])
	_log_victory_if_needed()
	return true


func add_card_to_deck(card_id: StringName, put_in_discard: bool = true) -> bool:
	if not cards_by_id.has(card_id):
		_log("reward_failed missing_card=%s" % card_id)
		return false

	deck_card_ids.append(card_id)
	if put_in_discard:
		discard_pile.append(card_id)
	else:
		draw_pile.append(card_id)
	_log("reward_added id=%s deck_size=%d" % [card_id, deck_card_ids.size()])
	return true


func add_card_to_starting_deck(card_id: StringName) -> bool:
	if not cards_by_id.has(card_id):
		_log("unlock_failed missing_card=%s" % card_id)
		return false
	if deck_card_ids.has(card_id):
		_log("unlock_skipped duplicate_card=%s" % card_id)
		return false

	deck_card_ids.append(card_id)
	draw_pile.append(card_id)
	_shuffle(draw_pile)
	_log("unlock_added id=%s deck_size=%d" % [card_id, deck_card_ids.size()])
	return true


func remove_card_everywhere(card_id: StringName, amount: int = 1) -> int:
	var deck_removed: int = _remove_from_array_without_exhaust(deck_card_ids, card_id, amount)
	var pile_removed: int = 0
	pile_removed += _remove_from_array_without_exhaust(hand, card_id, amount - pile_removed)
	pile_removed += _remove_from_array_without_exhaust(draw_pile, card_id, amount - pile_removed)
	pile_removed += _remove_from_array_without_exhaust(discard_pile, card_id, amount - pile_removed)
	pile_removed += _remove_from_array_without_exhaust(exhaust_pile, card_id, amount - pile_removed)
	var removed: int = max(deck_removed, pile_removed)
	if removed > 0:
		_log("removed_card id=%s amount=%d" % [card_id, removed])
	return removed


func apply_event_effects(effects: Array) -> void:
	_apply_effects(effects)


func is_victory() -> bool:
	return target_progress > 0 and progress >= target_progress


func get_enemy_intent_text() -> String:
	if is_victory():
		return "节点已通过"
	if is_boss_encounter:
		var boss_intent: Variant = _get_current_boss_intent()
		if boss_intent == null:
			return "考核追问"
		if boss_intent.pressure > 0:
			return "%s：造成 %d 压力" % [boss_intent.display_name, boss_intent.pressure]
		return boss_intent.display_name
	return "%s：造成 %d 压力" % [intent_name, pressure_per_turn]


func get_boss_readability_text() -> String:
	if not is_boss_encounter:
		return ""

	var lines: Array[String] = []
	var boss_intent: Variant = _get_current_boss_intent()
	if boss_intent != null:
		lines.append("当前意图：%s" % get_enemy_intent_text())
		var detail: String = _format_boss_intent_detail(boss_intent)
		if detail != "":
			lines.append(detail)

	var phase_hint: String = get_boss_phase_hint_text()
	if phase_hint != "":
		lines.append(phase_hint)

	var material_text: String = get_boss_material_checklist_text()
	if material_text != "":
		lines.append(material_text)

	return "\n".join(lines)


func get_boss_material_checklist_text() -> String:
	if not is_boss_encounter or boss_definition == null:
		return ""
	if boss_definition.id != &"B002":
		if boss_definition.id == &"B003":
			return "送审准备：声望 %d/2，草稿 %d/4，数据 %d/2。" % [
				min(2, get_resource(&"reputation")),
				min(4, get_resource(&"draft")),
				min(2, get_resource(&"data")),
			]
		if boss_definition.id == &"B004":
			return "资格材料：方法论笔记 %d/3，论文碎片 %d/2，草稿 %d/4。" % [
				min(3, get_resource(&"methodology_notes")),
				min(2, get_resource(&"paper_fragments")),
				min(4, get_resource(&"draft")),
			]
		if boss_definition.id == &"B005":
			return "项目材料：经费 %d/2，论文碎片 %d/2，本战数据 %d/2。" % [
				min(2, get_resource(&"funds")),
				min(2, get_resource(&"paper_fragments")),
				min(2, get_resource_gain_this_battle(&"data")),
			]
		if boss_definition.id == &"B006":
			return "预答辩材料：论文碎片 %d/3，声望 %d/2，方法论笔记 %d/3。" % [
				min(3, get_resource(&"paper_fragments")),
				min(2, get_resource(&"reputation")),
				min(3, get_resource(&"methodology_notes")),
			]
		if boss_definition.id == &"B007":
			return "答辩材料：论文碎片 %d/4，声望 %d/2，方法论笔记 %d/4。" % [
				min(4, get_resource(&"paper_fragments")),
				min(2, get_resource(&"reputation")),
				min(4, get_resource(&"methodology_notes")),
			]
		if boss_definition.id == &"B008":
			return "补答辩材料：方法论笔记 %d/3，论文碎片 %d/3，声望 %d/1。" % [
				min(3, get_resource(&"methodology_notes")),
				min(3, get_resource(&"paper_fragments")),
				min(1, get_resource(&"reputation")),
			]
		return ""
	return "材料清单：本战累计数据 %d/2，草稿 %d/3。" % [
		min(2, get_resource_gain_this_battle(&"data")),
		min(3, get_resource_gain_this_battle(&"draft")),
	]


func get_boss_phase_hint_text() -> String:
	if not is_boss_encounter or boss_definition == null:
		return ""
	if boss_definition.phase_trigger_progress <= 0:
		return ""

	var phase_name: String = _format_boss_phase_name()
	var condition_text: String = _format_condition_text(boss_definition.phase_condition)
	if boss_phase_triggered:
		return "%s已完成。" % phase_name

	var remaining: int = boss_definition.phase_trigger_progress - progress
	if remaining <= 0:
		return "%s即将触发：准备%s。" % [phase_name, condition_text]
	if remaining <= 12:
		return "%s临近：还差 %d 进度，准备%s。" % [phase_name, remaining, condition_text]
	return "%s：进度达到 %d 时，需要%s。" % [phase_name, boss_definition.phase_trigger_progress, condition_text]


func resolve_enemy_turn() -> Dictionary:
	if is_victory():
		_log_victory_if_needed()
		return {
			"pressure": 0,
			"vitality": vitality,
			"block": block,
			"victory": true,
		}

	if is_boss_encounter:
		return _resolve_boss_turn()

	take_pressure(pressure_per_turn)
	return {
		"pressure": pressure_per_turn,
		"vitality": vitality,
		"block": block,
		"victory": false,
	}


func take_pressure(amount: int) -> void:
	var remaining: int = amount
	if block > 0:
		var absorbed: int = min(block, remaining)
		block -= absorbed
		remaining -= absorbed

	if remaining > 0:
		vitality = max(0, vitality - remaining)

	_log("pressure amount=%d vitality=%d block=%d" % [amount, vitality, block])


func get_resource(resource_id: StringName) -> int:
	return int(resources.get(resource_id, 0))


func get_resource_gain_this_battle(resource_id: StringName) -> int:
	return int(resource_gains_this_battle.get(resource_id, 0))


func apply_prebattle_modifier(effect_id: StringName, amount: int, source_label: String = "") -> bool:
	if effect_id == &"" or amount <= 0:
		return false

	match effect_id:
		&"opening_draw":
			draw_cards(amount)
			_log("prebattle_modifier source=%s effect=opening_draw amount=%d hand=%d" % [source_label, amount, hand.size()])
			return true
		&"starting_block":
			block += amount
			_log("prebattle_modifier source=%s effect=starting_block amount=%d block=%d" % [source_label, amount, block])
			return true
		&"starting_progress":
			progress += amount
			_check_boss_phase_trigger()
			_log_victory_if_needed()
			_log("prebattle_modifier source=%s effect=starting_progress amount=%d progress=%d" % [source_label, amount, progress])
			return true
		&"first_turn_action_point":
			action_points += amount
			_log("prebattle_modifier source=%s effect=first_turn_action_point amount=%d ap=%d" % [source_label, amount, action_points])
			return true
		&"pressure_reduction":
			if is_boss_encounter:
				block += amount * 2
				_log("prebattle_modifier source=%s effect=boss_pressure_buffer amount=%d block=%d" % [source_label, amount, block])
			else:
				pressure_per_turn = max(0, pressure_per_turn - amount)
				_log("prebattle_modifier source=%s effect=pressure_reduction amount=%d pressure=%d" % [source_label, amount, pressure_per_turn])
			return true
		&"target_progress_reduction":
			target_progress = max(1, target_progress - amount)
			_log("prebattle_modifier source=%s effect=target_progress_reduction amount=%d target=%d" % [source_label, amount, target_progress])
			return true
		_:
			_log("unknown_prebattle_modifier=%s source=%s" % [effect_id, source_label])
			return false


func to_debug_dict() -> Dictionary:
	return {
		"turn": turn,
		"vitality": vitality,
		"action_points": action_points,
		"block": block,
		"progress": progress,
		"target_progress": target_progress,
		"pressure_per_turn": pressure_per_turn,
		"encounter_id": encounter_id,
		"encounter_name": encounter_name,
		"enemy_intent": get_enemy_intent_text(),
		"resources": resources.duplicate(),
		"resource_gains_this_battle": resource_gains_this_battle.duplicate(),
		"draw_pile": _stringify_ids(draw_pile),
		"hand": _stringify_ids(hand),
		"discard_pile": _stringify_ids(discard_pile),
		"exhaust_pile": _stringify_ids(exhaust_pile),
		"deck_card_ids": _stringify_ids(deck_card_ids),
		"pending_discoveries": pending_discoveries.duplicate(true),
		"event_log": event_log.duplicate(),
	}


func _apply_effects(effects: Array, source_tags: PackedStringArray = PackedStringArray()) -> void:
	for effect: Variant in effects:
		if effect == null:
			continue
		if not _condition_met(effect.condition):
			continue

		match effect.effect_type:
			&"gain_progress":
				var amount: int = int(effect.amount) + _next_progress_modifier + _consume_tag_progress_modifier(source_tags)
				_next_progress_modifier = 0
				progress += max(0, amount)
				_check_boss_phase_trigger()
				_log_victory_if_needed()
			&"gain_block":
				block += effect.amount
			&"draw":
				draw_cards(effect.amount)
			&"gain_resource":
				_gain_resource(effect.resource, effect.amount)
			&"lose_resource_or_energy":
				_lose_resource_or_energy(effect.resource, effect.amount)
			&"lose_energy":
				vitality = max(0, vitality - effect.amount)
			&"lose_action_point":
				action_points = max(0, action_points - effect.amount)
			&"remove_status":
				_remove_status(effect.target, effect.card_id, effect.amount)
			&"remove_status_by_tag":
				_remove_status_by_tag(effect.target, effect.tag_filter, effect.amount)
			&"discard":
				_discard_from_hand(effect.amount)
			&"discard_tag_from_hand":
				_discard_tag_from_hand(effect.tag_filter, effect.amount)
			&"modify_next_progress":
				_next_progress_modifier += effect.amount
			&"modify_next_tag_progress":
				_add_tag_progress_modifier(effect.tag_filter, effect.amount)
			&"discover":
				pending_discoveries.append({
					"amount": effect.amount,
					"tag_filter": effect.tag_filter,
					"target": effect.target,
				})
			&"add_card_to_deck":
				add_card_to_deck(effect.card_id, true)
			&"add_card_to_draw":
				if cards_by_id.has(effect.card_id):
					deck_card_ids.append(effect.card_id)
					draw_pile.append(effect.card_id)
					_shuffle(draw_pile)
				else:
					_log("event_add_failed missing_card=%s" % effect.card_id)
			&"add_card_to_hand":
				if cards_by_id.has(effect.card_id):
					deck_card_ids.append(effect.card_id)
					hand.append(effect.card_id)
				else:
					_log("event_add_failed missing_card=%s" % effect.card_id)
			&"modify_target_progress":
				target_progress = max(1, target_progress + effect.amount)
			_:
				_log("unknown_effect=%s" % effect.effect_type)


func _apply_on_draw_status(card_id: StringName) -> void:
	var card: Variant = cards_by_id.get(card_id)
	if card == null:
		return
	if card.card_type != &"status":
		return

	var immediate_effects: Array = []
	for effect: Variant in card.effects:
		if effect != null and effect.condition != &"end_turn":
			immediate_effects.append(effect)
	_apply_effects(immediate_effects)

	if card.exhausts and hand.has(card_id):
		hand.erase(card_id)
		exhaust_pile.append(card_id)


func _apply_end_turn_statuses() -> void:
	var effects_to_apply: Array = []
	for card_id: StringName in hand:
		var card: Variant = cards_by_id.get(card_id)
		if card == null or card.card_type != &"status":
			continue
		for effect: Variant in card.effects:
			if effect != null and effect.condition == &"end_turn":
				effects_to_apply.append(effect)
	_apply_effects(effects_to_apply)


func _gain_resource(resource_id: StringName, amount: int) -> void:
	if resource_id == &"energy" or resource_id == &"vitality":
		vitality = clamp(vitality + amount, 0, max_vitality)
		return

	resources[resource_id] = max(0, int(resources.get(resource_id, 0)) + amount)
	if amount > 0:
		resource_gains_this_battle[resource_id] = get_resource_gain_this_battle(resource_id) + amount


func _lose_resource_or_energy(resource_id: StringName, amount: int) -> void:
	if get_resource(resource_id) > 0:
		_gain_resource(resource_id, -amount)
	else:
		vitality = max(0, vitality - amount * 2)


func _condition_met(condition: StringName) -> bool:
	match condition:
		&"", &"always":
			return true
		&"has_inspiration":
			return get_resource(&"inspiration") > 0
		&"has_data":
			return get_resource(&"data") > 0
		&"no_data":
			return get_resource(&"data") <= 0
		&"has_experiment_noise_in_hand":
			return _has_status_card_with_tag(hand, &"experiment_noise")
		&"has_status_in_hand":
			return _has_status_card_with_tag(hand, &"status")
		&"has_draft":
			return get_resource(&"draft") > 0
		&"has_2_inspiration":
			return get_resource(&"inspiration") >= 2
		&"has_2_draft":
			return get_resource(&"draft") >= 2
		&"has_2_data":
			return get_resource(&"data") >= 2
		&"has_2_draft_or_2_data":
			return get_resource(&"draft") >= 2 or get_resource(&"data") >= 2
		&"has_3_draft":
			return get_resource(&"draft") >= 3
		&"has_4_draft":
			return get_resource(&"draft") >= 4
		&"has_2_reputation":
			return get_resource(&"reputation") >= 2
		&"has_1_reputation":
			return get_resource(&"reputation") >= 1
		&"has_2_funds":
			return get_resource(&"funds") >= 2
		&"has_funds":
			return get_resource(&"funds") > 0
		&"has_3_methodology_notes":
			return get_resource(&"methodology_notes") >= 3
		&"has_4_methodology_notes":
			return get_resource(&"methodology_notes") >= 4
		&"has_2_paper_fragments":
			return get_resource(&"paper_fragments") >= 2
		&"has_3_paper_fragments":
			return get_resource(&"paper_fragments") >= 3
		&"has_4_paper_fragments":
			return get_resource(&"paper_fragments") >= 4
		&"has_2_data_and_3_draft":
			return get_resource(&"data") >= 2 and get_resource(&"draft") >= 3
		&"has_2_data_or_3_draft":
			return get_resource(&"data") >= 2 or get_resource(&"draft") >= 3
		&"has_2_reputation_or_4_draft":
			return get_resource(&"reputation") >= 2 or get_resource(&"draft") >= 4
		&"has_3_methodology_notes_or_2_paper_fragments":
			return get_resource(&"methodology_notes") >= 3 or get_resource(&"paper_fragments") >= 2
		&"has_2_funds_or_2_paper_fragments":
			return get_resource(&"funds") >= 2 or get_resource(&"paper_fragments") >= 2
		&"has_3_paper_fragments_or_2_reputation":
			return get_resource(&"paper_fragments") >= 3 or get_resource(&"reputation") >= 2
		&"has_4_paper_fragments_or_2_reputation":
			return get_resource(&"paper_fragments") >= 4 or get_resource(&"reputation") >= 2
		&"gained_2_data":
			return get_resource_gain_this_battle(&"data") >= 2
		&"gained_3_draft":
			return get_resource_gain_this_battle(&"draft") >= 3
		&"gained_2_data_and_3_draft":
			return get_resource_gain_this_battle(&"data") >= 2 and get_resource_gain_this_battle(&"draft") >= 3
		&"gained_2_data_or_3_draft":
			return get_resource_gain_this_battle(&"data") >= 2 or get_resource_gain_this_battle(&"draft") >= 3
		&"played_literature_this_turn":
			return _played_tags_this_turn.has("literature")
		&"played_experiment_last_turn":
			return _played_tags_last_turn.has("experiment")
		&"end_turn":
			return true
		_:
			_log("unknown_condition=%s" % condition)
			return false


func _remove_status(target: StringName, card_id: StringName, amount: int) -> void:
	match target:
		&"hand":
			_remove_from_pile(hand, card_id, amount)
		&"draw":
			_remove_from_pile(draw_pile, card_id, amount)
		&"deck":
			remove_card_everywhere(card_id, amount)
		&"discard":
			_remove_from_pile(discard_pile, card_id, amount)
		&"exhaust":
			_remove_from_pile(exhaust_pile, card_id, amount)
		_:
			_log("unknown_pile=%s" % target)


func _remove_status_by_tag(target: StringName, tag_filter: StringName, amount: int) -> void:
	match target:
		&"hand":
			_remove_status_from_pile_by_tag(hand, tag_filter, amount)
		&"draw":
			_remove_status_from_pile_by_tag(draw_pile, tag_filter, amount)
		&"deck":
			_remove_status_from_deck_by_tag(tag_filter, amount)
		&"discard":
			_remove_status_from_pile_by_tag(discard_pile, tag_filter, amount)
		&"exhaust":
			_remove_status_from_pile_by_tag(exhaust_pile, tag_filter, amount)
		_:
			_log("unknown_pile=%s" % target)


func _remove_from_pile(pile: Array[StringName], card_id: StringName, amount: int) -> void:
	var removed: int = 0
	while removed < amount:
		var index: int = pile.find(card_id)
		if index == -1:
			return
		pile.remove_at(index)
		exhaust_pile.append(card_id)
		removed += 1


func _remove_status_from_pile_by_tag(pile: Array[StringName], tag_filter: StringName, amount: int) -> void:
	var removed: int = 0
	while removed < amount:
		var index: int = _find_status_card_with_tag(pile, tag_filter)
		if index == -1:
			return
		var card_id: StringName = pile[index]
		pile.remove_at(index)
		exhaust_pile.append(card_id)
		removed += 1


func _remove_status_from_deck_by_tag(tag_filter: StringName, amount: int) -> void:
	var removed: int = 0
	while removed < amount:
		var index: int = _find_status_card_with_tag(deck_card_ids, tag_filter)
		if index == -1:
			return
		var card_id: StringName = deck_card_ids[index]
		if remove_card_everywhere(card_id, 1) <= 0:
			return
		removed += 1


func _find_status_card_with_tag(pile: Array[StringName], tag_filter: StringName) -> int:
	for index in range(pile.size()):
		var card: Variant = cards_by_id.get(pile[index])
		if card != null and card.card_type == &"status" and card.tags.has(String(tag_filter)):
			return index
	return -1


func _has_status_card_with_tag(pile: Array[StringName], tag_filter: StringName) -> bool:
	return _find_status_card_with_tag(pile, tag_filter) != -1


func _remove_from_array_without_exhaust(values: Array[StringName], card_id: StringName, amount: int) -> int:
	var removed: int = 0
	while removed < amount:
		var index: int = values.find(card_id)
		if index == -1:
			return removed
		values.remove_at(index)
		removed += 1
	return removed


func _discard_from_hand(amount: int) -> void:
	for _i in range(amount):
		if hand.is_empty():
			return
		discard_pile.append(hand.pop_back())


func _discard_tag_from_hand(tag_filter: StringName, amount: int) -> void:
	var discarded: int = 0
	while discarded < amount:
		var index: int = _find_card_with_tag(hand, tag_filter)
		if index == -1:
			return
		var card_id: StringName = hand[index]
		hand.remove_at(index)
		discard_pile.append(card_id)
		discarded += 1


func _find_card_with_tag(pile: Array[StringName], tag_filter: StringName) -> int:
	for index in range(pile.size()):
		var card: Variant = cards_by_id.get(pile[index])
		if card != null and card.tags.has(String(tag_filter)):
			return index
	return -1


func _refill_draw_pile() -> void:
	if discard_pile.is_empty():
		return

	while not discard_pile.is_empty():
		draw_pile.append(discard_pile.pop_front())
	_shuffle(draw_pile)
	_log("reshuffle draw=%d" % draw_pile.size())


func _rebuild_draw_pile_from_deck() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	pending_discoveries.clear()
	for card_id: StringName in deck_card_ids:
		draw_pile.append(card_id)
	_shuffle(draw_pile)


func _shuffle(values: Array[StringName]) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var temp: StringName = values[i]
		values[i] = values[j]
		values[j] = temp


func _reset_resources(preserve_run_persistent: bool = false) -> void:
	for resource_id: Variant in resources.keys():
		if preserve_run_persistent and RUN_PERSISTENT_RESOURCE_IDS.has(resource_id):
			continue
		resources[resource_id] = 0


func _reset_resource_gains_this_battle() -> void:
	resource_gains_this_battle.clear()


func _apply_boss_starting_rules() -> void:
	if not is_boss_encounter or boss_definition == null:
		return

	for raw_card_id: String in boss_definition.starting_status_cards:
		var card_id := StringName(raw_card_id)
		if cards_by_id.has(card_id):
			deck_card_ids.append(card_id)
			discard_pile.append(card_id)
			_log("boss_start_status id=%s" % card_id)


func _get_current_boss_intent() -> Variant:
	if boss_definition == null:
		return null
	var turn_index: int = max(0, turn - 1)
	return boss_definition.get_intent_for_turn(turn_index)


func _resolve_boss_turn() -> Dictionary:
	var boss_intent: Variant = _get_current_boss_intent()
	var pressure: int = 0
	if boss_intent != null:
		pressure = boss_intent.pressure
		_apply_effects(boss_intent.effects)
		if boss_intent.has_condition():
			if _condition_met(boss_intent.condition):
				_apply_effects(boss_intent.success_effects)
			else:
				_apply_effects(boss_intent.failure_effects)

	if pressure > 0:
		take_pressure(pressure)
	else:
		_log("boss_intent id=%s pressure=0 vitality=%d" % [boss_intent.id if boss_intent != null else &"", vitality])

	return {
		"pressure": pressure,
		"vitality": vitality,
		"block": block,
		"victory": false,
	}


func _check_boss_phase_trigger() -> void:
	if not is_boss_encounter or boss_definition == null or boss_phase_triggered:
		return
	if boss_definition.phase_trigger_progress <= 0:
		return
	if progress < boss_definition.phase_trigger_progress:
		return

	boss_phase_triggered = true
	if boss_definition.phase_condition == &"" or _condition_met(boss_definition.phase_condition):
		_apply_effects(boss_definition.phase_success_effects)
		_log("boss_phase_success id=%s progress=%d" % [encounter_id, progress])
	else:
		_apply_effects(boss_definition.phase_failure_effects)
		_log("boss_phase_failure id=%s progress=%d" % [encounter_id, progress])


func _format_boss_intent_detail(boss_intent: Variant) -> String:
	var parts: Array[String] = []
	if boss_intent.has_condition():
		parts.append("检查：%s" % _format_condition_text(boss_intent.condition))

	var success_text: String = _format_effects_text(boss_intent.success_effects)
	if success_text != "":
		parts.append("达成：%s" % success_text)

	var failure_text: String = _format_effects_text(boss_intent.failure_effects)
	if failure_text != "":
		parts.append("未达成：%s" % failure_text)

	var effect_text: String = _format_effects_text(boss_intent.effects)
	if effect_text != "":
		parts.append("附加：%s" % effect_text)

	if parts.is_empty():
		return ""
	return "；".join(parts)


func _format_condition_text(condition: StringName) -> String:
	match condition:
		&"has_inspiration":
			return "至少 1 灵感"
		&"has_data":
			return "至少 1 数据"
		&"no_data":
			return "没有数据"
		&"has_experiment_noise_in_hand":
			return "手牌有实验噪音负面牌"
		&"has_status_in_hand":
			return "手牌有负面牌"
		&"has_2_inspiration":
			return "至少 2 灵感"
		&"has_2_draft":
			return "至少 2 草稿"
		&"has_2_data":
			return "至少 2 数据"
		&"has_2_draft_or_2_data":
			return "至少 2 草稿或 2 数据"
		&"has_3_draft":
			return "至少 3 草稿"
		&"has_4_draft":
			return "至少 4 草稿"
		&"has_2_reputation":
			return "至少 2 声望"
		&"has_2_funds":
			return "至少 2 经费"
		&"has_funds":
			return "至少 1 经费"
		&"has_3_methodology_notes":
			return "至少 3 方法论笔记"
		&"has_4_methodology_notes":
			return "至少 4 方法论笔记"
		&"has_2_paper_fragments":
			return "至少 2 论文碎片"
		&"has_3_paper_fragments":
			return "至少 3 论文碎片"
		&"has_4_paper_fragments":
			return "至少 4 论文碎片"
		&"has_2_data_and_3_draft":
			return "至少 2 数据和 3 草稿"
		&"has_2_data_or_3_draft":
			return "至少 2 数据或 3 草稿"
		&"has_2_reputation_or_4_draft":
			return "至少 2 声望或 4 草稿"
		&"has_3_methodology_notes_or_2_paper_fragments":
			return "至少 3 方法论笔记或 2 论文碎片"
		&"has_2_funds_or_2_paper_fragments":
			return "至少 2 经费或 2 论文碎片"
		&"has_3_paper_fragments_or_2_reputation":
			return "至少 3 论文碎片或 2 声望"
		&"has_4_paper_fragments_or_2_reputation":
			return "至少 4 论文碎片或 2 声望"
		&"gained_2_data":
			return "本战累计至少 2 数据"
		&"gained_3_draft":
			return "本战累计至少 3 草稿"
		&"gained_2_data_and_3_draft":
			return "本战累计至少 2 数据和 3 草稿"
		&"gained_2_data_or_3_draft":
			return "本战累计至少 2 数据或 3 草稿"
		_:
			return String(condition)


func _format_effects_text(effects: Array) -> String:
	var parts: Array[String] = []
	for effect: Variant in effects:
		if effect == null:
			continue

		match effect.effect_type:
			&"gain_progress":
				parts.append("进度 +%d" % effect.amount)
			&"gain_block":
				parts.append("防护 +%d" % effect.amount)
			&"gain_resource":
				parts.append("%s %s" % [_format_resource_name(effect.resource), _format_signed_amount(effect.amount)])
			&"lose_resource_or_energy":
				parts.append("%s -%d，否则精力 -%d" % [_format_resource_name(effect.resource), effect.amount, effect.amount * 2])
			&"lose_energy":
				parts.append("精力 -%d" % effect.amount)
			&"remove_status_by_tag":
				parts.append("移除 1 张%s负面牌" % _format_tag_text(effect.tag_filter))
			&"discard_tag_from_hand":
				parts.append("弃掉 1 张%s牌" % _format_tag_text(effect.tag_filter))
			&"add_card_to_deck", &"add_card_to_draw", &"add_card_to_hand":
				parts.append("加入 %s" % _format_card_name(effect.card_id))
			&"modify_target_progress":
				parts.append("目标进度 %s" % _format_signed_amount(effect.amount))
			_:
				parts.append(String(effect.effect_type))
	return "，".join(parts)


func _format_signed_amount(amount: int) -> String:
	if amount >= 0:
		return "+%d" % amount
	return str(amount)


func _format_resource_name(resource_id: StringName) -> String:
	match resource_id:
		&"energy", &"vitality":
			return "精力"
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


func _format_tag_text(tag_filter: StringName) -> String:
	match tag_filter:
		&"experiment_noise":
			return "实验噪音"
		&"experiment":
			return "实验"
		&"status":
			return "负面"
		_:
			return String(tag_filter)


func _format_card_name(card_id: StringName) -> String:
	var card: Variant = cards_by_id.get(card_id)
	if card != null:
		return card.display_name
	return String(card_id)


func _format_boss_phase_name() -> String:
	if boss_definition == null:
		return "阶段检查"
	match boss_definition.phase_event_id:
		&"proposal_topic_check":
			return "确定题目检查"
		&"midterm_panel_advice":
			return "专家组建议"
		&"blind_review_summary":
			return "送审意见汇总"
		&"doctoral_qualification_review":
			return "资格审查汇总"
		&"project_midterm_review":
			return "项目中期意见"
		&"doctoral_predefense_review":
			return "预答辩意见汇总"
		&"doctoral_defense_vote":
			return "答辩委员会表决"
		&"supplementary_defense_review":
			return "补答辩材料复核"
		_:
			return "阶段检查"


func _stringify_ids(ids: Array[StringName]) -> Array[String]:
	var output: Array[String] = []
	for id: StringName in ids:
		output.append(String(id))
	return output


func _log(message: String) -> void:
	event_log.append(message)


func _register_played_tags(tags: PackedStringArray) -> void:
	for tag: String in tags:
		_played_tags_this_turn[tag] = true


func _add_tag_progress_modifier(tag_filter: StringName, amount: int) -> void:
	if tag_filter == &"":
		return

	var key := String(tag_filter)
	_next_tag_progress_modifiers[key] = int(_next_tag_progress_modifiers.get(key, 0)) + amount


func _consume_tag_progress_modifier(tags: PackedStringArray) -> int:
	var total := 0
	for tag: String in tags:
		if _next_tag_progress_modifiers.has(tag):
			total += int(_next_tag_progress_modifiers[tag])
			_next_tag_progress_modifiers.erase(tag)
	return total


func _log_victory_if_needed() -> void:
	if _victory_logged:
		return
	if not is_victory():
		return

	_victory_logged = true
	_log("victory encounter=%s progress=%d/%d" % [encounter_id, progress, target_progress])
