@tool
extends EditorScript

const GAME_DATA_CATALOG := preload("res://scripts/data/game_data_catalog.gd")
const BATTLE_STATE := preload("res://scripts/battle/battle_state.gd")


func _run() -> void:
	var cards: Dictionary = GAME_DATA_CATALOG.load_cards_by_id()
	var decks: Dictionary = GAME_DATA_CATALOG.load_decks_by_id()
	var encounters: Dictionary = GAME_DATA_CATALOG.load_encounters_by_id()
	var deck: Variant = decks.get(&"D001")
	var encounter: Variant = encounters.get(&"N001")
	if deck == null:
		push_error("Missing D001 starter deck.")
		return
	if encounter == null:
		push_error("Missing N001 ordinary pressure encounter.")
		return

	var battle: Variant = BATTLE_STATE.new()
	battle.setup(cards, deck, 7)
	battle.set_encounter(encounter)
	battle.start_battle()

	print("initial_hand=%d" % battle.hand.size())
	print("initial_ap=%d" % battle.action_points)
	print("initial_total_cards=%d" % (battle.hand.size() + battle.draw_pile.size() + battle.discard_pile.size() + battle.exhaust_pile.size()))
	print("encounter=%s target=%d pressure=%d" % [battle.encounter_id, battle.target_progress, battle.pressure_per_turn])

	var effect_battle: Variant = BATTLE_STATE.new()
	effect_battle.setup(cards, deck, 11)
	effect_battle.set_encounter(encounter)
	effect_battle.start_battle()
	effect_battle.hand = [&"C001", &"C006", &"C011"]
	effect_battle.draw_pile.clear()
	effect_battle.discard_pile.clear()
	effect_battle.exhaust_pile.clear()
	effect_battle.action_points = 3

	_play_if_present(effect_battle, &"C001")
	_play_if_present(effect_battle, &"C006")
	_play_if_present(effect_battle, &"C011")

	print("after_ap=%d" % effect_battle.action_points)
	print("after_progress=%d" % effect_battle.progress)
	print("after_inspiration=%d" % effect_battle.get_resource(&"inspiration"))
	print("after_data=%d" % effect_battle.get_resource(&"data"))
	print("after_draft=%d" % effect_battle.get_resource(&"draft"))
	print("after_hand=%d" % effect_battle.hand.size())
	print("after_discard=%d" % effect_battle.discard_pile.size())


func _play_if_present(battle: Variant, card_id: StringName) -> void:
	if battle.hand.has(card_id):
		var played: bool = battle.play_card(card_id)
		print("played_%s=%s" % [card_id, str(played)])
	else:
		print("played_%s=not_in_hand" % card_id)
