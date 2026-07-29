# 路线候选权重 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [072_route_choice_seed_shuffle.md](072_route_choice_seed_shuffle.md)
- [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)
- [075_route_choice_recommendation_tooltip.md](075_route_choice_recommendation_tooltip.md)
- [077_early_route_new_nodes.md](077_early_route_new_nodes.md)
- [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)

## 目标

让下一节点候选不只是纯随机，而是开始根据本局构筑和资源倾向加权。玩家走出实验设备、导师人脉、论文 DDL 等倾向后，相关路线节点会更容易进入 3 个候选。

## 规则

- `RouteState.get_next_node_choices()` 新增可选参数 `choice_weights`。
- 没有权重或候选分数相同时，沿用 [072](072_route_choice_seed_shuffle.md) 的 seed 洗牌。
- 有权重差异时，对非 Boss 候选列进行带权无放回抽取。
- 基础分为 10，UI 层传入的权重作为额外加分。
- 候选权重只影响非 Boss 候选列；包含 Boss 的关键推进列仍保持原顺序。

## UI 权重来源

`BattleTestScene` 根据当前牌组标签和资源生成权重。首版权重写在 UI 脚本中；当前权重数值已迁移到 `data/route_node_hints/*.tres`，见 [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)。

| 倾向 | 提高的节点 |
| --- | --- |
| 实验、设备、复现、数据 | `E003 设备坏了`、`N003 设备排队`、`N009 数据清洗夜` |
| 牌组已有实验噪音 | `E003 设备坏了`、`N003 设备排队`、`N009 数据清洗夜` |
| 当前有经费 | `N003 设备排队`、`E003 设备坏了`、`N009 数据清洗夜` |
| 导师、人脉、合作、声望 | `E001 食堂偶遇大牛`、`N002 周会压力`、`E008 导师临时约谈` |
| 论文、草稿、文献、灵感、DDL | `E004 论文被拒`、`N002 周会压力`、`N009 数据清洗夜`、`E008 导师临时约谈` |
| 已有论文碎片 | `E004 论文被拒`、`N009 数据清洗夜` |
| 项目或经费倾向 | `N003 设备排队`、`E004 论文被拒` |

## 实现内容

更新：

- `scripts/run/route_state.gd`
  - `get_next_node_choices()` 新增 `choice_weights` 参数。
  - 新增 `_choice_scores_are_equal()`。
  - 新增 `_select_choice_candidates_by_weight()`。
  - 新增 `_get_choice_candidate_weight()` 和 `_get_choice_candidate_score()`。
- `scripts/ui/battle_test_scene.gd`
  - `_prepare_next_node_options()` 传入 `_get_route_choice_weights()`。
  - 新增 `_get_route_choice_weights()`；当前会遍历路线节点提示资源中的权重字段。
  - 新增 `_deck_has_any_tag()`。
  - 新增 `_add_route_choice_weight()`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 测试存档：`user://codex_route_weight_test_save.json`

脚本编译验证：

```text
res://scripts/run/route_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
```

RouteState 手动权重验证：

```text
unweighted_67890=N002,N003,E001
manual_weighted_67890=E003,N003,E001
manual_weight_includes_e003=true
```

UI 实验设备权重验证：

```text
scene_plain_weights={  }
scene_plain_choices=N002,N003,E001
scene_equipment_weights={ &"E003": 14, &"N003": 10 }
scene_equipment_choices=N003,E003,E001
scene_equipment_includes_e003=true
```

结果说明：

- 无构筑倾向时，候选仍按 seed 洗牌结果输出。
- 加入实验设备牌后，UI 会给 `E003/N003` 加权。
- 同一个 seed 下，实验设备权重可以把原本未出现的 `E003` 拉进三选一候选。

## 下一步

1. 路线候选按钮推荐提示已完成，见 [075_route_choice_recommendation_tooltip.md](075_route_choice_recommendation_tooltip.md)。
2. 新增早期普通/事件节点已完成，见 [077_early_route_new_nodes.md](077_early_route_new_nodes.md)。
3. 路线权重规则外置成数据表已完成，见 [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)。
