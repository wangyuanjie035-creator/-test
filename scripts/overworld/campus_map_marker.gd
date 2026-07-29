@tool
extends Node2D
class_name CampusMapMarker

const MARKER_STATE_DEFAULT := &"default"
const MARKER_STATE_STORY_KEY := &"story_key"
const MARKER_STATE_CONDITION_LOCKED := &"condition_locked"
const MARKER_STATE_BOSS_AVAILABLE := &"boss_available"
const VISUAL_PROFILE_NPC := &"npc_scholar"
const VISUAL_PROFILE_ADVISOR := &"advisor_npc"
const VISUAL_PROFILE_PEER := &"peer_npc"
const VISUAL_PROFILE_LAB_EQUIPMENT := &"lab_equipment"
const VISUAL_PROFILE_LIBRARY_STACK := &"library_stack"
const VISUAL_PROFILE_COMMITTEE_PANEL := &"committee_panel"
const VISUAL_PROFILE_REST_CORNER := &"rest_corner"
const VISUAL_PROFILE_NOTICE := &"notice_board"
const VISUAL_PROFILE_ADVISOR_NOTICE := &"advisor_notice"
const VISUAL_PROFILE_ADMIN_NOTICE := &"admin_notice"
const VISUAL_PROFILE_REVISION_NOTICE := &"revision_notice"
const VISUAL_PROFILE_ARENA := &"challenge_gate"
const VISUAL_PROFILE_DEFENSE_GATE := &"defense_gate"
const VISUAL_PROFILE_COMMITTEE_GATE := &"committee_gate"
const VISUAL_PROFILE_CACHE := &"resource_cache"
const VISUAL_PROFILE_DATA_CACHE := &"data_cache"
const VISUAL_PROFILE_DRAFT_CACHE := &"draft_cache"
const VISUAL_PROFILE_FUNDS_CACHE := &"funds_cache"
const VISUAL_PROFILE_INSPIRATION_CACHE := &"inspiration_cache"
const VISUAL_PROFILE_NOTES_CACHE := &"notes_cache"
const VISUAL_PROFILE_PAPER_CACHE := &"paper_cache"
const VISUAL_PROFILE_SAFEHOUSE_GATE := &"safehouse_gate"
const PULSE_RESOURCE_PHASE := 0.0
const PULSE_STORY_KEY_PHASE := 0.55
const PULSE_BOSS_PHASE := 1.25
const PULSE_GUIDANCE_PHASE := 0.0
const PULSE_SUPPLY_PHASE := 2.15
const PULSE_SUMMARY_PHASE := 3.65
const PULSE_FOCUS_PHASE := 5.10
const MARKER_TEXTURE_BASE_PATH := "res://assets/campus/markers/"
const MARKER_TEXTURE_FRAME_SIZE := Vector2(64.0, 64.0)
const MARKER_TEXTURE_ANCHOR := Vector2(32.0, 52.0)

@export var marker_kind: StringName = &"encounter"
@export var resource_id: StringName = &""
@export var content_tags: Array[StringName] = []
@export var marker_state: StringName = MARKER_STATE_DEFAULT
@export var accent_color: Color = Color(0.85, 0.72, 0.36)
@export var guidance_target: bool = false
@export var supply_hint_target: bool = false
@export var focused_target: bool = false
@export var summary_guidance_target: bool = false

var completed: bool = false
var _pulse_time: float = 0.0
var _cached_texture_profile: StringName = &""
var _cached_profile_texture: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_refresh_texture_cache()
	_refresh_process_state()
	queue_redraw()


func _process(delta: float) -> void:
	if not _should_pulse():
		return
	_pulse_time = fposmod(_pulse_time + delta * 3.2, TAU)
	queue_redraw()


func configure_marker(
	new_kind: StringName,
	new_resource_id: StringName,
	new_accent_color: Color,
	new_marker_state: StringName = MARKER_STATE_DEFAULT,
	new_guidance_target: bool = false,
	new_supply_hint_target: bool = false,
	new_focused_target: bool = false,
	new_summary_guidance_target: bool = false,
	new_content_tags: Array[StringName] = []
) -> void:
	marker_kind = new_kind
	resource_id = new_resource_id
	content_tags = _normalize_content_tags(new_content_tags)
	accent_color = new_accent_color
	marker_state = new_marker_state
	guidance_target = new_guidance_target
	supply_hint_target = new_supply_hint_target
	focused_target = new_focused_target
	summary_guidance_target = new_summary_guidance_target
	_refresh_texture_cache()
	_refresh_process_state()
	queue_redraw()


func set_completed(new_completed: bool) -> void:
	completed = new_completed
	visible = not completed
	_refresh_process_state()
	queue_redraw()


func set_guidance_target(new_guidance_target: bool) -> void:
	guidance_target = new_guidance_target
	_refresh_process_state()
	queue_redraw()


func set_supply_hint_target(new_supply_hint_target: bool) -> void:
	supply_hint_target = new_supply_hint_target
	_refresh_process_state()
	queue_redraw()


func set_focused_target(new_focused_target: bool) -> void:
	focused_target = new_focused_target
	_refresh_process_state()
	queue_redraw()


func set_summary_guidance_target(new_summary_guidance_target: bool) -> void:
	summary_guidance_target = new_summary_guidance_target
	_refresh_process_state()
	queue_redraw()


func get_visual_profile() -> StringName:
	match marker_kind:
		&"safehouse":
			return VISUAL_PROFILE_SAFEHOUSE_GATE
		&"resource":
			return _get_resource_visual_profile()
		&"boss":
			return _get_boss_visual_profile()
		&"event":
			return _get_event_visual_profile()
		_:
			return _get_encounter_visual_profile()


