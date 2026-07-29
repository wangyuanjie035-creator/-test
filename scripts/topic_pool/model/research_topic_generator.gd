extends RefCounted
class_name ResearchTopicGenerator

const MIN_CANDIDATES := 3
const MAX_CANDIDATES := 5

var seed: int = 1
var growth_rank: int = 0
var archetypes: Array[ResearchTopicArchetype] = []
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
	_rng.seed = seed
	return true


func generate_candidates(requested_count: int = 0) -> Array[ResearchTopicCandidate]:
	var count: int = requested_count
	if count <= 0:
		count = _rng.randi_range(MIN_CANDIDATES, MAX_CANDIDATES)
	count = clampi(count, MIN_CANDIDATES, mini(MAX_CANDIDATES, archetypes.size()))
	var pool: Array[ResearchTopicArchetype] = archetypes.duplicate()
	var generated: Array[ResearchTopicCandidate] = []
	for index: int in range(count):
		var chosen_index: int = _choose_weighted_index(pool)
		if chosen_index < 0:
			break
		var archetype: ResearchTopicArchetype = pool.pop_at(chosen_index)
		generated.append(_create_candidate(archetype, index))
	return generated


func _choose_weighted_index(pool: Array[ResearchTopicArchetype]) -> int:
	var total_weight: int = 0
	var weights: Array[int] = []
	for archetype: ResearchTopicArchetype in pool:
		var weight: int = _get_difficulty_weight(archetype.difficulty_tier)
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
	var risk_count: int = mini(
		archetype.risk_pool.size(),
		archetype.base_risk_count + (1 if candidate_potential >= 3 else 0)
	)
	var risk_pool: Array[DualTopicRiskDefinition] = archetype.risk_pool.duplicate()
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


func _shuffle_risks(pool: Array[DualTopicRiskDefinition]) -> void:
	for index: int in range(pool.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var current: DualTopicRiskDefinition = pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = current
