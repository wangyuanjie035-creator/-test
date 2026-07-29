# 结算区域视觉层级 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [013_run_settlement.md](013_run_settlement.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)
- [027_boss_reward_visuals.md](027_boss_reward_visuals.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [044_b007_graduation_endings.md](044_b007_graduation_endings.md)
- [047_doctor4_revision_route.md](047_doctor4_revision_route.md)
- [050_settlement_section_layout.md](050_settlement_section_layout.md)

## 目标

阶段结算不再只是一整段测试文本，而是拆成更容易阅读的层级：

- 结局标题。
- 结局说明。
- 节点、牌组和精力状态。
- 局外资源汇总。
- 存档结果。

这样玩家能更快分辨当前是 `阶段通过`、`精力耗尽` 还是 `开题延期`，也能更直接看见“这一局留下了什么”。

## UI 结构

新增 `settlement_panel` 作为结算容器，内部包含：

| 节点 | 用途 |
| --- | --- |
| `settlement_title_label` | 显示结局标题 |
| `settlement_description_label` | 显示结局叙事说明 |
| `settlement_stats_label` | 显示节点、牌组和精力 |
| `settlement_resources_label` | 显示局外资源增量 |
| `settlement_label` | 显示局外存档结果 |

不同结局会使用不同强调色：

| outcome_id | 标题 | 强调方向 |
| --- | --- | --- |
| `route_completed` | 阶段通过 | 绿色，通过和成长 |
| `outstanding_graduation` | 优秀毕业 | 金色，高质量成果 |
| `master_graduated` | 顺利毕业 | 绿色，稳定通过 |
| `narrow_graduation` | 擦线毕业 | 黄绿色，惊险收束和复盘 |
| `outstanding_doctoral_graduation` | 优秀博士毕业 | 金色，博士线高质量终局 |
| `doctoral_graduated` | 博士毕业 | 青绿色，博士线终局完成 |
| `delayed_doctoral_graduation` | 延毕后毕业 | 淡紫色，延毕后收束和韧性 |
| `transfer_admitted` | 转博资格确认 | 青色，博士路线入口 |
| `proposal_delayed` | 开题延期 | 暖色，延期但可复盘 |
| `midterm_warning` | 中期预警 | 紫色，材料复盘和方法调整 |
| `blind_review_failed` | 盲审未过 | 蓝色，返修地图和论文复盘 |
| `qualification_failed` | 博士资格考核未过 | 紫红色，博士线长期复盘 |
| `project_midterm_failed` | 项目中期检查未过 | 暖红色，项目管理和长期复盘 |
| `predefense_failed` | 博士预答辩未过 | 淡紫色，答辩地图和论文主线复盘 |
| `doctoral_defense_delayed` | 博士答辩延期 | 紫色，延毕压力和答辩复盘 |
| `supplementary_defense_failed` | 补答辩再延期 | 紫色，更深层延毕复盘和心理韧性 |
| `burnout` | 精力耗尽 | 红色，坏结局和警示 |

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增结算面板及多个分层标签。
  - 新增 `get_settlement_title_text()` 和 `get_settlement_resource_text()` 供验证使用。
  - `get_settlement_visible()` 改为读取 `settlement_panel.visible`。
  - 新增 `_format_settlement_stats()`、`_format_settlement_resources()` 等格式化函数。
  - 新增按结局变化的面板背景和边框颜色。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
```

开题延期面板验证：

```text
visible=true
outcome=proposal_delayed
title=开题延期
description_has_delay=true
stats=节点 5/6 | 牌组 17 张 | 精力 0/50
resources=局外资源：经验教训 +15 | 方法论笔记 +7 | 心理韧性 +1 | 黑历史档案 +1
save_label_visible=true
panel_visible=true
hand_disabled=true
```

其他结局标题验证：

```text
success_visible=true
success_title=阶段通过
success_resources=局外资源：经验教训 +3 | 方法论笔记 +2 | 论文碎片 +1
burnout_visible=true
burnout_title=精力耗尽
burnout_resources=局外资源：经验教训 +2 | 心理韧性 +2 | 黑历史档案 +1
```

## 结果说明

- 阶段通过和坏结局都能进入新的结算面板。
- 结算信息从单段文本拆成清晰层级。
- 原有结算数据和存档逻辑未改变。
- 自动化验证接口仍能读取结算是否可见、结局类型和资源。

## 下一步

1. Boss 胜利奖励视觉区分已完成，见 [027_boss_reward_visuals.md](027_boss_reward_visuals.md)。
2. `B002 中期考核` 已完成首版实现，见 [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)。