func get_visual_profile_summary() -> String:
	return "%s:%s" % [String(marker_kind), String(get_visual_profile())]


func get_visual_texture_path() -> String:
	return _get_profile_texture_path(get_visual_profile())


func has_visual_texture() -> bool:
	return _get_visual_profile_texture() != null


func get_visual_texture_source_summary() -> String:
	var profile: StringName = get_visual_profile()
	var path: String = _get_profile_texture_path(profile)
	if _get_visual_profile_texture() == null:
		return "%s=fallback:%s" % [String(profile), path]
	return "%s=texture:%s" % [String(profile), path]


func _get_encounter_visual_profile() -> StringName:
	if _has_content_tag(&"advisor"):
		return VISUAL_PROFILE_ADVISOR
	if _has_content_tag(&"peer") or _has_content_tag(&"collaboration"):
		return VISUAL_PROFILE_PEER
	if _has_content_tag(&"equipment") or _has_content_tag(&"lab") or _has_content_tag(&"data"):
		return VISUAL_PROFILE_LAB_EQUIPMENT
	if _has_content_tag(&"library") or _has_content_tag(&"paper_fragments"):
		return VISUAL_PROFILE_LIBRARY_STACK
	if _has_content_tag(&"committee") or _has_content_tag(&"exam") or _has_content_tag(&"defense"):
		return VISUAL_PROFILE_COMMITTEE_PANEL
	if _has_content_tag(&"self_care") or _has_content_tag(&"canteen"):
		return VISUAL_PROFILE_REST_CORNER
	return VISUAL_PROFILE_NPC


func _get_event_visual_profile() -> StringName:
	if _has_content_tag(&"advisor"):
		return VISUAL_PROFILE_ADVISOR_NOTICE
	if _has_content_tag(&"revision"):
		return VISUAL_PROFILE_REVISION_NOTICE
	if _has_content_tag(&"administration") or _has_content_tag(&"campus_notice") or _has_content_tag(&"funds"):
		return VISUAL_PROFILE_ADMIN_NOTICE
	return VISUAL_PROFILE_NOTICE


func _get_boss_visual_profile() -> StringName:
	if _has_content_tag(&"defense") or resource_id == &"defense":
		return VISUAL_PROFILE_DEFENSE_GATE
	if _has_content_tag(&"committee") or _has_content_tag(&"exam"):
		return VISUAL_PROFILE_COMMITTEE_GATE
	return VISUAL_PROFILE_ARENA


func _get_resource_visual_profile() -> StringName:
	match resource_id:
		&"data":
			return VISUAL_PROFILE_DATA_CACHE
		&"draft":
			return VISUAL_PROFILE_DRAFT_CACHE
		&"funds":
			return VISUAL_PROFILE_FUNDS_CACHE
		&"inspiration":
			return VISUAL_PROFILE_INSPIRATION_CACHE
		&"methodology_notes", &"experience_lessons":
			return VISUAL_PROFILE_NOTES_CACHE
		&"paper_fragments":
			return VISUAL_PROFILE_PAPER_CACHE
		_:
			return VISUAL_PROFILE_CACHE


func _has_content_tag(tag: StringName) -> bool:
	return content_tags.has(tag)


func _normalize_content_tags(raw_tags: Array[StringName]) -> Array[StringName]:
	var normalized: Array[StringName] = []
	for tag: StringName in raw_tags:
		if not normalized.has(tag):
			normalized.append(tag)
	return normalized


func _refresh_texture_cache() -> void:
	_cached_texture_profile = get_visual_profile()
	_cached_profile_texture = _load_profile_texture(_cached_texture_profile)


func _get_visual_profile_texture() -> Texture2D:
	var profile: StringName = get_visual_profile()
	if profile != _cached_texture_profile:
		_cached_texture_profile = profile
		_cached_profile_texture = _load_profile_texture(profile)
	return _cached_profile_texture


func _load_profile_texture(profile: StringName) -> Texture2D:
	var path: String = _get_profile_texture_path(profile)
	if not ResourceLoader.exists(path, "Texture2D"):
		return null
	var loaded: Resource = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
	if loaded is Texture2D:
		return loaded as Texture2D
	return null


func _get_profile_texture_path(profile: StringName) -> String:
	return "%s%s.png" % [MARKER_TEXTURE_BASE_PATH, String(profile)]


func _refresh_process_state() -> void:
	set_process(_should_pulse())


func _should_pulse() -> bool:
	if completed:
		return false
	return focused_target or guidance_target or supply_hint_target or summary_guidance_target or marker_kind == &"resource" or marker_kind == &"safehouse" or marker_state == MARKER_STATE_STORY_KEY or marker_state == MARKER_STATE_BOSS_AVAILABLE


func _draw() -> void:
	if completed:
		return
	var profile_texture: Texture2D = _get_visual_profile_texture()
	if profile_texture != null:
		_draw_marker_texture(profile_texture)
	else:
		match marker_kind:
			&"safehouse":
				_draw_safehouse_gate()
			&"resource":
				_draw_resource()
			&"boss":
				_draw_boss()
			&"event":
				_draw_event()
			_:
				_draw_encounter()
	_draw_state_overlay()


