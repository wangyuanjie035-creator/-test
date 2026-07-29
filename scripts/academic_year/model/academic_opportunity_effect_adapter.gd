extends RefCounted
class_name AcademicOpportunityEffectAdapter


static func to_opening_modifier(decision: Dictionary) -> Dictionary:
	if not bool(decision.get("accepted", false)):
		return {}
	var effect_id: StringName = StringName(decision.get("effect_id", &""))
	match effect_id:
		&"cooperation_opening":
			return {
				"id": effect_id,
				"action_points": 1,
				"cycle_rule_id": &"collaboration_rhythm",
				"summary": "跨组协作：首周行动 +1；每周首次组织/协作返还 1 行动",
			}
		&"industry_window":
			return {
				"id": effect_id,
				"evidence": 1,
				"risk_reveals": 1,
				"cycle_rule_id": &"industry_milestone",
				"summary": "产业反馈：证据 +1、识别首项风险；每周首次受控实验完成度 +1",
			}
		&"failure_asset_pilot":
			return {
				"id": effect_id,
				"evidence": 1,
				"completion": 1,
				"cycle_rule_id": &"prototype_learning",
				"summary": "失败成果试点：证据/完成度 +1；每周首次盲试或异常转化为原型资产",
			}
		_:
			return {}
