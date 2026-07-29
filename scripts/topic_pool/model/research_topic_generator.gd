extends RefCounted
class_name ResearchTopicGenerator

const MIN_CANDIDATES := 3
const MAX_CANDIDATES := 5
const MAX_GENERATION_ATTEMPTS := 20

var seed: int = 1
var growth_rank: int = 0
var archetypes: Array[ResearchTopicArchetype] = []
var context_tags: PackedStringArray = []
var available_method_categories: PackedStringArray = []
var generation_diagnostics: Array[String] = []
var fallback_count: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(
	run_seed: int,
	player_growth_rank: int,
	source_archetypes: Array[ResearchTopicArchetype]
) -> bool:
	if source_archetypes.size() < MIN_CANDIDATES:
		push_error("ResearchTopicGenerator requires at least three archetypes.")
		return false
	for archetype: ResearchTopicArchetype in source_archetypes:
		if archetype == null or not archetype.is_valid_definition():
			push_error("ResearchTopicGenerator received an invalid archetype.")
			return false
	seed = maxi(1, run_seed)
	growth_rank = clampi(player_growth_rank, 0, 3)
	archetypes = source_archetypes.duplicate()
	context_tags = []
	available_method_categories = _default_method_categories()
	generation_diagnostics.clear()
	fallback_count = 0
	_rng.seed = seed
	return true


func configure_context(
	current_context_tags: PackedStringArray,
	current_method_categories: PackedStringArray = []
) -> void:
	context_tags = current_context_tags.duplicate()
	available_method_categories = (
		_default_method_categories()
		if current_method_categories.is_empty()
		else current_method_categories.duplicate()
	)


func generate_candidates(requested_count: int = 0) -> Array[ResearchTopicCandidate]:
	generation_diagnostics.clear()
	fallback_count = 0
	var count: int = requested_count
	if count <= 0:
		count = _rng.randi_range(MIN_CANDIDATES, MAX_CANDIDATES)
	count = clampi(count, MIN_CANDIDATES, MAX_CANDIDATES)
	var pool: Array[ResearchTopicArchetype] = _eligible_archetypes()
	if pool.size() < count:
		generation_diagnostics.append(
			"eligible_pool_too_small:%d/%d" % [pool.size(), count]
		)
		count = pool.size()
	var generated: Array[ResearchTopicCandidate] = []
	for index: int in range(count):
		var candidate: ResearchTopicCandidate = _try_create_candidate(pool, index)
		if candidate == null:
			candidate = _create_safe_fallback(index, generated)
		if candidate == null:
			generation_diagnostics.append("candidate_generation_failed:%d" % index)
			break
		generated.append(candidate)
		_remove_archetype(pool, candidate.archetype)
	return generated


func _try_create_candidate(
	pool: Array[ResearchTopicArchetype],
	index: int
) -> ResearchTopicCandidate:
	for attempt: int in range(MAX_GENERATION_ATTEMPTS):
		var chosen_index: int = _choose_weighted_index(pool)
		if chosen_index < 0:
			return null
		var archetype: ResearchTopicArchetype = pool[chosen_index]
		var candidate: ResearchTopicCandidate = _create_candidate(archetype, index)
		var rejection: String = _candidate_rejection_reason(candidate)
		if rejection.is_empty():
			return candidate
		generation_diagnostics.append(
			"rejected:%s:attempt_%d:%s" % [archetype.id, attempt + 1, rejection]
		)
	return null


func _eligible_archetypes() -> Array[ResearchTopicArchetype]:
	var eligible: Array[ResearchTopicArchetype] = []
	for archetype: ResearchTopicArchetype in archetypes:
		var rejection: String = _archetype_rejection_reason(archetype)
		if rejection.is_empty():
			eligible.append(archetype)
		else:
			generation_diagnostics.append("filtered:%s:%s" % [archetype.id, rejection])
	return eligible


func _archetype_rejection_reason(archetype: ResearchTopicArchetype) -> String:
	if growth_rank < archetype.minimum_growth_rank:
		return "growth_rank"
	for required_tag: String in archetype.requires_context_tags:
		if not context_tags.has(required_tag):
			return "missing_context:%s" % required_tag
	for forbidden_tag: String in archetype.forbidden_context_tags:
		if context_tags.has(forbidden_tag):
			return "forbidden_context:%s" % forbidden_tag
	if _available_route_count(archetype) < 2:
		return "insufficient_method_routes"
	return ""


