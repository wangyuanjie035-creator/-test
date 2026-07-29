# N006 项目推进压力 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)
- [038_doctor2_funding_window.md](038_doctor2_funding_window.md)
- [039_b005_project_midterm.md](039_b005_project_midterm.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)

## 目标

让 `B004 博士资格考核` 通过后进入博二阶段的第一个普通节点，而不是立刻阶段结算。

首版路线：

```text
E005 转博申请
  -> N005 博一开题重构
  -> B004 博士资格考核
  -> N006 项目推进压力
  -> E006 基金申请窗口
  -> B005 项目中期检查
  -> N007 预答辩筹备
  -> B006 博士预答辩
  -> B007 博士答辩
```

## 节点设计

| 字段 | 值 |
| --- | --- |
| id | `N006` |
| 名称 | 项目推进压力 |
| 阶段 | `doctor_2` |
| 目标进度 | 64 |
| 每回合压力 | 9 |
| 意图 | 项目节点压缩 |

设计意图：

- B004 后进入博二阶段，让转博路线开始体现“更长路线”的承诺。
- 目标和压力继续高于硕士普通节点，表现横向项目、实验排期和论文计划并行推进。
- 当前已经接入博士线奖励池，奖励为 `C032 委员会沟通`、`C034 项目排期表`、`C035 预答辩演练`。

## 实现内容

新增：

- `data/encounters/n006_project_pressure.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_QUALIFICATION_FIRST_ENCOUNTER = N006`。
  - 后续新增 `POST_DOCTOR2_FUNDING_EVENT = E006`，用于 N006 后进入基金申请窗口。
- `scripts/ui/battle_test_scene.gd`
  - B004 Boss 奖励选择后，追加并进入 `N006`。
  - 如果 `N006` 数据缺失，B004 会保持原有阶段结算兜底，避免卡死。
  - N006 普通奖励选择后，追加并进入 `E006`。

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
has_n006=true
n006_name=项目推进压力
n006_stage=doctor_2
n006_target=64
n006_pressure=9
has_b004=true
```

B004 后续路线验证：

```text
current_before_b004_reward=博士资格考核
b004_reward_options=b004_problem_chain,b004_committee_bridge,b004_remove_qualification_noise
selected_b004_reward=true
current_after_b004_reward=项目推进压力
route_ids_after_n006=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006
settlement_after_b004_reward=
```

N006 完成验证：

```text
n006_reward_count=3
selected_n006_reward=true
active_event_after_n006=E006
current_route_after_e006=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006
settlement_after_n006_reward=
```

## 下一步

1. `E006 基金申请窗口` 已接入，见 [038_doctor2_funding_window.md](038_doctor2_funding_window.md)。
2. `B005 项目中期检查` 已接入，见 [039_b005_project_midterm.md](039_b005_project_midterm.md)。
3. `N007 预答辩筹备` 已接入，见 [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)。
4. `B006 博士预答辩` 已接入，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
5. 博士线普通奖励池已接入，见 [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)。
6. `B007 博士答辩` 已接入，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
7. 博士 Boss 专属奖励池已接入，B004 后进入 N006 时不再使用通用 Boss 奖励，见 [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)。
