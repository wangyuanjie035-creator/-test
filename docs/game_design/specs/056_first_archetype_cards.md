# 第一批流派卡实现 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [010_reward_selection.md](010_reward_selection.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [054_card_tag_audit.md](054_card_tag_audit.md)
- [055_card_tag_patch.md](055_card_tag_patch.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)

## 目标

在已经跑通路线和局外成长后，开始让卡牌奖励真正服务构筑流派。

本次优先补三个空标签：

- `equipment`：实验设备流。
- `mentor`：导师人脉流。
- `rush` / `risk`：DDL 爆发流。

本次不新增底层效果类型，只使用现有系统已经支持的：

- `gain_progress`
- `gain_resource`
- `gain_block`
- `lose_energy`
- `modify_next_progress`
- `modify_next_tag_progress`
- `remove_status`
- `add_card_to_deck`

## 新增卡牌

| ID | 名称 | 费用 | 标签 | 定位 | 效果 |
| --- | --- | --- | --- | --- | --- |
| `C015` | 预约设备 | 1 | `equipment`, `experiment` | 实验设备流 | 下回合第一张实验牌额外获得 8 进度 |
| `C018` | 通宵赶稿 | 0 | `rush`, `risk`, `draft` | DDL 爆发流 | 失去 4 精力，获得 2 草稿和 8 进度；将 1 张恍惚加入牌组 |
| `C019` | 极限 ddl | 0 | `rush`, `risk` | DDL 爆发流 | 失去 3 精力；下一次获得进度时额外 +10，本牌消耗 |
| `C024` | 导师沟通 | 1 | `mentor`, `network`, `cooperation`, `funds` | 导师人脉流 | 获得 6 进度和 1 经费；移除手牌中 1 张自我怀疑 |
| `C025` | 组会汇报 | 1 | `mentor`, `reputation` | 导师人脉流 | 获得 7 进度；若有数据，获得 1 声望 |

## 节点奖励池

普通节点现在优先读取 `EncounterDefinition.victory_rewards`。

| 节点 | 奖励池 | 设计意图 |
| --- | --- | --- |
| `N001 普通压力` | `C002`, `C004`, `C007` | 保留原首轮文献/草稿奖励体验 |
| `N002 周会压力` | `C024`, `C025`, `C021` | 导师人脉、汇报和照护 |
| `N003 设备排队` | `C012`, `C014`, `C015`, `C028`, `C038` | 实验、清理、设备、负结果转化和设备维护 |
| `N004 截稿临近` | `C018`, `C019`, `C007` | DDL 爆发和论文转化 |

博士线普通节点仍使用 `DOCTORAL_REWARD_POOLS`，不受本次普通节点奖励池影响。

后续 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md) 调整了 `N001`、`N002`、`N006` 和 `N008` 的奖励池，以接入项目经费流和返修延毕流。[059_experiment_noise_cards.md](059_experiment_noise_cards.md) 进一步把 `C014 清理实验台` 接入 `N003`，[061_negative_result_conversion_card.md](061_negative_result_conversion_card.md) 又把 `C028 负结果也是结果` 接入 `N003`，[062_equipment_maintenance_card.md](062_equipment_maintenance_card.md) 把 `C038 设备维护记录` 接入 `N003`。[063_weighted_reward_selection.md](063_weighted_reward_selection.md) 将超过 3 张的普通节点奖励池解释为候选池，并按构筑倾向裁剪为三选一。[065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md) 又把 `N002` 扩展为 5 张候选池，并接入 `C039 会后纪要`。[066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md) 把 `N001` 扩展为 5 张候选池，并接入 `C040 研究问题清单`。[067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md) 把 `N004` 扩展为 5 张候选池，并接入 `C041 截稿后复盘`。

## 实现内容

新增：

- `data/cards/reward/c015_reserve_equipment.tres`
- `data/cards/reward/c018_all_nighter_draft.tres`
- `data/cards/reward/c019_hard_deadline.tres`
- `data/cards/reward/c024_advisor_sync.tres`
- `data/cards/reward/c025_group_meeting_report.tres`

更新：

- `data/encounters/n001_ordinary_pressure.tres`
- `data/encounters/n002_weekly_meeting.tres`
- `data/encounters/n003_equipment_queue.tres`
- `data/encounters/n004_deadline_near.tres`
- `scripts/ui/battle_test_scene.gd`
  - 新增 `_append_encounter_reward_options()`。
  - 普通奖励先读当前 Encounter 的 `victory_rewards`；为空时才回落到 `rarity == common` 的默认池。
  - 后续 [063_weighted_reward_selection.md](063_weighted_reward_selection.md) 已把超过 3 张的普通节点奖励池改为加权候选池。

## 设计取舍

`C018 通宵赶稿` 使用现有 `add_card_to_deck` 效果，因此会把 `S005 恍惚` 加入牌组并放入弃牌堆。这比“只加入弃牌堆、不进牌组”更重一些，但符合风险牌的首版定位，也避免新增一个只服务单张卡的效果类型。

`C024 导师沟通` 还不是三选一，而是把进度、经费和移除自我怀疑合并成一张稳定合作牌。后续如果要做真正的选择型卡牌，再统一设计选择牌机制。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/data/card_definition.gd=0
res://scripts/data/effect_definition.gd=0
res://scripts/data/encounter_definition.gd=0
res://scripts/data/deck_definition.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

数据加载验证：

```text
card_count=29
new_cards=C015:预约设备:common:1:equipment,experiment|C018:通宵赶稿:common:0:rush,risk,draft|C019:极限 ddl:common:0:rush,risk|C024:导师沟通:common:1:mentor,network,cooperation,funds|C025:组会汇报:common:1:mentor,reputation
missing_new_cards=
```

奖励池验证：

> 下方输出保留本文首版实现时的历史值；当前 `N001`、`N002` 和 `N004` 均已在后续规格中扩展。

```text
n001_rewards=C002,C004,C007
n002_rewards=C024,C025,C021
n003_rewards=C012,C014,C015,C028,C038
n004_rewards=C018,C019,C007
scene_reward_options=N002:C024,C025,C021|N003:C012,C014,C015,C028,C038|N004:C018,C019,C007
```

新卡效果验证：

```text
C015_progress=14
C018_progress=8_vitality=46_draft=2_hasS005=true
C019_progress=16_vitality=47_exhaust=true
C024_progress=6_funds=1_removedS010=true
C025_progress=7_reputation=1
```

## 下一步

1. 项目经费流和返修延毕流已接入，见 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)。
2. 给奖励按钮增加标签/流派提示，已完成，见 [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)。
3. 实验噪音和 `清理实验台` 已接入，见 [059_experiment_noise_cards.md](059_experiment_noise_cards.md)。
4. `负结果也是结果` 已接入，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
5. `设备维护记录` 已接入，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
6. 同流派奖励权重已完成，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
7. `N002` 候选池扩展和 `会后纪要` 已完成，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
8. `N001` 候选池扩展和 `研究问题清单` 已完成，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
9. `N004` 候选池扩展和 `截稿后复盘` 已完成，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
