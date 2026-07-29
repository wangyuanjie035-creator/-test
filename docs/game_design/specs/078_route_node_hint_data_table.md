# 路线节点提示数据表 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [074_route_choice_weighting.md](074_route_choice_weighting.md)
- [075_route_choice_recommendation_tooltip.md](075_route_choice_recommendation_tooltip.md)
- [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)
- [077_early_route_new_nodes.md](077_early_route_new_nodes.md)
- [079_route_node_detail_panel.md](079_route_node_detail_panel.md)

## 目标

把路线候选卡片的风险标签、奖励倾向、强调色和路线权重从 `BattleTestScene` 的硬编码映射中抽出来，改为 Godot Resource 数据表。以后新增节点时，优先新增或修改 `data/route_node_hints/*.tres`，UI 脚本只负责读取并解释数据。

## 数据结构

新增：

- `scripts/data/route_node_hint_definition.gd`
- `data/route_node_hints/*.tres`

字段：

| 字段 | 用途 |
| --- | --- |
| `id` | 对应路线节点 ID，例如 `N009`、`E008`、`B002` |
| `risk_label` | 事件/Boss 的固定风险标签；普通战斗可留空并走目标/压力动态计算 |
| `reward_tendency` | 节点卡片上的 `倾向：...` |
| `accent_color` | 节点卡片边框强调色 |
| `experiment_focus_weight` | 实验、设备、复现、数据牌组倾向带来的路线权重 |
| `experiment_noise_weight` | 实验噪音负面牌带来的路线权重 |
| `funds_weight` | 当前经费资源带来的路线权重 |
| `mentor_focus_weight` | 导师、人脉、合作、声望牌组倾向带来的路线权重 |
| `reputation_weight` | 当前声望资源带来的路线权重 |
| `paper_focus_weight` | 论文、草稿、文献、灵感、DDL 倾向带来的路线权重 |
| `paper_fragments_weight` | 当前论文碎片资源带来的路线权重 |
| `project_focus_weight` | 项目或经费倾向带来的路线权重 |

## 设计说明

- 使用 `.tres` 自定义 Resource，符合 GodotPrompter 的资源化规则。
- Resource 只保存数据，不包含路线选择逻辑、UI 构造逻辑或场景访问。
- Catalog 使用脚本路径识别资源，避免新 `class_name` 在编辑器热加载时尚未注册导致脚本 reload 失败。
- 普通战斗节点如果 `risk_label` 为空，仍按目标进度和每回合压力动态计算 `高压/稳健/标准`。
- 推荐原因根据权重字段自动推导；例如 `experiment_focus_weight > 0` 且当前牌组有实验倾向，就显示 `已有实验、设备或数据相关牌`。

## 实现内容

更新：

- `scripts/data/game_data_catalog.gd`
  - 新增 `ROUTE_NODE_HINT_DIR`。
  - 新增 `ROUTE_NODE_HINT_SCRIPT_PATH`。
  - 新增 `load_route_node_hints_by_id()`。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `route_node_hints`。
  - 新局开始时加载路线提示数据。
  - `_get_route_choice_weights()` 改为遍历提示资源中的权重字段。
  - `_get_next_node_risk_label()` 优先读取提示资源，普通战斗保留动态兜底。
  - `_get_next_node_reward_tendency()` 和 `_get_next_node_option_accent_color()` 改为读取提示资源。
  - `_format_route_choice_recommendation_hint()` 改为根据权重字段生成推荐原因。

新增提示资源：

```text
B001-B008
E001/E003/E004/E005/E006/E007/E008
N001-N009
```

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/data/route_node_hint_definition.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/route_state.gd=0
```

资源加载验证：

```text
hint_count=24
has_e008=true
has_n009=true
e008_hint=导师变数/导师 / 方向/10/6/3
n009_hint=/数据 / 复现/9/8/2/4/3
```

卡片文案验证：

```text
e008_card=导师临时约谈|事件节点 | 风险：导师变数|倾向：导师 / 方向|选项事件
n009_card=数据清洗夜|战斗节点 | 风险：标准|倾向：数据 / 复现|目标 38 / 压力 6
b002_card=中期考核|Boss 节点 | 风险：考核|倾向：材料 / 复现|目标 95 / 阶段 Boss
```

权重读取验证：

```text
plain_weights=N002:3,E004:12,E008:3,N009:4
equipment_weights=N002:3,E003:14,N003:14,E004:15,E008:3,N009:13
equipment_has_n009=true
```

结果说明：

- 路线提示资源能被 Catalog 正确加载。
- `E008/N009/B002` 的卡片正文由数据资源驱动。
- 加入设备维护记录后，实验设备倾向可以通过数据表推高 `E003/N003/N009`。
- 新 Resource 热加载时不再依赖全局 `class_name` 注册缓存。

## 下一步

1. 路线节点详情面板已完成，见 [079_route_node_detail_panel.md](079_route_node_detail_panel.md)。
2. 如果继续扩充节点池，新增节点时应同步新增对应 `route_node_hints` 资源。
3. 后续可以把路线权重原因文案也外置，让文案和数值都完全策划化。
