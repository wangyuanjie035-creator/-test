extends SceneTree

const CATALOG: ResearchTopicCatalog = preload(
	"res://data/topic_pool/starter_topic_catalog.tres"
)
const PRESENTER := preload(
	"res://scripts/topic_pool/ui/research_topic_candidate_presenter.gd"
)


func _initialize() -> void:
	var archetypes: Array[ResearchTopicArchetype] = []
	archetypes.assign(CATALOG.archetypes)
	var generator := ResearchTopicGenerator.new()
	if not generator.setup(240731, 0, archetypes):
		_fail("Could not configure the topic generator.")
		return
	var candidates: Array[ResearchTopicCandidate] = generator.generate_candidates(3)
	if candidates.size() != 3:
		_fail("Phase-two information test did not receive three candidates.")
		return
	for candidate: ResearchTopicCandidate in candidates:
		var profile: Dictionary = PRESENTER.build_public_profile(candidate)
		for field: String in [
			"uncertainty",
			"known_clue",
			"base_value",
			"potential_outlook",
			"rule_hint",
		]:
			if String(profile.get(field, "")).is_empty():
				_fail("Public candidate profile omitted %s." % field)
				return
		var veiled: Dictionary = PRESENTER.build_public_profile(
			candidate,
			PRESENTER.InformationLevel.VEILED
		)
		var guided: Dictionary = PRESENTER.build_public_profile(
			candidate,
			PRESENTER.InformationLevel.GUIDED
		)
		if veiled.get("known_clue", "") == guided.get("known_clue", ""):
			_fail("Information levels do not produce a meaningful comparison.")
			return
		for information_level: ResearchTopicCandidatePresenter.InformationLevel in [
			PRESENTER.InformationLevel.VEILED,
			PRESENTER.InformationLevel.BALANCED,
			PRESENTER.InformationLevel.GUIDED,
		]:
			var variant_text: String = PRESENTER.format_candidate_card(
				candidate,
				information_level
			)
			if "风险槽：" in variant_text or "预期收益：" in variant_text:
				_fail("An information variant exposes exact risk count or reward.")
				return
	var card_text: String = PRESENTER.format_candidate_card(candidates[0])
	if "风险槽：" in card_text or "预期收益：" in card_text:
		_fail("Candidate card still exposes exact risk count or reward.")
		return
	if "风险轮廓：" not in card_text or "潜在成果：" not in card_text:
		_fail("Candidate card does not replace exact values with public clues.")
		return
	print("PHASE_TWO_CANDIDATE_INFORMATION: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
