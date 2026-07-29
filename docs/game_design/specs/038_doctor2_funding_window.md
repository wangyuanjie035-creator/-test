# E006 基金申请窗口 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)
- [039_b005_project_midterm.md](039_b005_project_midterm.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)

## 目标

让博二阶段不只是普通战斗，而是出现一次资源取舍事件：争取基金、保论文管线、接横向项目，或暂缓申请。

首版路线：

```text
B004 博士资格考核
  -> N006 项目推进压力
  -> E006 基金申请窗口
  -> B005 项目中期检查
  -> N007 预答辩筹备
  -> B006 博士预答辩
  -> B007 博士答辩
```

## E006 事件选项

| 选项 | 条件 | 效果 | 定位 |
| --- | --- | --- | --- |
| 冲刺青年基金 | 至少 3 方法论笔记或 2 论文碎片 | 消耗 1 方法论笔记，失去 5 精力；经费 +3，声望 +1，论文碎片 +1；牌组新增 `S002 焦虑` | 高收益高压力 |
| 先保论文管线 | 至少 2 论文碎片 | 论文碎片 +2，牌组新增 `C007 润色摘要` | 稳论文 |
| 接一个横向项目 | 无 | 经费 +2，方法论笔记 +1，牌组新增 `C012 样本制备` 与 `S004 信息过载` | 资源换负担 |
| 暂缓申请 | 无 | 恢复 3 精力，经验教训 +2，方法论笔记 +1 | 保守复盘 |

## 实现内容

新增：

- `data/events/e006_funding_window.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_DOCTOR2_FUNDING_EVENT = E006`。
  - 后续新增 `POST_FUNDING_PROJECT_BOSS = B005`。
- `scripts/ui/battle_test_scene.gd`
  - N006 普通奖励选择后，追加并进入 `E006`。
  - 事件选项条件新增 `has_3_methodology_notes`、`has_2_paper_fragments`、`has_3_methodology_notes_or_2_paper_fragments`。
  - E006 事件选项选择后，追加并进入 `B005`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/route_state.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/run/run_settlement.gd=0
encounter_count=6
event_count=4
has_n006=true
has_e006=true
e006_name=基金申请窗口
e006_choices=4
e006_first_requirement=has_3_methodology_notes_or_2_paper_fragments
```

N006 后进入 E006 验证：

```text
current_before_n006_reward=项目推进压力
n006_reward_count=3
selected_n006_reward=true
active_event_after_n006=E006
current_route_after_e006=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006
settlement_after_n006_reward=
```

E006 选项验证：

```text
grant_available=true
paper_available=true
selected_e006_grant=true
e006_result=精力 -5；经费 +3；声望 +1；方法论笔记 -1；论文碎片 +1；牌组新增：焦虑。
current_after_e006=项目中期检查
route_ids_after_b005=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006,B005
settlement_after_e006=
```

条件不足验证：

```text
locked_grant_available=false
locked_grant_select=false
delay_select=true
delay_settlement=route_completed
```

## 下一步

1. `B005 项目中期检查` 已接入，见 [039_b005_project_midterm.md](039_b005_project_midterm.md)。
2. `N007 预答辩筹备` 已接入，见 [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)。
3. `B006 博士预答辩` 已接入，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
4. `B007 博士答辩` 已接入，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
5. 为博士线事件增加长期标记，例如基金中标、项目负担或合作关系。
