# 简化分叉路线选择规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [012_route_state_and_encounter_variants.md](012_route_state_and_encounter_variants.md)
- [019_event_nodes_in_route.md](019_event_nodes_in_route.md)
- [020_route_map_and_event_feedback.md](020_route_map_and_event_feedback.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [023_first_boss_node.md](023_first_boss_node.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)
- [072_route_choice_seed_shuffle.md](072_route_choice_seed_shuffle.md)
- [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)
- [074_route_choice_weighting.md](074_route_choice_weighting.md)
- [075_route_choice_recommendation_tooltip.md](075_route_choice_recommendation_tooltip.md)
- [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)
- [077_early_route_new_nodes.md](077_early_route_new_nodes.md)
- [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)
- [079_route_node_detail_panel.md](079_route_node_detail_panel.md)

## 目标

把固定路线升级为“节点完成后选择下一节点”的简化分叉，让玩家开始拥有路线决策。MVP 先使用阶段候选池，不做完整地图连线，避免过早进入复杂地图编辑器。

## 路线规则

开局固定进入：

```text
N001 普通压力
```

之后每完成一个节点，会从下一阶段候选池中展示最多 3 个可选节点。已完成或已经进入过的节点不会再次出现。早期非 Boss 候选列会根据本局 seed 稳定洗牌，见 [072_route_choice_seed_shuffle.md](072_route_choice_seed_shuffle.md)。当牌组标签或资源形成倾向时，候选还会按路线权重抽取，见 [074_route_choice_weighting.md](074_route_choice_weighting.md)。

当前候选池：

| 阶段 | 候选 |
| --- | --- |
| 1 | `N001` |
| 2 | `E001`、`N002`、`N003`、`E003`、`E008`、`N009` |
| 3 | `N002`、`E003`、`N003`、`E001`、`E004`、`E008`、`N009` |
| 4 | `E004`、`E003`、`N003`、`N002`、`E001`、`E008`、`N009` |
| 5 | `N004` |
| 6 | `B001` |
| 7 | `B002` |
| 8 | `B003`、`E005` |

设计意图：

- 第 1 节点固定，方便新局稳定进入战斗。
- 中间阶段允许在事件和战斗之间选择，早期候选池已扩展到 6-7 个节点，见 [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md) 和 [077_early_route_new_nodes.md](077_early_route_new_nodes.md)。
- `E003 设备坏了` 已作为实验设备事件加入早中期候选，见 [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)。
- `N009 数据清洗夜` 和 `E008 导师临时约谈` 已作为新的早期普通/事件节点加入候选池，见 [077_early_route_new_nodes.md](077_early_route_new_nodes.md)。
- 普通路线终点固定为 `N004 截稿临近`，之后进入 `B001 开题报告`，保证一局有明确 Boss 收束。
- 当前 Boss 线已推进到 `B003 盲审专家`。
- `B002` 后会出现不转博路线 `B003` 和转博事件 `E005`，见 [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md) 与 [034_transfer_application_event.md](034_transfer_application_event.md)。
- 候选池过滤重复节点，避免同一局反复打同一个普通节点。
- 非 Boss 候选顺序受本局 seed 和构筑权重影响；包含 Boss 的关键推进列保持原顺序。

## UI 规则

- 战斗胜利并选择奖励后，出现“选择下一节点”按钮组。
- 事件处理完成后，也出现“选择下一节点”按钮组。
- 旧的单个 `下一节点/继续路线` 按钮暂时隐藏，避免和分叉按钮冲突。
- 下一节点按钮显示为节点卡片，包含节点类型、风险和奖励倾向，见 [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)。
- 路线条只显示已经选择进入的路线，并在当前节点完成后追加“可选下一节点”提示。
- 如果候选因为当前构筑倾向被加权，按钮 tooltip 会显示推荐原因，见 [075_route_choice_recommendation_tooltip.md](075_route_choice_recommendation_tooltip.md)。
- 节点风险、奖励倾向、强调色和路线权重来自 `data/route_node_hints/*.tres`，见 [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)。
- 候选按钮下方显示当前候选的详情面板，悬停按钮时切换详情，见 [079_route_node_detail_panel.md](079_route_node_detail_panel.md)。

示例：

```text
路线：[已]1 普通压力 | 可选下一节点：设备坏了 / 周会压力 / 食堂偶遇大牛
```

## 实现内容

更新：

- `scripts/run/route_state.gd`
  - 新增 `DEFAULT_CHOICE_COLUMNS`。
  - 新增 `choice_columns`。
  - 新增 `get_next_node_choices()`，按候选池生成可选节点。
  - 新增 `advance_to_node()`，选择指定下一节点并加入本局路线。
  - `get_total_nodes()` 改为使用候选池长度作为目标节点数。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `route_choice_label` 和 `route_choice_container`。
  - 新增 `next_node_options`。
  - 新增 `get_next_node_option_ids()`、`select_next_node_option()`、`select_first_next_node_option()` 等验证接口。
  - 新增 `_refresh_route_choices()` 和下一节点按钮生成逻辑。
  - 路线条显示当前可选下一节点。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
reload_route_state.gd=0
reload_battle_test_scene.gd=0
reload_battle_state.gd=0
```

分叉选择验证：

```text
initial_route_ids=N001
initial_route_map=路线：[当前]1 普通压力
after_reward_choice_ids=E001,N002,N003
after_reward_choice_buttons=3
after_reward_route_map=路线：[已]1 普通压力 | 可选下一节点：食堂偶遇大牛 / 周会压力 / 设备排队
selected_n003=true
current_after_select=N003
route_ids_after_select=N001,N003
encounter_after_select=N003
second_choice_ids=N002,E003
second_choice_buttons=2
```

事件后分叉验证：

```text
choice_ids_after_n001=E001,N002,N003
selected_first_option=E001
active_event=E001
event_button_count=4
event_taken=true
event_result=灵感 +1；数据 +1；牌组新增：精读文献。
choice_ids_after_event=N002,E003,N003
choice_buttons_after_event=3
route_map_after_event=路线：[已]1 普通压力 -> [已]2 食堂偶遇大牛 | 可选下一节点：周会压力 / 设备坏了 / 设备排队
selected_e003=true
active_event_2=E003
route_ids_after_e003=N001,E001,E003
```

早期普通路线完成验证：

```text
final_route_ids=N001,E001,N002,E003,N004
settlement_visible=true
settlement_outcome=route_completed
completed_nodes=5
next_options_final=
route_choice_buttons_final=0
final_route_map=路线：[已]1 普通压力 -> [已]2 食堂偶遇大牛 -> [已]3 周会压力 -> [已]4 论文被拒 -> [已]5 截稿临近
```

## 结果说明

- 新局不再预先填满固定路线，只从 `N001` 开始。
- 节点完成后能出现 2-3 个下一节点候选。
- 玩家选择的节点会加入本局路线，并成为新的当前节点。
- 事件节点完成后也能进入分叉选择。
- 早期版本中 `N004` 完成后会触发阶段结算；当前 Boss 线接入后，`N004` 后会进入 `B001 -> B002 -> B003`。

## 下一步

1. 候选按钮已升级为节点卡片，见 [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)。
2. `B001 开题报告`、`B002 中期考核` 和 `B003 盲审专家` Boss 节点已完成首版接入。
3. B002 后转博/不转博分支已完成首版接入，见 [034_transfer_application_event.md](034_transfer_application_event.md)。
4. 路线候选 seed 洗牌已完成，见 [072_route_choice_seed_shuffle.md](072_route_choice_seed_shuffle.md)。
5. 早期候选池扩展已完成，见 [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)。
6. 路线候选权重已完成首版，见 [074_route_choice_weighting.md](074_route_choice_weighting.md)。
