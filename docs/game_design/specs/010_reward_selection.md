# 节点奖励选择规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-26

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [008_battle_test_ui.md](008_battle_test_ui.md)
- [009_ordinary_pressure_encounter.md](009_ordinary_pressure_encounter.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)
- [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)
- [069_run_seed_randomization.md](069_run_seed_randomization.md)

## 目标

普通节点通过后，玩家获得一次正反馈：从 3 张普通奖励卡中选择 1 张加入当前牌组。这个系统是构筑体验的第一块真正闭环。

## 首批奖励池

已录入 6 张普通奖励卡：

| ID | 名称 | 定位 |
| --- | --- | --- |
| C002 | 精读文献 | 文献灵感 |
| C004 | 整理笔记 | 文献、草稿 |
| C007 | 润色摘要 | 草稿、声望、进度 |
| C012 | 样本制备 | 实验、数据 |
| C013 | 复现实验 | 实验、复现 |
| C021 | 走出实验楼 | 调适、回复 |

## 规则

- 当 `BattleState.is_victory()` 为 true 时，测试界面显示奖励区。
- 如果当前普通节点配置了 `victory_rewards`，奖励区优先使用该节点奖励池；当候选超过 3 张时，按构筑标签轻量加权后裁剪为三选一，分数相同则保留原顺序，分数不同则带权随机抽取；随机源来自当前旅程 seed，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)、[068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md) 和 [069_run_seed_randomization.md](069_run_seed_randomization.md)。
- 如果当前普通节点没有配置 `victory_rewards`，奖励区从 `rarity == common` 且非状态牌的卡中取前 3 张。
- 如果当前节点是博士线普通节点 `N005`、`N006`、`N007` 或 `N008`，优先使用博士线/延毕线专属奖励池，见 [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md) 和 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)。
- `N003 设备排队` 已扩展为 5 张实验设备候选，并加入 `C038 设备维护记录`，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
- `N002 周会压力` 已扩展为 5 张导师/项目/照护候选，并加入 `C039 会后纪要`，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
- `N001 普通压力` 已扩展为 5 张文献/论文/照护候选，并加入 `C040 研究问题清单`，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
- `N004 截稿临近` 已扩展为 5 张 DDL/论文/照护候选，并加入 `C041 截稿后复盘`，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
- 点击奖励按钮后调用 `BattleState.add_card_to_deck(card_id, true)`。
- 被选择的奖励卡加入 `deck_card_ids`，并放入弃牌堆。
- 每个节点只能选择 1 次奖励。
- 奖励按钮会根据卡牌标签显示 `流派：...`，tooltip 会显示中文标签，见 [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)。
- 当普通节点大候选池发生加权裁剪时，tooltip 会额外显示推荐原因，见 [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)。

## 实现内容

新增资源：

- `data/cards/reward/c002_close_reading.tres`
- `data/cards/reward/c004_organize_notes.tres`
- `data/cards/reward/c007_polish_abstract.tres`
- `data/cards/reward/c012_prepare_samples.tres`
- `data/cards/reward/c013_replicate_experiment.tres`
- `data/cards/reward/c021_leave_lab.tres`

更新：

- `scripts/battle/battle_state.gd`
  - 新增 `deck_card_ids`。
  - 新增 `add_card_to_deck()`。
  - 增加本回合/上回合标签记录。
  - 支持 `played_literature_this_turn`、`played_experiment_last_turn`、`modify_next_tag_progress`。
- `scripts/ui/battle_test_scene.gd`
  - 新增奖励标签和奖励按钮区。
  - 节点胜利后显示三选一奖励。
  - 选择奖励后刷新 UI，并显示当前牌组张数。
  - 普通节点优先读取 `EncounterDefinition.victory_rewards`。
  - 普通节点候选池超过 3 张时，按非初始卡标签和少量明确协同带权随机裁剪为三选一；同分时保留原顺序。
  - N005/N006/N007/N008 胜利后显示博士线或延毕线奖励池。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

验证输出：

```text
card_count=16
reward_count=6
deck_size_initial=15
reward_buttons_initial=0
play_win_card=true
victory=true
reward_buttons_victory=3
reward_options=C002,C004,C007
select_reward=true
reward_taken=true
deck_size_after=16
discard_size_after=2
reward_buttons_after=0
```

结果说明：

- 当前数据层能加载 16 张卡，其中 6 张是普通奖励卡。
- 普通节点胜利前不显示奖励。
- 胜利后显示 3 个奖励按钮。
- 选择奖励后当前牌组从 15 张变为 16 张。
- 奖励卡进入弃牌堆，后续节点系统可以复用这张牌。

## 下一步

1. “下一节点”按钮和节点循环已完成，见 [011_node_loop.md](011_node_loop.md)。
2. 博士线普通奖励池已完成，见 [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)。
3. 第二阶段会把奖励池按构筑流派和标签继续分层，见 [053_build_archetype_framework.md](053_build_archetype_framework.md)。
4. 普通节点按主题奖励池给出第一批流派卡，见 [056_first_archetype_cards.md](056_first_archetype_cards.md)。
5. 项目经费流和返修延毕流奖励池已接入，见 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)。
6. 奖励按钮已显示流派提示，见 [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)。
7. 实验噪音和 `清理实验台` 已接入，见 [059_experiment_noise_cards.md](059_experiment_noise_cards.md)。
8. `负结果也是结果` 已接入 `N003` 奖励池，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
9. `设备维护记录` 已接入 `N003` 奖励池，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
10. 同流派奖励权重已完成，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
11. 奖励推荐原因 tooltip 已完成，见 [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)。
12. `N002` 候选池扩展和 `会后纪要` 已完成，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
13. `N001` 候选池扩展和 `研究问题清单` 已完成，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
14. `N004` 候选池扩展和 `截稿后复盘` 已完成，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
15. 带权随机奖励选择已完成，见 [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)。
16. 新旅程随机 seed 和复现入口已完成，见 [069_run_seed_randomization.md](069_run_seed_randomization.md)。