func _draw_marker_texture(profile_texture: Texture2D) -> void:
	if marker_kind == &"resource":
		_draw_resource_texture_halo()
	else:
		_draw_texture_ground_shadow()
	draw_texture_rect(
		profile_texture,
		Rect2(-MARKER_TEXTURE_ANCHOR, MARKER_TEXTURE_FRAME_SIZE),
		false,
		Color.WHITE
	)


func _draw_texture_ground_shadow() -> void:
	draw_rect(Rect2(Vector2(-18, 18), Vector2(36, 4)), Color(0.05, 0.08, 0.09, 0.38))


func _draw_resource_texture_halo() -> void:
	var pulse_alpha: float = 0.14 + 0.10 * _pulse01(0.85, PULSE_RESOURCE_PHASE)
	var halo_color: Color = accent_color.lightened(0.18)
	halo_color.a = pulse_alpha
	draw_rect(Rect2(Vector2(-19, -21), Vector2(38, 38)), halo_color)
	_draw_texture_ground_shadow()


func _draw_encounter() -> void:
	match _get_encounter_visual_profile():
		VISUAL_PROFILE_ADVISOR:
			_draw_advisor_npc()
		VISUAL_PROFILE_PEER:
			_draw_peer_npc()
		VISUAL_PROFILE_LAB_EQUIPMENT:
			_draw_lab_equipment()
		VISUAL_PROFILE_LIBRARY_STACK:
			_draw_library_stack()
		VISUAL_PROFILE_COMMITTEE_PANEL:
			_draw_committee_panel()
		VISUAL_PROFILE_REST_CORNER:
			_draw_rest_corner()
		_:
			_draw_scholar_npc()


func _draw_safehouse_gate() -> void:
	var pulse_alpha: float = 0.16 + 0.10 * _pulse01(0.85, PULSE_RESOURCE_PHASE)
	var halo_color: Color = accent_color.lightened(0.20)
	halo_color.a = pulse_alpha
	draw_rect(Rect2(Vector2(-22, -24), Vector2(44, 46)), halo_color)
	draw_rect(Rect2(Vector2(-20, 18), Vector2(40, 5)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-19, -14), Vector2(38, 34)), Color(0.06, 0.09, 0.10))
	draw_rect(Rect2(Vector2(-16, -11), Vector2(32, 28)), accent_color.darkened(0.10))
	draw_rect(Rect2(Vector2(-19, -20), Vector2(38, 8)), Color(0.15, 0.22, 0.20))
	draw_rect(Rect2(Vector2(-13, -7), Vector2(26, 24)), Color(0.16, 0.12, 0.10))
	draw_rect(Rect2(Vector2(-10, -4), Vector2(20, 21)), Color(0.28, 0.20, 0.14))
	draw_rect(Rect2(Vector2(5, 5), Vector2(3, 3)), Color(0.92, 0.82, 0.36))
	draw_rect(Rect2(Vector2(-6, -26), Vector2(12, 7)), Color(0.84, 0.90, 0.74))
	draw_rect(Rect2(Vector2(-3, -23), Vector2(6, 2)), Color(0.18, 0.24, 0.20))


func _draw_scholar_npc() -> void:
	draw_rect(Rect2(Vector2(-15, 18), Vector2(30, 4)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-11, -16), Vector2(22, 32)), Color(0.07, 0.10, 0.13))
	draw_rect(Rect2(Vector2(-9, -14), Vector2(18, 11)), Color(0.76, 0.58, 0.44))
	draw_rect(Rect2(Vector2(-8, -3), Vector2(16, 17)), accent_color)
	draw_rect(Rect2(Vector2(-12, 1), Vector2(4, 10)), accent_color.darkened(0.28))
	draw_rect(Rect2(Vector2(8, 1), Vector2(4, 10)), accent_color.darkened(0.28))
	draw_rect(Rect2(Vector2(-7, 14), Vector2(5, 6)), Color(0.06, 0.07, 0.08))
	draw_rect(Rect2(Vector2(2, 14), Vector2(5, 6)), Color(0.06, 0.07, 0.08))
	draw_rect(Rect2(Vector2(-4, -9), Vector2(2, 2)), Color(0.06, 0.07, 0.08))
	draw_rect(Rect2(Vector2(2, -9), Vector2(2, 2)), Color(0.06, 0.07, 0.08))
	_draw_speech_bubble()


func _draw_advisor_npc() -> void:
	draw_rect(Rect2(Vector2(-16, 18), Vector2(32, 4)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-12, -17), Vector2(24, 33)), Color(0.06, 0.08, 0.10))
	draw_rect(Rect2(Vector2(-9, -15), Vector2(18, 10)), Color(0.72, 0.56, 0.42))
	draw_rect(Rect2(Vector2(-9, -5), Vector2(18, 20)), accent_color.darkened(0.08))
	draw_rect(Rect2(Vector2(-4, -4), Vector2(8, 20)), Color(0.92, 0.90, 0.78))
	draw_rect(Rect2(Vector2(-12, 4), Vector2(4, 10)), accent_color.darkened(0.30))
	draw_rect(Rect2(Vector2(8, 4), Vector2(4, 10)), accent_color.darkened(0.30))
	draw_rect(Rect2(Vector2(-7, 15), Vector2(5, 6)), Color(0.05, 0.06, 0.07))
	draw_rect(Rect2(Vector2(2, 15), Vector2(5, 6)), Color(0.05, 0.06, 0.07))
	draw_rect(Rect2(Vector2(-7, -10), Vector2(5, 2)), Color(0.08, 0.10, 0.12))
	draw_rect(Rect2(Vector2(2, -10), Vector2(5, 2)), Color(0.08, 0.10, 0.12))
	draw_rect(Rect2(Vector2(-2, -10), Vector2(4, 1)), Color(0.08, 0.10, 0.12))
	draw_rect(Rect2(Vector2(10, -27), Vector2(20, 13)), Color(0.07, 0.09, 0.10, 0.95))
	draw_rect(Rect2(Vector2(12, -25), Vector2(16, 9)), Color(0.90, 0.88, 0.74))
	draw_rect(Rect2(Vector2(14, -23), Vector2(10, 2)), Color(0.28, 0.30, 0.24))
	draw_rect(Rect2(Vector2(14, -19), Vector2(7, 2)), Color(0.28, 0.30, 0.24))


