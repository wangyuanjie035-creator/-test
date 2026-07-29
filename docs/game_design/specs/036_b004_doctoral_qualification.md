# B004 博士资格考核 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [035_doctoral_route_entry.md](035_doctoral_route_entry.md)
- [013_run_settlement.md](013_run_settlement.md)
- [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)
- [038_doctor2_funding_window.md](038_doctor2_funding_window.md)
- [039_b005_project_midterm.md](039_b005_project_midterm.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)

## 目标

把转博路线从 `N005 博一开题重构` 推进到第一个博士 Boss：`B004 博士资格考核`。

首版路线：

```text
B002 中期考核
  -> E005 转博申请
  -> N005 博一开题重构
  -> B004 博士资格考核
  -> N006 项目推进压力
  -> E006 基金申请窗口
  -> B005 项目中期检查
  -> N007 预答辩筹备
  -> B006 博士预答辩
  -> B007 博士答辩
```

## Boss 设计

| 字段 | 值 |
| --- | --- |
| id | `B004` |
| 名称 | 博士资格考核 |
| 阶段 | `doctor_1` |
| 目标进度 | 135 |
| 初始负面牌 | `S002 焦虑`、`S010 自我怀疑` |
| 阶段检查 | 75 进度 |
| 阶段条件 | 至少 3 方法论笔记或 2 论文碎片 |
| 失败结算 | `qualification_failed` |

设计意图：

- B004 是博士线第一道真正门槛，压力明显高于硕士 Boss。
- 核心检查不再只看本战资源，而是看转博前后沉淀下来的方法论和论文材料。
- 失败时给更多长期复盘资源，符合博士线“路线更长、坏结局也更有价值”的原则。

## 意图循环

| 意图 | 类型 | 压力 | 条件 / 效果 |
| --- | --- | --- | --- |
| 课题规模放大 | 干扰 | 6 | 目标进度 +4 |
| 理论基础审查 | 检查 | 0 | 需要 3 方法论笔记；达成消耗 1 方法论笔记并获得 18 进度，失败加入信息过载 |
| 资格考试追问 | 压力 | 13 | 需要 2 灵感；失败加入自我怀疑 |
| 同届横向比较 | 干扰 | 8 | 加入焦虑 |
| 论文管线追问 | 检查 | 0 | 需要 2 论文碎片；达成声望 +1、进度 +12，失败加入拖延 |

## 实现内容

新增：

- `data/bosses/b004_doctoral_qualification.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_TRANSFER_QUALIFICATION_BOSS = B004`。
  - 后续新增 `POST_QUALIFICATION_FIRST_ENCOUNTER = N006`，用于 B004 后进入博二入口。
- `scripts/ui/battle_test_scene.gd`
  - N005 普通奖励选择后，追加并进入 `B004`。
  - B004 Boss 奖励选择后，追加并进入 `N006`。
  - 新增 `qualification_failed` 结算颜色和日志。
  - B004 的 Boss 奖励文案改为博士问题链、资格考核意见和资格焦虑。
- `scripts/battle/battle_state.gd`
  - 新增 B004 资格材料清单。
  - 新增条件：`has_3_methodology_notes`、`has_2_paper_fragments`、`has_3_methodology_notes_or_2_paper_fragments`。
- `scripts/run/run_settlement.gd`
  - 新增 `qualification_failed` 标题、描述和资源规则。

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
boss_count=4
has_b004=true
b004_name=博士资格考核
b004_stage=doctor_1
b004_target=135
b004_intents=5
b004_phase=75:has_3_methodology_notes_or_2_paper_fragments
b004_failure=qualification_failed
```

路线接入验证：

```text
options_after_b002=B003,E005
current_after_e005=博一开题重构
n005_reward_count=3
selected_n005_reward=true
current_after_n005_reward=博士资格考核
route_ids_after_b004=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004
```

B004 信息和结算验证：

```text
b004_phase_hint=阶段检查：进度达到 75 时，需要至少 3 方法论笔记或 2 论文碎片。
b004_materials=资格材料：方法论笔记 3/3，论文碎片 2/2，草稿 0/4。
b004_reward_options=b004_problem_chain,b004_committee_bridge,b004_remove_qualification_noise
selected_b004_reward=true
current_after_b004_reward=项目推进压力
route_ids_after_n006=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006
settlement_after_b004_reward=
b004_failure_outcome=qualification_failed
b004_failure_title=博士资格考核未过
```

## 下一步

1. `N006 项目推进压力` 已接入，见 [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)。
2. `E006 基金申请窗口` 已接入，见 [038_doctor2_funding_window.md](038_doctor2_funding_window.md)。
3. `B005 项目中期检查` 已接入，见 [039_b005_project_midterm.md](039_b005_project_midterm.md)。
4. `N007 预答辩筹备` 已接入，见 [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)。
5. `B006 博士预答辩` 已接入，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
6. 博士线普通奖励池已接入，见 [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)。
7. `B007 博士答辩` 已接入，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
8. 博士 Boss 专属奖励池已接入，B004 胜利后显示 `确定博士问题链`、`建立委员会沟通`、`删去资格焦虑`，见 [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)。
