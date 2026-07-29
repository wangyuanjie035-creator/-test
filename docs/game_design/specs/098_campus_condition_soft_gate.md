# 098 校园条件不足软拦截

## 目标

把条件不足的校园关键节点从“只做地图预告”升级为“首次交互提示准备不足，二次确认后仍可进入”。这样玩家不会误触发尚未准备好的事件或 Boss，同时保留早期开发期验证战斗、事件和资源回写链路的通路。后续已把入口行为改为数据配置，见 [099_campus_requirement_intercept_modes.md](099_campus_requirement_intercept_modes.md)。

## 交互规则

- 适用对象：非资源类交互点，且当前 `requirement_summary` 不为空。
- 首次交互条件不足节点时，不进入战斗或事件，当前模式保持在 `overworld`。
- 首次交互会记录 `pending_condition_override_interaction_id`，HUD 焦点提示追加 `再次确认进入`。
- 再次交互同一个节点时，即使资源仍不足，也会进入对应战斗或事件。
- 如果资源已经满足，第一次交互直接进入，不触发二次确认。
- 如果离开当前交互点、拾取资源、重置校园阶段，或该节点需求已经满足，待确认状态会清空。
- 本版不改变 `condition_locked` 地图视觉规则，也不改变路线需求表。

## 修改文件

- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `_pending_condition_override_interaction_id`。
  - 新增 `get_pending_condition_override_interaction_id()`，用于验证当前待确认节点。
  - `_start_interaction()` 在进入战斗前检查条件不足状态。
  - `_refresh_hud()` 在焦点交互为待确认节点时追加 `再次确认进入`。
  - `_on_interactable_body_exited()`、`_reset_campus()`、资源拾取和条件刷新时清理待确认状态。

## 验证记录

验证环境：
- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 脚本和场景验证使用 `ResourceLoader.CACHE_MODE_IGNORE`。

脚本编译验证：

```text
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

软拦截行为验证：

```text
locked_midterm_marker=condition_locked
locked_first_start=false
locked_first_mode=overworld
locked_pending=midterm_room
locked_second_start=true
locked_second_mode=battle
locked_active_interaction=midterm_room
locked_active_route=B002
ready_midterm_marker=boss_available
ready_first_start=true
ready_first_mode=battle
ready_pending=
ready_active_route=B002
focus_pending=midterm_room
focus_prompt=中期考核 路 B002｜准备不足：数据 0/2、草稿 0/3｜再次确认进入
```

## 手测要点

1. 运行主场景后，切到 `研二`。
2. 资源不足时靠近 `中期考核`，地图标记应为 `condition_locked`，交互摘要应显示 `准备不足：数据 0/2、草稿 0/3`。
3. 第一次交互 `中期考核` 后，应停留在校园地图，HUD 焦点提示追加 `再次确认进入`。
4. 不离开交互范围的情况下再次交互，应进入 `B002 中期考核`。
5. 先收集足够 `数据` 和 `草稿` 后再交互 `中期考核`，应第一次就进入，不出现二次确认。
6. 首次交互后离开该交互范围，再靠近交互时应重新走首次提示流程。

## 下一步

1. 已完成：在路线需求数据上增加拦截模式字段，例如 `warn_only`、`soft_gate`、`hard_gate`，见 [099_campus_requirement_intercept_modes.md](099_campus_requirement_intercept_modes.md)。
2. 给 HUD 下一步提示增加更具体的补足建议，例如“先收集草稿提纲，再挑战中期考核”。
3. 后续正式美术素材到位后，把当前 `condition_locked` 和引导叠层替换为像素门牌、地面箭头或 NPC 提醒。
