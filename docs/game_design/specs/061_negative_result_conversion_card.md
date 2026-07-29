# 负结果转化卡 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [010_reward_selection.md](010_reward_selection.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)

## 目标

在 `S003 不可复现` 和 `S009 样本污染` 已经能进入牌组后，补一张主动转化牌，让实验坏状态也能成为正反馈来源。

本次新增：

| ID | 名称 | 费用 | 标签 | 定位 | 效果 |
| --- | --- | --- | --- | --- | --- |
| `C028` | 负结果也是结果 | 1 | `data`, `methodology`, `resilience` | 实验噪音转化 | 若手牌有实验噪音负面牌，移除 1 张，获得 1 数据和 1 灵感 |

升级版预留效果：

- 若手牌有任意负面牌，移除 1 张。
- 获得 1 数据、1 灵感和 1 方法论笔记。

当前原型还没有完整升级系统，因此升级效果只是先写入数据，等待后续升级机制使用。

## 新增条件

| 条件 | 用途 |
| --- | --- |
| `has_experiment_noise_in_hand` | 手牌中存在带 `experiment_noise` 标签的状态牌 |
| `has_status_in_hand` | 手牌中存在任意状态牌 |

`C028` 的效果顺序是先判断条件给资源，最后移除负面牌。这样可以避免先移除负面牌后，后续资源效果条件失效。

## 奖励池调整

| 节点 | 新奖励池 | 设计意图 |
| --- | --- | --- |
| `N003 设备排队` | `C012`, `C014`, `C015`, `C028`, `C038` | 样本、清理、预约设备、负结果转化和设备维护 |

`C013 复现实验` 仍可通过 `B002` 的 Boss 奖励 `建立复现实验流程` 获得。`N003` 先更偏向处理实验路线的启动和坏状态；运行时会由 [063_weighted_reward_selection.md](063_weighted_reward_selection.md) 从 5 张候选中裁剪为三选一。

## 实现内容

新增：

- `data/cards/reward/c028_negative_result.tres`

更新：

- `data/encounters/n003_equipment_queue.tres`
- `scripts/battle/battle_state.gd`

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

数据加载验证：

```text
card_count=37
has_C028=true
c028_summary=C028:负结果也是结果:1:data,methodology,resilience
n003_rewards=C012,C014,C015,C028,C038
```

效果验证：

```text
C028_with_S003=data=1 inspiration=1 hand= discard=C028 exhaust=S003
C028_with_S009=data=1 inspiration=1 hand= discard=C028 exhaust=S009
C028_without_noise=data=0 inspiration=0 hand= discard=C028 exhaust=
S009_draw_with_C028=hand=C028,S009 discard=
```

`C028` 使用 `data` 而不是 `experiment` 标签，因此 `S009 样本污染` 抽到时不会把这张转化牌误当成实验牌弃掉。

奖励展示验证：

```text
C028_button=负结果也是结果/费用 1/流派：实验设备 / 心态照护/若手牌有实验噪音负面牌，移除 1 张，获得 1 数据和 1 灵感。
C028_tooltip=若手牌有实验噪音负面牌，移除 1 张，获得 1 数据和 1 灵感。;流派：实验设备 / 心态照护;标签：数据、方法论、心理韧性
```

## 下一步

1. `设备维护记录` 已接入，让经费也能进入实验设备流的资源转化链，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
2. 同流派奖励权重已完成，已有实验噪音时会优先推高 `C028`，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
3. 后续升级系统接入后，验证 `C028+` 是否能正确消耗任意负面牌。
