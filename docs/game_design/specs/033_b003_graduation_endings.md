# B003 毕业结局选择 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [013_run_settlement.md](013_run_settlement.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)
- [034_transfer_application_event.md](034_transfer_application_event.md)

## 目标

把 `B003 盲审专家` 的胜利奖励升级为毕业结局选择，不再只显示通用 Boss 奖励。

首版提供三个结局：

| 结局 | outcome_id | 条件 | 设计定位 |
| --- | --- | --- | --- |
| 优秀毕业 | `outstanding_graduation` | 精力至少 20，且声望至少 2 | 高质量通过，给更多论文和方法资源 |
| 顺利毕业 | `master_graduated` | 精力至少 10，且声望至少 1 或草稿至少 4 | 稳定通过，给均衡成长 |
| 擦线毕业 | `narrow_graduation` | 始终可选 | 保底成功，资源更偏向经验教训和心理韧性 |

## 交互规则

`B003` 胜利后，Boss 奖励面板标题改为：

```text
毕业结局选择
```

三个结局都会显示，但未满足条件的按钮会置灰。`擦线毕业` 始终可选，避免玩家打赢 B003 后因为条件不足而无法结算。

自动化测试接口 `select_first_reward()` 会跳过锁定结局，选择第一个可用结局。

## 结算资源

三个结局都沿用阶段结算基础资源，并追加不同倾向：

| outcome_id | 额外资源 |
| --- | --- |
| `outstanding_graduation` | 经验教训 +3，方法论笔记 +4，论文碎片 +4 |
| `master_graduated` | 经验教训 +2，方法论笔记 +3，论文碎片 +3 |
| `narrow_graduation` | 经验教训 +4，方法论笔记 +1，心理韧性 +1，论文碎片 +1 |

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 B003 结局 ID 常量。
  - `B003` 胜利后显示 `优秀毕业`、`顺利毕业`、`擦线毕业`。
  - 新增 `_is_boss_reward_available()`，用于结局条件判断。
  - 新增 `_get_boss_reward_settlement_reason()`，把结局按钮映射到结算 outcome。
  - `select_first_reward()` 会跳过锁定结局。
- `scripts/run/run_settlement.gd`
  - 新增 `outstanding_graduation`、`master_graduated`、`narrow_graduation` 标题、描述和资源规则。
- `scripts/ui/battle_test_scene.gd`
  - 新增三个毕业结局的结算强调色。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/run_settlement.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/run/route_state.gd=0
res://scripts/data/game_data_catalog.gd=0
```

三结局验证：

```text
outstanding_options=b003_outstanding_graduation,b003_standard_graduation,b003_narrow_graduation
outstanding_available=true
outstanding_selected=true
outstanding_outcome=outstanding_graduation
outstanding_title=优秀毕业

standard_outstanding_available=false
standard_available=true
standard_selected=true
standard_outcome=master_graduated
standard_title=顺利毕业

narrow_outstanding_available=false
narrow_standard_available=false
narrow_available=true
narrow_selected=true
narrow_outcome=narrow_graduation
narrow_title=擦线毕业
```

锁定结局验证：

```text
locked_outstanding_selected=false
locked_settlement=
locked_reward_taken=false
```

自动选择验证：

```text
battle_test_scene_reload=0
select_first_result=true
select_first_outcome=narrow_graduation
select_first_title=擦线毕业
```

## 结果说明

- B003 胜利后已经从通用 Boss 奖励升级为毕业结局选择。
- 高条件结局会锁定，保底结局始终可选。
- 三个结局拥有独立 outcome、标题、叙事说明和资源倾向。
- 当前不转博硕士毕业线已经有完整结尾。

## 下一步

1. `E005 转博申请` 已完成首版接入，见 [034_transfer_application_event.md](034_transfer_application_event.md)。
2. 后续可把 B003 结局条件显示得更清楚，例如在按钮上展示当前精力、声望和草稿差距。
