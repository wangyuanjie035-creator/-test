@tool
extends RefCounted
class_name GameDataCatalog

const CARD_DIRS: PackedStringArray = [
	"res://data/cards/base",
	"res://data/cards/reward",
	"res://data/cards/status",
	"res://data/cards/unlock",
]

const BOSS_DIR := "res://data/bosses"
const EVENT_DIR := "res://data/events"
const ENCOUNTER_DIR := "res://data/encounters"
const DECK_DIR := "res://data/decks"
const ROUTE_NODE_HINT_DIR := "res://data/route_node_hints"
const CAMPUS_STAGE_DIR := "res://data/campus/stages"
const CAMPUS_ROUTE_REQUIREMENT_CATALOG_PATH := "res://data/campus/route_requirements.tres"
const ENCOUNTER_SCRIPT_PATH := "res://scripts/data/encounter_definition.gd"
const ROUTE_NODE_HINT_SCRIPT_PATH := "res://scripts/data/route_node_hint_definition.gd"
const CAMPUS_STAGE_SCRIPT_PATH := "res://scripts/data/campus_stage_definition.gd"
const CAMPUS_ROUTE_REQUIREMENT_CATALOG_SCRIPT_PATH := "res://scripts/data/campus_route_requirement_catalog_definition.gd"


static func load_resources_from_dir(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Data directory not found: %s" % path)
		return resources

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource: Resource = ResourceLoader.load(path.path_join(file_name), "", ResourceLoader.CACHE_MODE_IGNORE)
			if resource != null:
				resources.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()

	return resources


static func load_cards_by_id() -> Dictionary:
	var cards: Dictionary = {}
	for dir_path in CARD_DIRS:
		for resource in load_resources_from_dir(dir_path):
			if resource is CardDefinition:
				cards[resource.id] = resource
	return cards


static func load_bosses_by_id() -> Dictionary:
	var bosses: Dictionary = {}
	for resource in load_resources_from_dir(BOSS_DIR):
		if resource is BossDefinition:
			bosses[resource.id] = resource
	return bosses


static func load_events_by_id() -> Dictionary:
	var events: Dictionary = {}
	for resource in load_resources_from_dir(EVENT_DIR):
		if resource is EventDefinition:
			events[resource.id] = resource
	return events


static func load_encounters_by_id() -> Dictionary:
	var encounters: Dictionary = {}
	for resource in load_resources_from_dir(ENCOUNTER_DIR):
		if resource != null and resource.get_script() != null and resource.get_script().resource_path == ENCOUNTER_SCRIPT_PATH:
			encounters[resource.id] = resource
	return encounters


static func load_decks_by_id() -> Dictionary:
	var decks: Dictionary = {}
	for resource in load_resources_from_dir(DECK_DIR):
		if resource is DeckDefinition:
			decks[resource.id] = resource
	return decks


static func load_route_node_hints_by_id() -> Dictionary:
	var hints: Dictionary = {}
	for resource in load_resources_from_dir(ROUTE_NODE_HINT_DIR):
		if resource != null and resource.get_script() != null and resource.get_script().resource_path == ROUTE_NODE_HINT_SCRIPT_PATH:
			hints[resource.id] = resource
	return hints


static func load_campus_stages_by_id() -> Dictionary:
	var stages: Dictionary = {}
	for resource in load_resources_from_dir(CAMPUS_STAGE_DIR):
		if resource != null and resource.get_script() != null and resource.get_script().resource_path == CAMPUS_STAGE_SCRIPT_PATH:
			stages[resource.id] = resource
	return stages


static func load_campus_route_requirements_by_id() -> Dictionary:
	var requirements: Dictionary = {}
	var catalog: Resource = ResourceLoader.load(CAMPUS_ROUTE_REQUIREMENT_CATALOG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if catalog == null or catalog.get_script() == null or catalog.get_script().resource_path != CAMPUS_ROUTE_REQUIREMENT_CATALOG_SCRIPT_PATH:
		push_warning("Campus route requirement catalog not found: %s" % CAMPUS_ROUTE_REQUIREMENT_CATALOG_PATH)
		return requirements

	for entry: Resource in catalog.get("entries"):
		if entry != null and entry.get("route_node_id") != &"":
			requirements[entry.get("route_node_id")] = entry
	return requirements
