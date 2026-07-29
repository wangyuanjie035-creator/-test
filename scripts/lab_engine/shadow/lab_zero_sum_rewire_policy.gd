extends RefCounted

const CONVERSIONS: Dictionary[int, Dictionary] = {
	0: {"input": &"inspiration", "input_amount": 1, "output": &"raw_data", "output_amount": 2},
	1: {"input": &"raw_data", "input_amount": 4, "output": &"clean_data", "output_amount": 1},
	2: {"input": &"clean_data", "input_amount": 1, "output": &"charts", "output_amount": 1},
	3: {"input": &"charts", "input_amount": 1, "output": &"paper_progress", "output_amount": 5},
}

var selected_link: int = -1

func eligible_links(state: RefCounted) -> Array[int]:
	var result: Array[int] = []
	for link: int in range(4):
		if int(state.slots[link].level) > 0 and int(state.slots[link + 1].level) > 0:
			result.append(link)
	return result

func select_link(state: RefCounted, link: int) -> Dictionary:
	if selected_link >= 0:
		return {"selected": true, "link": selected_link, "reason": &"already_selected"}
	if not eligible_links(state).has(link):
		return {"selected": false, "link": link, "reason": &"ineligible_link"}
	selected_link = link
	return {"selected": true, "link": link}

func apply_day(state: RefCounted, day_result: Dictionary) -> Dictionary:
	if selected_link < 0:
		return {"applied": false, "reason": &"no_link_selected"}
	var succeeded: Dictionary[int, bool] = {}
	for event: Dictionary in day_result.get("events", []):
		if bool(event.get("success", false)):
			succeeded[int(event.get("slot", -1))] = true
	if not bool(succeeded.get(selected_link, false)) or not bool(succeeded.get(selected_link + 1, false)):
		return {"applied": false, "link": selected_link, "reason": &"link_incomplete"}
	var conversion: Dictionary = CONVERSIONS[selected_link]
	var input_id: StringName = conversion.input
	var input_amount: int = int(conversion.input_amount)
	if int(state.get(input_id)) < input_amount:
		return {"applied": false, "link": selected_link, "reason": &"insufficient_stock"}
	var output_id: StringName = conversion.output
	var output_amount: int = int(conversion.output_amount)
	var output_limit: int = 1000000 if output_id == &"paper_progress" else int(state.RESOURCE_LIMITS[output_id])
	if int(state.get(output_id)) + output_amount > output_limit:
		return {"applied": false, "link": selected_link, "reason": &"output_would_clamp"}
	var deltas: Dictionary[StringName, int] = {}
	deltas[input_id] = state.change_resource(input_id, -input_amount)
	deltas[output_id] = state.change_resource(output_id, output_amount)
	return {"applied": true, "link": selected_link, "deltas": deltas}
