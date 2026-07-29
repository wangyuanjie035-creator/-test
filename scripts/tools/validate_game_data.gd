@tool
extends EditorScript

const GAME_DATA_CATALOG := preload("res://scripts/data/game_data_catalog.gd")


func _run() -> void:
	var cards := GAME_DATA_CATALOG.load_cards_by_id()
	var decks := GAME_DATA_CATALOG.load_decks_by_id()

	print("cards=%d" % cards.size())
	print("decks=%d" % decks.size())

	for deck_id in decks:
		var deck = decks[deck_id]
		var missing_cards: PackedStringArray = PackedStringArray()
		for card_id in deck.card_ids:
			if not cards.has(StringName(card_id)):
				missing_cards.append(card_id)

		if missing_cards.is_empty():
			print("deck_ok=%s size=%d" % [deck.id, deck.card_ids.size()])
		else:
			push_error("Deck %s references missing cards: %s" % [deck.id, ", ".join(missing_cards)])
