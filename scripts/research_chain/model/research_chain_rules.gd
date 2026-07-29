class_name ResearchChainRules
extends RefCounted

const MAX_CHAIN_SIZE: int = 5

func preview(cards: Array[ResearchCardDefinition], state: Dictionary, encounter: ResearchEncounterDefinition, previous_structure: PackedInt32Array = PackedInt32Array()) -> Dictionary:
	var validation: Dictionary = validate_chain(cards)
	if not bool(validation.valid):
		return {"valid": false, "reason": validation.reason}
	var base_score: int = 0
	var connection_score: int = 0
	var archetype_score: int = 0
	var credibility_delta: int = 0
	var energy_delta: int = -1
	var debt_delta: int = 0
	var negative_delta: int = 0
	var stages: PackedInt32Array = PackedInt32Array()
	for card: ResearchCardDefinition in cards:
		base_score += card.base_score
		stages.append(card.stage)
	for index: int in range(cards.size() - 1):
		var gap: int = cards[index + 1].stage - cards[index].stage
		if gap == 1:
			connection_score += 2
		elif gap > 1:
			credibility_delta -= gap - 1
	for index: int in range(cards.size()):
		var effect_result: Dictionary = _score_effect(cards[index], index, cards, state)
		archetype_score += int(effect_result.get("score", 0))
		credibility_delta += int(effect_result.get("credibility", 0))
		energy_delta += int(effect_result.get("energy", 0))
		debt_delta += int(effect_result.get("debt", 0))
		negative_delta += int(effect_result.get("negative", 0))
	if not encounter.is_boss and _covers_group_meeting_stages(stages):
		credibility_delta += 1
	var credibility_multiplier: float = _credibility_multiplier(int(state.credibility))
	var encounter_multiplier: float = 0.7 if encounter.is_boss and stages == previous_structure else 1.0
	var subtotal: int = base_score + connection_score + archetype_score
	var final_score: int = floori(subtotal * credibility_multiplier * encounter_multiplier)
	return {
		"valid": true,
		"reason": "",
		"base_score": base_score,
		"connection_score": connection_score,
		"archetype_score": archetype_score,
		"subtotal": subtotal,
		"credibility_multiplier": credibility_multiplier,
		"encounter_multiplier": encounter_multiplier,
		"final_score": final_score,
		"energy_delta": energy_delta,
		"credibility_delta": credibility_delta,
		"debt_delta": debt_delta,
		"negative_delta": negative_delta,
		"structure": stages,
	}

func validate_chain(cards: Array[ResearchCardDefinition]) -> Dictionary:
	if cards.is_empty():
		return {"valid": false, "reason": "至少选择一张卡牌。"}
	if cards.size() > MAX_CHAIN_SIZE:
		return {"valid": false, "reason": "科研链最多包含 5 张卡牌。"}
	for index: int in range(cards.size() - 1):
		if cards[index + 1].stage < cards[index].stage:
			return {"valid": false, "reason": "科研阶段不能逆序。"}
	return {"valid": true, "reason": ""}

