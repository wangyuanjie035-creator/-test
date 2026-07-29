extends SceneTree

const CATALOG: ResearchTopicCatalog = preload(
	"res://data/topic_pool/starter_topic_catalog.tres"
)
const PRESENTER := preload(
	"res://scripts/topic_pool/ui/research_topic_candidate_presenter.gd"
)
const AUDIT_SEEDS: Array[int] = [240731, 240917, 241103, 241219, 250106]


func _initialize() -> void:
	var archetypes: Array[ResearchTopicArchetype] = []
	archetypes.assign(CATALOG.archetypes)
	var comparisons: Array[Dictionary] = []
	for seed_value: int in AUDIT_SEEDS:
		var generator := ResearchTopicGenerator.new()
		if not generator.setup(seed_value, 1, archetypes):
			_fail("Generator setup failed for seed %d." % seed_value)
			return
		var candidates: Array[ResearchTopicCandidate] = generator.generate_candidates(3)
		if candidates.size() != 3:
			_fail("Seed %d did not generate three candidates." % seed_value)
			return
		for candidate: ResearchTopicCandidate in candidates:
			comparisons.append({
				"seed": seed_value,
				"candidate_id": candidate.candidate_id,
				"veiled": PRESENTER.build_public_profile(
					candidate,
					PRESENTER.InformationLevel.VEILED
				),
				"balanced": PRESENTER.build_public_profile(
					candidate,
					PRESENTER.InformationLevel.BALANCED
				),
				"guided": PRESENTER.build_public_profile(
					candidate,
					PRESENTER.InformationLevel.GUIDED
				),
			})
	var path := "res://.temp/phase2_risk_outline_comparison.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write the comparison artifact.")
		return
	file.store_string(JSON.stringify({
		"status": "OWNER_CALIBRATION_PASS_EXTERNAL_RECHECK_PENDING",
		"formal_default": "guided",
		"comparison_count": comparisons.size(),
		"comparisons": comparisons,
	}, "\t"))
	file.close()
	print(
		"PHASE_TWO_RISK_OUTLINE_AUDIT: PASS (%d comparisons, default GUIDED)"
		% comparisons.size()
	)
	quit(0)


func _fail(message: String) -> void:
	push_error("PHASE_TWO_RISK_OUTLINE_AUDIT: %s" % message)
	quit(1)