func _draw_peer_npc() -> void:
	draw_rect(Rect2(Vector2(-18, 18), Vector2(36, 4)), Color(0.05, 0.08, 0.09, 0.50))
	_draw_small_peer_body(Vector2(-8, 0), accent_color)
	_draw_small_peer_body(Vector2(8, 1), accent_color.lightened(0.14))
	draw_rect(Rect2(Vector2(-3, -24), Vector2(6, 5)), Color(0.07, 0.09, 0.10, 0.95))
	draw_rect(Rect2(Vector2(-1, -19), Vector2(10, 3)), Color(0.92, 0.95, 0.88))


func _draw_small_peer_body(offset: Vector2, body_color: Color) -> void:
	draw_rect(Rect2(offset + Vector2(-7, -15), Vector2(14, 9)), Color(0.72, 0.56, 0.42))
	draw_rect(Rect2(offset + Vector2(-8, -6), Vector2(16, 18)), Color(0.06, 0.08, 0.10))
	draw_rect(Rect2(offset + Vector2(-6, -4), Vector2(12, 15)), body_color)
	draw_rect(Rect2(offset + Vector2(-5, 11), Vector2(4, 7)), Color(0.05, 0.06, 0.07))
	draw_rect(Rect2(offset + Vector2(1, 11), Vector2(4, 7)), Color(0.05, 0.06, 0.07))
	draw_rect(Rect2(offset + Vector2(-4, -11), Vector2(2, 2)), Color(0.06, 0.07, 0.08))
	draw_rect(Rect2(offset + Vector2(2, -11), Vector2(2, 2)), Color(0.06, 0.07, 0.08))


func _draw_lab_equipment() -> void:
	draw_rect(Rect2(Vector2(-18, 18), Vector2(36, 4)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-18, -14), Vector2(36, 31)), Color(0.05, 0.08, 0.10))
	draw_rect(Rect2(Vector2(-15, -11), Vector2(30, 22)), accent_color.darkened(0.10))
	draw_rect(Rect2(Vector2(-11, -7), Vector2(14, 9)), Color(0.38, 0.72, 0.78))
	draw_rect(Rect2(Vector2(6, -7), Vector2(5, 5)), Color(0.90, 0.82, 0.32))
	draw_rect(Rect2(Vector2(6, 1), Vector2(5, 5)), Color(0.62, 0.94, 0.70))
	draw_rect(Rect2(Vector2(-13, 9), Vector2(26, 4)), Color(0.07, 0.09, 0.10))
	draw_rect(Rect2(Vector2(-6, 13), Vector2(4, 7)), Color(0.05, 0.06, 0.07))
	draw_rect(Rect2(Vector2(4, 13), Vector2(4, 7)), Color(0.05, 0.06, 0.07))
	draw_rect(Rect2(Vector2(-2, -22), Vector2(4, 8)), Color(0.72, 0.92, 0.96))
	draw_rect(Rect2(Vector2(-6, -25), Vector2(12, 4)), Color(0.72, 0.92, 0.96))


func _draw_library_stack() -> void:
	draw_rect(Rect2(Vector2(-17, 18), Vector2(34, 4)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-15, -15), Vector2(30, 33)), Color(0.06, 0.08, 0.10))
	draw_rect(Rect2(Vector2(-12, -12), Vector2(24, 7)), accent_color)
	draw_rect(Rect2(Vector2(-10, -4), Vector2(22, 7)), Color(0.86, 0.72, 0.48))
	draw_rect(Rect2(Vector2(-13, 4), Vector2(25, 7)), Color(0.54, 0.66, 0.82))
	draw_rect(Rect2(Vector2(-8, 12), Vector2(18, 4)), Color(0.92, 0.88, 0.68))
	draw_rect(Rect2(Vector2(-8, -11), Vector2(2, 5)), Color(0.16, 0.18, 0.16))
	draw_rect(Rect2(Vector2(-5, -3), Vector2(2, 5)), Color(0.16, 0.18, 0.16))
	draw_rect(Rect2(Vector2(4, 5), Vector2(2, 5)), Color(0.16, 0.18, 0.16))


func _draw_committee_panel() -> void:
	draw_rect(Rect2(Vector2(-20, 18), Vector2(40, 4)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-20, -6), Vector2(40, 21)), Color(0.07, 0.08, 0.10))
	draw_rect(Rect2(Vector2(-17, -3), Vector2(34, 15)), accent_color.darkened(0.14))
	for index: int in range(3):
		var x: float = -12.0 + index * 12.0
		draw_rect(Rect2(Vector2(x - 4, -20), Vector2(8, 8)), Color(0.72, 0.56, 0.42))
		draw_rect(Rect2(Vector2(x - 5, -12), Vector2(10, 10)), Color(0.08, 0.10, 0.12))
		draw_rect(Rect2(Vector2(x - 3, -10), Vector2(6, 8)), accent_color.lightened(0.08))
	draw_rect(Rect2(Vector2(-5, 4), Vector2(10, 3)), Color(0.94, 0.86, 0.42))


