extends SceneTree

const ENTRY_SCENE: PackedScene = preload(
	"res://scenes/topic_pool/dynamic_topic_entry.tscn"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var entry: DynamicTopicEntry = ENTRY_SCENE.instantiate() as DynamicTopicEntry
	entry.run_seed = 240731
	entry.growth_rank = 1
	root.add_child(entry)
	await process_frame
	await process_frame
	var option: OptionButton = entry.get_node(
		"Margin/Layout/ChoiceArea/CalibrationRow/InformationLevelOption"
	)
	var grid: GridContainer = entry.get_node(
		"Margin/Layout/ChoiceArea/CandidateScroll/CandidateGrid"
	)
	if option.item_count != 3 or option.selected != 1:
		_fail("Calibration control did not start on the balanced profile.")
		return
	var candidate_ids: Array[StringName] = []
	for candidate: ResearchTopicCandidate in entry.portfolio.candidates:
		candidate_ids.append(candidate.candidate_id)
	var balanced_text: String = (grid.get_child(0) as Button).text
	option.select(2)
	option.item_selected.emit(2)
	await process_frame
	var guided_text: String = (grid.get_child(0) as Button).text
	var refreshed_ids: Array[StringName] = []
	for candidate: ResearchTopicCandidate in entry.portfolio.candidates:
		refreshed_ids.append(candidate.candidate_id)
	if candidate_ids != refreshed_ids:
		_fail("Changing information level rerolled the candidates.")
		return
	if balanced_text == guided_text:
		_fail("Changing information level did not update the public clues.")
		return
	if entry.candidate_information_level != (
		ResearchTopicCandidatePresenter.InformationLevel.GUIDED
	):
		_fail("Calibration selection was not retained by the entry screen.")
		return
	print("PHASE_TWO_CALIBRATION_UI: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error("PHASE_TWO_CALIBRATION_UI: %s" % message)
	quit(1)
