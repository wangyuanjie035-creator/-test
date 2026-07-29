class_name LabRunState
extends RefCounted

const RESOURCE_LIMITS: Dictionary[StringName, int] = {
	&"inspiration": 10, &"raw_data": 20, &"clean_data": 10,
	&"charts": 10, &"energy": 8, &"technical_debt": 10,
}

var day: int = 1
var inspiration: int = 0
var raw_data: int = 0
var clean_data: int = 0
var charts: int = 0
var paper_progress: int = 0
var energy: int = 8
var technical_debt: int = 0
var heat: int = 0
var automation_locked: bool = false
var stopped_slot: int = -1
var slots: Dictionary[int, Dictionary] = {}
var total_triggers: int = 0
var highest_combo: int = 0
var highest_daily_progress: int = 0
var reached_debt_ten: bool = false
var had_shutdown: bool = false
var maintenance_ready: bool = false
var maintenance_prevented_slot: int = -1
var _next_instance_id: int = 1

func _init() -> void:
	for slot: int in range(6):
		slots[slot] = {"card_id": &"", "level": 0, "days_installed": 0, "instance_id": 0}

func install(card: Resource) -> String:
	var entry: Dictionary = slots[card.slot]
	if entry.card_id == card.id:
		entry.level = mini(2, int(entry.level) + 1)
		slots[card.slot] = entry
		return "upgrade"
	entry = {
		"card_id": card.id,
		"level": 1,
		"days_installed": 0,
		"instance_id": _next_instance_id,
	}
	_next_instance_id += 1
	slots[card.slot] = entry
	return "install"

func change_resource(resource_id: StringName, delta: int) -> int:
	var before: int = int(get(resource_id))
	var after: int
	if resource_id == &"paper_progress":
		after = maxi(0, before + delta)
	else:
		after = clampi(before + delta, 0, RESOURCE_LIMITS[resource_id])
	set(resource_id, after)
	if resource_id == &"technical_debt" and after >= 10:
		automation_locked = true
		reached_debt_ten = true
	return after - before

func snapshot() -> Dictionary:
	return {
		"day": day, "inspiration": inspiration, "raw_data": raw_data,
		"clean_data": clean_data, "charts": charts, "paper_progress": paper_progress,
		"energy": energy, "technical_debt": technical_debt, "heat": heat,
		"automation_locked": automation_locked, "stopped_slot": stopped_slot,
		"slots": slots.duplicate(true), "total_triggers": total_triggers,
		"highest_combo": highest_combo, "highest_daily_progress": highest_daily_progress,
		"maintenance_ready": maintenance_ready,
		"maintenance_prevented_slot": maintenance_prevented_slot,
	}

func duplicate_run() -> RefCounted:
	var copy: RefCounted = get_script().new()
	for property_name: StringName in [
		&"day", &"inspiration", &"raw_data", &"clean_data", &"charts",
		&"paper_progress", &"energy", &"technical_debt", &"heat",
		&"automation_locked", &"stopped_slot", &"total_triggers",
		&"highest_combo", &"highest_daily_progress", &"reached_debt_ten",
		&"had_shutdown", &"_next_instance_id",
		&"maintenance_ready", &"maintenance_prevented_slot",
	]:
		copy.set(property_name, get(property_name))
	copy.slots = slots.duplicate(true)
	return copy
