# 带权随机奖励选择 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-02

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)
- [069_run_seed_randomization.md](069_run_seed_randomization.md)

## 目标

把普通节点大候选池从“分数排序后固定取前三”升级为“按分数带权随机抽 3 张”。这样玩家已经形成构筑倾向后，奖励会更像卡牌构筑游戏里的随机奖励：同流派卡更容易出现，但不会每次都完全相同。

## 规则

- 只影响普通遭遇节点的 `victory_rewards` 大候选池。
- 候选池不超过 3 张时，仍全部按原顺序展示。
- 候选池超过 3 张时，先沿用 [063](063_weighted_reward_selection.md) 的分数规则。
- 如果所有候选分数完全相同，仍按候选池原顺序展示前 3 张，保护默认体验和早期测试稳定性。
- 如果候选分数不同，用 `score * score` 作为票数，进行无放回随机抽取，直到选满 3 张。
- 抽出的 3 张卡最终按候选池原顺序排列在界面上，避免按钮顺序过于跳动。
- 随机种子由路线 seed、当前节点序号、遭遇 id、当前牌组和候选池共同计算；测试脚本可传入 `seed_override` 复现某个抽取结果。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - `_select_weighted_reward_options()` 增加 `seed_override` 参数。
  - 新增 `_reward_scores_are_equal()`，同分时回退原顺序。
  - 新增 `_select_reward_candidates_by_weight()`，按票数无放回抽取。
  - 新增 `_get_reward_candidate_weight()`，使用 `score * score` 放大构筑协同。
  - 新增 `_get_reward_selection_seed()`、`_mix_reward_seed()` 和 `_hash_reward_text()`，提供可复现种子。

未改变：

- 分数来源仍使用 [063](063_weighted_reward_selection.md) 的同流派、实验噪音和经费规则。
- 博士线普通节点固定三选一不进入带权随机。
- Boss 奖励、毕业结局和事件选项不进入带权随机。
- 推荐原因 tooltip 仍沿用 [064](064_reward_recommendation_tooltip.md) 的规则。

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

默认回退验证：

```text
card_count=40
n004_default=C018,C019,C007
n004_default_scores=C018:10|C019:10|C007:10|C021:10|C041:10
```

带权随机验证：

```text
n004_rush_scores=C018:20|C019:18|C007:12|C021:10|C041:16
n004_seed_samples=1=C018,C019,C041|2=C018,C019,C041|3=C018,C019,C041|4=C019,C007,C021|5=C018,C007,C041|6=C018,C019,C041|7=C019,C021,C041|8=C018,C021,C041|9=C018,C021,C041|10=C018,C021,C041
n003_noise_scores=C012:10|C014:16|C015:10|C028:20|C038:10
n003_seed_samples=1=C012,C014,C038|2=C012,C014,C028|3=C012,C014,C028|4=C012,C015,C028|5=C014,C015,C028|6=C014,C028,C038|7=C014,C028,C038|8=C014,C015,C028|9=C014,C015,C028|10=C012,C014,C028
n001_literature_scores=C002:14|C004:12|C021:14|C007:10|C040:14
n001_literature_seed_1=C021,C007,C040
n001_literature_seed_2=C002,C004,C021
```

结果说明：

- 无构筑倾向、所有分数相同时，仍保留旧的默认三选一。
- 有 DDL 倾向时，`N004` 会明显倾向于推入 `C041 截稿后复盘`，但不同 seed 仍可能出现不同组合。
- 有实验噪音时，`N003` 更容易出现 `C014/C028`，但保留少量随机波动。
- 文献倾向下，`N001` 能在不同 seed 中出现不同的文献/照护/论文组合。

## 下一步

1. 观察手测时“高协同但没出现”的频率；如果太挫败，可以把特殊协同加分再提高，或为最高分候选增加保底。
2. 新旅程随机 seed 和指定 seed 复现入口已完成，见 [069_run_seed_randomization.md](069_run_seed_randomization.md)。
3. 等卡量继续增长后，可以加入稀有度、阶段和最近选择历史，避免同一局奖励过于重复。
