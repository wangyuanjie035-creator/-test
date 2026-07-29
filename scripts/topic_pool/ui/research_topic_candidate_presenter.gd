extends RefCounted
class_name ResearchTopicCandidatePresenter


static func build_public_profile(candidate: ResearchTopicCandidate) -> Dictionary:
	if candidate == null or candidate.archetype == null:
		return {}
	return {
		"uncertainty": _uncertainty_text(candidate.archetype.difficulty_tier),
		"known_clue": _known_clue_text(candidate.archetype.generation_tags),
		"base_value": _base_value_text(candidate.archetype.base_reward),
		"potential_outlook": _potential_outlook_text(candidate.potential),
		"rule_hint": _rule_hint_text(candidate.special_rule),
	}


static func format_candidate_card(candidate: ResearchTopicCandidate) -> String:
	if candidate == null or candidate.archetype == null:
		return "无效课题"
	var tier_names: Array[String] = ["常规", "进阶", "前沿", "禁区"]
	var tags := "、".join(candidate.archetype.tags)
	var profile: Dictionary = build_public_profile(candidate)
	return (
		"%s\n\n%s\n\n难度：%s    窗口：%d 周\n"
		+ "风险轮廓：%s\n已知疑点：%s\n"
		+ "基础价值：%s\n潜在成果：%s\n标签：%s\n\n%s"
	) % [
		candidate.archetype.display_name,
		candidate.archetype.premise,
		tier_names[candidate.archetype.difficulty_tier],
		candidate.deadline_weeks,
		String(profile.get("uncertainty", "尚待调查")),
		String(profile.get("known_clue", "目前只有初步线索")),
		String(profile.get("base_value", "可形成基础研究资产")),
		String(profile.get("potential_outlook", "真实上限未知")),
		tags,
		String(profile.get("rule_hint", "线索：标准研究流程")),
	]


static func _uncertainty_text(
	difficulty: ResearchTopicArchetype.DifficultyTier
) -> String:
	match difficulty:
		ResearchTopicArchetype.DifficultyTier.ROUTINE:
			return "轮廓较清楚，但内部问题尚未确认"
		ResearchTopicArchetype.DifficultyTier.ADVANCED:
			return "存在多处待核实信息"
		ResearchTopicArchetype.DifficultyTier.FRONTIER:
			return "关键信息缺失，可能出现额外问题"
		ResearchTopicArchetype.DifficultyTier.FORBIDDEN:
			return "高度未知，不保证当前方法足够"
		_:
			return "尚待调查"


static func _known_clue_text(tags: PackedStringArray) -> String:
	if tags.has("scarce_data"):
		return "可用样本可能不足"
	if tags.has("multi_source"):
		return "不同来源可能互相冲突"
	if tags.has("new_collection"):
		return "需要进入真实环境获取材料"
	if tags.has("theory"):
		return "核心论证仍需澄清"
	if tags.has("engineering"):
		return "流程稳定性尚未确认"
	if tags.has("existing_data"):
		return "已有材料可用，但质量未知"
	return "目前只有初步线索"


static func _base_value_text(base_reward: int) -> String:
	if base_reward >= 3:
		return "即使止损，也可能沉淀稀有研究资产"
	if base_reward == 2:
		return "可形成方法或数据资产"
	return "可形成基础材料与风险认知"


static func _potential_outlook_text(potential: int) -> String:
	match potential:
		0:
			return "常规成果，仍可能在调查后调整"
		1:
			return "常规至进阶，真实上限未知"
		2:
			return "进阶至前沿，需承担更多不确定性"
		3:
			return "可能形成突破，失败代价也更高"
		_:
			return "尚待调查"


static func _rule_hint_text(rule_id: StringName) -> String:
	match rule_id:
		&"reproduction_bonus":
			return "线索：复现路径可能带来额外价值"
		&"negative_result_asset":
			return "线索：负面结果未必毫无价值"
		&"scarce_data":
			return "线索：调查本身可能形成材料"
		&"cross_domain":
			return "线索：中期转向可能保留部分积累"
		&"pipeline_engine":
			return "线索：前期投入较重，后期可能提速"
		&"multi_source":
			return "线索：来源越多，潜力与冲突都会增加"
		&"indivisible_hypothesis":
			return "线索：课题结构可能难以安全拆分"
		&"deployment_exposure":
			return "线索：长期不调查可能产生额外代价"
		_:
			return "线索：标准研究流程"
