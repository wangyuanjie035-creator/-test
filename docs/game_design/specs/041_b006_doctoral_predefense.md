# B006 博士预答辩 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [013_run_settlement.md](013_run_settlement.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)

## 目标

让 `N007 预答辩筹备` 完成后进入博三 Boss：`B006 博士预答辩`，把博士线从“博三入口”推进到一次真正的答辩前审查。

当前路线：

```text
E006 基金申请窗口
  -> B005 项目中期检查
  -> N007 预答辩筹备
  -> B006 博士预答辩
  -> B007 博士答辩
```

## Boss 设计

| 字段 | 值 |
| --- | --- |
| id | `B006` |
| 名称 | 博士预答辩 |
| 阶段 | `doctor_3` |
| 目标进度 | 180 |
| 初始负面牌 | `S004 信息过载`、`S010 自我怀疑`、`S002 焦虑` |
| 阶段检查 | 105 进度 |
| 阶段条件 | 至少 3 论文碎片或 2 声望 |
| 失败结算 | `predefense_failed` |

设计意图：

- B006 是博士线目前最重的 Boss，检查论文主线、委员会认可和方法复盘。
- 条件侧重跨节点积累：论文碎片、声望、方法论笔记都会在预答辩中被追问。
- 即使预答辩未过，也会产出大量复盘资源，让失败成为下一轮博士线的正反馈。

## 意图循环

| 意图 | 类型 | 压力 | 条件 / 效果 |
| --- | --- | --- | --- |
| 论文主线追问 | 检查 | 0 | 需要 3 论文碎片；达成消耗 1 论文碎片并获得 20 进度，失败加入自我怀疑 |
| 委员会连续质询 | 压力 | 14 | 需要 2 声望；失败加入焦虑 |
| 章节连贯性缺口 | 干扰 | 8 | 加入信息过载，下一次进度 -6 |
| 方法路线复盘 | 检查 | 0 | 需要 3 方法论笔记；达成消耗 1 方法论笔记并获得 16 进度，失败加入信息过载 |
| 答辩时间表压缩 | 压力 | 12 | 需要 4 草稿；失败加入拖延 |

阶段检查“预答辩意见汇总”：

- 进度达到 105 时触发。
- 若有至少 3 论文碎片或 2 声望，获得 18 进度。
- 否则加入焦虑和自我怀疑，并让目标进度 +12。

## 实现内容

新增：

- `data/bosses/b006_doctoral_predefense.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_PREDEFENSE_BOSS = B006`。
- `scripts/ui/battle_test_scene.gd`
  - N007 普通奖励选择后，追加并进入 `B006`。
  - 新增 `predefense_failed` 结算颜色和日志。
  - B006 的 Boss 奖励文案改为答辩叙事、预答辩意见和答辩噪音。
- `scripts/battle/battle_state.gd`
  - 新增 B006 预答辩材料清单。
  - 新增条件：`has_3_paper_fragments`、`has_3_paper_fragments_or_2_reputation`。
- `scripts/run/run_settlement.gd`
  - 新增 `predefense_failed` 标题、描述和资源规则。

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
boss_count=6
encounter_count=7
has_b006=true
has_n007=true
b006_summary=博士预答辩:doctor_3:180:5:105:predefense_failed
b006_phase_condition=has_3_paper_fragments_or_2_reputation
```

路线接入验证：

```text
current_after_b005=N007
n007_reward_count=3
current_before_n007_reward=N007
select_n007_reward=true
current_after_n007_reward=B006
route_after_n007=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006,B005,N007,B006
settlement_after_n007=
```

B006 信息和结算验证：

```text
b006_materials=预答辩材料：论文碎片 3/3，声望 0/2，方法论笔记 3/3。
b006_phase_hint=阶段检查：进度达到 105 时，需要至少 3 论文碎片或 2 声望。
b006_reward_count=3
b006_reward_options=b006_defense_narrative,b006_rehearsal_routine,b006_remove_defense_noise
select_b006_reward=true
current_after_b006=B007
settlement_after_b006=
failure_reason=predefense_failed
failure_title=博士预答辩未过
failure_resources=局外资源：经验教训 +11 | 方法论笔记 +5 | 心理韧性 +2 | 论文碎片 +5 | 黑历史档案 +1
```

## 下一步

1. `B007 博士答辩` 已接入，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
2. 博士 Boss 专属奖励池已接入，B006 胜利后显示 `重排答辩叙事`、`固化答辩演练`、`清理答辩噪音`，见 [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)。
