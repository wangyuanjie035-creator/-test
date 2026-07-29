@tool
extends EditorScript

const CARD_DEFINITION := preload("res://scripts/data/card_definition.gd")
const DECK_DEFINITION := preload("res://scripts/data/deck_definition.gd")
const EFFECT_DEFINITION := preload("res://scripts/data/effect_definition.gd")


func _run() -> void:
	_make_dir("res://data/cards/base")
	_make_dir("res://data/cards/status")
	_make_dir("res://data/decks")

	_save_card(_card({
		"id": &"C001",
		"display_name": "查文献",
		"card_type": &"action",
		"rarity": &"starter",
		"cost": 1,
		"tags": PackedStringArray(["literature"]),
		"description": "获得 1 灵感，抽 1 张牌。",
		"upgraded_description": "获得 1 灵感，抽 1 张牌，获得 2 进度。",
		"effects": [
			_effect(&"gain_resource", 1, &"inspiration"),
			_effect(&"draw", 1),
		],
		"upgraded_effects": [
			_effect(&"gain_resource", 1, &"inspiration"),
			_effect(&"draw", 1),
			_effect(&"gain_progress", 2),
		],
	}), "res://data/cards/base/c001_read_literature.tres")

	_save_card(_card({
		"id": &"C006",
		"display_name": "写草稿",
		"card_type": &"action",
		"rarity": &"starter",
		"cost": 1,
		"tags": PackedStringArray(["draft"]),
		"description": "获得 2 草稿。",
		"upgraded_description": "获得 3 草稿。",
		"effects": [_effect(&"gain_resource", 2, &"draft")],
		"upgraded_effects": [_effect(&"gain_resource", 3, &"draft")],
	}), "res://data/cards/base/c006_write_draft.tres")

	_save_card(_card({
		"id": &"C011",
		"display_name": "做实验",
		"card_type": &"action",
		"rarity": &"starter",
		"cost": 1,
		"tags": PackedStringArray(["experiment", "data"]),
		"description": "获得 6 进度；若有至少 1 灵感，额外获得 1 数据。",
		"upgraded_description": "获得 8 进度；若有至少 1 灵感，额外获得 1 数据。",
		"effects": [
			_effect(&"gain_progress", 6),
			_effect(&"gain_resource", 1, &"data", &"self", &"", &"", &"has_inspiration"),
		],
		"upgraded_effects": [
			_effect(&"gain_progress", 8),
			_effect(&"gain_resource", 1, &"data", &"self", &"", &"", &"has_inspiration"),
		],
	}), "res://data/cards/base/c011_run_experiment.tres")

	_save_card(_card({
		"id": &"C020",
		"display_name": "自我调整",
		"card_type": &"skill",
		"rarity": &"starter",
		"cost": 1,
		"tags": PackedStringArray(["care", "block"]),
		"description": "获得 7 防护；若手牌有“焦虑”，可消耗其中 1 张。",
		"upgraded_description": "获得 10 防护；若手牌有“焦虑”，可消耗其中 1 张。",
		"effects": [
			_effect(&"gain_block", 7),
			_effect(&"remove_status", 1, &"", &"hand", &"S002"),
		],
		"upgraded_effects": [
			_effect(&"gain_block", 10),
			_effect(&"remove_status", 1, &"", &"hand", &"S002"),
		],
	}), "res://data/cards/base/c020_self_regulate.tres")

	_save_card(_card({
		"id": &"C023",
		"display_name": "请教师兄",
		"card_type": &"cooperation",
		"rarity": &"starter",
		"cost": 1,
		"tags": PackedStringArray(["network", "discover"]),
		"description": "发现 1 张行动牌，本场战斗临时加入手牌。",
		"upgraded_description": "发现 1 张行动牌或技能牌，本场战斗临时加入手牌。",
		"effects": [_effect(&"discover", 1, &"", &"hand", &"", &"action")],
		"upgraded_effects": [_effect(&"discover", 1, &"", &"hand", &"", &"action_or_skill")],
	}), "res://data/cards/base/c023_ask_senior.tres")

	_save_card(_status_card(&"S001", "拖延", "无效果。打出需 1 行动点并消耗。", 1), "res://data/cards/status/s001_delay.tres")
	_save_card(_status_card(&"S002", "焦虑", "抽到时本回合结束失去 2 精力。", -1, [_effect(&"lose_energy", 2, &"energy", &"self", &"", &"", &"end_turn")]), "res://data/cards/status/s002_anxiety.tres")
	_save_card(_status_card(&"S004", "信息过载", "抽到时弃 1 张牌。", -1, [_effect(&"discard", 1, &"", &"hand")]), "res://data/cards/status/s004_info_overload.tres")
	_save_card(_status_card(&"S005", "恍惚", "本回合少 1 行动点，触发后消耗。", -1, [_effect(&"lose_action_point", 1)]), "res://data/cards/status/s005_dazed.tres")
	_save_card(_status_card(&"S010", "自我怀疑", "抽到时获得的下一次进度 -4，最低为 0。", -1, [_effect(&"modify_next_progress", -4)]), "res://data/cards/status/s010_self_doubt.tres")

	var starter_deck: DeckDefinition = DECK_DEFINITION.new()
	starter_deck.id = &"D001"
	starter_deck.display_name = "研究生初始牌组"
	starter_deck.card_ids = PackedStringArray([
		"C001", "C001", "C001", "C001",
		"C011", "C011", "C011", "C011",
		"C006", "C006", "C006",
		"C020", "C020", "C020",
		"C023",
	])
	_save_resource(starter_deck, "res://data/decks/d001_starter_deck.tres")

	print("Generated MVP starter data.")


