# 博四短路线：返修长夜与补答辩 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-29

关联文档：

- [013_run_settlement.md](013_run_settlement.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)
- [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)

## 目标

把 `B007 博士答辩` 失败后的延毕内容从单个事件扩成一个最小可玩短路线：

```text
B007 博士答辩失败
  -> E007 博四返修会
  -> N008 返修长夜
  -> B008 补答辩
  -> 延毕后毕业 / 补答辩再延期
```

这条路线表达“延毕不是等级上限之外的空白，而是一次高压返修章节”。玩家失败后仍然能选择返修方向、打一段普通节点、再面对一次补答辩 Boss。

## 新增节点

| id | 名称 | 类型 | 阶段 | 目标进度 | 压力 | 设计定位 |
| --- | --- | --- | --- | --- | --- | --- |
| `N008` | 返修长夜 | 普通节点 | `doctor_4` | 62 | 8 | 答辩延期后的低精力返修节点 |
| `B008` | 补答辩 | Boss | `doctor_4` | 150 | 意图循环 | 延毕短路线终局 Boss |

N008 使用博士线普通奖励池：

```text
C031 问题链重排
C033 论文主线图
C035 预答辩演练
```

当前版本已把 N008 奖励池调整为返修线：

```text
C037 返修清单
C033 论文主线图
C035 预答辩演练
```

## B008 胜利收束

`B008 补答辩` 胜利后显示三个收束选项，全部进入 `delayed_doctoral_graduation`，但沉淀的资源不同：

| reward_id | 显示名称 | 效果 |
| --- | --- | --- |
| `b008_supplementary_pass` | 补答辩通过 | 论文碎片 +2，方法论笔记 +2 |
| `b008_revision_archive` | 归档返修矩阵 | 经验教训 +3，方法论笔记 +3 |
| `b008_rehearsal_legacy` | 带走补答辩演练 | 获得 1 张 `C035 预答辩演练`；若添加失败，改为声望 +1 |

## B008 失败结算

如果 `B008` 中精力归零，进入新坏结局：

| outcome_id | 标题 | 定位 |
| --- | --- | --- |
| `supplementary_defense_failed` | 补答辩再延期 | 比博士答辩延期更深一层的延毕复盘 |

资源倾向：

```text
经验教训 +12
方法论笔记 +6
心理韧性 +4
论文碎片 +5
黑历史档案 +1
若 B008 进度达到一半，论文碎片额外 +1
```

额外局外正反馈：

- `supplementary_defense_failed` 会解锁 `revision_matrix_seed`。
- 新局带入 `U003 返修矩阵`，获得 6 进度和 1 方法论笔记，本牌消耗。
- 详细规格见 [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)。

## 实现内容

新增：

- `data/encounters/n008_revision_night.tres`
- `data/bosses/b008_supplementary_defense.tres`

更新：

- `data/events/e007_doctoral_delay_repair.tres`
  - 三个选项都恢复精力，确保后续 N008 不会以 0 精力开场。
  - `整理返修矩阵` 恢复 10 精力。
  - `组织补答辩演练` 恢复 8 精力。
  - `先保住人再改稿` 恢复 14 精力。
- `scripts/run/route_state.gd`
  - 新增 `POST_DELAY_REPAIR_ENCOUNTER = N008`。
  - 新增 `POST_SUPPLEMENTARY_DEFENSE_BOSS = B008`。
- `scripts/ui/battle_test_scene.gd`
  - E007 选项选择后优先进入 `N008`；如果 N008 缺失，兜底进入 `doctoral_defense_delayed`。
  - N008 普通奖励选择后进入 `B008`。
  - B008 胜利后显示三个延毕后毕业收束选项。
  - 结局型 Boss 奖励现在会直接结算，不再受默认路线候选列影响。
  - 新增 `supplementary_defense_failed` 的结算颜色和日志。
- `scripts/battle/battle_state.gd`
  - 新增 B008 补答辩材料清单。
  - 新增 `has_1_reputation` 条件。
  - 新增阶段检查名称 `补答辩材料复核`。
- `scripts/run/run_settlement.gd`
  - 新增 `supplementary_defense_failed` 标题、描述和资源规则。

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
has_e007=true
has_n008=true
has_b008=true
n008_summary=返修长夜:doctor_4:62:8
b008_summary=补答辩:doctor_4:150:5:85:supplementary_defense_failed
```

短路线验证：

```text
after_b007_failure_current=E007
after_b007_failure_event=E007
after_b007_failure_settlement=
selected_e007=true
after_e007_current=N008
after_e007_vitality=10
after_e007_methodology=5
after_e007_paper=5
after_e007_settlement=
n008_reward_options=C037,C033,C035
selected_n008=true
after_n008_current=B008
after_n008_is_boss=true
after_n008_settlement=
b008_reward_options=b008_supplementary_pass,b008_revision_archive,b008_rehearsal_legacy
selected_b008=true
b008_settlement=delayed_doctoral_graduation
b008_title=延毕后毕业
b008_route=B007,E007,N008,B008
```

B008 失败验证：

```text
b008_failure_outcome=supplementary_defense_failed
b008_failure_title=补答辩再延期
b008_failure_resilience=4
```

## 下一步

1. `supplementary_defense_failed` 专属局外解锁已完成，见 [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)。
2. 后续可以给博四路线增加第二个普通节点或分支，例如“返修实验补样”和“委员会单独沟通”。