func _score_effect(card: ResearchCardDefinition, index: int, cards: Array[ResearchCardDefinition], state: Dictionary) -> Dictionary:
	var result: Dictionary = {"score": 0, "credibility": 0, "energy": 0, "debt": 0, "negative": 0}
	var before: Array[ResearchCardDefinition] = cards.slice(0, index)
	match card.effect:
		ResearchCardDefinition.Effect.NEXT_HYPOTHESIS:
			result.score = 2 if index + 1 < cards.size() and cards[index + 1].stage == ResearchCardDefinition.Stage.HYPOTHESIS else 0
		ResearchCardDefinition.Effect.OTHER_LITERATURE:
			result.score = 2 if _count_stage(cards, ResearchCardDefinition.Stage.LITERATURE) > 1 else 0
		ResearchCardDefinition.Effect.BRIDGE:
			result.score = 4 if index > 0 and index + 1 < cards.size() and cards[index - 1].stage == ResearchCardDefinition.Stage.LITERATURE and cards[index + 1].stage == ResearchCardDefinition.Stage.EXPERIMENT else 0
		ResearchCardDefinition.Effect.HAS_HYPOTHESIS:
			result.score = 2 if _has_stage(before, ResearchCardDefinition.Stage.HYPOTHESIS) else 0
		ResearchCardDefinition.Effect.AFTER_EXPERIMENT:
			result.score = 3 if index > 0 and cards[index - 1].stage == ResearchCardDefinition.Stage.EXPERIMENT else 0
		ResearchCardDefinition.Effect.HAS_DATA:
			result.score = 2 if _has_stage(before, ResearchCardDefinition.Stage.DATA) else 0
		ResearchCardDefinition.Effect.FOUR_STAGES:
			result.score = 5 if _unique_stage_count(cards) >= 4 else 0
		ResearchCardDefinition.Effect.REST:
			result.energy = 1
		ResearchCardDefinition.Effect.REPEAT_EXPERIMENT:
			if _count_stage(cards, ResearchCardDefinition.Stage.EXPERIMENT) > 1:
				result.score = 4
				result.credibility = 1
		ResearchCardDefinition.Effect.REPLICATION_SCALE:
			result.score = mini(6, _count_tag(before, &"replication") * 2)
		ResearchCardDefinition.Effect.HIGH_CREDIBILITY:
			result.score = 6 if int(state.credibility) >= 7 else 0
		ResearchCardDefinition.Effect.REPLICATION_FINISHER:
			result.score = 10 if _count_tag(cards, &"replication") >= 3 else 0
		ResearchCardDefinition.Effect.GAIN_NEGATIVE:
			result.score = 1
			result.negative = 1
		ResearchCardDefinition.Effect.ARCHIVE_NEGATIVE:
			if int(state.negative_result) >= 1:
				result.score = 5
				result.negative = -1
		ResearchCardDefinition.Effect.REFRAME_NEGATIVE:
			if int(state.negative_result) >= 1:
				result.score = 4
				result.credibility = 1
		ResearchCardDefinition.Effect.PUBLISH_NEGATIVE:
			var used: int = mini(3, int(state.negative_result))
			result.score = used * 3
			result.negative = -used
		ResearchCardDefinition.Effect.GAIN_DEBT_TWO:
			result.debt = 2
		ResearchCardDefinition.Effect.DEBT_SCORE:
			result.score = mini(6, int(state.technical_debt))
			result.debt = 1
		ResearchCardDefinition.Effect.AUTOMATION_SCALE:
			result.score = mini(9, _count_tag(before, &"automation") * 3)
		ResearchCardDefinition.Effect.REFACTOR_DEBT:
			result.score = mini(5, int(state.technical_debt)) * 2
			result.debt = -3
		_:
			pass
	return result

func _credibility_multiplier(value: int) -> float:
	if value <= 2:
		return 0.75
	if value <= 6:
		return 1.0
	if value <= 9:
		return 1.15
	return 1.3

func _covers_group_meeting_stages(stages: PackedInt32Array) -> bool:
	var required: PackedInt32Array = PackedInt32Array([0, 2, 3, 4, 5])
	for stage: int in required:
		if not stages.has(stage):
			return false
	return true

func _has_stage(cards: Array[ResearchCardDefinition], stage: int) -> bool:
	return _count_stage(cards, stage) > 0

func _count_stage(cards: Array[ResearchCardDefinition], stage: int) -> int:
	var count: int = 0
	for card: ResearchCardDefinition in cards:
		if card.stage == stage:
			count += 1
	return count

func _count_tag(cards: Array[ResearchCardDefinition], tag: StringName) -> int:
	var count: int = 0
	for card: ResearchCardDefinition in cards:
		if card.tags.has(tag):
			count += 1
	return count

func _unique_stage_count(cards: Array[ResearchCardDefinition]) -> int:
	var unique: Dictionary[int, bool] = {}
	for card: ResearchCardDefinition in cards:
		unique[card.stage] = true
	return unique.size()

