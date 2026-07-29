# N007 预答辩筹备 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [039_b005_project_midterm.md](039_b005_project_midterm.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)

## 目标

让 `B005 项目中期检查` 通过后进入博三阶段入口，而不是立刻阶段结算。

首版路线：

```text
E006 基金申请窗口
  -> B005 项目中期检查
  -> N007 预答辩筹备
  -> B006 博士预答辩
  -> B007 博士答辩
```

## 节点设计

| 字段 | 值 |
| --- | --- |
| id | `N007` |
| 名称 | 预答辩筹备 |
| 阶段 | `doctor_3` |
| 目标进度 | 76 |
| 每回合压力 | 10 |
| 意图 | 预答辩倒计时 |

设计意图：

- N007 是博士线进入博三的第一个可玩节点。
- 目标和压力继续抬高，用来表现预答辩材料、论文主线和委员会预期同时逼近。
- 当前已经接入博士线奖励池；B006 接入后，N007 不再作为阶段终点，而是进入 `B006 博士预答辩`。

## 实现内容

新增：

- `data/encounters/n007_predefense_prep.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_PROJECT_MIDTERM_FIRST_ENCOUNTER = N007`。
- `scripts/ui/battle_test_scene.gd`
  - B005 Boss 奖励选择后，追加并进入 `N007`。
  - 如果 `N007` 数据缺失，B005 会保持阶段结算兜底，避免流程卡死。
  - B006 接入后，N007 普通奖励选择会继续追加并进入 `B006`。

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
encounter_count=7
boss_count=6
has_n007=true
has_b005=true
n007_name=预答辩筹备
n007_stage=doctor_3
n007_target=76
n007_pressure=10
```

B005 后进入 N007 验证：

```text
current_before_b005_reward=项目中期检查
b005_reward_options=b005_project_ledger,b005_timeline_protocol,b005_remove_project_noise
selected_b005_reward=true
current_after_b005_reward=预答辩筹备
route_ids_after_n007=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006,B005,N007
settlement_after_b005_reward=
```

B006 接入后的 N007 完成验证：

```text
n007_reward_count=3
selected_n007_reward=true
current_after_n007_reward=B006
route_after_n007=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006,B005,N007,B006
settlement_after_n007=
```

## 下一步

1. `B006 博士预答辩` 已接入，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
2. 博士线普通奖励池已接入，见 [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)。
3. `B007 博士答辩` 已接入，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
4. 博士 Boss 专属奖励池已接入，B005 后进入 N007 时不再使用通用 Boss 奖励，见 [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)。
