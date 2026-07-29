# 路线候选 Seed 洗牌 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [012_route_state_and_encounter_variants.md](012_route_state_and_encounter_variants.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [069_run_seed_randomization.md](069_run_seed_randomization.md)
- [071_settlement_seed_display.md](071_settlement_seed_display.md)
- [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)
- [074_route_choice_weighting.md](074_route_choice_weighting.md)
- [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)

## 目标

让下一节点候选也受本局 `run_seed` 影响。这样同一个 seed 可以复现相同路线候选顺序，不同 seed 则会在早期探索阶段给出不同的候选按钮顺序。

这一步先做低风险的“候选洗牌”，为以后扩展更大的路线候选池打基础。

## 规则

- `RouteState.get_next_node_choices()` 仍然返回最多 3 个下一节点。
- 非 Boss 候选列会根据 `route.seed`、当前路线节点和候选内容做稳定洗牌。
- 同一个 seed、同一条已走路线，重复刷新 UI 时候选顺序不变。
- 不同 seed 可能得到不同候选顺序。
- 包含 Boss 的关键推进列不洗牌，保持原顺序。例如 `B003 / E005 转博申请` 仍按原设计顺序展示。
- 早期候选列首版扩展到 4-5 个节点，见 [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)；当前新增节点后已扩展到 6-7 个节点，见 [077_early_route_new_nodes.md](077_early_route_new_nodes.md)。同一规则现在会体现为“洗牌后取前三”。

## 实现内容

更新：

- `scripts/run/route_state.gd`
  - 新增 `ROUTE_RNG_MODULUS` 和 `ROUTE_CHOICE_SEED_OFFSET`。
  - `get_next_node_choices()` 先收集可用候选，再对非 Boss 候选列进行 seed 洗牌。
  - 新增 `_get_available_choice_candidates()`。
  - 新增 `_should_randomize_choice_candidates()`，用于保留 Boss 关键列顺序。
  - 新增 `_shuffle_choice_candidates()`、`_get_choice_selection_seed()`、`_mix_route_seed()` 和 `_hash_route_text()`。

未改变：

- 开局仍固定为 `N001 普通压力`。
- `B001`、`B002` 等单一 Boss 推进节点仍固定。
- 转博分支的触发、条件和按钮可用性不变。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/run/route_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
```

早期候选 seed 复现验证：

```text
choices_seed_12345_a=E003,N002,E001
choices_seed_12345_b=E003,N002,E001
choices_seed_67890=N002,N003,E001
same_seed_same=true
different_seed_diff=true
```

Boss 关键列顺序验证：

```text
boss_column_12345=B003,E005
boss_column_67890=B003,E005
boss_column_stable=true
```

结果说明：

- 同一个 seed 重复读取下一节点候选，顺序一致。
- 不同 seed 可以改变早期探索候选顺序。
- 包含 Boss 的关键推进列不受 seed 洗牌影响，`B003 / E005` 保持原顺序。
- 早期候选池扩展后，这一步已经可以体现为内容变化，见 [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)。

## 下一步

1. 扩展早期阶段候选池已完成，首版见 [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)，新增节点见 [077_early_route_new_nodes.md](077_early_route_new_nodes.md)。
2. 路线候选权重已完成首版，见 [074_route_choice_weighting.md](074_route_choice_weighting.md)。
3. 候选按钮已升级为节点卡片，见 [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)。
