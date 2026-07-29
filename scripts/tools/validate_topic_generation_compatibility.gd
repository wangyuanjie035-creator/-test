extends SceneTree

const CATALOG: ResearchTopicCatalog = preload(
	"res://data/topic_pool/starter_topic_catalog.tres"
)


func _initialize() -> void:
	if not CATALOG.is_valid_catalog():
		_fail("Topic catalog compatibility metadata is invalid.")
		return
	if not _validate_opening_candidates():
		return
	if not _validate_context_filter():
		return
	if not _validate_method_route_filter():
		return
	if not _validate_late_unlock():
		return
	print("TOPIC_GENERATION_COMPATIBILITY: PASS")
	quit(0)


func _validate_opening_candidates() -> bool:
	for run_seed: int in [240731, 1784352143, 90177, 44021]:
		var generator: ResearchTopicGenerator = _new_generator(run_seed, 0)
		var candidates: Array[ResearchTopicCandidate] = generator.generate_candidates(3)
		if candidates.size() != 3:
			return _fail("Opening generation did not return three legal candidates.")
		for candidate: ResearchTopicCandidate in candidates:
			if candidate.archetype.minimum_growth_rank > 0:
				return _fail("Opening generation bypassed growth rank.")
			if not _candidate_risks_are_compatible(candidate):
				return _fail("Opening generation produced an incompatible risk.")
			if candidate.archetype.required_method_routes.size() < 2:
				return _fail("Candidate has fewer than two declared routes.")
	return true


func _validate_context_filter() -> bool:
	var generator: ResearchTopicGenerator = _new_generator(240731, 1)
	generator.configure_context(PackedStringArray(["wet_lab_only"]))
	var candidates: Array[ResearchTopicCandidate] = generator.generate_candidates(5)
	for candidate: ResearchTopicCandidate in candidates:
		if candidate.archetype.forbidden_context_tags.has("wet_lab_only"):
			return _fail("Forbidden context did not filter a theory-only topic.")
	return true


func _validate_method_route_filter() -> bool:
	var generator: ResearchTopicGenerator = _new_generator(240731, 0)
	generator.configure_context(
		PackedStringArray(),
		PackedStringArray(["investigation", "experiment"])
	)
	var candidates: Array[ResearchTopicCandidate] = generator.generate_candidates(3)
	if not candidates.is_empty():
		return _fail("Generator accepted topics without two available method routes.")
	if generator.generation_diagnostics.is_empty():
		return _fail("Rejected generation did not produce diagnostics.")
	return true


func _validate_late_unlock() -> bool:
	var deployment_seen: bool = false
	for seed_offset: int in range(40):
		var generator: ResearchTopicGenerator = _new_generator(7000 + seed_offset, 2)
		generator.configure_context(PackedStringArray(["advanced_equipment"]))
		for candidate: ResearchTopicCandidate in generator.generate_candidates(5):
			if candidate.archetype.id == &"real_world_deployment":
				deployment_seen = true
				break
		if deployment_seen:
			break
	if not deployment_seen:
		return _fail("Late growth never unlocked the advanced equipment topic.")
	return true


func _candidate_risks_are_compatible(candidate: ResearchTopicCandidate) -> bool:
	for risk: DualTopicRiskDefinition in candidate.risks:
		if not candidate.archetype.allowed_risk_kinds.has(int(risk.kind)):
			return false
	return true


func _new_generator(run_seed: int, growth_rank: int) -> ResearchTopicGenerator:
	var generator := ResearchTopicGenerator.new()
	var typed_archetypes: Array[ResearchTopicArchetype] = []
	typed_archetypes.assign(CATALOG.archetypes)
	assert(generator.setup(run_seed, growth_rank, typed_archetypes))
	return generator


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
