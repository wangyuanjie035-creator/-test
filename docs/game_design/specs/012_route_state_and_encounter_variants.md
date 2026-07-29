# 路线状态与普通节点变体规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-26

关联文档：

- [009_ordinary_pressure_encounter.md](009_ordinary_pressure_encounter.md)
- [010_reward_selection.md](010_reward_selection.md)
- [011_node_loop.md](011_node_loop.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)

## 目标

让局内推进不再固定重复 `N001 普通压力`，而是由一个轻量路线状态控制当前节点和下一节点。MVP 先使用固定路线，后续再替换成分叉地图、更多事件池和 Boss 节点。

## MVP 路线

本文首版实现时的固定路线为：

| 顺序 | ID | 名称 | 目标进度 | 每回合压力 | 定位 |
| --- | --- | --- | --- | --- | --- |
| 1 | N001 | 普通压力 | 40 | 6 | 标准节点 |
| 2 | N002 | 周会压力 | 36 | 7 | 目标较低、压力较尖锐 |
| 3 | N003 | 设备排队 | 34 | 5 | 压力较低、实验窗口感 |
| 4 | N004 | 截稿临近 | 46 | 8 | 普通节点中的小考 |

事件节点接入后，Godot 路线曾更新为 `N001 -> E001 -> N002 -> E004 -> N003 -> N004`，见 [019_event_nodes_in_route.md](019_event_nodes_in_route.md)。当前版本已进一步升级为简化分叉路线，见 [022_branching_route_choice.md](022_branching_route_choice.md)。

## 规则

- `RouteState` 保存本局路线节点 ID、当前下标和已完成节点。
- 本文首版实现时，新旅程测试路线固定为 `N001 -> N002 -> N003 -> N004`；事件接入后已更新为 `N001 -> E001 -> N002 -> E004 -> N003 -> N004`。
- 如果固定路线中的节点数据缺失，路线会跳过缺失项。
- 如果固定路线全缺失，但项目中有其他遭遇数据，则按 ID 排序回退生成路线。
- 选择奖励后，当前节点会被标记为已完成。
- 只有 `RouteState.has_next_node()` 为 true 时，“下一节点”按钮才可用。
- 进入下一节点时，UI 从 `RouteState` 取下一遭遇并交给 `BattleState.start_next_encounter()`。
- 最后一个节点完成并选择奖励后，“下一节点”不可再点击，测试路线结束。

## 实现内容

新增遭遇资源：

- `data/encounters/n002_weekly_meeting.tres`
- `data/encounters/n003_equipment_queue.tres`
- `data/encounters/n004_deadline_near.tres`

新增脚本：

- `scripts/run/route_state.gd`
  - `setup()`：生成固定 MVP 路线。
  - `get_current_encounter()`：返回当前遭遇资源。
  - `complete_current_node()`：标记当前节点完成。
  - `advance_to_next_node()`：推进到下一节点。
  - `to_debug_dict()`：输出验证用状态。

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `ROUTE_STATE` 预加载。
  - 新增 `route` 状态。
  - 开局从路线获取第一个节点。
  - “下一节点”从路线推进，不再固定读取 `N001`。
  - 状态栏显示 `节点 当前/总数`。
  - 路线结束时将“下一节点”按钮显示为“路线完成”并禁用。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据加载验证：

```text
reload_route_state.gd=0
reload_battle_state.gd=0
reload_battle_test_scene.gd=0
encounter_count=4
encounter_ids=N001,N002,N003,N004
```

路线推进验证：

```text
route_ids=N001,N002,N003,N004
encounter_sequence=N001,N002,N003,N004
target_sequence=40,36,34,46
pressure_sequence=6,7,5,8
next_results=true/true/true/true,true/true/true/true,true/true/true/true
node_index=4
deck_size=19
final_played=true
final_selected=true
final_next_available=false
final_next_started=false
completed_node_ids=N001,N002,N003,N004
current_index=3
has_next_node=false
```

结果说明：

- 本文验证时路线按 `N001 -> N002 -> N003 -> N004` 推进；当前事件版路线验证见 [019_event_nodes_in_route.md](019_event_nodes_in_route.md)。
- 每个节点使用自己的目标进度和压力数值。
- 前 3 个节点胜利并选择奖励后，都能进入下一节点。
- 完成第 4 个节点并选择奖励后，路线判断为没有下一节点。
- 4 次奖励选择后牌组从 15 张增长到 19 张，构筑成长可以跨节点保留。

## 下一步

1. 阶段结算和精力耗尽坏结局正反馈已完成，见 [013_run_settlement.md](013_run_settlement.md)。
2. `RouteState` 节点类型字段和事件节点已完成首版接入，见 [019_event_nodes_in_route.md](019_event_nodes_in_route.md)。
3. 固定路线已升级为“3 选 1 下一节点”的简化路线选择，见 [022_branching_route_choice.md](022_branching_route_choice.md)。
