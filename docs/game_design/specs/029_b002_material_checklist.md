# B002 材料清单累计追踪 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [002_mvp_boss_set.md](002_mvp_boss_set.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [030_b002_reward_pool.md](030_b002_reward_pool.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)

## 目标

`B002 中期考核` 的“材料清单”不再只检查当前手里剩余多少数据和草稿，而是检查本场 Boss 战累计获得过多少数据和草稿。

这更符合中期考核的语义：

- 数据即使被“数据真实性检查”消耗，也说明玩家曾经准备过数据。
- 草稿即使后续转化成其他资源，也应该计入阶段材料。
- 玩家可以围绕“本战累计数据 2 / 草稿 3”组织构筑。

## 规则

本场战斗会记录正向获得的研究资源：

```text
resource_gains_this_battle
```

B002 目前读取：

| 项目 | 目标 |
| --- | --- |
| 数据 | 本战累计至少 2 |
| 草稿 | 本战累计至少 3 |

阶段检查“专家组建议”：

- 若本战累计至少 2 数据或 3 草稿，获得 1 声望和 8 进度。
- 否则加入 1 张 `S002 焦虑`，并使目标进度 +8。

意图“阶段材料抽查”：

- 若本战累计至少 2 数据和 3 草稿，获得 1 声望。
- 否则加入 1 张 `S001 拖延`。

## UI 提示

B002 的 Boss 信息区会追加一行：

```text
材料清单：本战累计数据 0/2，草稿 0/3。
```

数值会随着本场战斗中获得数据和草稿而增加，并封顶显示为目标值。

## 实现内容

更新：

- `scripts/battle/battle_state.gd`
  - 新增 `resource_gains_this_battle`。
  - 新增 `get_resource_gain_this_battle()`。
  - 正向 `gain_resource` 会累计到本战获得量。
  - 每次开始新战斗、下一普通节点、下一 Boss 时重置累计。
  - 新增条件：`gained_2_data`、`gained_3_draft`、`gained_2_data_and_3_draft`、`gained_2_data_or_3_draft`。
  - 新增 `get_boss_material_checklist_text()`。
- `data/bosses/b002_midterm_review.tres`
  - `阶段材料抽查` 改为使用 `gained_2_data_and_3_draft`。
  - `专家组建议` 改为使用 `gained_2_data_or_3_draft`。
- `scripts/data/game_data_catalog.gd`
  - 数据加载改为 `ResourceLoader.CACHE_MODE_IGNORE`，避免编辑器热改 `.tres` 后仍读到旧资源。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/data/game_data_catalog.gd=0
res://scripts/battle/battle_state.gd=0
```

累计数据验证：

```text
b002_phase_condition=gained_2_data_or_3_draft
b002_material_condition=gained_2_data_and_3_draft
current_data_after_spend=0
gained_data_after_spend=2
has_current_2_data=false
has_gained_2_data=true
material_text_data_only=材料清单：本战累计数据 2/2，草稿 0/3。
phase_triggered_from_gained_data=true
reputation_after_phase=1
progress_after_phase=63
```

完整材料清单验证：

```text
current_draft=4
gained_draft=4
has_current_materials=false
has_gained_materials=true
material_text_complete=材料清单：本战累计数据 2/2，草稿 3/3。
readability=当前意图：汇报进展：造成 8 压力
专家组建议已完成。
材料清单：本战累计数据 2/2，草稿 3/3。
```

## 结果说明

- B002 材料清单现在检查本场累计获得量。
- 消耗数据不会导致材料清单进度倒退。
- Boss 信息区能显示当前材料清单进度。
- 数据加载器在编辑器热验证时更稳定。

## 下一步

1. B002 专属奖励池已完成，见 [030_b002_reward_pool.md](030_b002_reward_pool.md)。
2. `B003 盲审专家` 已完成首版实现，见 [032_third_boss_blind_review.md](032_third_boss_blind_review.md)。
