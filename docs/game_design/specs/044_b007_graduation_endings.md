# B007 博士毕业结局选择 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-29

关联文档：

- [013_run_settlement.md](013_run_settlement.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)
- [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)
- [047_doctor4_revision_route.md](047_doctor4_revision_route.md)

## 目标

把 `B007 博士答辩` 的胜利奖励升级为博士毕业结局选择，不再只是通用 Boss 奖励或单一博士毕业结算。

首版提供三个结局：

| 结局 | outcome_id | 条件 | 设计定位 |
| --- | --- | --- | --- |
| 优秀博士毕业 | `outstanding_doctoral_graduation` | 精力至少 20，声望至少 2，论文碎片至少 4，方法论笔记至少 4 | 高质量博士毕业，奖励最高 |
| 博士毕业 | `doctoral_graduated` | 精力至少 10，且论文碎片至少 3 或声望至少 1 | 稳定博士毕业，奖励均衡 |
| 延毕后毕业 | `delayed_doctoral_graduation` | 始终可选 | 保底博士毕业，奖励偏向延毕复盘和心理韧性 |

## 交互规则

`B007` 胜利后，Boss 奖励面板标题改为：

```text
博士毕业结局选择
```

三个结局都会显示，但未满足条件的按钮会置灰。`延毕后毕业` 始终可选，避免玩家打赢 B007 后因为资源条件不足而无法完成结算。

自动化测试接口 `select_first_reward()` 会跳过锁定结局，选择第一个可用结局。

## 结算资源

三个博士毕业结局都沿用阶段结算基础资源，并追加不同倾向：

| outcome_id | 额外资源 |
| --- | --- |
| `outstanding_doctoral_graduation` | 经验教训 +6，方法论笔记 +8，心理韧性 +2，论文碎片 +8 |
| `doctoral_graduated` | 经验教训 +5，方法论笔记 +6，心理韧性 +2，论文碎片 +6 |
| `delayed_doctoral_graduation` | 经验教训 +8，方法论笔记 +4，心理韧性 +3，论文碎片 +4 |

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 B007 结局 ID 常量。
  - `B007` 胜利后显示 `优秀博士毕业`、`博士毕业`、`延毕后毕业`。
  - `_is_boss_reward_available()` 新增 B007 结局条件判断。
  - `_get_boss_reward_settlement_reason()` 新增 B007 结局到 outcome 的映射。
  - `select_first_reward()` 会跳过锁定结局。
- `scripts/run/run_settlement.gd`
  - 新增 `outstanding_doctoral_graduation`、`delayed_doctoral_graduation` 标题、描述和资源规则。
  - 保留 `doctoral_graduated` 作为标准博士毕业结局。
- `scripts/ui/battle_test_scene.gd`
  - 新增三个博士毕业结局的结算强调色和日志文案。

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

结局选择验证：

```text
outstanding_options=b007_outstanding_doctoral_graduation,b007_doctoral_graduation,b007_delayed_doctoral_graduation
outstanding_outstanding_available=true
outstanding_outcome=outstanding_doctoral_graduation
outstanding_title=优秀博士毕业

standard_outstanding_available=false
standard_standard_available=true
standard_outcome=doctoral_graduated
standard_title=博士毕业

delayed_outstanding_available=false
delayed_standard_available=false
delayed_delayed_available=true
delayed_outcome=delayed_doctoral_graduation
delayed_title=延毕后毕业
```

## 下一步

1. 博士 Boss 专属奖励池已接入，覆盖 B004 到 B006；B007 保持本文件定义的毕业结局选择，见 [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)。
2. E007 博四返修会已接入，并继续通向 `N008 返修长夜` 与 `B008 补答辩`，见 [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md) 与 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。
