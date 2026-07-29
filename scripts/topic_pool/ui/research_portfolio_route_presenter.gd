class_name ResearchPortfolioRoutePresenter
extends RefCounted


static func build_route_profile(topics: Array[ResearchTopicCandidate]) -> Dictionary:
	if topics.size() < 2:
		return {
			"route_id": &"single",
			"title": "专注单课题",
			"tradeoff": "低负担 · 收益稳定",
			"mechanic": "没有组合压力；学年结算额外缓解压力。",
			"tendency": "适配：稳健复现 / 集中验证",
		}

	var shared_tags: PackedStringArray = _shared_tags(topics[0], topics[1])
	if not shared_tags.is_empty():
		return {
			"route_id": &"synergy",
			"title": "协同双课题",
			"tradeoff": "共享产能 · 中等上限",
			"mechanic": "每周首次产出证据时，另一课题证据 +1。",
			"tendency": "适配：连续实验 / 交叉验证",
			"shared_tags": shared_tags,
		}

	return {
		"route_id": &"conflict",
		"title": "冲突双课题",
		"tradeoff": "高压并行 · 高声望上限",
		"mechanic": "两课题都推进的周末压力 +1；成功结算获得更高声望。",
		"tendency": "适配：风险探索 / 止损回收",
	}


static func format_route_profile(topics: Array[ResearchTopicCandidate]) -> String:
	var profile: Dictionary = build_route_profile(topics)
	var lines: PackedStringArray = [
		"路线预览｜%s" % String(profile.get("title", "")),
		String(profile.get("tradeoff", "")),
		String(profile.get("mechanic", "")),
		String(profile.get("tendency", "")),
	]
	var shared_tags: PackedStringArray = profile.get("shared_tags", PackedStringArray())
	if not shared_tags.is_empty():
		lines.insert(2, "共同方向：%s" % " / ".join(shared_tags))
	return "\n".join(lines)


static func _shared_tags(
	first: ResearchTopicCandidate,
	second: ResearchTopicCandidate
) -> PackedStringArray:
	var shared := PackedStringArray()
	for tag: String in first.archetype.tags:
		if second.archetype.tags.has(tag):
			shared.append(tag)
	return shared
