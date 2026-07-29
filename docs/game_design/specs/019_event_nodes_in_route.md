# 路线事件节点接入规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [003_mvp_event_set.md](003_mvp_event_set.md)
- [011_node_loop.md](011_node_loop.md)
- [012_route_state_and_encounter_variants.md](012_route_state_and_encounter_variants.md)
- [013_run_settlement.md](013_run_settlement.md)
- [018_second_meta_unlock_card.md](018_second_meta_unlock_card.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)

## 目标

把战斗之外的研究生事件接入局内路线，让一局不再只是连续战斗。MVP 先实现固定事件节点和选项结算，后续再扩展成可视化分叉地图、事件池和更复杂的条件选项。

## MVP 路线

本文实现时的固定路线：

| 顺序 | ID | 类型 | 名称 |
| --- | --- | --- | --- |
| 1 | `N001` | 战斗 | 普通压力 |
| 2 | `E001` | 事件 | 食堂偶遇大牛 |
| 3 | `N002` | 战斗 | 周会压力 |
| 4 | `E004` | 事件 | 论文被拒 |
| 5 | `N003` | 战斗 | 设备排队 |
| 6 | `N004` | 战斗 | 截稿临近 |

分叉路线接入后，`E001` 和 `E004` 不再固定出现，而是作为候选节点出现，见 [022_branching_route_choice.md](022_branching_route_choice.md)。

## 事件规则

- `RouteState` 为每个路线节点记录 `node_kind`，目前支持 `encounter` 和 `event`。
- 战斗节点胜利并选择奖励后，会出现下一节点候选。
- 如果下一节点是事件，UI 显示事件描述和选项，而不是启动新战斗。
- 事件选项只能选择一次。
- 选项可以有简单条件，例如 `has_2_draft`、`has_2_inspiration`。
- 事件选项会复用 `EffectDefinition`，当前支持资源变化、失去精力、加入卡牌、移除状态等效果。
- 事件完成后，会出现下一节点候选。
- 如果事件导致精力归零，会进入 `burnout` 阶段结算。

## 首批落地事件

### E001 食堂偶遇大牛

定位：前期正向事件，提供轻量构筑和方法论收益。

选项：

- `凑过去请教`：失去 3 精力，获得 2 灵感、1 声望和 1 方法论笔记。
- `默默记下关键词`：获得 1 灵感和 1 数据，将 1 张 `C002 精读文献` 加入牌组。
- `递上自己的草稿`：需要 2 草稿，消耗 2 草稿，获得 2 声望和 1 方法论笔记，将 1 张 `C007 润色摘要` 加入牌组。
- `假装没听见`：恢复 2 精力。

### E004 论文被拒

定位：坏消息转化事件，连接局内构筑和局外正反馈。

选项：

- `转投稳妥期刊`：获得 1 论文碎片和 1 声望，将 1 张 `S010 自我怀疑` 加入牌组。
- `大修重投`：需要 2 草稿，消耗 2 草稿，获得 8 进度和 1 论文碎片，将 1 张 `C007 润色摘要` 加入牌组。
- `换一个叙事角度`：需要 2 灵感，消耗 2 灵感，尝试移除 1 张 `S010 自我怀疑`，获得 1 方法论笔记，将 1 张 `C004 整理笔记` 加入牌组。
- `破防一天`：失去 4 精力，获得 2 经验教训。

### E003 设备坏了

定位：实验设备事件，把 `S003 不可复现` 和 `S009 样本污染` 接入路线。

选项：

- `花钱维修`：需要 2 经费，消耗 2 经费，获得 1 数据，将 1 张 `C014 清理实验台` 加入牌组。
- `找隔壁实验室借`：需要 1 声望，获得 1 数据，将 1 张 `C023 请教师兄` 加入牌组。
- `改做理论分析`：获得 2 灵感，将 1 张 `S003 不可复现` 加入牌组。
- `抢窗口继续跑`：失去 3 精力，获得 1 数据，将 1 张 `S009 样本污染` 加入牌组。

接入和验证记录见 [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)。

## 实现内容

新增事件资源：

- `data/events/e001_canteen_scholar.tres`
- `data/events/e003_equipment_breakdown.tres`
- `data/events/e004_paper_rejected.tres`

更新脚本：

- `scripts/run/route_state.gd`
  - 新增 `NODE_KIND_ENCOUNTER`、`NODE_KIND_EVENT`。
  - 固定路线更新为 `N001 -> E001 -> N002 -> E004 -> N003 -> N004`。
  - 新增 `get_current_node_kind()`、`is_current_event_node()`、`get_current_event()`。
- `scripts/battle/battle_state.gd`
  - 新增 `apply_event_effects()`。
  - 新增事件可用的 `add_card_to_deck`、`add_card_to_draw`、`add_card_to_hand` 效果。
  - 新增运行中持久资源：`experience_lessons`、`methodology_notes`、`paper_fragments`。
- `scripts/run/run_settlement.gd`
  - 结算时把战斗状态里累计的事件局外资源并入最终局外资源。
- `scripts/ui/battle_test_scene.gd`
  - 新增事件描述、事件选项按钮、事件选择状态。
  - 新增 `select_event_choice()`、`select_first_event_choice()` 等验证接口。
  - 路线条和事件实际结果反馈见 [020_route_map_and_event_feedback.md](020_route_map_and_event_feedback.md)。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据加载验证：

```text
reload_route_state.gd=0
reload_battle_state.gd=0
reload_run_settlement.gd=0
reload_battle_test_scene.gd=0
reload_game_data_catalog.gd=0
card_count=35
encounter_count=4
event_count=6
has_e001=true
has_e003=true
has_e004=true
e001_choices=4
e003_choices=4
e004_choices=4
```

路线和事件流程验证：

```text
route_ids=N001,E001,N002,E004,N003,N004
initial_node=N001
n001_played=true
n001_reward=true
entered_e001=true
active_event_after_n001=E001
e001_buttons=4
e001_choice=true
e001_choice_id=note_keywords
deck_after_e001_choice=17
e001_added_c002=true
next_after_e001_choice=true
entered_n002=true
node_after_e001=N002
c002_persisted_n002=true
n002_played=true
n002_reward=true
entered_e004=true
active_event_after_n002=E004
e004_choice=true
paper_after_e004=1
s010_added=true
entered_n003=true
node_after_e004=N003
paper_persisted_n003=1
s010_persisted_n003=true
settlement_paper_fragments=1
settlement_completed_nodes=4
```

结果说明：

- 事件节点已经进入固定路线。
- 战斗奖励后可以进入事件，事件处理后可以继续进入下一场战斗。
- `E001` 能把 `C002 精读文献` 加入牌组，并在下一场战斗保留。
- `E004` 能获得论文碎片，并在下一场战斗和阶段结算中保留。当前路线已进一步加入 `E003`，完整实验噪音接入验证见 [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)。
- 负面反馈 `S010 自我怀疑` 可以通过事件加入后续牌组。

## 下一步

1. 事件节点已从固定路线升级为下一节点候选，见 [022_branching_route_choice.md](022_branching_route_choice.md)。
2. 事件选项的实际结果反馈已完成首版，见 [020_route_map_and_event_feedback.md](020_route_map_and_event_feedback.md)。
3. `E003 设备坏了` 已接入实验噪音路线，见 [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)。
4. 做一个独立的路线地图界面，为后续更完整的地图连线做准备。
