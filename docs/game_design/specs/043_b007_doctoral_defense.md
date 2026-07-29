# B007 博士答辩 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [013_run_settlement.md](013_run_settlement.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [044_b007_graduation_endings.md](044_b007_graduation_endings.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)
- [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)
- [047_doctor4_revision_route.md](047_doctor4_revision_route.md)

## 目标

让 `B006 博士预答辩` 胜利后进入博士线终局 Boss：`B007 博士答辩`。

当前博士线终局路线：

```text
N007 预答辩筹备
  -> B006 博士预答辩
  -> B007 博士答辩
  -> 博士毕业结局选择 / E007 博四返修会 -> N008 返修长夜 -> B008 补答辩 -> 延毕后毕业 / 补答辩再延期
```

## Boss 设计

| 字段 | 值 |
| --- | --- |
| id | `B007` |
| 名称 | 博士答辩 |
| 阶段 | `doctor_3` |
| 目标进度 | 220 |
| 初始负面牌 | `S004 信息过载`、`S010 自我怀疑`、`S002 焦虑`、`S001 拖延` |
| 阶段检查 | 135 进度 |
| 阶段条件 | 至少 4 论文碎片或 2 声望 |
| 胜利后 | 博士毕业结局选择 |
| 失败后 | `E007 博四返修会`，随后进入 `N008 返修长夜` 与 `B008 补答辩` |

设计意图：

- B007 是当前博士线终局，目标进度高于 B006。
- 答辩材料检查抬高到论文碎片 4、方法论笔记 4，并继续要求声望。
- 失败不是归零，而是先进入“博四/延毕压力”的返修事件，再进入返修长夜和补答辩短路线。

## 意图循环

| 意图 | 类型 | 压力 | 条件 / 效果 |
| --- | --- | --- | --- |
| 博士论文主张追问 | 检查 | 0 | 需要 3 论文碎片；达成消耗 1 论文碎片并获得 24 进度，失败加入自我怀疑 |
| 委员会连续表决 | 压力 | 16 | 需要 2 声望；失败加入焦虑 |
| 方法有效性追问 | 检查 | 0 | 需要 4 方法论笔记；达成消耗 1 方法论笔记并获得 20 进度，失败加入信息过载 |
| 答辩时间压缩 | 干扰 | 10 | 加入拖延，下一次进度 -6 |
| 成果链核对 | 检查 | 0 | 需要 2 论文碎片；达成声望 +1、进度 +14，失败加入恍惚 |

阶段检查“答辩委员会表决”：

- 进度达到 135 时触发。
- 若有至少 4 论文碎片或 2 声望，获得 24 进度。
- 否则加入焦虑和自我怀疑，并让目标进度 +16。

## 实现内容

新增：

- `data/bosses/b007_doctoral_defense.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_DOCTORAL_DEFENSE_BOSS = B007`。
  - 后续新增 `POST_DOCTORAL_DELAY_REPAIR_EVENT = E007`。
  - 后续新增 `POST_DELAY_REPAIR_ENCOUNTER = N008` 与 `POST_SUPPLEMENTARY_DEFENSE_BOSS = B008`。
- `scripts/ui/battle_test_scene.gd`
  - B006 Boss 奖励选择后，追加并进入 `B007`。
  - B007 胜利后进入博士毕业结局选择，见 [044_b007_graduation_endings.md](044_b007_graduation_endings.md)。
  - B007 失败后进入 `E007 博四返修会`，见 [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)。
  - E007 后接入 `N008 返修长夜` 与 `B008 补答辩`，见 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。
  - 新增博士毕业结局和 `doctoral_defense_delayed` 结算颜色、日志。
  - B007 的 Boss 奖励文案改为答辩结论、答辩意见和毕业噪音。
- `scripts/battle/battle_state.gd`
  - 新增 B007 答辩材料清单。
  - 新增条件：`has_4_methodology_notes`、`has_4_paper_fragments`、`has_4_paper_fragments_or_2_reputation`。
  - 新增阶段检查名称“答辩委员会表决”。
- `scripts/run/run_settlement.gd`
  - 新增 `doctoral_graduated` 和 `doctoral_defense_delayed` 标题、描述和资源规则。

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
boss_count=7
has_b007=true
b007_summary=博士答辩:doctor_3:220:5:135:doctoral_defense_delayed
b007_phase_condition=has_4_paper_fragments_or_2_reputation
```

路线与结算验证：

```text
current_after_n007=B006
select_b006_reward=true
current_after_b006=B007
settlement_after_b006=
b007_materials=答辩材料：论文碎片 4/4，声望 0/2，方法论笔记 4/4。
b007_phase_hint=答辩委员会表决：进度达到 135 时，需要至少 4 论文碎片或 2 声望。
route_after_b007=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006,B005,N007,B006,B007
b007_reward_options=b007_outstanding_doctoral_graduation,b007_doctoral_graduation,b007_delayed_doctoral_graduation
select_b007_reward=true
settlement_after_b007=doctoral_graduated
settlement_title_after_b007=博士毕业
failure_current_after_b007=E007
failure_settlement_after_b007=
```

答辩延期返修事件验证：

```text
after_failure_current=E007
after_failure_active_event=E007
after_failure_route=B007,E007
after_failure_settlement=
e007_choice_count=3
after_e007_current=N008
after_e007_settlement=
after_n008_current=B008
after_n008_is_boss=true
b008_settlement=delayed_doctoral_graduation
b008_title=延毕后毕业
b008_route=B007,E007,N008,B008
```

## 下一步

1. 博士毕业结局分层已接入，见 [044_b007_graduation_endings.md](044_b007_graduation_endings.md)。
2. B004 到 B006 的博士 Boss 专属奖励池已接入；B007 作为终局 Boss 保持博士毕业结局选择，见 [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)。
3. E007 博四返修会已接入，见 [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)。
4. 博四短路线 `E007 -> N008 -> B008` 已接入，见 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。
