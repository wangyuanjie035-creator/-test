extends SceneTree

const CATALOG: ResearchTopicCatalog = preload(
	"res://data/topic_pool/starter_topic_catalog.tres"
)


func _initialize() -> void:
	if not CATALOG.is_valid_catalog():
		_fail("Starter topic catalog is invalid.")
		return
	var first: Array[ResearchTopicCandidate] = _generate(240731, 0, 3)
	var repeated: Array[ResearchTopicCandidate] = _generate(240731, 0, 3)
	var different: Array[ResearchTopicCandidate] = _generate(1784352143, 0, 3)
	if first.size() != 3 or repeated.size() != 3 or different.size() != 3:
		_fail("Generator did not produce the requested candidate count.")
		return
	if _signatures(first) != _signatures(repeated):
		_fail("Same seed and growth rank produced different candidates.")
		return
	if _signatures(first) == _signatures(different):
		_fail("Different seeds produced the same complete candidate set.")
		return
	if _contains_tier(first, ResearchTopicArchetype.DifficultyTier.FRONTIER):
		_fail("A new player received a frontier topic.")
		return
	var fixed_seeds: Array[int] = [240731, 1784352143, 90177]
	var fixed_signatures: Dictionary[String, bool] = {}
	var fixed_first_archetypes: Dictionary[StringName, bool] = {}
	for fixed_seed: int in fixed_seeds:
		var fixed_candidates: Array[ResearchTopicCandidate] = _generate(fixed_seed, 0, 3)
		var signature := JSON.stringify(_signatures(fixed_candidates))
		fixed_signatures[signature] = true
		fixed_first_archetypes[fixed_candidates[0].archetype.id] = true
		for candidate: ResearchTopicCandidate in fixed_candidates:
			if candidate.reward < candidate.archetype.base_reward:
				_fail("A harder candidate reduced its archetype reward.")
				return
			if candidate.deadline_weeks < 3 or candidate.deadline_weeks > 8:
				_fail("A fixed-seed candidate produced an invalid deadline.")
				return
	if fixed_signatures.size() != fixed_seeds.size():
		_fail("The three registered balance seeds did not create distinct offers.")
		return
	if fixed_first_archetypes.size() < 2:
		_fail("All registered balance seeds shared the same first topic.")
		return

	var high_rank_frontier_count: int = 0
	for seed_offset: int in range(12):
		var high_rank: Array[ResearchTopicCandidate] = _generate(
			9000 + seed_offset,
			2,
			5
		)
		if _contains_tier(high_rank, ResearchTopicArchetype.DifficultyTier.FRONTIER):
			high_rank_frontier_count += 1
	if high_rank_frontier_count < 6:
		_fail("Growth did not make frontier topics meaningfully more common.")
		return

	var portfolio := ResearchPortfolioModel.new()
	if not portfolio.setup(first, 1):
		_fail("Single-slot portfolio setup failed.")
		return
	var first_pick: ResearchTopicCandidate = first[0]
	var second_pick: ResearchTopicCandidate = first[1]
	if not bool(portfolio.select_candidate(first_pick.candidate_id).get("success", false)):
		_fail("Could not select the first topic.")
		return
	var blocked: Dictionary = portfolio.select_candidate(second_pick.candidate_id)
	if blocked.get("reason", &"") != &"no_free_slot":
		_fail("Initial portfolio accepted more than one active topic.")
		return
	var archived: Dictionary = portfolio.archive_active_topic(
		first_pick.candidate_id,
		{"grade": &"withdrawn", "asset": &"risk_insight"}
	)
	if not bool(archived.get("success", false)) or portfolio.archive.size() != 1:
		_fail("Withdrawing a topic did not preserve an archive record.")
		return
	if not bool(portfolio.select_candidate(second_pick.candidate_id).get("success", false)):
		_fail("Freed slot could not accept another candidate.")
		return
	portfolio.increase_slot_capacity()
	if portfolio.slot_capacity != 2 or portfolio.get_free_slot_count() != 1:
		_fail("Portfolio growth did not unlock a second slot.")
		return
	print("DYNAMIC_TOPIC_POOL: PASS")
	quit(0)


func _generate(
	seed: int,
	growth_rank: int,
	count: int
) -> Array[ResearchTopicCandidate]:
	var generator := ResearchTopicGenerator.new()
	var typed_archetypes: Array[ResearchTopicArchetype] = []
	typed_archetypes.assign(CATALOG.archetypes)
	generator.setup(seed, growth_rank, typed_archetypes)
	return generator.generate_candidates(count)


func _signatures(candidates: Array[ResearchTopicCandidate]) -> Array[String]:
	var signatures: Array[String] = []
	for candidate: ResearchTopicCandidate in candidates:
		signatures.append(JSON.stringify(candidate.to_debug_dict()))
	return signatures


func _contains_tier(
	candidates: Array[ResearchTopicCandidate],
	tier: ResearchTopicArchetype.DifficultyTier
) -> bool:
	for candidate: ResearchTopicCandidate in candidates:
		if candidate.archetype.difficulty_tier == tier:
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
