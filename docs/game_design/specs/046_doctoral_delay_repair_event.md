# E007 博四返修会 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-29

关联文档：

- [013_run_settlement.md](013_run_settlement.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [044_b007_graduation_endings.md](044_b007_graduation_endings.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)
- [047_doctor4_revision_route.md](047_doctor4_revision_route.md)
- [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)

## 目标

让 `B007 博士答辩` 失败后不再立刻进入纯结算，而是先进入一次 `E007 博四返修会`。玩家在延毕压力下选择一条返修方向，再进入博四短路线。

首版路线：

```text
B007 博士答辩
  -> 精力归零
  -> E007 博四返修会
  -> N008 返修长夜
  -> B008 补答辩
  -> 延毕后毕业 / 补答辩再延期
```

这条路线仍然是坏结局，不改写失败事实；它的作用是把失败现场转化为一次明确的正反馈选择。

## E007 事件选项

| 选项 | 条件 | 效果 | 设计定位 |
| --- | --- | --- | --- |
| 整理返修矩阵 | 无 | 恢复 10 精力，方法论笔记 +3，论文碎片 +2，获得 1 张 `C033 论文主线图` | 把委员会意见整理成下一轮论文主线 |
| 组织补答辩演练 | 需要 1 声望 | 恢复 8 精力，论文碎片 +1，方法论笔记 +1，获得 1 张 `C035 预答辩演练` | 走委员会沟通和表达修复路线 |
| 先保住人再改稿 | 无 | 恢复 14 精力，经验教训 +4，方法论笔记 +1 | 先恢复状态，把延毕压力沉淀成韧性 |

## 实现内容

新增：

- `data/events/e007_doctoral_delay_repair.tres`

更新：

- `scripts/run/route_state.gd`
  - 新增 `POST_DOCTORAL_DELAY_REPAIR_EVENT = E007`。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `_handle_vitality_depleted()`。
  - 新增 `_advance_to_doctoral_delay_repair_event()`。
  - `B007` 精力归零时先追加并进入 `E007`，如果事件数据缺失则保留原有 `doctoral_defense_delayed` 结算兜底。
  - `E007` 事件选项选择后优先进入 `N008 返修长夜`。
  - 如果 N008 数据缺失，保留 `doctoral_defense_delayed` 结算兜底。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/route_state.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/run/run_settlement.gd=0
res://scripts/data/game_data_catalog.gd=0
event_count=5
has_e007=true
e007_name=博四返修会
e007_choices=3
```

B007 失败转接验证：

```text
reload_err=0
after_failure_current=E007
after_failure_active_event=E007
after_failure_route=B007,E007
after_failure_settlement=
e007_choice_count=3
e007_first_available=true
selected_e007=true
after_e007_current=N008
after_e007_vitality=10
after_e007_methodology=5
after_e007_paper=5
after_e007_settlement=
```

## 下一步

1. 博四短路线已接入，见 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。
2. `补答辩再延期` 专属局外解锁已接入，见 [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)。