func _draw_rest_corner() -> void:
	draw_rect(Rect2(Vector2(-18, 18), Vector2(36, 4)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-16, 2), Vector2(32, 9)), accent_color)
	draw_rect(Rect2(Vector2(-14, -10), Vector2(28, 10)), accent_color.darkened(0.18))
	draw_rect(Rect2(Vector2(-13, 11), Vector2(4, 9)), Color(0.06, 0.07, 0.08))
	draw_rect(Rect2(Vector2(9, 11), Vector2(4, 9)), Color(0.06, 0.07, 0.08))
	draw_rect(Rect2(Vector2(-9, -21), Vector2(18, 8)), Color(0.98, 0.88, 0.42))
	draw_rect(Rect2(Vector2(-6, -25), Vector2(12, 4)), Color(0.98, 0.88, 0.42))
	draw_rect(Rect2(Vector2(-3, -29), Vector2(6, 4)), Color(0.98, 0.88, 0.42))


func _draw_event() -> void:
	draw_rect(Rect2(Vector2(-17, 18), Vector2(34, 4)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-16, -18), Vector2(32, 36)), Color(0.06, 0.09, 0.12))
	draw_rect(Rect2(Vector2(-13, -15), Vector2(26, 30)), accent_color)
	draw_rect(Rect2(Vector2(-9, -11), Vector2(18, 20)), Color(0.94, 0.88, 0.62))
	draw_rect(Rect2(Vector2(-6, -7), Vector2(12, 2)), Color(0.20, 0.18, 0.14))
	draw_rect(Rect2(Vector2(-6, -2), Vector2(10, 2)), Color(0.20, 0.18, 0.14))
	draw_rect(Rect2(Vector2(-2, 3), Vector2(4, 7)), Color(0.22, 0.10, 0.10))
	draw_rect(Rect2(Vector2(-2, 12), Vector2(4, 3)), Color(0.22, 0.10, 0.10))
	draw_rect(Rect2(Vector2(-5, -22), Vector2(10, 5)), Color(0.96, 0.90, 0.58))
	match _get_event_visual_profile():
		VISUAL_PROFILE_ADVISOR_NOTICE:
			_draw_advisor_notice_badge()
		VISUAL_PROFILE_ADMIN_NOTICE:
			_draw_admin_notice_badge()
		VISUAL_PROFILE_REVISION_NOTICE:
			_draw_revision_notice_badge()


func _draw_advisor_notice_badge() -> void:
	draw_rect(Rect2(Vector2(5, -26), Vector2(14, 10)), Color(0.08, 0.10, 0.12, 0.96))
	draw_rect(Rect2(Vector2(7, -24), Vector2(10, 6)), Color(0.90, 0.88, 0.74))
	draw_rect(Rect2(Vector2(9, -22), Vector2(6, 1)), Color(0.22, 0.24, 0.18))
	draw_rect(Rect2(Vector2(9, -20), Vector2(4, 1)), Color(0.22, 0.24, 0.18))


func _draw_admin_notice_badge() -> void:
	draw_rect(Rect2(Vector2(-14, -25), Vector2(11, 9)), Color(0.08, 0.10, 0.12, 0.96))
	draw_rect(Rect2(Vector2(-12, -23), Vector2(7, 5)), Color(0.52, 0.72, 0.88))
	draw_rect(Rect2(Vector2(-10, -21), Vector2(3, 1)), Color(0.08, 0.10, 0.12))


func _draw_revision_notice_badge() -> void:
	draw_rect(Rect2(Vector2(5, -25), Vector2(12, 9)), Color(0.08, 0.10, 0.12, 0.96))
	draw_rect(Rect2(Vector2(7, -23), Vector2(8, 5)), Color(0.92, 0.52, 0.42))
	draw_rect(Rect2(Vector2(9, -21), Vector2(4, 1)), Color(0.08, 0.10, 0.12))
	draw_rect(Rect2(Vector2(11, -24), Vector2(2, 8)), Color(0.92, 0.52, 0.42))


func _draw_boss() -> void:
	draw_rect(Rect2(Vector2(-22, 20), Vector2(44, 5)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-20, -20), Vector2(40, 40)), Color(0.08, 0.06, 0.08))
	draw_rect(Rect2(Vector2(-17, -17), Vector2(34, 34)), accent_color)
	draw_rect(Rect2(Vector2(-12, -9), Vector2(24, 18)), Color(0.12, 0.08, 0.10))
	draw_rect(Rect2(Vector2(-8, -5), Vector2(16, 10)), accent_color.darkened(0.38))
	draw_rect(Rect2(Vector2(-14, 11), Vector2(28, 5)), Color(0.95, 0.74, 0.34))
	draw_rect(Rect2(Vector2(-16, -25), Vector2(32, 5)), Color(0.95, 0.74, 0.34))
	draw_rect(Rect2(Vector2(-12, -30), Vector2(6, 6)), Color(0.95, 0.74, 0.34))
	draw_rect(Rect2(Vector2(-3, -33), Vector2(6, 8)), Color(0.95, 0.74, 0.34))
	draw_rect(Rect2(Vector2(6, -30), Vector2(6, 6)), Color(0.95, 0.74, 0.34))
	match _get_boss_visual_profile():
		VISUAL_PROFILE_DEFENSE_GATE:
			_draw_defense_gate_badge()
		VISUAL_PROFILE_COMMITTEE_GATE:
			_draw_committee_gate_badge()


