extends SceneTree

const ROUTE_PRESENTER := preload(
	"res://scripts/topic_pool/ui/research_portfolio_route_presenter.gd"
)


func _initialize() -> void:
	var theory: ResearchTopicCandidate = _candidate(&"theory", PackedStringArray(["theory"]))
	var shared: ResearchTopicCandidate = _candidate(
		&"shared",
		PackedStringArray(["theory", "data"])
	)
	var engineering: ResearchTopicCandidate = _candidate(
		&"engineering",
		PackedStringArray(["engineering"])
	)

	if not _expect_route([theory], &"single", "稳健复现"):
		return
	if not _expect_route([theory, shared], &"synergy", "另一课题证据 +1"):
		return
	if not _expect_route([theory, engineering], &"conflict", "周末压力 +1"):
		return
	print("PHASE_TWO_ROUTE_PROFILES: PASS")
	quit(0)


func _expect_route(
	topics: Array[ResearchTopicCandidate],
	expected_route: StringName,
	required_text: String
) -> bool:
	var profile: Dictionary = ROUTE_PRESENTER.build_route_profile(topics)
	if StringName(profile.get("route_id", &"")) != expected_route:
		return _fail("Unexpected route profile: %s" % profile)
	var formatted: String = ROUTE_PRESENTER.format_route_profile(topics)
	if not formatted.contains(required_text):
		return _fail("Route profile omitted its decision consequence: %s" % formatted)
	return true


func _candidate(id_value: StringName, tags: PackedStringArray) -> ResearchTopicCandidate:
	var archetype := ResearchTopicArchetype.new()
	archetype.id = id_value
	archetype.display_name = String(id_value)
	archetype.tags = tags
	var candidate := ResearchTopicCandidate.new()
	candidate.candidate_id = id_value
	candidate.archetype = archetype
	return candidate


func _fail(message: String) -> bool:
	push_error("PHASE_TWO_ROUTE_PROFILES: %s" % message)
	quit(1)
	return false
