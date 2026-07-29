# 第一个 Boss 节点：开题报告 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [002_mvp_boss_set.md](002_mvp_boss_set.md)
- [013_run_settlement.md](013_run_settlement.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [024_boss_readability_and_rewards.md](024_boss_readability_and_rewards.md)
- [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)

## 目标

给当前原型补上第一个明确 Boss 目标。本文记录 `B001 开题报告` 的首版实现；后续路线已延长到 `B002 中期考核` 与 `B003 盲审专家`，见 [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md) 和 [032_third_boss_blind_review.md](032_third_boss_blind_review.md)。

## 路线接入

当前路线选择仍从 `N001 普通压力` 开始。中段通过 2-3 个候选节点进行选择，完成 `N004 截稿临近` 后会出现唯一 Boss 候选：

```text
B001 开题报告
```

完成 `N004` 不再直接触发 `route_completed`，必须进入 `B001`。当前版本中，通过 `B001` 后会继续到 `B002`，再继续到 `B003`，不再直接结算。

## B001 开题报告

| 字段 | 内容 |
| --- | --- |
| ID | `B001` |
| 名称 | 开题报告 |
| 阶段 | 研一 Boss |
| 目标进度 | 70 |
| 开局负面 | 将 1 张 `S010 自我怀疑` 加入弃牌堆和牌组 |
| 阶段检查 | 进度达到 35 时触发一次“确定题目”检查 |

## 意图循环

| 回合 | 意图 | 首版效果 |
| --- | --- | --- |
| 1 | 研究意义追问 | 造成 7 压力；若没有灵感，加入 1 张 `S010 自我怀疑` |
| 2 | 文献基础检查 | 若有 2 灵感，获得 1 草稿；否则加入 1 张 `S004 信息过载` |
| 3 | 方向可行性质疑 | 造成 9 压力 |
| 4 | 导师补充问题 | 加入 1 张 `S001 拖延`，目标进度 +5 |

## 阶段检查

当进度达到 35 时触发一次：

- 若有 2 草稿或 2 数据，获得 10 进度。
- 否则加入 1 张 `S001 拖延`。

设计意图：

- 让 `查文献`、`写草稿`、`做实验` 在 Boss 战里都有价值。
- 让玩家第一次看到“资源检查”机制。
- 让 Boss 比普通节点更长、更有压力，但还不引入过多特殊 UI。

## 结算奖励

如果 `route_completed` 发生在 Boss 战后，结算额外获得：

- 方法论笔记 +2。
- 论文碎片 +1。

这部分叠加在原本路线完成奖励之上。

## 实现内容

新增：

- `data/bosses/b001_proposal_defense.tres`

更新：

- `scripts/data/boss_definition.gd`
  - 新增 `phase_condition`、`phase_success_effects`、`phase_failure_effects`。
- `scripts/run/route_state.gd`
  - 新增 `NODE_KIND_BOSS`。
  - 下一节点候选池末尾新增 `B001`。
  - 新增 `get_current_boss()`。
- `scripts/battle/battle_state.gd`
  - 新增 Boss 状态：`is_boss_encounter`、`boss_definition`、`boss_phase_triggered`。
  - 新增 `set_boss()`、`start_next_boss()`。
  - Boss 敌方回合使用 `BossIntentDefinition`。
  - 新增 `modify_target_progress` 效果。
  - 新增 Boss 阶段检查触发逻辑。
- `scripts/ui/battle_test_scene.gd`
  - 加载 Boss 数据。
  - 下一节点候选按钮支持 Boss 类型。
  - 进入 Boss 节点时启动 Boss 战。
- `scripts/run/run_settlement.gd`
  - Boss 通关结算额外给予方法论笔记和论文碎片。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据加载：

```text
reload_boss_definition.gd=0
reload_route_state.gd=0
reload_battle_state.gd=0
reload_run_settlement.gd=0
reload_battle_test_scene.gd=0
reload_game_data_catalog.gd=0
boss_count=1
has_b001=true
b001_name=开题报告
b001_target=70
b001_intents=4
b001_phase=35
```

路线接入验证：

```text
options_after_n004=B001
settlement_after_n004=false
selected_boss=true
current_node=B001
battle_is_boss=true
boss_encounter_id=B001
boss_target=70
boss_intent=研究意义追问：造成 7 压力
boss_deck_has_s010=true
boss_discard_has_s010=true
settlement_after_boss=true
settlement_outcome=route_completed
settlement_paper=3
settlement_methodology=14
final_route_ids=N001,N002,N003,E004,N004,B001
final_options=
```

Boss 意图验证：

```text
start_is_boss=true
start_target=70
start_intent=研究意义追问：造成 7 压力
start_discard_has_s010=true
turn1_pressure=7
turn1_vitality=43
turn1_added_s010=true
turn2_intent=文献基础检查
turn2_added_s004=true
```

阶段检查验证：

```text
phase_played=true
phase_progress=50
phase_triggered=true
phase_victory=false
phase_event_log=...|boss_phase_success id=B001 progress=50|played id=C011 ap=2 progress=50
```

## 结果说明

- `B001` 能作为 Boss 节点出现在路线末尾。
- 完成 `N004` 后不会直接结算，必须进入 Boss。
- Boss 开局会加入 `S010 自我怀疑`。
- Boss 意图循环能造成压力、执行资源检查并加入负面牌。
- 进度达到 35 后会触发一次阶段检查。
- Boss 胜利后才触发阶段通过结算，并给予额外局外资源。
- 后续版本已将路线延长到 `B002 中期考核`，因此 `B001` 通过后会先进入下一 Boss，见 [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)。

## 下一步

1. Boss 战意图文本、阶段检查提示和 Boss 胜利奖励已完成，见 [024_boss_readability_and_rewards.md](024_boss_readability_and_rewards.md)。
2. `B001` 失败结算：开题延期已完成，见 [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)。
3. 给 Boss 胜利奖励增加更强的视觉区分。
