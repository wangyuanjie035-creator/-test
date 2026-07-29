# 节点循环规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-26

关联文档：

- [007_minimal_battle_state.md](007_minimal_battle_state.md)
- [009_ordinary_pressure_encounter.md](009_ordinary_pressure_encounter.md)
- [010_reward_selection.md](010_reward_selection.md)

## 目标

把“战斗胜利 -> 选择奖励 -> 进入下一节点”串成一个可重复的最小局内循环。玩家在一个普通压力节点中获得奖励后，可以立刻用扩容后的牌组进入新的普通压力节点，并保留当前精力作为局内持续压力。

## 规则

- 只有在节点胜利且已选择奖励后，才允许进入下一节点。
- 下一节点暂时复用 `N001 普通压力`，后续地图系统完成后再替换为真实节点池。
- 进入下一节点时保留当前 `vitality`，不回复到满精力。
- 当前牌组以 `deck_card_ids` 为准，包含上一节点选择的奖励卡。
- 新节点开始时重建抽牌堆、清空手牌/弃牌堆/消耗堆/待发现项，并重新洗牌。
- 新节点重置回合、行动点、防护、进度、战斗内资源和临时标签状态。
- 新节点开始后自动进入第 1 回合并抽 5 张牌。

## 实现内容

- `scripts/battle/battle_state.gd`
  - 新增 `start_next_encounter(encounter, seed, preserve_vitality)`。
  - 新增 `_rebuild_draw_pile_from_deck()`，从 `deck_card_ids` 重建当前战斗牌堆。
  - 修正 `_refill_draw_pile()` 的日志缩进，避免脚本解析失败。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `node_index` 记录当前节点编号。
  - 新增“下一节点”按钮。
  - 新增 `start_next_node()`，在奖励选择后启动新的普通压力节点。
  - 新增 `get_next_node_available()` 供自动验证使用。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

验证流程：

1. 初始化战斗测试场景。
2. 结束第 1 回合，承受 6 点压力，使精力降到 44。
3. 强制手牌为 `C011 做实验`，把进度设为目标前 1 点并打出卡牌，触发胜利。
4. 选择第一张奖励卡。
5. 点击/调用下一节点逻辑。

验证输出：

```text
reload_battle_state.gd=0
reload_battle_test_scene.gd=0
played=true
vitality_before_victory=44
reward_buttons_after_win=3
selected=true
next_available_after_reward=true
deck_after_reward=16
vitality_before_next=44
next_started=true
node_index=2
turn=1
vitality_after_next=44
deck_after_next=16
pile_total=16
hand_buttons=5
reward_buttons_after_next=0
progress_after_next=0
next_available_after_next=false
```

结果说明：

- 奖励选择后“下一节点”入口会打开。
- 下一节点成功从第 2 个节点开始，回合重置为 1。
- 精力从 44 保留到下一节点，没有自动回满。
- 当前牌组保持 16 张，说明奖励卡已经进入后续循环。
- 新战斗的抽牌堆、手牌、弃牌堆和消耗堆总数为 16，没有复制或丢失卡牌。
- 新节点开始后奖励区清空，进度归零，不能继续点击“下一节点”。

## 下一步

1. 路线状态层和 3 个普通节点变体已完成，见 [012_route_state_and_encounter_variants.md](012_route_state_and_encounter_variants.md)。
2. 阶段结算和精力耗尽坏结局正反馈已完成，见 [013_run_settlement.md](013_run_settlement.md)。
3. 节点间小型事件节点已完成首版接入，见 [019_event_nodes_in_route.md](019_event_nodes_in_route.md)。
