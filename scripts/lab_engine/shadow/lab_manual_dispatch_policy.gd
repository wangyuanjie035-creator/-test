extends RefCounted

const CONVERSIONS: Dictionary[int, Dictionary] = {
	0: {"input": &"inspiration", "input_amount": 1, "output": &"raw_data", "output_amount": 2},
	1: {"input": &"raw_data", "input_amount": 4, "output": &"clean_data", "output_amount": 1},
	2: {"input": &"clean_data", "input_amount": 1, "output": &"charts", "output_amount": 1},
}

var used: bool = false
var result: Dictionary = {}

func available_links(state: RefCounted) -> Array[int]:
	var links: Array[int] = []
	if used or state.day < 4:
		return links
	for link: int in range(3):
		if int(state.slots[link].level) <= 0 or int(state.slots[link + 1].level) <= 0:
			continue
		var conversion: Dictionary = CONVERSIONS[link]
		if int(state.get(StringName(conversion.input))) < int(conversion.input_amount):
			continue
		var output_id: StringName = conversion.output
		if int(state.get(output_id)) + int(conversion.output_amount) > int(state.RESOURCE_LIMITS[output_id]):
			continue
		links.append(link)
	return links

func execute(state: RefCounted, link: int) -> Dictionary:
	if used:
		return result.duplicate(true)
	if not available_links(state).has(link):
		return {"applied": false, "link": link, "reason": &"unavailable"}
	var conversion: Dictionary = CONVERSIONS[link]
	var input_id: StringName = conversion.input
	var output_id: StringName = conversion.output
	var deltas: Dictionary[StringName, int] = {}
	deltas[input_id] = state.change_resource(input_id, -int(conversion.input_amount))
	deltas[output_id] = state.change_resource(output_id, int(conversion.output_amount))
	used = true
	result = {"applied": true, "day": state.day, "link": link, "deltas": deltas}
	return result.duplicate(true)
