# 设备维护记录卡 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)

## 目标

补齐实验设备流中的“经费 -> 设备稳定性 -> 数据/方法论”链条，让项目经费流和实验设备流能发生正向连接。

本次新增：

| ID | 名称 | 费用 | 标签 | 定位 | 效果 |
| --- | --- | --- | --- | --- | --- |
| `C038` | 设备维护记录 | 1 | `equipment`, `funds`, `methodology`, `data` | 设备资源转化 | 获得 4 防护；若有经费，消耗 1 经费，获得 1 数据和 1 方法论笔记 |

升级版预留效果：

- 获得 6 防护。
- 若有经费，消耗 1 经费，获得 1 数据和 2 方法论笔记。

## 新增条件

| 条件 | 用途 |
| --- | --- |
| `has_funds` | 当前至少有 1 经费 |

`C038` 的资源效果顺序是先获得数据和方法论笔记，再消耗经费。这样玩家只有 1 经费时也能完整触发收益，不会因为先扣经费导致后续条件失效。

## 奖励池调整

| 节点 | 新奖励池 | 设计意图 |
| --- | --- | --- |
| `N003 设备排队` | `C012`, `C014`, `C015`, `C028`, `C038` | 样本、清理、预约设备、负结果转化和设备维护 |

`N003` 保留 5 个候选作为节点候选池；运行时会按构筑倾向裁剪为三选一。有经费倾向或当前有经费时，`设备维护记录` 会被优先推高，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。

## 实现内容

新增：

- `data/cards/reward/c038_equipment_maintenance_log.tres`

更新：

- `data/encounters/n003_equipment_queue.tres`
- `scripts/battle/battle_state.gd`
- `scripts/ui/battle_test_scene.gd`

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
c038_summary=C038:设备维护记录:1:equipment,funds,methodology,data
n003_rewards=C012,C014,C015,C028,C038
```

效果验证：

```text
C038_with_funds=funds=0 data=1 methodology=1 block=4 discard=C038
C038_without_funds=funds=0 data=0 methodology=0 block=4 discard=C038
```

奖励展示验证：

```text
C038_button=设备维护记录/费用 1/流派：实验设备/获得 4 防护；若有经费，消耗 1 经费，获得 1 数据和 1 方法论笔记。
C038_tooltip=获得 4 防护；若有经费，消耗 1 经费，获得 1 数据和 1 方法论笔记。;流派：实验设备;标签：设备、经费、方法论、数据
```

## 下一步

1. 同流派奖励权重已完成，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
2. 后续可以补 `借用 GPU` 或 `共享服务器`，继续扩展设备牌对进度爆发的支持。
3. 当升级系统接入后，验证 `C038+` 的 2 方法论笔记收益是否过强。
