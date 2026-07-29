# 路线候选推荐原因 Tooltip v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [074_route_choice_weighting.md](074_route_choice_weighting.md)
- [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)
- [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)

## 目标

路线候选已经会根据牌组标签和资源倾向加权。为了让玩家理解“为什么这局更容易出现某些节点”，在下一节点按钮的 tooltip 里追加推荐原因。

## 规则

- 按钮正文不增加额外文字，避免界面变得拥挤。
- tooltip 保留原有节点说明。
- 如果当前局势命中路线权重规则，则在 tooltip 末尾追加：
  - `推荐：原因1；原因2`
- 每个节点最多显示 2 条推荐原因。
- Boss 候选不显示推荐原因，保持关键推进节点说明简洁。

## 推荐原因

首版按节点 ID 写死推荐原因。当前已改为根据 `data/route_node_hints/*.tres` 的权重字段推导原因，见 [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)。

| 权重字段 | 可能原因 |
| --- | --- |
| `experiment_focus_weight` | 已有实验、设备或数据相关牌 |
| `experiment_noise_weight` | 牌组已有实验噪音 |
| `funds_weight` | 当前有经费可支撑设备路线 |
| `mentor_focus_weight` | 已有导师、人脉或合作相关牌 |
| `reputation_weight` | 当前有声望资源 |
| `paper_focus_weight` | 已有论文、草稿或 DDL 相关牌 |
| `paper_fragments_weight` | 已有论文碎片 |
| `project_focus_weight` | 已有项目或经费倾向 |

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - `_format_next_node_option_tooltip()` 改为分段组装 tooltip。
  - 新增 `_format_route_choice_recommendation_hint()`。
  - 新增 `_append_route_choice_reason()`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 测试存档：`user://codex_route_tooltip_test_save.json`

脚本编译验证：

```text
res://scripts/run/route_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
```

实验设备 tooltip 验证：

```text
choices=N003,E003,E001
e003_tooltip=你预约了很久的设备突然报修，管理员说最快也要下周。|推荐：已有实验、设备或数据相关牌
```

结果说明：

- 实验设备牌组下，`E003` 的 tooltip 会追加推荐原因。
- tooltip 没有改变按钮正文，只增强悬停信息。

## 下一步

1. 路线候选按钮升级成节点卡片已完成，见 [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)。
2. 增加 1-2 个新的早期普通/事件节点，让推荐原因有更丰富的落点。
3. 路线权重和推荐原因已使用同一份数据表驱动，见 [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)。
