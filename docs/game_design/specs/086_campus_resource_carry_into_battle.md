# 校园资源带入战斗 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [082_event_requirement_progress.md](082_event_requirement_progress.md)
- [083_2d_campus_overworld_mvp.md](083_2d_campus_overworld_mvp.md)
- [085_campus_battle_result_writeback.md](085_campus_battle_result_writeback.md)

## 目标

让校园地图上的资源真正影响卡牌战斗层。

示例：

```text
校园资源：草稿 2
进入 E001 食堂偶遇大牛
事件选项“递上自己的草稿”变为可选
选择后战斗层草稿 2 -> 0，声望 +2，方法论笔记 +1
返回校园后：草稿 0，声望 2，方法论笔记 1
```

这样地图探索和卡牌事件开始产生真实连接，而不是两个互不影响的界面。

## 同步规则

进入战斗时：

- 校园层将已持有的资源注入 `BattleState.resources`。
- 注入后刷新战斗 UI，让事件条件和详情进度立即使用这些资源。
- 注入后的战斗资源会作为回写快照。

返回校园时：

- 如果交互未完成，不同步差值，也不消耗 NPC。
- 如果交互完成，计算 `战斗结束资源 - 进入战斗资源快照`。
- 正差值加入校园资源。
- 负差值从校园资源扣除，最低为 0。

已同步资源：

```text
灵感、数据、草稿、经费、声望、经验教训、方法论笔记、论文碎片
```

## 实现内容

更新：

- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `_apply_campus_resources_to_active_battle()`。
  - `_open_battle_for_interactable()` 在进入目标节点后注入校园资源。
  - 注入资源后调用战斗 UI 刷新，确保事件按钮状态立即更新。
  - `_apply_battle_resource_deltas_to_campus()` 从“只同步正向增量”升级为“同步正负差值”。

未改变：

- 战斗内部资源规则不变。
- 未完成返回仍不会消耗地图交互点。
- 资源点收集逻辑不变。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

校园草稿带入事件验证：

```text
campus_draft_before=2
start_canteen=true
active_node=E001
battle_draft_injected=2
show_draft_choice=true
battle_draft_after_choice=0
battle_reputation_after_choice=2
battle_methodology_after_choice=1
completed=true
campus_draft_after=0
campus_reputation_after=2
campus_methodology_after=1
available_count=5
```

未完成返回回归验证：

```text
unfinished_completed=false
unfinished_draft_after=2
unfinished_available_count=6
```

普通事件正向回写回归验证：

```text
event_completed=true
event_methodology=1
event_reputation=1
event_available_count=5
```

## 手测要点

建议测试：

1. 通过调试或后续资源点让校园层拥有 `草稿 2`。
2. 进入 `食堂偶遇大牛`。
3. 检查 `递上自己的草稿` 是否可选，并显示 `草稿 2/2`。
4. 选择该选项后返回校园。
5. 校园 HUD 应显示草稿被扣除，声望和方法论笔记增加。

## 下一步

1. 已完成：[087_campus_resource_points_expansion.md](087_campus_resource_points_expansion.md) 增加草稿、灵感、数据、经费等校园资源点。
2. 把战斗完成后的“返回校园”按钮做成结算面板动作，而不是临时右上角按钮。
3. 将校园资源和路线阶段绑定，让导师办公室、会议室等地点随着研一/研二/博一阶段刷新不同交互。
