# 094 校园阶段与条件资源化

## 目标

把校园地图里的阶段交互池和路线条件表迁移为 Godot Resource 数据，减少 `CampusOverworldScene` 中的硬编码。后续扩展博二、博三、博四返修或替换地图资源时，可以优先改数据文件，而不是改场景脚本。

## 数据结构

新增 Resource 脚本：

- `scripts/data/campus_stage_definition.gd`：一个校园阶段，包含阶段 ID、显示名、调试按钮名、排序和交互列表。
- `scripts/data/campus_interaction_definition.gd`：一个地图交互点，包含交互 ID、类型、路线节点、资源奖励、位置、随机偏移、标记状态和强调色。
- `scripts/data/campus_route_requirement_catalog_definition.gd`：路线条件表入口。
- `scripts/data/campus_route_requirement_definition.gd`：一个路线节点的条件配置。
- `scripts/data/campus_requirement_group_definition.gd`：一组条件，支持 `all` 与 `any`。
- `scripts/data/campus_resource_requirement_definition.gd`：单项资源需求。

新增数据文件：

- `data/campus/stages/master1.tres`
- `data/campus/stages/master2.tres`
- `data/campus/stages/doctor1.tres`
- `data/campus/route_requirements.tres`

## 实现内容

更新：

- `scripts/data/game_data_catalog.gd`
  - 新增 `load_campus_stages_by_id()`。
  - 新增 `load_campus_route_requirements_by_id()`。
- `scripts/overworld/campus_overworld_scene.gd`
  - 阶段调试按钮从 `CampusStageDefinition` 生成。
  - 地图交互点从 `data/campus/stages/*.tres` 生成。
  - 条件锁定从 `data/campus/route_requirements.tres` 查询。
  - 删除研一、研二、博一交互池的旧硬编码函数。

未改变：

- 研一、研二、博一仍各有 10 个交互点。
- 当前调试按钮仍为 `研一 / 研二 / 博一`。
- 迁移当时 `condition_locked` 仍只做地图预告和摘要提示，不阻止交互；当前最新流程已加入二次确认软拦截，见 [098_campus_condition_soft_gate.md](098_campus_condition_soft_gate.md)。
- 地图坐标、资源数量、标记状态和颜色保持与迁移前一致。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/data/campus_resource_requirement_definition.gd=0
res://scripts/data/campus_requirement_group_definition.gd=0
res://scripts/data/campus_interaction_definition.gd=0
res://scripts/data/campus_stage_definition.gd=0
res://scripts/data/campus_route_requirement_definition.gd=0
res://scripts/data/campus_route_requirement_catalog_definition.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

资源加载验证：

```text
stage_count=3
stage_doctor1_interactions=10
stage_master1_interactions=10
stage_master2_interactions=10
requirement_count=9
```

行为回归验证：

```text
master1_label=研一
master1_count=10
button_count=3
master1_disabled=true
master2_label=研二
master2_count=10
master2_ids=data_cleaning_night,submission_rehearsal,replication_alarm,transfer_office,midterm_room,blind_review_room,replication_data_pack,archived_draft_stack,review_reputation_note,paper_fragments_pinboard
master2_transfer_state=condition_locked
master2_transfer_req=声望 0/2 或 草稿 0/4
master2_midterm_state=condition_locked
master2_midterm_req=数据 0/2、草稿 0/3
master2_data_after_collect=2
master2_draft_after_collect=2
master2_midterm_state_after_partial=condition_locked
master2_midterm_req_after_partial=数据 2/2、草稿 2/3
doctor1_label=博一
doctor1_count=10
doctor1_ids=doctoral_problem_chain,project_pressure_board,funding_window,qualification_room,committee_notes,paper_fragments_stack,project_funds_notice,longitudinal_data_pack,doctoral_inspiration,draft_restructure
doctor_funding_state_initial=condition_locked
doctor_funding_req_initial=经费 0/2
doctor_qualification_state_initial=condition_locked
doctor_qualification_req_initial=方法论笔记 0/3 或 论文碎片 0/2
doctor_funds_after_collect=2
doctor_funding_state_after_funds=story_key
doctor_funding_req_after_funds=
```

## 手测要点

1. 运行主场景后，确认左上阶段按钮仍显示 `研一 / 研二 / 博一`。
2. 默认研一仍有同门交流、实验室排队、食堂偶遇大牛、导师临时约谈、开题报告和 5 个资源点。
3. 切到研二后，确认 `转博申请窗口`、`中期考核`、`盲审专家` 的条件不足提示仍存在。
4. 切到博一后，拾取 `项目经费通知`，`基金申请窗口` 应从 `condition_locked` 恢复为 `story_key`。

## 下一步

1. 已完成：用同一套 Resource 结构扩展博二、博三和博四返修校园阶段，见 [095_campus_doctoral_stage_expansion.md](095_campus_doctoral_stage_expansion.md)。
2. 将当前阶段调试按钮接到正式剧情推进：研二 Boss 后根据是否转博进入硕士毕业线或博士线。
3. 已完成：在条件表上增加可配置字段，决定某个锁定节点是“仅提示”“二次确认”还是“禁止进入”，见 [099_campus_requirement_intercept_modes.md](099_campus_requirement_intercept_modes.md)。
