# E005 转博申请分支 v0.2

状态：已完成转博事件与博士线入口接入，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)
- [033_b003_graduation_endings.md](033_b003_graduation_endings.md)
- [035_doctoral_route_entry.md](035_doctoral_route_entry.md)
- [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)
- [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)
- [038_doctor2_funding_window.md](038_doctor2_funding_window.md)
- [039_b005_project_midterm.md](039_b005_project_midterm.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md)

## 目标

让 `B002 中期考核` 后真正出现“不转博 / 申请转博”的分支。

首版路线：

```text
B002 中期考核
  -> B003 盲审专家
  -> E005 转博申请 -> N005 博一开题重构 -> B004 博士资格考核 -> N006 项目推进压力 -> E006 基金申请窗口 -> B005 项目中期检查 -> N007 预答辩筹备 -> B006 博士预答辩 -> B007 博士答辩
```

当前 `E005` 作为转博路线入口。提交成功后进入 `N005 博一开题重构`；`transfer_admitted` 仍保留为博士线数据缺失时的兜底正反馈结算。

## 路线规则

完成 `B002` 并选择 Boss 奖励后，下一节点候选变为：

```text
B003 盲审专家 / 转博申请
```

选择 `B003`：

- 进入不转博硕士毕业线。
- 打过 B003 后进入毕业结局选择。

选择 `E005 转博申请`：

- 进入事件节点。
- 满足条件可以提交转博申请。
- 条件不足或主动放弃时，可以选择“先完成硕士毕业”，继续进入 `B003`。

## E005 事件选项

| 选项 | 条件 | 效果 | 后续 |
| --- | --- | --- | --- |
| 提交转博申请 | 至少 2 声望或 4 草稿 | 方法论笔记 +2，论文碎片 +1，声望 +1，牌组新增 `C023 请教师兄` | 进入 `N005 博一开题重构` |
| 先完成硕士毕业 | 无 | 方法论笔记 +1，经验教训 +1 | 进入 `B003 盲审专家` |

设计意图：

- 转博不是免费强化，需要玩家在 B002 前后留下足够的声望或材料。
- 条件不足时不会卡住，玩家仍能回到硕士毕业线。
- 博士线首个节点缺失时，`transfer_admitted` 作为兜底正反馈结算，避免路线卡死。

## 转博资格确认

提交转博申请成功后优先进入 `N005 博一开题重构`。如果博士线首个节点缺失，则兜底结算为：

```text
outcome_id = transfer_admitted
title = 转博资格确认
```

额外资源：

- 经验教训 +2。
- 方法论笔记 +3。
- 论文碎片 +2。

事件本身还会先给：

- 方法论笔记 +2。
- 论文碎片 +1。
- 声望 +1。
- `C023 请教师兄` 加入牌组。

## 实现内容

新增：

- `data/events/e005_transfer_application.tres`
- `data/encounters/n005_doctoral_proposal_reframe.tres`

更新：

- `scripts/run/route_state.gd`
  - B002 后候选从 `[B003]` 扩展为 `[B003, E005]`。
- `scripts/ui/battle_test_scene.gd`
  - 新增事件需求：`has_2_reputation`、`has_4_draft`、`has_2_reputation_or_4_draft`。
  - `E005` 路线详情中显示 `转博资格`、声望/草稿进度和当前是否可提交，见 [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md)。
  - 新增 `_resolve_transfer_application_choice()`。
  - `submit_transfer_application` 会优先进入 `N005 博一开题重构`。
  - 如果 `N005` 数据缺失，则进入 `transfer_admitted` 兜底结算。
  - `continue_master_graduation` 会把 `B003` 追加到路线并进入盲审专家。
  - 新增 `transfer_admitted` 的结算颜色和日志文案。
- `scripts/run/run_settlement.gd`
  - 新增 `transfer_admitted` 标题、描述和资源规则。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据加载验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/run_settlement.gd=0
res://scripts/run/route_state.gd=0
res://scripts/data/game_data_catalog.gd=0
event_count=3
has_e005=true
e005_name=转博申请
e005_choices=2
e005_first_requirement=has_2_reputation_or_4_draft
```

B002 后分支验证：

```text
selected_b002_reward=true
options_after_b002=B003,E005
selected_e005=true
active_event=E005
event_buttons=2
```

条件不足回到硕士线验证：

```text
submit_available_initial=false
submit_initial=false
settlement_after_locked=
continue_master=true
current_after_continue=盲审专家
route_ids_after_continue=N001,N002,E004,N003,N004,B001,B002,E005,B003
```

满足条件转博验证：

```text
submit_available=true
submit_result=true
settlement_after_submit=
current_after_submit=博一开题重构
route_ids_after_submit=N001,N002,E004,N003,N004,B001,B002,E005,N005
admit_event_result=声望 +1；方法论笔记 +2；论文碎片 +1；牌组新增：请教师兄。
```

N005 接入验证：

```text
encounter_count=5
has_n005=true
n005_name=博一开题重构
n005_stage=doctor_1
n005_target=52
n005_pressure=8
n005_reward_count=3
selected_n005_reward=true
current_after_n005_reward=博士资格考核
```

## 结果说明

- B002 后已经出现 `B003` 与 `E005` 两个分支候选。
- E005 内部会检查转博条件。
- 条件不足不会卡死，可以回到 B003。
- 条件满足时可以进入 `N005 博一开题重构`。
- `transfer_admitted` 保留为博士线数据缺失时的兜底结算。

## 下一步

1. `B004 博士资格考核` 已接入，见 [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)。
2. `N006`、`E006`、`B005`、`N007`、`B006` 与 `B007` 已接入，见 [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)、[038_doctor2_funding_window.md](038_doctor2_funding_window.md)、[039_b005_project_midterm.md](039_b005_project_midterm.md)、[040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)、[041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md) 与 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
3. 转博条件已接入路线详情面板，见 [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md)；后续可以进一步显示到路线候选卡片正文上。
