# 早期路线新增节点 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)
- [074_route_choice_weighting.md](074_route_choice_weighting.md)
- [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)
- [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)

## 目标

把早期路线候选池从“复用旧节点”推进到“有新内容差异”。本步新增 1 个普通战斗节点和 1 个事件节点，让早期三选一出现更多研究生日常分支，同时继续保持 `N004 -> B001 -> B002 -> B003/E005` 主线收束不变。

## 新增节点

| 节点 | 类型 | 主题 | 数值/选项 | 主要产出 |
| --- | --- | --- | --- | --- |
| `N009 数据清洗夜` | 普通战斗 | 数据清洗、复现、实验返工 | 目标 38，每回合压力 6 | `C013/C014/C028/C038/C040` |
| `E008 导师临时约谈` | 事件 | 导师、方向校准、资源窗口 | 4 个事件选项 | 方法论笔记、声望、论文碎片、经费或经验教训 |

`E008` 选项：

| 选项 | 条件 | 结果 |
| --- | --- | --- |
| 对齐阶段预期 | 无 | 失去 2 精力，获得 1 方法论笔记和 1 声望 |
| 带着提纲过去 | `has_2_draft` | 消耗 2 草稿，获得 1 论文碎片，将 1 张 `会后纪要` 加入牌组 |
| 顺便申请资源 | `has_1_reputation` | 获得 1 经费，将 1 张 `导师沟通` 加入牌组 |
| 先把压力记下来 | 无 | 失去 2 精力，获得 2 经验教训，将 1 张 `自我怀疑` 加入牌组 |

## GodotPrompter 执行约束

- 新节点内容使用 `.tres` 自定义 Resource 保存，不把事件逻辑写进资源。
- 路线、权重和 UI 展示逻辑仍留在脚本中。
- GDScript 改动保持显式类型，不新增未定义条件或效果类型。
- 验证以行为为主：资源能加载、路线能抽到、UI 文案能生成。

## 路线接入

`RouteState.DEFAULT_CHOICE_COLUMNS` 第 2-4 阶段加入 `E008/N009`：

| 阶段 | 候选 |
| --- | --- |
| 2 | `E001`、`N002`、`N003`、`E003`、`E008`、`N009` |
| 3 | `N002`、`E003`、`N003`、`E001`、`E004`、`E008`、`N009` |
| 4 | `E004`、`E003`、`N003`、`N002`、`E001`、`E008`、`N009` |

第 5 阶段仍固定进入 `N004 截稿临近`，因此新增节点只扩展早期选择，不改变 Boss 主线节奏。

## 权重和 UI

- `N009` 会被实验、设备、复现、数据、实验噪音、经费和论文倾向推高。
- `E008` 会被导师、人脉、合作、声望和论文倾向推高。
- 路线卡片新增：
  - `N009`：风险 `标准`，倾向 `数据 / 复现`。
  - `E008`：风险 `导师变数`，倾向 `导师 / 方向`。

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
res://scripts/data/encounter_definition.gd=0
res://scripts/data/event_definition.gd=0
res://scripts/data/event_choice_definition.gd=0
res://scripts/data/effect_definition.gd=0
```

资源加载验证：

```text
has_n009=true
n009_summary=数据清洗夜/38/6/C013,C014,C028,C038,C040
has_e008=true
e008_choices=align_expectations/对齐阶段预期/|bring_outline/带着提纲过去/has_2_draft|ask_resources/顺便申请资源/has_1_reputation|absorb_pressure/先把压力记下来/
e008_tags=mentor,direction,network
```

路线抽样验证：

```text
route_found_n009=true
route_found_e008=true
route_samples=1:E008,E001,N003;3:E003,E008,N002;4:E003,N002,E008;5:E001,E003,N009;6:N009,E008,N003;7:N009,E001,N003
manual_weighted_choices=E008,N009,E003
manual_weighted_has_new=true
```

路线卡片文案验证：

```text
n009_card=数据清洗夜|战斗节点 | 风险：标准|倾向：数据 / 复现|目标 38 / 压力 6
e008_card=导师临时约谈|事件节点 | 风险：导师变数|倾向：导师 / 方向|选项事件
```

## 下一步

1. 手动实机测试：多跑几个 seed，点进 `N009/E008`，确认战斗、事件选项和路线继续体验自然。
2. 节点风险、奖励倾向和路线权重外置为数据表已完成，见 [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)。
3. 完整路线跑通后，再回到 `B002` 后的转博条件，把“满足条件才出现/可提交转博”做成更正式的分支规则。