func _available_route_count(archetype: ResearchTopicArchetype) -> int:
	var count: int = 0
	for route: String in archetype.required_method_routes:
		var route_available: bool = true
		for category: String in route.split(">"):
			if not available_method_categories.has(category):
				route_available = false
				break
		if route_available:
			count += 1
	return count


func _choose_weighted_index(pool: Array[ResearchTopicArchetype]) -> int:
	var total_weight: int = 0
	var weights: Array[int] = []
	for archetype: ResearchTopicArchetype in pool:
		var weight: int = (
			_get_difficulty_weight(archetype.difficulty_tier)
			* archetype.generation_weight
		)
		weights.append(weight)
		total_weight += weight
	if total_weight <= 0:
		return -1
	var roll: int = _rng.randi_range(1, total_weight)
	var accumulated: int = 0
	for index: int in range(weights.size()):
		accumulated += weights[index]
		if roll <= accumulated:
			return index
	return weights.size() - 1


func _get_difficulty_weight(tier: ResearchTopicArchetype.DifficultyTier) -> int:
	var distance: int = int(tier) - growth_rank
	if distance > 1:
		return 0
	if distance == 1:
		return 15 + growth_rank * 5
	if distance == 0:
		return 50
	return maxi(10, 35 - abs(distance) * 8)


func _create_candidate(
	archetype: ResearchTopicArchetype,
	index: int
) -> ResearchTopicCandidate:
	var potential_variation: int = _rng.randi_range(0, 1)
	var candidate_potential: int = mini(3, archetype.base_potential + potential_variation)
	var candidate_reward: int = archetype.base_reward + (
		1 if candidate_potential > archetype.base_potential else 0
	)
	var deadline: int = _rng.randi_range(
		archetype.min_deadline_weeks,
		archetype.max_deadline_weeks
	)
	var risk_pool: Array[DualTopicRiskDefinition] = []
	for risk: DualTopicRiskDefinition in archetype.risk_pool:
		if archetype.allowed_risk_kinds.has(int(risk.kind)):
			risk_pool.append(risk)
	var risk_count: int = mini(
		risk_pool.size(),
		archetype.base_risk_count + (1 if candidate_potential >= 3 else 0)
	)
	_shuffle_risks(risk_pool)
	var selected_risks: Array[DualTopicRiskDefinition] = []
	for risk_index: int in range(risk_count):
		selected_risks.append(risk_pool[risk_index])
	var candidate := ResearchTopicCandidate.new()
	candidate.setup(
		StringName("%s_%d_%d" % [archetype.id, seed, index]),
		archetype,
		candidate_potential,
		candidate_reward,
		deadline,
		selected_risks
	)
	return candidate


func _candidate_rejection_reason(candidate: ResearchTopicCandidate) -> String:
	if candidate == null or candidate.archetype == null:
		return "invalid_candidate"
	if candidate.risks.size() < candidate.archetype.base_risk_count:
		return "insufficient_compatible_risks"
	for risk: DualTopicRiskDefinition in candidate.risks:
		if not candidate.archetype.allowed_risk_kinds.has(int(risk.kind)):
			return "incompatible_risk:%s" % risk.id
	if _available_route_count(candidate.archetype) < 2:
		return "insufficient_method_routes"
	if candidate.deadline_weeks < 3 or candidate.deadline_weeks > 8:
		return "invalid_deadline"
	return ""


func _create_safe_fallback(
	index: int,
	generated: Array[ResearchTopicCandidate]
) -> ResearchTopicCandidate:
	for archetype: ResearchTopicArchetype in archetypes:
		if not archetype.safe_fallback:
			continue
		if not _archetype_rejection_reason(archetype).is_empty():
			continue
		var already_used: bool = false
		for candidate: ResearchTopicCandidate in generated:
			if candidate.archetype == archetype:
				already_used = true
				break
		if already_used:
			continue
		var candidate: ResearchTopicCandidate = _create_candidate(archetype, index)
		if _candidate_rejection_reason(candidate).is_empty():
			fallback_count += 1
			generation_diagnostics.append("safe_fallback:%s" % archetype.id)
			return candidate
	return null


func _remove_archetype(
	pool: Array[ResearchTopicArchetype],
	archetype: ResearchTopicArchetype
) -> void:
	var index: int = pool.find(archetype)
	if index >= 0:
		pool.remove_at(index)


func _default_method_categories() -> PackedStringArray:
	return PackedStringArray([
		"investigation",
		"experiment",
		"organization",
		"writing",
		"collaboration",
		"survival",
	])


func _shuffle_risks(pool: Array[DualTopicRiskDefinition]) -> void:
	for index: int in range(pool.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var current: DualTopicRiskDefinition = pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = current