func _draw_defense_gate_badge() -> void:
	draw_rect(Rect2(Vector2(-6, -15), Vector2(12, 7)), Color(0.86, 0.92, 0.94))
	draw_rect(Rect2(Vector2(-8, -7), Vector2(16, 3)), Color(0.86, 0.92, 0.94))
	draw_rect(Rect2(Vector2(-2, -4), Vector2(4, 7)), Color(0.86, 0.92, 0.94))
	draw_rect(Rect2(Vector2(-5, -13), Vector2(10, 2)), Color(0.12, 0.14, 0.16))


func _draw_committee_gate_badge() -> void:
	for index: int in range(3):
		var x: float = -8.0 + index * 8.0
		draw_rect(Rect2(Vector2(x - 3, -15), Vector2(6, 6)), Color(0.86, 0.82, 0.64))
		draw_rect(Rect2(Vector2(x - 4, -9), Vector2(8, 4)), Color(0.12, 0.14, 0.16))


func _draw_resource() -> void:
	var pulse_alpha: float = 0.14 + 0.10 * _pulse01(0.85, PULSE_RESOURCE_PHASE)
	var halo_color: Color = accent_color.lightened(0.18)
	halo_color.a = pulse_alpha

	draw_rect(Rect2(Vector2(-17, -19), Vector2(34, 34)), halo_color)
	draw_rect(Rect2(Vector2(-15, 17), Vector2(30, 4)), Color(0.05, 0.08, 0.09, 0.50))
	draw_rect(Rect2(Vector2(-14, -13), Vector2(28, 26)), Color(0.07, 0.09, 0.10))
	draw_rect(Rect2(Vector2(-11, -10), Vector2(22, 20)), accent_color)
	draw_rect(Rect2(Vector2(-11, -2), Vector2(22, 3)), accent_color.darkened(0.35))
	draw_rect(Rect2(Vector2(-6, -16), Vector2(12, 5)), Color(0.12, 0.13, 0.12))
	draw_rect(Rect2(Vector2(-3, -18), Vector2(6, 3)), Color(0.12, 0.13, 0.12))
	draw_rect(Rect2(Vector2(-8, -8), Vector2(16, 16)), Color(0.14, 0.17, 0.16))
	_draw_resource_icon()


func _draw_speech_bubble() -> void:
	draw_rect(Rect2(Vector2(8, -28), Vector2(18, 12)), Color(0.07, 0.09, 0.10, 0.95))
	draw_rect(Rect2(Vector2(10, -26), Vector2(14, 8)), Color(0.92, 0.95, 0.88))
	draw_rect(Rect2(Vector2(12, -18), Vector2(4, 4)), Color(0.92, 0.95, 0.88))
	draw_rect(Rect2(Vector2(13, -23), Vector2(2, 2)), Color(0.18, 0.22, 0.24))
	draw_rect(Rect2(Vector2(18, -23), Vector2(2, 2)), Color(0.18, 0.22, 0.24))


func _draw_resource_icon() -> void:
	match resource_id:
		&"draft":
			_draw_draft_icon()
		&"inspiration":
			_draw_inspiration_icon()
		&"data":
			_draw_data_icon()
		&"funds":
			_draw_funds_icon()
		&"methodology_notes":
			_draw_notes_icon()
		&"experience_lessons":
			_draw_lessons_icon()
		&"paper_fragments":
			_draw_paper_fragments_icon()
		_:
			_draw_generic_resource_icon()


func _draw_draft_icon() -> void:
	draw_rect(Rect2(Vector2(-5, -7), Vector2(10, 14)), Color(0.96, 0.94, 0.86))
	draw_rect(Rect2(Vector2(2, -7), Vector2(3, 3)), Color(0.74, 0.74, 0.66))
	draw_rect(Rect2(Vector2(-3, -2), Vector2(6, 1)), Color(0.43, 0.43, 0.38))
	draw_rect(Rect2(Vector2(-3, 2), Vector2(5, 1)), Color(0.43, 0.43, 0.38))


func _draw_inspiration_icon() -> void:
	draw_rect(Rect2(Vector2(-4, -7), Vector2(8, 8)), Color(0.98, 0.92, 0.38))
	draw_rect(Rect2(Vector2(-3, 1), Vector2(6, 2)), Color(0.86, 0.74, 0.34))
	draw_rect(Rect2(Vector2(-2, 4), Vector2(4, 2)), Color(0.57, 0.49, 0.32))
	draw_rect(Rect2(Vector2(-7, -3), Vector2(2, 2)), Color(0.98, 0.92, 0.38))
	draw_rect(Rect2(Vector2(5, -3), Vector2(2, 2)), Color(0.98, 0.92, 0.38))


func _draw_data_icon() -> void:
	draw_rect(Rect2(Vector2(-3, -8), Vector2(6, 3)), Color(0.82, 0.90, 0.92))
	draw_rect(Rect2(Vector2(-5, -5), Vector2(10, 12)), Color(0.82, 0.90, 0.92))
	draw_rect(Rect2(Vector2(-4, 0), Vector2(8, 6)), Color(0.42, 0.86, 0.70))
	draw_rect(Rect2(Vector2(-3, -3), Vector2(2, 2)), Color(0.94, 0.98, 0.96))


