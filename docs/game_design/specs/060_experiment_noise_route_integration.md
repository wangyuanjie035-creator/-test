# 实验噪音路线接入 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [003_mvp_event_set.md](003_mvp_event_set.md)
- [019_event_nodes_in_route.md](019_event_nodes_in_route.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)

## 目标

让 `S003 不可复现` 和 `S009 样本污染` 不只存在于卡牌数据里，而是能从实际路线事件和 Boss 检查进入牌组。

本次接入两个入口：

- `E003 设备坏了`：实验设备事件，通过选择把实验噪音或清理工具加入牌组。
- `B002 数据真实性检查`：没有数据时，失败后加入 `S003 不可复现`。

## E003 设备坏了

| 选项 | 条件 | 结果 | 定位 |
| --- | --- | --- | --- |
| 花钱维修 | 需要 2 经费 | 消耗 2 经费，获得 1 数据，将 1 张 `C014 清理实验台` 加入牌组 | 用资源换稳定 |
| 找隔壁实验室借 | 需要 1 声望 | 获得 1 数据，将 1 张 `C023 请教师兄` 加入牌组 | 用人脉换实验窗口 |
| 改做理论分析 | 无 | 获得 2 灵感，将 1 张 `S003 不可复现` 加入牌组 | 换方向但留下复现风险 |
| 抢窗口继续跑 | 无 | 失去 3 精力，获得 1 数据，将 1 张 `S009 样本污染` 加入牌组 | 高风险抢进度 |

## 路线接入

`E003` 进入早中期候选路线：

```text
N001 后：E001 / N002 / N003
E001 后：N002 / E003 / N003
第三列候选：E004 / E003 / N003
```

这样玩家通常会在研一后半到研二前半遇到一次实验设备事件。`E004 论文被拒` 仍保留在同一阶段候选中，只是不再和 `E003` 强制同时出现。

## B002 接入

`B002 中期考核` 的第二回合意图 `数据真实性检查` 更新为：

- 若有数据：消耗 1 数据，获得 12 进度。
- 若没有数据：将 1 张 `S003 不可复现` 加入牌组。

这让实验数据流在中期考核中更加清晰：没有数据不再只是泛用的 `恍惚`，而是留下一个与实验系统相关的可处理风险。

## 实现内容

新增：

- `data/events/e003_equipment_breakdown.tres`

更新：

- `scripts/run/route_state.gd`
- `data/bosses/b002_midterm_review.tres`

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/run/route_state.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/data/event_definition.gd=0
res://scripts/data/event_choice_definition.gd=0
res://scripts/data/boss_definition.gd=0
res://scripts/data/boss_intent_definition.gd=0
```

数据和路线验证：

```text
counts=cards=36 events=6 bosses=8 encounters=8
has_e003=true
e003_choices=pay_repair,borrow_neighbor_lab,switch_to_theory,rush_equipment_window
choices_after_n001=E001,N002,N003
choices_after_e001=N002,E003,N003
```

事件效果验证：

```text
e003_pay_repair=v=20 data=1 inspiration=0 funds=0 deck=C014 discard=C014
e003_borrow_neighbor_lab=v=20 data=1 inspiration=0 funds=2 deck=C023 discard=C023
e003_switch_to_theory=v=20 data=0 inspiration=2 funds=2 deck=S003 discard=S003
e003_rush_equipment_window=v=17 data=1 inspiration=0 funds=2 deck=S009 discard=S009
```

Boss 接入验证：

```text
b002_data_failure=deck=S003 discard=S003
b002_intent_text=数据真实性检查
```

## 下一步

1. 让 `C014 清理实验台` 在事件或 Boss 后更有存在感，例如 UI 提示当前牌组里有多少实验噪音。
2. `负结果也是结果` 已接入，能把实验噪音转化为数据和灵感，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
3. `设备维护记录` 已接入，把经费也接进实验设备流的资源转化链，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
4. `N003` 的动态三选一已按实验噪音和经费倾向加权，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
