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
	var low_pressure: RefCounted = _model(240731)
	var normal_context: Dictionary = {
		"prestige": 2,
		"failure_assets": 1,
		"route_id": &"single",
		"starting_pressure": 1,
		"max_pressure": AcademicYearModel.MAX_PRESSURE,
	}
	var normal_result: Dictionary = low_pressure.generate_offers(2, normal_context)
	if not bool(normal_result.get("success", false)):
		_fail("A valid low-pressure history generated no opportunity.")
		return
	var normal_offers: Array = normal_result.get("opportunities", [])
	if normal_offers.size() != 2:
		_fail("The fixed-seed comparison did not produce two choices.")
		return
	for offer: Dictionary in normal_offers:
		if not bool(offer.get("affordable", false)):
			_fail("A low-pressure opportunity was incorrectly blocked.")
			return
	if (
		StringName(normal_offers[0].get("effect_id", &""))
		== StringName(normal_offers[1].get("effect_id", &""))
	):
		_fail("Competing opportunities offered the same immediate benefit.")
		return

	var high_pressure: RefCounted = _model(240731)
	var capped_context: Dictionary = normal_context.duplicate(true)
	capped_context["starting_pressure"] = AcademicYearModel.MAX_PRESSURE
	var capped_result: Dictionary = high_pressure.generate_offers(2, capped_context)
	var capped_offers: Array = capped_result.get("opportunities", [])
	if capped_offers.is_empty():
		_fail("Blocked opportunities disappeared instead of explaining the constraint.")
		return
	for offer: Dictionary in capped_offers:
		if bool(offer.get("affordable", true)):
			_fail("Pressure-capped history exposed a free positive-cost opportunity.")
			return
	var blocked_id: StringName = StringName(capped_offers[0].get("id", &""))
	var blocked_resolution: Dictionary = high_pressure.resolve_offer_choice(blocked_id)
	if (
		bool(blocked_resolution.get("success", true))
		or StringName(blocked_resolution.get("reason", &"")) != &"pressure_capacity"
	):
		_fail("The model accepted an opportunity whose cost could not be paid.")
		return
	var rest_resolution: Dictionary = high_pressure.resolve_offer_choice(&"")
	if not bool(rest_resolution.get("success", false)):
		_fail("A pressure-capped history could not choose conservative rest.")
		return

	var failed_history: RefCounted = _model(3301)
	var failed_context: Dictionary = normal_context.duplicate(true)
	failed_context["prestige"] = 0
	failed_context["failure_assets"] = 1
	var failed_result: Dictionary = failed_history.generate_offers(2, failed_context)
	var failed_offers: Array = failed_result.get("opportunities", [])
	var found_failure_offer: bool = false
	for offer: Dictionary in failed_offers:
		if StringName(offer.get("id", &"")) == &"startup_pilot":
			found_failure_offer = true
	if not found_failure_offer:
		_fail("Failure assets did not unlock their distinct opportunity.")
		return

	print("PHASE_THREE_OPPORTUNITY_BALANCE: PASS")
	quit(0)


func _model(seed_value: int) -> RefCounted:
	var model: RefCounted = OPPORTUNITY_MODEL.new()
	var definitions: Array[Resource] = [COLLABORATION, INDUSTRY, STARTUP]
	if not model.setup(seed_value, definitions):
		_fail("Could not configure the opportunity model.")
	return model


func _fail(message: String) -> void:
	push_error("PHASE_THREE_OPPORTUNITY_BALANCE: %s" % message)
	quit(1)
