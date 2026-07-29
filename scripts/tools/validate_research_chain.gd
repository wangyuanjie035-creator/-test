extends SceneTree

const CATALOG := preload("res://scripts/research_chain/data/research_content_catalog.gd")
const RULES := preload("res://scripts/research_chain/model/research_chain_rules.gd")

func _init() -> void:
	var catalog: ResearchContentCatalog = CATALOG.new()
	var rules: ResearchChainRules = RULES.new()
	var cards: Dictionary[StringName, ResearchCardDefinition] = catalog.build_cards()
	var encounters: Array[ResearchEncounterDefinition] = catalog.build_encounters()
	_assert(catalog.build_deck(&"replication").size() == 20, "复现牌库必须为 20 张")
	_assert(catalog.build_deck(&"negative").size() == 20, "阴性牌库必须为 20 张")
	_assert(catalog.build_deck(&"legacy").size() == 20, "祖传代码牌库必须为 20 张")
	var state: Dictionary = {"energy": 10, "credibility": 5, "technical_debt": 0, "negative_result": 0}
	var valid_chain: Array[ResearchCardDefinition] = [cards[&"G01"], cards[&"G03"], cards[&"G04"], cards[&"G05"], cards[&"G07"]]
	var preview: Dictionary = rules.preview(valid_chain, state, encounters[0])
	_assert(bool(preview.valid), "顺序科研链应合法")
	_assert(int(preview.final_score) > 0, "合法科研链应产生分数")
	var invalid_chain: Array[ResearchCardDefinition] = [cards[&"G07"], cards[&"G01"]]
	_assert(not bool(rules.preview(invalid_chain, state, encounters[0]).valid), "逆序科研链必须拒绝")
	var negative_state: Dictionary = state.duplicate()
	negative_state.negative_result = 2
	var negative_chain: Array[ResearchCardDefinition] = [cards[&"N03"], cards[&"G04"], cards[&"G05"], cards[&"N02"], cards[&"N04"]]
	var negative_preview: Dictionary = rules.preview(negative_chain, negative_state, encounters[0])
	_assert(int(negative_preview.archetype_score) >= 15, "阴性结果转化必须形成爆发")
	print("RESEARCH_CHAIN_VALIDATION: PASS")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("RESEARCH_CHAIN_VALIDATION: %s" % message)
	quit(1)
