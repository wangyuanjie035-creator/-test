@tool
extends RefCounted
class_name RunSettlement

const STARTER_DECK_SIZE := 15


static func build(route: Variant, battle: Variant, reason: StringName) -> Dictionary:
	var completed_nodes: int = 0
	var total_nodes: int = 0
	if route != null:
		completed_nodes = int(route.get_completed_node_count())
		total_nodes = int(route.get_total_nodes())

	var deck_size: int = STARTER_DECK_SIZE
	var vitality: int = 0
	var max_vitality: int = 0
	if battle != null:
		deck_size = battle.deck_card_ids.size()
		vitality = battle.vitality
		max_vitality = battle.max_vitality

	var deck_growth: int = max(0, deck_size - STARTER_DECK_SIZE)
	var outcome_id := String(reason)
	var title := "阶段结算"
	var description := "这段研究经历留下了可复盘的东西。"

	match reason:
		&"route_completed":
			title = "阶段通过"
			description = "你完成了这一段研究路线，新的方法、卡牌和经验会留到后续旅程。"
		&"master_graduated":
			title = "顺利毕业"
			description = "论文主线已经立住，盲审意见被整理成可执行的修改清单。你完成了硕士阶段，也带走了一套能复用的研究方法。"
		&"outstanding_graduation":
			title = "优秀毕业"
			description = "论文质量、答辩状态和研究认可度都到达了更高标准。这不是单纯通关，而是一段可以反哺下一次旅程的高质量样本。"
		&"narrow_graduation":
			title = "擦线毕业"
			description = "过程并不漂亮，但你把论文从混乱里抢救了出来。它留下的不是体面，而是一份非常具体的复盘地图。"
		&"outstanding_doctoral_graduation":
			title = "优秀博士毕业"
			description = "博士论文、答辩状态和学术认可都达到了更高标准。这次毕业不只是结束，也是一份高质量研究样本。"
		&"doctoral_graduated":
			title = "博士毕业"
			description = "你完成了博士答辩。论文主线、方法叙事和委员会认可被收束成一份可以带走的研究身份。"
		&"delayed_doctoral_graduation":
			title = "延毕后毕业"
			description = "博士阶段被拉长过，但你最终完成了答辩。延毕留下的不是空白，而是一套更能承受复杂研究的复盘能力。"
		&"transfer_admitted":
			title = "转博资格确认"
			description = "导师同意把课题扩展成博士路线。真正的长线压力还在后面，但这次申请已经把方向、材料和支持关系固定下来了。"
		&"qualification_failed":
			title = "博士资格考核未过"
			description = "资格考核没有通过，但这次失败已经把博士阶段真正缺的东西暴露出来：问题链、理论根基和论文管线。它会变成下一次更扎实的准备。"
		&"project_midterm_failed":
			title = "项目中期检查未过"
			description = "项目中期检查没有过关，经费、数据管线和论文产出之间的矛盾被集中暴露。它会留下更具体的项目管理经验和论文复盘材料。"
		&"predefense_failed":
			title = "博士预答辩未过"
			description = "预答辩没有通过，但委员会已经把论文主线、方法叙事和答辩风险集中指出。下一次会带着更完整的答辩地图回来。"
		&"doctoral_defense_delayed":
			title = "博士答辩延期"
			description = "答辩没有在这一次完成，博士阶段被拖进博四和延毕压力。但这不是归零，答辩现场暴露出的缺口会变成下一次最清楚的修改清单。"
		&"supplementary_defense_failed":
			title = "补答辩再延期"
			description = "返修后仍然没能完成补答辩，但这次失败已经非常具体：修改矩阵、答辩表达和委员会沟通都留下了可带走的经验。"
		&"burnout":
			title = "精力耗尽"
			description = "这不是毫无意义的失败。中断前完成的节点、踩过的坑和积累的卡牌都会变成下一次的准备。"
		&"proposal_delayed":
			title = "开题延期"
			description = "这次开题没有一次通过，但问题已经被具体地暴露出来。导师和专家的追问会沉淀成下一次更稳的准备。"
		&"midterm_warning":
			title = "中期预警"
			description = "中期考核暴露了材料和时间表的缺口。它很难看，但也足够具体，下一次可以围绕数据、草稿和节奏重新组织。"
		&"blind_review_failed":
			title = "盲审未过"
			description = "盲审意见很重，但它把论文最薄弱的论证、数据和格式问题全部标了出来。下一次会带着更清楚的修改地图回来。"
		_:
			outcome_id = "unknown"

	var resources := _build_resources(reason, completed_nodes, deck_growth, vitality, max_vitality, battle)
	return {
		"outcome_id": outcome_id,
		"title": title,
		"description": description,
		"completed_nodes": completed_nodes,
		"total_nodes": total_nodes,
		"deck_size": deck_size,
		"deck_growth": deck_growth,
		"vitality": vitality,
		"max_vitality": max_vitality,
		"resources": resources,
		"summary_text": _format_summary(title, description, completed_nodes, total_nodes, deck_size, vitality, max_vitality, resources),
	}


