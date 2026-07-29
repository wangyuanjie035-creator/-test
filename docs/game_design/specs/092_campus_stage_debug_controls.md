# 092 校园阶段切换调试控件

## 目标

给当前校园地图增加一个临时调试入口，让运行游戏时可以直接切换 `研一 / 研二 / 博一` 校园池，方便检查不同阶段的 NPC、资源点、事件和 Boss。这个入口是开发期工具，后续可以替换为剧情推进、结算后跳转或正式地图导航。

## UI 规则

- 调试控件放在校园 HUD 左上状态面板中。
- 本步骤初版显示标题 `阶段` 和三个按钮：`研一`、`研二`、`博一`；后续已扩展为六个阶段按钮，见 [095_campus_doctoral_stage_expansion.md](095_campus_doctoral_stage_expansion.md)。
- 当前阶段按钮置灰，避免重复点击造成无意义重置。
- 按钮只在校园 HUD 可见；进入战斗层时 HUD 已隐藏。
- 切换阶段会重置当前校园探索状态，包括已拾取资源、已完成交互和浮字。

## 实现内容

更新：
- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `stage_debug_buttons`。
  - 新增 `_build_stage_debug_controls()` 构建按钮行。
  - 新增 `_on_stage_debug_button_pressed()`。
  - 新增 `_refresh_stage_debug_buttons()`，让当前阶段按钮置灰。
  - 新增 `get_stage_debug_button_count()` 和 `is_stage_debug_button_disabled()`，用于脚本验证。

未改变：
- 默认阶段仍是研一。
- 阶段池内容不变。
- 战斗和事件逻辑不变。
- 美术替换方案不变；按钮只是调试入口，不影响 `CampusMapMarker` 后续替换素材。

## 验证记录

验证环境：
- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

按钮状态验证：

```text
button_count=3
default_stage=master1
default_master1_disabled=true
default_master2_disabled=false
default_doctor1_disabled=false
default_count=10
```

阶段切换验证：

```text
master2_stage=master2
master2_label=研二
master2_disabled=true
master2_ids=data_cleaning_night,submission_rehearsal,replication_alarm,transfer_office,midterm_room,blind_review_room,replication_data_pack,archived_draft_stack,review_reputation_note,paper_fragments_pinboard
collect_master2_data=true
master2_data=2

doctor1_stage=doctor1
doctor1_label=博一
doctor1_disabled=true
doctor1_ids=doctoral_problem_chain,project_pressure_board,funding_window,qualification_room,committee_notes,paper_fragments_stack,project_funds_notice,longitudinal_data_pack,doctoral_inspiration,draft_restructure
doctor1_data_after_reset=0
start_qualification=true
qualification_active=B004
```

## 手测要点

1. 本步骤初版运行主场景时，左上 HUD 应显示 `阶段`、`研一`、`研二`、`博一`；当前最新版本还应包含 `博二`、`博三`、`博四`。
2. 默认 `研一` 按钮应置灰。
3. 点击 `研二` 后，HUD 应显示 `研二校园`，地图应刷新为研二交互池。
4. 点击 `博一` 后，HUD 应显示 `博一校园`，地图应刷新为博一交互池。
5. 切换阶段后，之前阶段已拾取的资源不应保留。

## 下一步

1. 已完成：把 `condition_locked` 和真实条件检查绑定，见 [093_campus_condition_locked_requirements.md](093_campus_condition_locked_requirements.md)。
2. 已完成：把阶段交互池迁移成数据表，见 [094_campus_data_resource_migration.md](094_campus_data_resource_migration.md)。
3. 已完成：扩展博二、博三和博四返修阶段按钮，见 [095_campus_doctoral_stage_expansion.md](095_campus_doctoral_stage_expansion.md)。
4. 后续剧情推进接入后，将调试按钮隐藏或移入开发者面板。
