class_name ResearchRunController
extends Node

signal state_changed(snapshot: Dictionary)
signal run_finished(won: bool, reason: String)

const CATALOG := preload("res://scripts/research_chain/data/research_content_catalog.gd")
const RULES := preload("res://scripts/research_chain/model/research_chain_rules.gd")

var archetype: StringName = &"replication"
var seed: int = 1
var energy: int = 10
var credibility: int = 5
var technical_debt: int = 0
var negative_result: int = 0
var score: int = 0
var turn: int = 1
var encounter_index: int = 0
var hand: Array[ResearchCardDefinition] = []
var chain: Array[ResearchCardDefinition] = []

var _catalog: ResearchContentCatalog = CATALOG.new()
var _rules: ResearchChainRules = RULES.new()
var _encounters: Array[ResearchEncounterDefinition] = []
var _draw_pile: Array[ResearchCardDefinition] = []
var _discard_pile: Array[ResearchCardDefinition] = []
var _previous_structure: PackedInt32Array = PackedInt32Array()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func start_run(selected_archetype: StringName, run_seed: int) -> void:
	archetype = selected_archetype
	seed = maxi(1, run_seed)
	energy = 10
	credibility = 5
	technical_debt = 0
	negative_result = 0
	encounter_index = 0
	_encounters = _catalog.build_encounters()
	_rng.seed = seed
	_start_encounter()

func add_to_chain(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= hand.size() or chain.size() >= ResearchChainRules.MAX_CHAIN_SIZE:
		return
	chain.append(hand.pop_at(hand_index))
	_emit_state()

func remove_from_chain(chain_index: int) -> void:
	if chain_index < 0 or chain_index >= chain.size():
		return
	hand.append(chain.pop_at(chain_index))
	_emit_state()

func submit_chain() -> void:
	var result: Dictionary = current_preview()
	if not bool(result.get("valid", false)):
		return
	score += int(result.final_score)
	energy = clampi(energy + int(result.energy_delta), 0, 10)
	credibility = clampi(credibility + int(result.credibility_delta), 0, 10)
	technical_debt = clampi(technical_debt + int(result.debt_delta), 0, 10)
	negative_result = clampi(negative_result + int(result.negative_delta), 0, 10)
	_previous_structure = result.structure
	_discard_pile.append_array(chain)
	_discard_pile.append_array(hand)
	chain.clear()
	hand.clear()
	if technical_debt >= 10:
		energy = maxi(0, energy - 2)
	elif technical_debt >= 7:
		energy = maxi(0, energy - 1)
	_resolve_turn()

func skip_turn() -> void:
	energy = clampi(energy - 1 + 1, 0, 10)
	credibility = maxi(0, credibility - 1)
	_discard_pile.append_array(chain)
	_discard_pile.append_array(hand)
	chain.clear()
	hand.clear()
	_resolve_turn()

func current_preview() -> Dictionary:
	var result: Dictionary = _rules.preview(chain, _state_values(), current_encounter(), _previous_structure)
	if current_encounter().is_boss and bool(result.get("valid", false)):
		var requirement_met: bool = _is_requirement_met(chain)
		result.requirement_text = _review_requirement()
		result.requirement_met = requirement_met
		if requirement_met:
			result.archetype_score = int(result.archetype_score) + 5
			result.subtotal = int(result.subtotal) + 5
			result.final_score = floori(int(result.subtotal) * float(result.credibility_multiplier) * float(result.encounter_multiplier))
		else:
			result.credibility_delta = int(result.credibility_delta) - 1
	return result

func current_encounter() -> ResearchEncounterDefinition:
	return _encounters[encounter_index]

func snapshot() -> Dictionary:
	return {
		"archetype": archetype, "seed": seed, "energy": energy, "credibility": credibility,
		"technical_debt": technical_debt, "negative_result": negative_result, "score": score,
		"turn": turn, "encounter": current_encounter(), "hand": hand, "chain": chain,
		"preview": current_preview(), "draw_count": _draw_pile.size(), "discard_count": _discard_pile.size(),
	}

func _start_encounter() -> void:
	score = 0
	turn = 1
	_previous_structure = PackedInt32Array()
	_draw_pile = _catalog.build_deck(archetype)
	_discard_pile.clear()
	hand.clear()
	chain.clear()
	_shuffle_draw_pile()
	_draw_to_seven()
	_emit_state()

func _resolve_turn() -> void:
	if energy <= 0:
		run_finished.emit(false, "精力耗尽，研究暂时中止。")
		return
	if score >= current_encounter().target_score:
		if encounter_index == 0:
			energy = mini(10, energy + 2)
			credibility = mini(10, credibility + 1)
			encounter_index = 1
			_start_encounter()
		else:
			run_finished.emit(true, "论文通过 Reviewer #2，原型流程完成。")
		return
	if turn >= current_encounter().turn_limit:
		run_finished.emit(false, "截止日期已到，论文分数不足。")
		return
	turn += 1
	_draw_to_seven()
	_emit_state()

func _draw_to_seven() -> void:
	while hand.size() < 7:
		if _draw_pile.is_empty():
			if _discard_pile.is_empty():
				break
			_draw_pile = _discard_pile
			_discard_pile = []
			_shuffle_draw_pile()
		hand.append(_draw_pile.pop_back())

func _shuffle_draw_pile() -> void:
	for index: int in range(_draw_pile.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var temporary: ResearchCardDefinition = _draw_pile[index]
		_draw_pile[index] = _draw_pile[swap_index]
		_draw_pile[swap_index] = temporary

func _state_values() -> Dictionary:
	return {"energy": energy, "credibility": credibility, "technical_debt": technical_debt, "negative_result": negative_result}

func _review_requirement() -> String:
	if turn <= 2:
		return "本回合使用至少三个不同科研阶段"
	if turn <= 4:
		return "本回合必须包含实验阶段"
	return "本回合必须包含论文阶段"

func _is_requirement_met(cards: Array[ResearchCardDefinition]) -> bool:
	if turn <= 2:
		var stages: Dictionary[int, bool] = {}
		for card: ResearchCardDefinition in cards:
			stages[card.stage] = true
		return stages.size() >= 3
	var required_stage: int = ResearchCardDefinition.Stage.EXPERIMENT if turn <= 4 else ResearchCardDefinition.Stage.PAPER
	for card: ResearchCardDefinition in cards:
		if card.stage == required_stage:
			return true
	return false

func _emit_state() -> void:
	state_changed.emit(snapshot())
