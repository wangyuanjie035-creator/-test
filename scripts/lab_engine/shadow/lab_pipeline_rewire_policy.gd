extends RefCounted

const LINK_REWARDS: Dictionary[int, Dictionary] = {
	0: {&"raw_data": 1},
	1: {&"clean_data": 1},
	2: {&"charts": 1},
	3: {&"paper_progress": 3},
}

var selected_link: int = -1

func eligible_links(state: RefCounted) -> Array[int]:
	var links: Array[int] = []
	for upstream_slot: int in range(4):
		if int(state.slots[upstream_slot].level) > 0 and int(state.slots[upstream_slot + 1].level) > 0:
			links.append(upstream_slot)
	return links

func select_link(state: RefCounted, upstream_slot: int) -> Dictionary:
	if selected_link >= 0:
		return {"selected": true, "link": selected_link, "reason": &"already_selected"}
	if not eligible_links(state).has(upstream_slot):
		return {"selected": false, "link": upstream_slot, "reason": &"ineligible_link"}
	selected_link = upstream_slot
	return {"selected": true, "link": selected_link}

func apply_day(state: RefCounted, day_result: Dictionary) -> Dictionary:
	if selected_link < 0:
		return {"applied": false, "reason": &"no_link_selected"}
	var upstream_succeeded: bool = false
	var downstream_succeeded: bool = false
	for event: Dictionary in day_result.get("events", []):
		if not bool(event.get("success", false)):
			continue
		var slot: int = int(event.get("slot", -1))
		upstream_succeeded = upstream_succeeded or slot == selected_link
		downstream_succeeded = downstream_succeeded or slot == selected_link + 1
	if not upstream_succeeded or not downstream_succeeded:
		return {"applied": false, "link": selected_link, "reason": &"link_incomplete"}
	var deltas: Dictionary[StringName, int] = {}
	for resource_id: StringName in LINK_REWARDS[selected_link]:
		deltas[resource_id] = state.change_resource(resource_id, int(LINK_REWARDS[selected_link][resource_id]))
	return {"applied": true, "link": selected_link, "deltas": deltas}
