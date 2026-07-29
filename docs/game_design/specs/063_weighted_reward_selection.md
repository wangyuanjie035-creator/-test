# 同流派奖励权重 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)
- [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)

## 目标

普通节点的 `victory_rewards` 从“直接展示列表”升级为“节点候选池”。当候选池超过 3 张时，界面只展示 3 张奖励卡，并根据玩家本局已经形成的构筑倾向做轻量加权。

首版先使用确定性的分数排序，不做随机抽样。这样便于调试和回溯。后续已经在 [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md) 中升级为带权随机：分数相同保留原顺序，分数不同则用分数平方作为票数无放回抽取。

## 规则

- 普通遭遇节点优先读取 `EncounterDefinition.victory_rewards`。
- 如果该候选池不超过 3 张，保持原顺序全部展示。
- 本文首版规则是候选池超过 3 张时按分数排序后取前 3 张；当前实现已由 [068](068_weighted_reward_random_selection.md) 升级为带权随机。
- 基础分为 10 分。
- 候选卡每命中 1 个玩家牌组里的非初始卡标签，获得 `2 * 数量` 分，单个标签最高加 6 分。
- `starter` 稀有度卡不参与权重统计，避免初始牌组把所有人的奖励都提前染色。
- 如果牌组中已有 `experiment_noise` 状态牌：
  - `C028 负结果也是结果` 额外 +10 分。
  - `C014 清理实验台` 额外 +6 分。
- 如果当前有经费，带 `funds` 标签的候选卡额外 +5 分。
- 同分时保留候选池原始顺序，方便策划用列表顺序控制默认体验。

## N003 首版效果

`N003 设备排队` 仍配置 5 张候选：

```text
C012,C014,C015,C028,C038
```

实际展示会被裁剪成 3 张：

| 情况 | 展示奖励 | 说明 |
| --- | --- | --- |
| 默认初始牌组 | `C012`, `C014`, `C015` | 保留样本、清理、预约设备的基础实验入口 |
| 已有实验噪音 | `C028`, `C014`, `C012` | 优先给转化噪音和清理噪音的解法 |
| 已有经费倾向 | `C038`, `C012`, `C014` | 优先给经费转数据/方法论的桥接卡 |

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `MAX_CARD_REWARD_OPTIONS`。
  - `_append_encounter_reward_options()` 先收集节点候选池，再调用加权选择。
  - 新增 `_select_weighted_reward_options()`、`_score_reward_candidate()`、`_get_deck_tag_counts()` 和 `_deck_has_status_tag()`。
  - 普通默认池的回退数量也改用 `MAX_CARD_REWARD_OPTIONS`。
  - 后续 [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md) 已复用权重原因，在 tooltip 中显示推荐理由。
  - 后续 [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md) 已把分数排序升级为带权随机。

未改变：

- Boss 奖励和毕业结局仍按专属 reward id 全部展示。
- 博士线普通节点 `DOCTORAL_REWARD_POOLS` 仍保持固定三选一。
- 事件节点不进入卡牌奖励权重逻辑。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/data/card_definition.gd=0
res://scripts/data/effect_definition.gd=0
res://scripts/data/encounter_definition.gd=0
```

奖励池与加权验证：

```text
card_count=37
n003_pool=C012,C014,C015,C028,C038
n003_default=C012,C014,C015
n003_default_scores=C012:10|C014:10|C015:10|C028:10|C038:10
n003_noise=C028,C014,C012
n003_noise_scores=C012:10|C014:16|C015:10|C028:20|C038:10
n003_funds=C038,C012,C014
n003_funds_scores=C012:10|C014:10|C015:10|C028:10|C038:17
```

## 下一步

1. 后续每扩展一个节点奖励池，都可以先放 4-6 张候选，再让本系统裁剪到三选一。
2. 确定性排序已升级为带权随机，并保留“同分按候选池顺序回退”的调试模式，见 [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)。
3. 奖励推荐原因 tooltip 已完成，见 [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)。
4. `N002` 已按本规则扩展为 5 张候选池，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
5. `N001` 已按本规则扩展为 5 张候选池，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
6. `N004` 已按本规则扩展为 5 张候选池，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
