# 099 校园条件拦截模式数据化

## 目标

把校园路线需求的入口行为从脚本固定逻辑迁到 `CampusRouteRequirementDefinition` 数据中。后续同一个 `condition_locked` 标记可以根据路线节点配置成仅提示、二次确认或硬拦截，不需要再改 `CampusOverworldScene`。

## 拦截模式

`scripts/data/campus_route_requirement_definition.gd` 新增 `intercept_mode`：

| 值 | 行为 |
| --- | --- |
| `warn_only` | 条件不足时仍显示 `condition_locked` 和 `准备不足`，但首次交互直接进入。 |
| `soft_gate` | 条件不足时首次交互停在校园，HUD 显示 `再次确认进入`；第二次交互进入。 |
| `hard_gate` | 条件不足时始终停在校园，HUD 显示 `材料不足，无法进入`；补足材料后首次交互进入。 |

如果条件已经满足，三种模式都会直接进入。缺失或非法模式默认按 `soft_gate` 处理，保证旧数据迁移后仍保持当前安全行为。

## 当前数据

`data/campus/route_requirements.tres` 中现有 9 条路线需求都显式配置为 `soft_gate`：

- `E005 转博申请`
- `E006 基金申请窗口`
- `B002 中期考核`
- `B003 盲审专家`
- `B004 博士资格考核`
- `B005 项目中期检查`
- `B006 博士预答辩`
- `B007 博士答辩`
- `B008 补答辩`

这意味着当前玩家体验与 [098_campus_condition_soft_gate.md](098_campus_condition_soft_gate.md) 保持一致。`warn_only` 和 `hard_gate` 已接入逻辑，后续可按剧情需要逐条启用。

## 修改文件

- `scripts/data/campus_route_requirement_definition.gd`
  - 新增 `INTERCEPT_WARN_ONLY`、`INTERCEPT_SOFT_GATE`、`INTERCEPT_HARD_GATE`。
  - 新增导出字段 `intercept_mode`，默认 `soft_gate`。
- `data/campus/route_requirements.tres`
  - 为 9 条现有路线需求写入 `intercept_mode = &"soft_gate"`。
- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `get_interactable_requirement_intercept_mode()`，用于验证某个交互点的拦截模式。
  - `_start_interaction()` 根据模式分流为仅提示、软拦截或硬拦截。
  - HUD 焦点提示会在 `hard_gate` 和 `warn_only` 下显示对应状态。

## 验证记录

验证环境：
- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 脚本、场景和数据验证使用 `ResourceLoader.CACHE_MODE_IGNORE`。

脚本编译与数据载入：

```text
res://scripts/data/campus_route_requirement_definition.gd=0
res://scripts/data/campus_route_requirement_catalog_definition.gd=0
res://scripts/data/campus_requirement_group_definition.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
route_requirement_count=9
mode_E005=soft_gate
mode_E006=soft_gate
mode_B002=soft_gate
mode_B003=soft_gate
mode_B004=soft_gate
mode_B005=soft_gate
mode_B006=soft_gate
mode_B007=soft_gate
mode_B008=soft_gate
```

三种模式行为验证：

```text
soft_mode=soft_gate
soft_first_start=false
soft_first_mode=overworld
soft_pending=midterm_room
soft_second_start=true
soft_second_mode=battle
soft_active_route=B002
warn_mode=warn_only
warn_first_start=true
warn_first_mode=battle
warn_pending=
warn_active_route=B002
hard_mode=hard_gate
hard_prompt_before=中期考核 路 B002｜准备不足：数据 0/2、草稿 0/3｜材料不足，无法进入
hard_first_start=false
hard_first_mode=overworld
hard_pending=
hard_active_route=
hard_ready_start=true
hard_ready_mode=battle
hard_ready_route=B002
```

## 手测要点

1. 默认运行主场景并切到 `研二`，`B002 中期考核` 应仍按 `soft_gate` 行为：首次提示，二次确认进入。
2. 临时把 `Route_b002` 的 `intercept_mode` 改为 `warn_only` 后，资源不足时首次交互应直接进入。
3. 临时把 `Route_b002` 的 `intercept_mode` 改为 `hard_gate` 后，资源不足时首次交互应停在校园，HUD 显示 `材料不足，无法进入`。
4. 在 `hard_gate` 下补足 `数据 2` 和 `草稿 3` 后，首次交互应进入 `B002`。

## 下一步

1. 已完成：给 HUD 下一步提示增加更具体的补足建议，见 [100_campus_guidance_supply_advice.md](100_campus_guidance_supply_advice.md)。
2. 在正式剧情调试中决定每条路线的默认模式：开发期关键节点多用 `soft_gate`，正式毕业结局或强条件节点可逐步改为 `hard_gate`。
3. 后续美术素材到位后，把硬拦截节点做成更明确的像素门牌、导师提醒或地面标识。