func _draw_funds_icon() -> void:
	draw_rect(Rect2(Vector2(-6, -2), Vector2(10, 8)), Color(0.92, 0.72, 0.26))
	draw_rect(Rect2(Vector2(-3, -6), Vector2(10, 8)), Color(0.98, 0.84, 0.32))
	draw_rect(Rect2(Vector2(-1, -4), Vector2(4, 4)), Color(0.62, 0.42, 0.16))


func _draw_notes_icon() -> void:
	draw_rect(Rect2(Vector2(-6, -7), Vector2(12, 14)), Color(0.90, 0.88, 0.72))
	draw_rect(Rect2(Vector2(-6, -7), Vector2(3, 14)), Color(0.36, 0.52, 0.70))
	draw_rect(Rect2(Vector2(-1, -3), Vector2(5, 1)), Color(0.44, 0.44, 0.36))
	draw_rect(Rect2(Vector2(-1, 1), Vector2(4, 1)), Color(0.44, 0.44, 0.36))


func _draw_lessons_icon() -> void:
	draw_rect(Rect2(Vector2(-6, -7), Vector2(12, 14)), Color(0.88, 0.80, 0.62))
	draw_rect(Rect2(Vector2(-4, -5), Vector2(8, 10)), Color(0.52, 0.70, 0.64))
	draw_rect(Rect2(Vector2(-2, -7), Vector2(4, 5)), Color(0.92, 0.56, 0.42))
	draw_rect(Rect2(Vector2(-2, 0), Vector2(4, 1)), Color(0.18, 0.22, 0.20))
	draw_rect(Rect2(Vector2(-2, 3), Vector2(4, 1)), Color(0.18, 0.22, 0.20))


func _draw_paper_fragments_icon() -> void:
	draw_rect(Rect2(Vector2(-7, -6), Vector2(9, 11)), Color(0.96, 0.94, 0.86))
	draw_rect(Rect2(Vector2(-1, -8), Vector2(9, 11)), Color(0.90, 0.90, 0.82))
	draw_rect(Rect2(Vector2(-4, -2), Vector2(5, 1)), Color(0.40, 0.42, 0.38))
	draw_rect(Rect2(Vector2(1, -4), Vector2(4, 1)), Color(0.40, 0.42, 0.38))
	draw_rect(Rect2(Vector2(1, 0), Vector2(5, 1)), Color(0.40, 0.42, 0.38))


func _draw_generic_resource_icon() -> void:
	draw_rect(Rect2(Vector2(-2, -6), Vector2(4, 12)), Color(0.92, 0.94, 0.86))
	draw_rect(Rect2(Vector2(-6, -2), Vector2(12, 4)), Color(0.92, 0.94, 0.86))


func _draw_state_overlay() -> void:
	match marker_state:
		MARKER_STATE_STORY_KEY:
			_draw_story_key_overlay()
		MARKER_STATE_CONDITION_LOCKED:
			_draw_condition_locked_overlay()
		MARKER_STATE_BOSS_AVAILABLE:
			_draw_boss_available_overlay()
	if guidance_target:
		_draw_guidance_target_overlay()
	if supply_hint_target:
		_draw_supply_hint_target_overlay()
	if summary_guidance_target:
		_draw_summary_guidance_target_overlay()
	if focused_target:
		_draw_focused_target_overlay()


func _draw_story_key_overlay() -> void:
	var badge_color: Color = Color(0.98, 0.86, 0.28)
	var pulse_alpha: float = 0.68 + 0.18 * _pulse01(1.00, PULSE_STORY_KEY_PHASE)
	badge_color.a = pulse_alpha
	draw_rect(Rect2(Vector2(8, -24), Vector2(12, 16)), Color(0.08, 0.07, 0.05, 0.88))
	draw_rect(Rect2(Vector2(10, -22), Vector2(8, 12)), badge_color)
	draw_rect(Rect2(Vector2(13, -20), Vector2(2, 6)), Color(0.18, 0.13, 0.04))
	draw_rect(Rect2(Vector2(13, -12), Vector2(2, 2)), Color(0.18, 0.13, 0.04))


func _draw_condition_locked_overlay() -> void:
	draw_rect(Rect2(Vector2(-18, -22), Vector2(36, 4)), Color(0.48, 0.10, 0.12, 0.86))
	draw_rect(Rect2(Vector2(-16, -20), Vector2(32, 32)), Color(0.06, 0.06, 0.07, 0.32))
	draw_rect(Rect2(Vector2(8, -25), Vector2(14, 14)), Color(0.08, 0.07, 0.07, 0.88))
	draw_rect(Rect2(Vector2(10, -18), Vector2(10, 7)), Color(0.72, 0.18, 0.20))
	draw_rect(Rect2(Vector2(12, -24), Vector2(6, 7)), Color(0.72, 0.18, 0.20))
	draw_rect(Rect2(Vector2(14, -22), Vector2(2, 4)), Color(0.08, 0.07, 0.07, 0.88))


func _draw_boss_available_overlay() -> void:
	var pulse_alpha: float = 0.14 + 0.10 * _pulse01(0.75, PULSE_BOSS_PHASE)
	var ring_color: Color = Color(0.95, 0.74, 0.34, pulse_alpha)
	draw_rect(Rect2(Vector2(-24, -24), Vector2(48, 4)), ring_color)
	draw_rect(Rect2(Vector2(-24, 20), Vector2(48, 4)), ring_color)
	draw_rect(Rect2(Vector2(-24, -20), Vector2(4, 40)), ring_color)
	draw_rect(Rect2(Vector2(20, -20), Vector2(4, 40)), ring_color)
	draw_rect(Rect2(Vector2(-8, -27), Vector2(16, 5)), Color(0.95, 0.74, 0.34))
	draw_rect(Rect2(Vector2(-5, -31), Vector2(4, 4)), Color(0.95, 0.74, 0.34))
	draw_rect(Rect2(Vector2(1, -31), Vector2(4, 4)), Color(0.95, 0.74, 0.34))


