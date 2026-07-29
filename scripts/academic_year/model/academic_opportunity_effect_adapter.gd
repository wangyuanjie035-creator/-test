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
				"summary": "跨组协作：首周行动 +1",
			}
		&"industry_window":
			return {
				"id": effect_id,
				"evidence": 1,
				"risk_reveals": 1,
				"summary": "产业反馈：证据 +1，并识别首项风险",
			}
		&"failure_asset_pilot":
			return {
				"id": effect_id,
				"evidence": 1,
				"completion": 1,
				"summary": "失败成果试点：证据 +1、完成度 +1",
			}
		_:
			return {}
