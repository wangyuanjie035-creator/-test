class_name ResearchContentCatalog
extends RefCounted

const CARD_SCRIPT := preload("res://scripts/research_chain/data/research_card_definition.gd")
const ENCOUNTER_SCRIPT := preload("res://scripts/research_chain/data/research_encounter_definition.gd")

func build_cards() -> Dictionary[StringName, ResearchCardDefinition]:
	var cards: Dictionary[StringName, ResearchCardDefinition] = {}
	_add(cards, &"G01", "精读文献", 0, 2, &"general", [&"literature"], 1, "下一张为假设时 +2 分")
	_add(cards, &"G02", "文献综述", 0, 3, &"general", [&"literature"], 2, "链中有另一张文献时 +2 分")
	_add(cards, &"G03", "提出假设", 1, 2, &"general", [&"hypothesis"], 3, "连接文献和实验时 +4 分")
	_add(cards, &"G04", "预实验", 2, 3, &"general", [&"experiment"], 4, "此前有假设时 +2 分")
	_add(cards, &"G05", "整理数据", 3, 3, &"general", [&"data"], 5, "紧接实验时 +3 分")
	_add(cards, &"G06", "统计分析", 4, 4, &"general", [&"analysis"], 6, "此前有数据时 +2 分")
	_add(cards, &"G07", "撰写论文", 5, 5, &"general", [&"paper"], 7, "链含至少四个不同阶段时 +5 分")
	_add(cards, &"G08", "方法备忘", 1, 1, &"general", [&"recovery"], 8, "结算后恢复 1 精力")
	_add(cards, &"R01", "重复实验", 2, 3, &"replication", [&"replication", &"experiment"], 9, "链中有另一张实验时 +4 分，可信度 +1")
	_add(cards, &"R02", "复现记录", 3, 3, &"replication", [&"replication", &"data"], 10, "此前每张复现牌 +2 分，最多 +6")
	_add(cards, &"R03", "可信数据", 4, 4, &"replication", [&"replication", &"analysis"], 11, "提交前可信度至少 7 时 +6 分")
	_add(cards, &"R04", "复现实验室", 5, 5, &"replication", [&"replication", &"paper"], 12, "链含至少三张复现牌时 +10 分")
	_add(cards, &"N01", "阴性结果", 3, 2, &"negative", [&"negative", &"data"], 13, "额外 +1 分，阴性结果 +1")
	_add(cards, &"N02", "失败归档", 4, 3, &"negative", [&"negative", &"analysis"], 14, "消耗 1 阴性结果并 +5 分")
	_add(cards, &"N03", "调整假设", 1, 2, &"negative", [&"negative", &"hypothesis"], 15, "有阴性结果时 +4 分，可信度 +1")
	_add(cards, &"N04", "结果也是结果", 5, 4, &"negative", [&"negative", &"paper"], 16, "每个阴性结果 +3 分，最多读取三个")
	_add(cards, &"L01", "祖传脚本", 2, 5, &"legacy", [&"automation", &"experiment"], 17, "技术债 +2")
	_add(cards, &"L02", "批处理", 3, 3, &"legacy", [&"automation", &"data"], 18, "按技术债加分，最多 +6；技术债 +1")
	_add(cards, &"L03", "自动分析", 4, 4, &"legacy", [&"automation", &"analysis"], 19, "此前每张自动化牌 +3 分，最多 +9")
	_add(cards, &"L04", "技术债重构", 5, 3, &"legacy", [&"automation", &"paper"], 20, "按技术债加分，最多 +10；技术债 -3")
	return cards

func build_deck(archetype: StringName) -> Array[ResearchCardDefinition]:
	var cards: Dictionary[StringName, ResearchCardDefinition] = build_cards()
	var ids: Array[StringName] = [&"G01", &"G01", &"G02", &"G03", &"G04", &"G04", &"G05", &"G05", &"G06", &"G06", &"G07", &"G08"]
	var archetype_ids: Array[StringName]
	match archetype:
		&"negative": archetype_ids = [&"N01", &"N01", &"N02", &"N02", &"N03", &"N03", &"N04", &"N04"]
		&"legacy": archetype_ids = [&"L01", &"L01", &"L02", &"L02", &"L03", &"L03", &"L04", &"L04"]
		_: archetype_ids = [&"R01", &"R01", &"R02", &"R02", &"R03", &"R03", &"R04", &"R04"]
	ids.append_array(archetype_ids)
	var deck: Array[ResearchCardDefinition] = []
	for id: StringName in ids:
		deck.append(cards[id])
	return deck

func build_encounters() -> Array[ResearchEncounterDefinition]:
	var group_meeting: ResearchEncounterDefinition = ENCOUNTER_SCRIPT.new()
	group_meeting.id = &"group_meeting"
	group_meeting.display_name = "组会汇报"
	group_meeting.turn_limit = 5
	group_meeting.target_score = 100
	var reviewer: ResearchEncounterDefinition = ENCOUNTER_SCRIPT.new()
	reviewer.id = &"reviewer_two"
	reviewer.display_name = "Reviewer #2"
	reviewer.turn_limit = 6
	reviewer.target_score = 180
	reviewer.is_boss = true
	return [group_meeting, reviewer]

func _add(cards: Dictionary[StringName, ResearchCardDefinition], id: StringName, title: String, stage: int, base_score: int, archetype: StringName, tags: Array[StringName], effect: int, text: String) -> void:
	var card: ResearchCardDefinition = CARD_SCRIPT.new()
	card.id = id
	card.display_name = title
	card.stage = stage as ResearchCardDefinition.Stage
	card.base_score = base_score
	card.archetype = archetype
	card.tags = tags
	card.effect = effect as ResearchCardDefinition.Effect
	card.rules_text = text
	cards[id] = card

