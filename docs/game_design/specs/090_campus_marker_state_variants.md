# 090 校园地图标记状态变体

## 目标

给 `CampusMapMarker` 增加状态覆盖层，让同一个地图标记可以表达不同语义：剧情关键、条件不足、Boss 可挑战。当前只改变视觉提示，不改变交互规则，为后续阶段化校园刷新、条件锁定和剧情节点引导做准备。

## 状态类型

| 状态 ID | 含义 | 当前用途 |
| --- | --- | --- |
| `default` | 默认状态 | 普通 NPC、事件、资源点 |
| `story_key` | 剧情关键 | `导师临时约谈` |
| `condition_locked` | 条件不足 | 组件能力已接入，后续给条件检查使用 |
| `boss_available` | Boss 可挑战 | `开题报告` |

## 视觉规则

- `story_key`：在标记右上角绘制黄色感叹号徽章，并轻微脉冲。
- `condition_locked`：绘制灰红遮罩和锁定小标，默认不脉冲。
- `boss_available`：在 Boss 标记外绘制金色边框和冠状提示，并轻微脉冲。
- `default`：不绘制额外覆盖层。

## 实现内容

更新：
- `scripts/overworld/campus_map_marker.gd`
  - 新增 `marker_state`。
  - 新增 `MARKER_STATE_DEFAULT`、`MARKER_STATE_STORY_KEY`、`MARKER_STATE_CONDITION_LOCKED`、`MARKER_STATE_BOSS_AVAILABLE`。
  - `configure_marker()` 增加状态参数。
  - `_should_pulse()` 扩展为资源点、剧情关键和 Boss 可挑战时刷新。
  - 新增状态覆盖层绘制函数。
- `scripts/overworld/campus_interactable.gd`
  - 新增 `marker_state`。
  - 新增 `set_marker_state()` 和 `get_marker_state()`。
  - `refresh_marker()` 同步状态到 `CampusMapMarker`。
- `scripts/overworld/campus_overworld_scene.gd`
  - `_add_interactable()` 从定义表读取 `marker_state`。
  - `advisor_drop_in` 标记为 `story_key`。
  - `proposal_room` 标记为 `boss_available`。

未改变：
- 事件/战斗进入规则不变。
- Boss 条件检查不变。
- 资源拾取和浮字反馈不变。
- `condition_locked` 目前只作为可配置状态，不会阻止交互。

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

状态同步验证：

```text
count=10
marker_count=10
advisor_state=story_key
advisor_processing=true
proposal_state=boss_available
proposal_processing=true
lab_state_before=default
lab_state_after=condition_locked
lab_processing_after=false
```

旧流程回归验证：

```text
collect_draft=true
draft_after_collect=2
draft_completed=true
feedback_after_collect=1
start_canteen=true
battle_draft_injected=2
show_draft_choice=true
draft_after_event=0
reputation_after_event=2
available_after_event=8
```

## 手测要点

1. 进入校园地图后，`导师临时约谈` 应显示剧情关键提示。
2. `开题报告` Boss 应显示可挑战提示。
3. 资源点仍应保留原来的图标、光晕和拾取浮字。
4. 进入 `食堂偶遇大牛` 前后，草稿资源带入和回写仍应正常。

## 下一步

1. 已完成：[091_campus_stage_interaction_pools.md](091_campus_stage_interaction_pools.md) 为研一、研二和博一建立阶段化校园交互池。
2. 已完成：[093_campus_condition_locked_requirements.md](093_campus_condition_locked_requirements.md) 把 `condition_locked` 和真实条件检查绑定。
3. 已完成：[094_campus_data_resource_migration.md](094_campus_data_resource_migration.md) 把交互点定义迁移成 Resource 数据。