func _draw_guidance_target_overlay() -> void:
	var pulse_alpha: float = 0.24 + 0.16 * _pulse01(0.95, PULSE_GUIDANCE_PHASE)
	var guide_color: Color = Color(0.42, 0.88, 0.96, pulse_alpha)
	draw_rect(Rect2(Vector2(-28, -28), Vector2(56, 3)), guide_color)
	draw_rect(Rect2(Vector2(-28, 25), Vector2(56, 3)), guide_color)
	draw_rect(Rect2(Vector2(-28, -25), Vector2(3, 50)), guide_color)
	draw_rect(Rect2(Vector2(25, -25), Vector2(3, 50)), guide_color)
	draw_rect(Rect2(Vector2(-6, -39), Vector2(12, 6)), Color(0.42, 0.88, 0.96))
	draw_rect(Rect2(Vector2(-4, -33), Vector2(8, 5)), Color(0.42, 0.88, 0.96))
	draw_rect(Rect2(Vector2(-2, -28), Vector2(4, 5)), Color(0.42, 0.88, 0.96))


func _draw_supply_hint_target_overlay() -> void:
	var pulse_alpha: float = 0.31 + 0.18 * _pulse01(0.90, PULSE_SUPPLY_PHASE)
	var hint_color: Color = Color(0.98, 0.82, 0.32, pulse_alpha)
	draw_rect(Rect2(Vector2(-23, -24), Vector2(16, 3)), hint_color)
	draw_rect(Rect2(Vector2(7, -24), Vector2(16, 3)), hint_color)
	draw_rect(Rect2(Vector2(-23, 21), Vector2(16, 3)), hint_color)
	draw_rect(Rect2(Vector2(7, 21), Vector2(16, 3)), hint_color)
	draw_rect(Rect2(Vector2(-24, -23), Vector2(3, 16)), hint_color)
	draw_rect(Rect2(Vector2(21, -23), Vector2(3, 16)), hint_color)
	draw_rect(Rect2(Vector2(-24, 7), Vector2(3, 16)), hint_color)
	draw_rect(Rect2(Vector2(21, 7), Vector2(3, 16)), hint_color)
	draw_rect(Rect2(Vector2(-3, -31), Vector2(6, 18)), Color(0.98, 0.82, 0.32))
	draw_rect(Rect2(Vector2(-9, -25), Vector2(18, 6)), Color(0.98, 0.82, 0.32))


func _draw_focused_target_overlay() -> void:
	var pulse_alpha: float = 0.38 + 0.24 * _pulse01(1.30, PULSE_FOCUS_PHASE)
	var focus_color: Color = Color(1.00, 0.96, 0.68, pulse_alpha)
	draw_rect(Rect2(Vector2(-31, -31), Vector2(12, 3)), focus_color)
	draw_rect(Rect2(Vector2(19, -31), Vector2(12, 3)), focus_color)
	draw_rect(Rect2(Vector2(-31, 28), Vector2(12, 3)), focus_color)
	draw_rect(Rect2(Vector2(19, 28), Vector2(12, 3)), focus_color)
	draw_rect(Rect2(Vector2(-31, -31), Vector2(3, 12)), focus_color)
	draw_rect(Rect2(Vector2(28, -31), Vector2(3, 12)), focus_color)
	draw_rect(Rect2(Vector2(-31, 19), Vector2(3, 12)), focus_color)
	draw_rect(Rect2(Vector2(28, 19), Vector2(3, 12)), focus_color)
	draw_rect(Rect2(Vector2(-4, -36), Vector2(8, 4)), Color(1.00, 0.96, 0.68, 0.90))


func _draw_summary_guidance_target_overlay() -> void:
	var pulse_alpha: float = 0.34 + 0.22 * _pulse01(1.12, PULSE_SUMMARY_PHASE)
	var ping_color: Color = Color(0.72, 0.96, 1.0, pulse_alpha)
	var solid_color: Color = Color(0.72, 0.96, 1.0, 0.92)

	draw_rect(Rect2(Vector2(-36, -36), Vector2(15, 4)), ping_color)
	draw_rect(Rect2(Vector2(21, -36), Vector2(15, 4)), ping_color)
	draw_rect(Rect2(Vector2(-36, 32), Vector2(15, 4)), ping_color)
	draw_rect(Rect2(Vector2(21, 32), Vector2(15, 4)), ping_color)
	draw_rect(Rect2(Vector2(-36, -36), Vector2(4, 15)), ping_color)
	draw_rect(Rect2(Vector2(32, -36), Vector2(4, 15)), ping_color)
	draw_rect(Rect2(Vector2(-36, 21), Vector2(4, 15)), ping_color)
	draw_rect(Rect2(Vector2(32, 21), Vector2(4, 15)), ping_color)
	draw_rect(Rect2(Vector2(-10, -42), Vector2(20, 3)), ping_color)
	draw_rect(Rect2(Vector2(-7, -47), Vector2(14, 5)), solid_color)
	draw_rect(Rect2(Vector2(-3, -52), Vector2(6, 5)), solid_color)


func _pulse01(multiplier: float = 1.0, phase: float = 0.0) -> float:
	return (sin(_pulse_time * multiplier + phase) + 1.0) * 0.5
