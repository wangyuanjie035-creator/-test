# B005 项目中期检查 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [038_doctor2_funding_window.md](038_doctor2_funding_window.md)
- [013_run_settlement.md](013_run_settlement.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)

## 目标

让 `E006 基金申请窗口` 后进入博二阶段 Boss：`B005 项目中期检查`。

首版路线：

```text
N006 项目推进压力
  -> E006 基金申请窗口
  -> B005 项目中期检查
  -> N007 预答辩筹备
  -> B006 博士预答辩
  -> B007 博士答辩
```

## Boss 设计

| 字段 | 值 |
| --- | --- |
| id | `B005` |
| 名称 | 项目中期检查 |
| 阶段 | `doctor_2` |
| 目标进度 | 155 |
| 初始负面牌 | `S004 信息过载`、`S005 恍惚` |
| 阶段检查 | 90 进度 |
| 阶段条件 | 至少 2 经费或 2 论文碎片 |
| 失败结算 | `project_midterm_failed` |

设计意图：

- B005 是博二阶段的项目管理压力汇总。
- E006 里获得的经费会跨节点保留到 B005，让基金申请窗口的选择真正影响后续 Boss。
- Boss 检查经费、数据管线和论文产出，体现博士阶段“资源、实验、论文”三线并行。

## 意图循环

| 意图 | 类型 | 压力 | 条件 / 效果 |
| --- | --- | --- | --- |
| 经费使用审查 | 检查 | 0 | 需要 2 经费；达成消耗 1 经费并获得 16 进度，失败加入恍惚 |
| 项目节点汇报 | 压力 | 12 | 需要 2 草稿；失败加入拖延 |
| 数据管线验收 | 检查 | 0 | 需要 2 数据；达成消耗 1 数据并获得 14 进度，失败加入信息过载 |
| 合作方拖拽 | 干扰 | 8 | 加入焦虑，下一次进度 -5 |
| 论文产出追问 | 检查 | 0 | 需要 2 论文碎片；达成声望 +1、进度 +12，失败加入自我怀疑 |

## 实现内容

新增：

- `data/bosses/b005_project_midterm.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_FUNDING_PROJECT_BOSS = B005`。
  - 后续新增 `POST_PROJECT_MIDTERM_FIRST_ENCOUNTER = N007`。
- `scripts/ui/battle_test_scene.gd`
  - E006 事件选项选择后，追加并进入 `B005`。
  - B005 Boss 奖励选择后，追加并进入 `N007`。
  - 新增 `project_midterm_failed` 结算颜色和日志。
  - B005 的 Boss 奖励文案改为项目路线、项目中期意见和项目噪音。
- `scripts/battle/battle_state.gd`
  - 将 `funds` 加入局内跨节点保留资源。
  - 新增 B005 项目材料清单。
  - 新增条件：`has_2_funds`、`has_2_funds_or_2_paper_fragments`。
- `scripts/run/run_settlement.gd`
  - 新增 `project_midterm_failed` 标题、描述和资源规则。

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
boss_count=5
event_count=4
has_b005=true
has_e006=true
b005_name=项目中期检查
b005_stage=doctor_2
b005_target=155
b005_intents=5
b005_phase=90:has_2_funds_or_2_paper_fragments
b005_failure=project_midterm_failed
```

路线接入验证：

```text
e006_selected=true
current_after_e006=项目中期检查
route_ids_after_b005=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006,B005
settlement_after_e006=
b005_funds=3
```

B005 信息和结算验证：

```text
b005_materials=项目材料：经费 2/2，论文碎片 2/2，本战数据 0/2。
b005_phase_hint=阶段检查：进度达到 90 时，需要至少 2 经费或 2 论文碎片。
b005_reward_options=b005_project_ledger,b005_timeline_protocol,b005_remove_project_noise
selected_b005_reward=true
current_after_b005_reward=预答辩筹备
route_ids_after_n007=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006,B005,N007
settlement_after_b005_reward=
b005_failure_outcome=project_midterm_failed
b005_failure_title=项目中期检查未过
```

## 下一步

1. `N007 预答辩筹备` 已接入，见 [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)。
2. `B006 博士预答辩` 已接入，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
3. 博士线普通奖励池已接入，见 [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)。
4. `B007 博士答辩` 已接入，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
5. 博士 Boss 专属奖励池已接入，B005 胜利后显示 `项目台账归档`、`固化项目排期`、`清理项目噪音`，见 [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)。