func _card(data: Dictionary) -> CardDefinition:
	var card: CardDefinition = CARD_DEFINITION.new()
	card.id = data["id"]
	card.display_name = data["display_name"]
	card.card_type = data["card_type"]
	card.rarity = data["rarity"]
	card.cost = data["cost"]
	card.tags = data["tags"]
	card.description = data["description"]
	card.upgraded_description = data["upgraded_description"]
	card.effects = _typed_effect_array(data.get("effects", []))
	card.upgraded_effects = _typed_effect_array(data.get("upgraded_effects", []))
	card.exhausts = data.get("exhausts", false)
	card.temporary = data.get("temporary", false)
	card.status_id_to_add = data.get("status_id_to_add", &"")
	return card


func _status_card(id: StringName, display_name: String, description: String, playable_cost: int, effects: Array = []) -> CardDefinition:
	var card: CardDefinition = CARD_DEFINITION.new()
	card.id = id
	card.display_name = display_name
	card.card_type = &"status"
	card.rarity = &"status"
	card.cost = playable_cost
	card.tags = PackedStringArray(["status"])
	card.description = description
	card.upgraded_description = description
	card.effects = _typed_effect_array(effects)
	card.exhausts = playable_cost >= 0
	return card


func _effect(effect_type: StringName, amount: int = 0, resource: StringName = &"", target: StringName = &"self", card_id: StringName = &"", tag_filter: StringName = &"", condition: StringName = &"") -> EffectDefinition:
	var effect: EffectDefinition = EFFECT_DEFINITION.new()
	effect.effect_type = effect_type
	effect.amount = amount
	effect.resource = resource
	effect.target = target
	effect.card_id = card_id
	effect.tag_filter = tag_filter
	effect.condition = condition
	return effect


func _typed_effect_array(values: Array) -> Array[EffectDefinition]:
	var typed: Array[EffectDefinition] = []
	for effect in values:
		typed.append(effect)
	return typed


func _save_card(card: CardDefinition, path: String) -> void:
	_save_resource(card, path)


func _save_resource(resource: Resource, path: String) -> void:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Failed to save %s: %s" % [path, error_string(err)])


func _make_dir(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		return

	var err := DirAccess.make_dir_recursive_absolute(path)
	if err != OK:
		push_error("Failed to create %s: %s" % [path, error_string(err)])
