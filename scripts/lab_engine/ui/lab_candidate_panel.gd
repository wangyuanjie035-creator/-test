class_name LabCandidatePanel
extends HBoxContainer

signal candidate_selected(index: int)

const CANDIDATE_BUTTON_SCRIPT := preload("res://scripts/lab_engine/ui/lab_candidate_button.gd")

var _buttons: Array[Button] = []

func _ready() -> void:
	name = "CandidateBox"
	add_theme_constant_override("separation", 9)
	custom_minimum_size = Vector2(0, 142)

func show_candidates(items: Array[Dictionary], selected_index: int) -> void:
	_clear_buttons()
	for index: int in range(items.size()):
		var item: Dictionary = items[index]
		var button: Button = CANDIDATE_BUTTON_SCRIPT.new()
		button.name = "CandidateButton%d" % index
		button.setup(item.title, item.slot_name, item.description, item.action_hint, int(item.get("category_id", 0)))
		button.pressed.connect(candidate_selected.emit.bind(index))
		add_child(button)
		_buttons.append(button)
	set_selected(selected_index)

func set_selected(index: int) -> void:
	for button_index: int in range(_buttons.size()):
		_buttons[button_index].set_selected(button_index == index)

func set_interaction_enabled(enabled: bool) -> void:
	for button: Button in _buttons:
		button.disabled = not enabled

func _clear_buttons() -> void:
	for button: Button in _buttons:
		if is_instance_valid(button):
			remove_child(button)
			button.queue_free()
	_buttons.clear()
