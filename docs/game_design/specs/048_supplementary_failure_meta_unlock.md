# 补答辩再延期局外解锁 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [014_meta_progression_save.md](014_meta_progression_save.md)
- [016_meta_carryover_preview.md](016_meta_carryover_preview.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [047_doctor4_revision_route.md](047_doctor4_revision_route.md)
- [049_settlement_unlock_highlight.md](049_settlement_unlock_highlight.md)

## 目标

让 `B008 补答辩` 失败后的坏结局不只是给资源，还能留下一个明确、可见、可带入下一局的正反馈。

当玩家进入 `supplementary_defense_failed` / `补答辩再延期` 后，局外存档新增解锁：

| unlock_id | 触发条件 | 带入卡 |
| --- | --- | --- |
| `revision_matrix_seed` | 最近一次结算为 `supplementary_defense_failed` | `U003 返修矩阵` |

## U003 返修矩阵

| 字段 | 值 |
| --- | --- |
| id | `U003` |
| 名称 | 返修矩阵 |
| 类型 | action |
| 稀有度 | unlock |
| 费用 | 1 |
| 效果 | 获得 6 进度和 1 方法论笔记 |
| 限制 | 本牌消耗 |
| 解锁 ID | `revision_matrix_seed` |

设计意图：

- “补答辩再延期”虽然是更深层坏结局，但下一局立刻能看到一张和返修经验相关的带入牌。
- `U003` 偏论文/方法论，不直接回血，避免和 `U001 自我照护` 重叠。
- 本牌消耗，保持单场战斗里的强度可控，但每个新节点仍会随牌组重洗回来。

## 实现内容

新增：

- `data/cards/unlock/u003_revision_matrix_seed.tres`

更新：

- `scripts/run/meta_progression_state.gd`
  - 新增 `UNLOCK_REVISION_MATRIX_SEED = revision_matrix_seed`。
  - `get_unlock_display_name()` 新增“返修矩阵种子”。
  - `_refresh_unlocks()` 在 `last_outcome_id == "supplementary_defense_failed"` 时解锁 `revision_matrix_seed`。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `REVISION_MATRIX_UNLOCK_ID` 和 `REVISION_MATRIX_CARD_ID`。
  - 开局带入逻辑新增 `revision_matrix_seed -> U003`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据验证：

```text
res://scripts/run/meta_progression_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
has_u003=true
u003_name=返修矩阵
u003_unlock=revision_matrix_seed
u003_rarity=unlock
```

解锁与带入验证：

```text
direct_new_unlocks=revision_matrix_seed
direct_saved_unlocks=revision_matrix_seed
direct_display=返修矩阵种子
direct_carried=U003
direct_preview=局外带入：返修矩阵 | 累计结算 1 次 | 经验教训 0 | 心理韧性 0
direct_has_u003=true
```

真实 B008 失败流程验证：

```text
b008_failure_outcome=supplementary_defense_failed
b008_failure_title=补答辩再延期
b008_failure_save_error=0
b008_failure_new_unlocks=self_care_seed,revision_strategy_seed,revision_matrix_seed
b008_failure_saved_unlocks=self_care_seed,revision_strategy_seed,revision_matrix_seed
next_carried=U001,U002,U003
next_has_u003=true
next_preview=局外带入：自我照护、返修策略、返修矩阵 | 累计结算 1 次 | 经验教训 17 | 心理韧性 4
```

## 下一步

1. 后续可以把 `补答辩再延期` 的结算界面文案强调为“返修矩阵已沉淀”，让玩家更直观看到坏结局收益。
2. 结算页新解锁高亮已完成，见 [049_settlement_unlock_highlight.md](049_settlement_unlock_highlight.md)。
3. 如果后续加入更多博四节点，可以让 `U003` 在博四/博士节点中获得额外效果。
