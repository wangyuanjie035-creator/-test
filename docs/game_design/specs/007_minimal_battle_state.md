# 最小战斗状态规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-26

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [004_godot_data_model.md](004_godot_data_model.md)
- [006_godot_data_layer_implementation.md](006_godot_data_layer_implementation.md)

## 目标体验

先不做 UI，只验证卡牌数据能驱动一个最小回合制循环：

- 从 `D001` 初始牌组创建抽牌堆。
- 每回合获得 3 行动点，抽 5 张牌。
- 玩家可以打出手牌，消耗行动点并执行卡牌效果。
- 回合结束时手牌进入弃牌堆。
- 抽牌堆为空时，弃牌堆洗回抽牌堆。

## MVP 战斗字段

| 字段 | 初始值 | 说明 |
| --- | --- | --- |
| max_vitality | 50 | 最大精力 |
| vitality | 50 | 当前精力 |
| base_action_points | 3 | 每回合行动点 |
| action_points | 3 | 当前行动点 |
| hand_size | 5 | 每回合抽牌数 |
| block | 0 | 当前防护，回合开始清空 |
| progress | 0 | 当前节点研究进度 |
| inspiration | 0 | 灵感 |
| data | 0 | 数据 |
| draft | 0 | 草稿 |
| funds | 0 | 经费 |
| reputation | 0 | 声望 |

## 首批支持效果

| effect_type | 行为 |
| --- | --- |
| gain_progress | 增加进度 |
| gain_block | 增加防护 |
| draw | 抽牌 |
| gain_resource | 增加灵感、数据、草稿、经费、声望或精力 |
| lose_energy | 失去精力 |
| lose_action_point | 失去行动点 |
| remove_status | 从目标牌堆移除指定状态牌 |
| discard | 弃掉手牌 |
| modify_next_progress | 修改下一次进度收益 |
| discover | MVP 暂记录待处理发现，不打开选择界面 |

## 暂不做

- 敌人和 Boss 行动。
- 真实 UI。
- 发现牌选择界面。
- 升级卡切换。
- 状态牌完整触发时机。
- 存档。

这些都在基础状态验证后继续加。

## 验收标准

- Godot editor executor 能加载 `BattleState`。
- 使用 `D001` 开局后，牌库总数为 15。
- `start_battle()` 后手牌为 5，行动点为 3。
- 打出 `查文献` 后行动点减少，灵感增加，手牌/弃牌堆变化正确。
- 打出 `写草稿` 后草稿增加。
- 打出 `做实验` 后进度增加，并在有灵感时获得数据。

## 实现记录

新增文件：

| 文件 | 用途 |
| --- | --- |
| `scripts/battle/battle_state.gd` | 最小战斗状态，负责牌堆、回合、行动点、资源和基础效果 |
| `scripts/tools/validate_battle_state.gd` | 编辑器内验证脚本 |

当前 `BattleState` 已支持：

- 从 `DeckDefinition` 和卡牌 catalog 初始化牌组。
- 洗牌、抽牌、弃牌、消耗牌。
- 回合开始和回合结束。
- 行动点、精力、防护、进度。
- 灵感、数据、草稿、经费、声望。
- 首批数据效果：`gain_progress`、`gain_block`、`draw`、`gain_resource`、`lose_energy`、`lose_action_point`、`remove_status`、`discard`、`modify_next_progress`、`discover`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

验证输出：

```text
draw_initial_hand=5
draw_initial_ap=3
draw_total_cards=15
played=C001:true;C006:true;C011:true
effect_ap=0
effect_progress=6
effect_inspiration=1
effect_data=1
effect_draft=2
effect_hand=0
effect_discard=3
```

结果说明：

- `D001` 正确组装为 15 张牌。
- `start_battle()` 后抽 5 张牌并获得 3 行动点。
- `查文献` 正确提供 1 灵感。
- `写草稿` 正确提供 2 草稿。
- `做实验` 正确提供 6 进度，并在已有灵感时提供 1 数据。

## 下一步

1. 极简战斗测试界面已完成，见 [008_battle_test_ui.md](008_battle_test_ui.md)。
2. 普通压力节点已接入，见 [009_ordinary_pressure_encounter.md](009_ordinary_pressure_encounter.md)。
3. 节点胜利后的奖励选择已完成，见 [010_reward_selection.md](010_reward_selection.md)。
