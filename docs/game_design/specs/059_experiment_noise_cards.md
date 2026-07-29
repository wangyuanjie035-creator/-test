# 实验噪音与清理实验台 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [010_reward_selection.md](010_reward_selection.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [054_card_tag_audit.md](054_card_tag_audit.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)

## 目标

补齐实验设备流的“坏状态处理”能力，让实验路线不只是堆数据，也能处理实验失败、污染和复现风险。

本次新增一个实验噪音子标签：

- `experiment_noise`：实验相关负面牌，例如不可复现、样本污染。

## 新增卡牌

| ID | 名称 | 费用 | 标签 | 定位 | 效果 |
| --- | --- | --- | --- | --- | --- |
| `C014` | 清理实验台 | 1 | `experiment`, `block` | 实验设备流防护 | 获得 8 防护；移除手牌中 1 张实验噪音负面牌 |
| `S003` | 不可复现 | -1 | `status`, `experiment_noise` | 实验噪音 | 抽到时失去 1 数据；若没有数据，失去 2 精力 |
| `S009` | 样本污染 | -1 | `status`, `experiment_noise` | 实验噪音 | 抽到时弃掉手牌中 1 张实验牌 |

## 奖励池调整

| 节点 | 奖励池 | 设计意图 |
| --- | --- | --- |
| `N003 设备排队` | `C012`, `C014`, `C015`, `C028`, `C038` | 样本、清理、设备预约、负结果转化和设备维护组成完整实验设备入口 |

`N003` 当前保留 5 张奖励候选，运行时由同流派奖励权重裁剪为动态三选一。已有实验噪音时，`C028 负结果也是结果` 和 `C014 清理实验台` 会被优先推给玩家，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。

## 新增效果类型

| 效果类型 | 参数 | 用途 |
| --- | --- | --- |
| `remove_status_by_tag` | `target`, `tag_filter`, `amount` | 从指定牌堆移除带某标签的状态牌 |
| `discard_tag_from_hand` | `tag_filter`, `amount` | 从手牌弃掉带某标签的牌 |
| `lose_resource_or_energy` | `resource`, `amount` | 有指定资源时扣资源；没有时扣 `amount * 2` 精力 |

`lose_resource_or_energy` 用于避免 `S003 不可复现` 同时触发“扣数据”和“无数据扣精力”。它是原子效果：有数据只扣数据，没有数据才扣精力。

## 实现内容

新增：

- `data/cards/reward/c014_cleanup_lab_bench.tres`
- `data/cards/status/s003_irreproducible.tres`
- `data/cards/status/s009_sample_contamination.tres`

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
new_cards=清理实验台|不可复现|样本污染
n003_rewards=C012,C014,C015,C028,C038
```

效果验证：

```text
C014_cleanup=block=8 hand= discard=C014 exhaust=S009
S003_no_data=data=0 vitality=18 hand=S003
S003_with_data=data=0 vitality=20
S009_draw=hand=S009 discard=C011
```

奖励展示验证：

```text
C014_button=清理实验台/费用 1/流派：实验设备/获得 8 防护；移除手牌中 1 张实验噪音负面牌。
C014_tooltip=获得 8 防护；移除手牌中 1 张实验噪音负面牌。;流派：实验设备;标签：实验、防护
```

## 下一步

1. 实验设备流资源转化卡 `设备维护记录` 已完成，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
2. 实验事故事件和 Boss 意图已经接入 `S003/S009`，见 [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)。
3. `负结果也是结果` 已接入，用于把实验噪音转化为数据和灵感，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
4. `设备维护记录` 已接入，用于把经费转化为数据和方法论笔记，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
5. 同流派奖励权重和三选一裁剪已完成，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
