extends SceneTree

const OPPORTUNITY_MODEL := preload(
	"res://scripts/academic_year/model/academic_opportunity_model.gd"
)
const COLLABORATION: Resource = preload(
	"res://data/academic_year/opportunities/lab_collaboration.tres"
)
const INDUSTRY: Resource = preload(
	"res://data/academic_year/opportunities/industry_interview.tres"
)
const STARTUP: Resource = preload(
	"res://data/academic_year/opportunities/startup_pilot.tres"
)


func _initialize() -> void:
	var first: RefCounted = _model(3301)
	var second: RefCounted = _model(3301)
	var context := {
		"prestige": 2,
		"failure_assets": 1,
		"route_id": &"single",
	}
	var first_offer: Dictionary = first.generate_offer(2, context)
	var second_offer: Dictionary = second.generate_offer(2, context)
	if not bool(first_offer.get("success", false)):
		_fail("An eligible transition did not generate an opportunity.")
		return
	if first_offer.get("opportunity", {}) != second_offer.get("opportunity", {}):
		_fail("The same seed and history generated different opportunities.")
		return
	var first_options: Array = first_offer.get("opportunities", [])
	if first_options.size() != 2:
		_fail("An eligible transition did not produce two competing opportunities.")
		return
	if first_options != second_offer.get("opportunities", []):
		_fail("The same seed and history generated a different opportunity set.")
		return
	var chosen_id: StringName = StringName(first_options[1].get("id", &""))
	var accepted: Dictionary = first.resolve_offer_choice(chosen_id)
	var record: Dictionary = accepted.get("record", {})
	if int(record.get("pressure_cost", 0)) <= 0:
		_fail("Accepting an opportunity did not preserve its public research cost.")
		return
	if StringName(record.get("destination_signal", &"")) == &"":
		_fail("Accepting an opportunity did not record its destination signal.")
		return
	if StringName(record.get("opportunity_id", &"")) != chosen_id:
		_fail("The model resolved a different opportunity than the player selected.")
		return
	if Array(record.get("declined_opportunity_ids", [])).size() != 1:
		_fail("The competing opportunity was not closed after selection.")
		return
	var accepted_profile: Dictionary = first.get_destination_profile()
	if StringName(accepted_profile.get("id", &"unformed")) == &"unformed":
		_fail("An accepted opportunity did not form a visible destination profile.")
		return
	var rejected: Dictionary = second.resolve_offer_choice(&"")
	if int(Dictionary(rejected.get("record", {})).get("pressure_cost", -1)) != 0:
		_fail("Rejecting an opportunity still charged research pressure.")
		return
	var resting_profile: Dictionary = second.get_destination_profile()
	if StringName(resting_profile.get("id", &"")) != &"unformed":
		_fail("Resting created a destination signal.")
		return
	print("PHASE_THREE_OPPORTUNITY_MODEL: PASS")
	quit(0)


func _model(seed_value: int) -> RefCounted:
	var model: RefCounted = OPPORTUNITY_MODEL.new()
	var definitions: Array[Resource] = [
		COLLABORATION,
		INDUSTRY,
		STARTUP,
	]
	if not model.setup(seed_value, definitions):
		_fail("Could not configure the opportunity model.")
	return model


func _fail(message: String) -> void:
	push_error("PHASE_THREE_OPPORTUNITY_MODEL: %s" % message)
	quit(1)
