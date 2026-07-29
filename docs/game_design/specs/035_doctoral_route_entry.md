# N005 博一开题重构 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [034_transfer_application_event.md](034_transfer_application_event.md)
- [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)
- [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)
- [038_doctor2_funding_window.md](038_doctor2_funding_window.md)
- [039_b005_project_midterm.md](039_b005_project_midterm.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)

## 目标

让 `E005 转博申请` 成功后不再停留在占位结算，而是进入博士路线的第一个可玩节点。

首版路线：

```text
B002 中期考核
  -> 不转博：B003 盲审专家
  -> 转博：E005 转博申请 -> N005 博一开题重构 -> B004 博士资格考核 -> N006 项目推进压力 -> E006 基金申请窗口 -> B005 项目中期检查 -> N007 预答辩筹备 -> B006 博士预答辩 -> B007 博士答辩
```

## 节点设计

| 字段 | 值 |
| --- | --- |
| id | `N005` |
| 名称 | 博一开题重构 |
| 阶段 | `doctor_1` |
| 目标进度 | 52 |
| 每回合压力 | 8 |
| 意图 | 重构问题意识 |

设计意图：

- 转博后的第一段不是立刻打 Boss，而是先让玩家感到“原课题被放大和重写”。
- 目标和压力高于硕士普通节点，但低于 Boss，用来测试博士线节奏。
- 该节点已经接入博士线奖励池，奖励为 `C031 问题链重排`、`C032 委员会沟通`、`C033 论文主线图`。

## 实现内容

新增：

- `data/encounters/n005_doctoral_proposal_reframe.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_TRANSFER_FIRST_ENCOUNTER = N005`。
  - 后续新增 `POST_TRANSFER_QUALIFICATION_BOSS = B004`，用于 N005 后进入博士资格考核。
- `scripts/ui/battle_test_scene.gd`
  - `submit_transfer_application` 成功后优先追加并进入 `N005`。
  - 如果 `N005` 数据缺失，回退到 `transfer_admitted` 结算，避免流程卡死。
  - N005 领奖后追加并进入 `B004 博士资格考核`。

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
encounter_count=5
has_n005=true
n005_name=博一开题重构
n005_stage=doctor_1
n005_target=52
n005_pressure=8
```

转博进入 N005 验证：

```text
selected_b002_reward=true
options_after_b002=B003,E005
selected_e005=true
submit_available=true
submit_result=true
settlement_after_submit=
current_after_submit=博一开题重构
route_ids_after_submit=N001,N002,E004,N003,N004,B001,B002,E005,N005
```

N005 完成验证：

```text
n005_reward_count=3
selected_n005_reward=true
current_after_n005_reward=博士资格考核
route_ids_after_b004=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004
```

回到硕士线验证：

```text
locked_submit_available=false
locked_submit_result=false
continue_master=true
current_after_continue=盲审专家
```

## 下一步

1. `B004 博士资格考核` 已接入，见 [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)。
2. `N006 项目推进压力` 已接入，见 [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)。
3. `E006 基金申请窗口` 已接入，见 [038_doctor2_funding_window.md](038_doctor2_funding_window.md)。
4. `B005 项目中期检查` 已接入，见 [039_b005_project_midterm.md](039_b005_project_midterm.md)。
5. `N007 预答辩筹备` 已接入，见 [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)。
6. `B006 博士预答辩` 已接入，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
7. 博士线普通奖励池已接入，见 [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)。
8. `B007 博士答辩` 已接入，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
