# 校园交互结果回写 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [083_2d_campus_overworld_mvp.md](083_2d_campus_overworld_mvp.md)
- [084_campus_map_layout_fix.md](084_campus_map_layout_fix.md)

## 目标

让校园地图不只是“打开战斗 UI 的菜单”，而是能记住一次地图交互是否已经完成。

首版规则：

- 从地图进入学术交流后，如果没有处理事件、没有胜利领奖、没有进入结算，直接返回校园不会消耗 NPC。
- 事件选项选择完成后，返回校园会让该事件 NPC 消失。
- 普通战斗或 Boss 领取奖励后，返回校园会让该 NPC/Boss 入口消失。
- 战斗层资源变化会带回校园 HUD；完整正负差值同步见 [086_campus_resource_carry_into_battle.md](086_campus_resource_carry_into_battle.md)。

## 完成判定

校园层根据 `BattleTestScene` 的只读状态判断当前交互是否完成：

| 条件 | 含义 |
| --- | --- |
| `was_event_choice_taken()` | 事件节点已经选择选项 |
| `was_reward_taken()` | 普通战斗或 Boss 已领取奖励 |
| `get_settlement_visible()` | 当前战斗已经进入结算 |
| 当前路线节点已离开入口节点 | 脚本化事件或路线跳转已经发生 |

如果以上条件都不满足，点击 `返回校园` 只视为暂时离开，不消耗地图交互点。

## 资源回写

进入学术交流时，校园层会记录战斗前资源快照。

返回校园并判定完成后，会把以下资源的正向增量加入校园资源：

```text
灵感、数据、草稿、经费、声望、经验教训、方法论笔记、论文碎片
```

本规格首版只同步正向增量：

- 事件获得 `方法论笔记 +1`、`声望 +1`，会带回校园。
- 如果事件内部消耗了草稿，首版不会从校园资源中反扣。

这个取舍是为了先保证“完成交互能留下正反馈”。后续已在 [086_campus_resource_carry_into_battle.md](086_campus_resource_carry_into_battle.md) 中升级为正负差值同步。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `was_reward_taken()` 只读接口。
- `scripts/overworld/campus_overworld_scene.gd`
  - 新增当前交互上下文：交互 ID、路线节点、交互摘要、战斗前资源快照。
  - 新增 `completed_interaction_ids`。
  - 新增 `get_available_interactable_ids()`。
  - 新增 `is_interaction_completed()`。
  - 新增 `get_completed_interaction_ids()`。
  - `return_to_campus()` 会先解析当前战斗结果，再清理战斗层。
  - 完成交互后调用 `CampusInteractable.mark_collected()` 隐藏 NPC/资源点。

未改变：

- 战斗 UI 的卡牌逻辑不变。
- 校园地图交互点生成逻辑不变。
- 未完成交互仍可再次进入。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

未完成返回验证：

```text
unfinished_start=true
unfinished_completed=false
unfinished_available_count=6
unfinished_can_restart=true
```

事件完成回写验证：

```text
event_start=true
event_node=E008
event_choice=true
event_completed=true
event_available_count=5
event_methodology=1
event_reputation=1
event_restart_blocked=false
```

普通战斗完成回写验证：

```text
encounter_start=true
encounter_reward_count=3
encounter_select_reward=true
encounter_completed=true
encounter_available_count=5
```

## 手测要点

运行项目后：

- 进入一个 NPC 学术交流后立刻点 `返回校园`，该 NPC 不应消失。
- 进入 `导师临时约谈`，选择 `对齐阶段预期`，返回校园后导师事件点应消失。
- 返回校园后 HUD 应显示带回的 `方法论笔记 1` 和 `声望 1`。
- 打完一个普通学术交流并领取奖励后，返回校园该 NPC 应消失。

## 下一步

1. 校园资源带入战斗层已完成，见 [086_campus_resource_carry_into_battle.md](086_campus_resource_carry_into_battle.md)。
2. 把战斗胜利后自动返回校园做成更自然的结算按钮，而不是临时右上角按钮。
3. 将完成过的交互点替换成“已交流”或“已处理”像素标记，而不是直接隐藏。
