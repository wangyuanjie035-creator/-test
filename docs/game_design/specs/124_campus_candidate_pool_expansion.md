# 124 交互候选库扩容

## 目标

承接 [123_campus_tag_candidate_selector.md](123_campus_tag_candidate_selector.md)，把校园阶段的“实际固定地图点位”和“生成候选池”拆开。

本步仍不启用随机地图生成：`_spawn_interactables()` 继续读取 `interactions`，所以玩家当前看到的每阶段固定地图仍是 12 个点位。新增的候选点只供标签选择器预览和审查，为后续真正接入随机校园地图做内容储备。

## 数据规则

- `CampusStageDefinition` 新增 `generation_candidate_interactions`。
- 当阶段配置了 `generation_candidate_interactions` 时，选择器优先从该数组里选点。
- 当阶段没有配置候选数组时，选择器回退使用 `interactions`，保证旧数据兼容。
- 每个阶段当前候选池为 16 个点，目标仍是 12 个点。
- 每阶段保留原有 12 个 `interactions`，额外加入 4 个候选点。

## 选择规则补强

123 首版选择器先覆盖 required tags，再按总分填充。本步在两者之间加入一层 focus tags 补齐：

1. 优先覆盖 `generation_required_tags`，保证关键体验不缺失。
2. 再尽量覆盖 `generation_focus_tags`，保证阶段主题稳定出现。
3. 最后按 required/focus 命中、交互类型权重和 seed tie-breaker 填满目标数量。

这样候选池变大后，即使有多个高分候选，也会优先保留阶段辨识度，例如博士三的“声望”准备点不会被全量答辩/写作点挤掉。

## 新增候选内容

| 阶段 | 新增候选 |
| --- | --- |
| 研一 | `advisor_feedback_note`、`lab_safety_briefing`、`orientation_notice_board`、`peer_literature_swap` |
| 研二 | `advisor_review_slot`、`equipment_benchmark_room`、`committee_precheck_note`、`draft_version_control` |
| 博一 | `doctor1_grant_budget_draft`、`doctor1_committee_office_hour`、`doctor1_method_workshop`、`doctor1_seminar_poster_wall` |
| 博二 | `doctor2_equipment_failure_ticket`、`doctor2_collaborator_sync_notes`、`doctor2_budget_reforecast_sheet`、`doctor2_field_data_handoff` |
| 博三 | `doctor3_slide_timing_drill`、`doctor3_external_reviewer_note`、`doctor3_thesis_figure_archive`、`doctor3_defense_rest_corner` |
| 博四 | `doctor4_revision_scope_meeting`、`doctor4_supplemental_data_patch`、`doctor4_peer_morale_circle`、`doctor4_final_response_letter` |

这些候选点先以现有 Resource 字段表达，后续替换美术资源时可以直接按 `id` 和 `content_tags` 绑定对应像素角色、建筑或物件素材。

## 实现记录

- [campus_stage_definition.gd](../../../scripts/data/campus_stage_definition.gd)
  - 新增 `generation_candidate_interactions: Array[Resource]`。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - `_get_stage_generation_candidate_definitions()` 优先读取 `generation_candidate_interactions`。
  - `_select_generation_candidate_definitions()` 在 required pass 后新增 focus pass。
- [data/campus/stages](../../../data/campus/stages)
  - 六个阶段均配置 16 个候选点。
  - 六个阶段的实际 `interactions` 仍保持 12 个。

## 验证记录

远程 Godot 执行器验证：

```text
stage_reload=0
scene_reload=0
```

六阶段审查：

```text
master1 map_count=12,pool=16,target=12,selected=12,missing=0,focus_hits=7/7,missing=
master2 map_count=12,pool=16,target=12,selected=12,missing=0,focus_hits=7/7,missing=
doctor1 map_count=12,pool=16,target=12,selected=12,missing=0,focus_hits=7/7,missing=
doctor2 map_count=12,pool=16,target=12,selected=12,missing=0,focus_hits=6/6,missing=
doctor3 map_count=12,pool=16,target=12,selected=12,missing=0,focus_hits=6/6,missing=
doctor4 map_count=12,pool=16,target=12,selected=12,missing=0,focus_hits=6/6,missing=
```

## 手测重点

1. 进入任意阶段校园，地图上实际可交互点仍应是 12 个。
2. 主线目标、补给建议、右上任务视图和小地图点位数不应因为候选池扩容而改变。
3. 调试审查里每阶段应显示 `pool=16,target=12,selected=12,missing=0`。
4. 相同 seed 下选择器结果应稳定；不同 seed 后续启用时可以产生不同点位组合。
5. 候选点先不要求全部出现在实际地图上，这是预期行为。

## 下一步

1. 已完成“候选池接入开关”，见 [125_campus_candidate_spawn_toggle.md](125_campus_candidate_spawn_toggle.md)。
2. 可以继续扩展到每阶段 20 个以上候选点，再接入建筑区域、点位权重和互斥组，避免同类点过度集中。
