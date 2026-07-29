# 早期路线候选池扩展 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)
- [072_route_choice_seed_shuffle.md](072_route_choice_seed_shuffle.md)
- [074_route_choice_weighting.md](074_route_choice_weighting.md)
- [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)
- [077_early_route_new_nodes.md](077_early_route_new_nodes.md)

## 目标

首版把早期路线候选池从刚好 3 个节点扩展到 4-5 个节点，让 [072](072_route_choice_seed_shuffle.md) 的 seed 洗牌真正影响“这一局出现哪些候选”，而不只是影响按钮顺序。后续新增节点后，早期候选池已扩展到 6-7 个节点。

首版只复用现有 `N002/N003/E001/E003/E004`，不新增节点资源，降低改动风险。后续在 [077](077_early_route_new_nodes.md) 中已新增 `N009 数据清洗夜` 和 `E008 导师临时约谈`，并接入同一早期候选池。

## 候选池

`RouteState.DEFAULT_CHOICE_COLUMNS` 更新为：

| 阶段 | 候选池 | UI 显示 |
| --- | --- | --- |
| 1 | `N001` | 固定开局 |
| 2 | `E001`、`N002`、`N003`、`E003`、`E008`、`N009` | 洗牌/加权后取 3 个 |
| 3 | `N002`、`E003`、`N003`、`E001`、`E004`、`E008`、`N009` | 过滤已进入节点，洗牌/加权后取 3 个 |
| 4 | `E004`、`E003`、`N003`、`N002`、`E001`、`E008`、`N009` | 过滤已进入节点，洗牌/加权后取 3 个 |
| 5 | `N004` | 固定进入截稿临近 |
| 6 | `B001` | 固定进入开题报告 |
| 7 | `B002` | 固定进入中期考核 |
| 8 | `B003`、`E005` | 保持原顺序，提供不转博/转博分支 |

## 设计说明

- `E003 设备坏了` 提前进入第一段候选，让实验设备风险可以更早出现。
- `E008 导师临时约谈` 和 `N009 数据清洗夜` 作为后续新增节点，补足导师方向与数据复现主题。
- `E001/E003/E004` 在第 2-4 阶段互相补位，避免某个事件因为一次未出现就完全错过。
- `N004 截稿临近` 仍作为普通路线收束点，保证早期探索不会无限漂移。
- Boss 和转博相关候选不参与这次扩池，继续保持主线节奏。

## 实现内容

更新：

- `scripts/run/route_state.gd`
  - 扩展 `DEFAULT_CHOICE_COLUMNS` 第 2-4 阶段候选池。
  - 保持 `max_choices = 3` 的 UI 输出规则不变。

未改变：

- 新局仍从 `N001 普通压力` 开始。
- `RouteState.get_next_node_choices()` 的过滤、seed 洗牌和 Boss 顺序保护规则不变。
- `N004 -> B001 -> B002 -> B003/E005` 后续主线不变。

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

首段候选内容变化验证：

```text
choices_seed_12345_a=E003,N002,E001
choices_seed_12345_b=E003,N002,E001
choices_seed_67890=N002,N003,E001
choices_seed_24680=N003,E001,E003
same_seed_same=true
content_diff_12345_67890=true
content_diff_12345_24680=true
```

路线收束验证：

```text
first_pick_route=N003,E001,E004
n004_fixed_choice=N004
```

结果说明：

- 同一个 seed 仍能复现相同候选内容和顺序。
- 不同 seed 下，首段候选已经会出现内容差异。
- 早期前三段选完后，下一步仍固定进入 `N004`，主线收束保持稳定。

## 下一步

1. 路线候选权重已完成首版，见 [074_route_choice_weighting.md](074_route_choice_weighting.md)。
2. 新增早期普通/事件节点已完成，见 [077_early_route_new_nodes.md](077_early_route_new_nodes.md)。
3. 候选按钮已升级为节点卡片，见 [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)。