static func _build_resources(
	reason: StringName,
	completed_nodes: int,
	deck_growth: int,
	vitality: int,
	max_vitality: int,
	battle: Variant
) -> Dictionary:
	var experience_lessons: int = max(1, completed_nodes * 2 + deck_growth)
	var methodology_notes: int = completed_nodes + int(deck_growth / 2)
	var psychological_resilience: int = 0
	var paper_fragments: int = 0
	var black_history_archive: int = 0

	if reason == &"route_completed":
		experience_lessons += 2
		methodology_notes += 2
		paper_fragments += 1
		if battle != null and bool(battle.is_boss_encounter):
			methodology_notes += 2
			paper_fragments += 1

	if reason == &"master_graduated":
		experience_lessons += 2
		methodology_notes += 3
		paper_fragments += 3

	if reason == &"outstanding_graduation":
		experience_lessons += 3
		methodology_notes += 4
		paper_fragments += 4

	if reason == &"narrow_graduation":
		experience_lessons += 4
		methodology_notes += 1
		psychological_resilience += 1
		paper_fragments += 1

	if reason == &"outstanding_doctoral_graduation":
		experience_lessons += 6
		methodology_notes += 8
		psychological_resilience += 2
		paper_fragments += 8

	if reason == &"doctoral_graduated":
		experience_lessons += 5
		methodology_notes += 6
		psychological_resilience += 2
		paper_fragments += 6

	if reason == &"delayed_doctoral_graduation":
		experience_lessons += 8
		methodology_notes += 4
		psychological_resilience += 3
		paper_fragments += 4

	if reason == &"transfer_admitted":
		experience_lessons += 2
		methodology_notes += 3
		paper_fragments += 2

	if reason == &"qualification_failed":
		experience_lessons += 6
		methodology_notes += 3
		psychological_resilience += 1
		paper_fragments += 2
		black_history_archive += 1
		if battle != null:
			var boss_progress: int = int(battle.progress)
			var boss_target: int = max(1, int(battle.target_progress))
			if boss_progress >= int(boss_target * 0.5):
				paper_fragments += 1

	if reason == &"project_midterm_failed":
		experience_lessons += 7
		methodology_notes += 3
		psychological_resilience += 1
		paper_fragments += 3
		black_history_archive += 1
		if battle != null:
			var boss_progress: int = int(battle.progress)
			var boss_target: int = max(1, int(battle.target_progress))
			if boss_progress >= int(boss_target * 0.5):
				paper_fragments += 1

	if reason == &"predefense_failed":
		experience_lessons += 8
		methodology_notes += 4
		psychological_resilience += 2
		paper_fragments += 4
		black_history_archive += 1
		if battle != null:
			var boss_progress: int = int(battle.progress)
			var boss_target: int = max(1, int(battle.target_progress))
			if boss_progress >= int(boss_target * 0.5):
				paper_fragments += 1

	if reason == &"doctoral_defense_delayed":
		experience_lessons += 10
		methodology_notes += 5
		psychological_resilience += 3
		paper_fragments += 5
		black_history_archive += 1
		if battle != null:
			var boss_progress: int = int(battle.progress)
			var boss_target: int = max(1, int(battle.target_progress))
			if boss_progress >= int(boss_target * 0.5):
				paper_fragments += 1

	if reason == &"supplementary_defense_failed":
		experience_lessons += 12
		methodology_notes += 6
		psychological_resilience += 4
		paper_fragments += 5
		black_history_archive += 1
		if battle != null:
			var boss_progress: int = int(battle.progress)
			var boss_target: int = max(1, int(battle.target_progress))
			if boss_progress >= int(boss_target * 0.5):
				paper_fragments += 1

	if reason == &"burnout":
		experience_lessons += 1
		psychological_resilience += 2
		black_history_archive += 1

	if reason == &"proposal_delayed":
		experience_lessons += 3
		methodology_notes += 1
		psychological_resilience += 1
		black_history_archive += 1
		if battle != null:
			var boss_progress: int = int(battle.progress)
			var boss_target: int = max(1, int(battle.target_progress))
			if boss_progress >= int(boss_target * 0.5):
				paper_fragments += 1

	if reason == &"midterm_warning":
		experience_lessons += 4
		methodology_notes += 2
		psychological_resilience += 1
		black_history_archive += 1
		if battle != null:
			var boss_progress: int = int(battle.progress)
			var boss_target: int = max(1, int(battle.target_progress))
			if boss_progress >= int(boss_target * 0.5):
				paper_fragments += 1

	if reason == &"blind_review_failed":
		experience_lessons += 5
		methodology_notes += 2
		psychological_resilience += 1
		paper_fragments += 2
		black_history_archive += 1
		if battle != null:
			var boss_progress: int = int(battle.progress)
			var boss_target: int = max(1, int(battle.target_progress))
			if boss_progress >= int(boss_target * 0.5):
				paper_fragments += 1

	if max_vitality > 0 and vitality > 0 and vitality <= int(max_vitality * 0.35):
		psychological_resilience += 1

	if battle != null:
		experience_lessons += max(0, battle.get_resource(&"experience_lessons"))
		methodology_notes += max(0, battle.get_resource(&"methodology_notes"))
		paper_fragments += max(0, battle.get_resource(&"paper_fragments"))

	return {
		"experience_lessons": experience_lessons,
		"methodology_notes": methodology_notes,
		"psychological_resilience": psychological_resilience,
		"paper_fragments": paper_fragments,
		"black_history_archive": black_history_archive,
	}


static func _format_summary(
	title: String,
	description: String,
	completed_nodes: int,
	total_nodes: int,
	deck_size: int,
	vitality: int,
	max_vitality: int,
	resources: Dictionary
) -> String:
	var lines: Array[String] = []
	lines.append("%s" % title)
	lines.append(description)
	lines.append("完成节点：%d/%d | 当前牌组：%d 张 | 精力：%d/%d" % [completed_nodes, total_nodes, deck_size, vitality, max_vitality])
	lines.append("获得局外资源：经验教训 +%d，方法论笔记 +%d，心理韧性 +%d，论文碎片 +%d，黑历史档案 +%d。" % [
		int(resources.get("experience_lessons", 0)),
		int(resources.get("methodology_notes", 0)),
		int(resources.get("psychological_resilience", 0)),
		int(resources.get("paper_fragments", 0)),
		int(resources.get("black_history_archive", 0)),
	])
	return "\n".join(lines)
