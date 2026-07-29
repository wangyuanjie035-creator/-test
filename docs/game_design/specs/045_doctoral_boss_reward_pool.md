# 博士 Boss 专属奖励池 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-29

关联文档：

- [002_mvp_boss_set.md](002_mvp_boss_set.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)
- [039_b005_project_midterm.md](039_b005_project_midterm.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [044_b007_graduation_endings.md](044_b007_graduation_endings.md)
- [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)
- [047_doctor4_revision_route.md](047_doctor4_revision_route.md)

## 目标

让博士线 Boss 胜利奖励不再复用 `boss_direction`、`boss_feedback`、`boss_remove_status` 三个通用奖励 ID，而是按博士阶段主题给出真正不同的资源、卡牌和净化选项。

首版覆盖：

```text
B004 博士资格考核 -> 专属奖励 -> N006 项目推进压力
B005 项目中期检查 -> 专属奖励 -> N007 预答辩筹备
B006 博士预答辩 -> 专属奖励 -> B007 博士答辩
```

`B007 博士答辩` 已升级为博士毕业结局选择，见 [044_b007_graduation_endings.md](044_b007_graduation_endings.md)，不再进入本通用 Boss 奖励池。

## 奖励池

| Boss | reward_id | 显示名称 | 类型 | 效果 |
| --- | --- | --- | --- | --- |
| `B004` | `b004_problem_chain` | 确定博士问题链 | 局外资源 | 方法论笔记 +2，论文碎片 +1 |
| `B004` | `b004_committee_bridge` | 建立委员会沟通 | 牌组构筑 | 获得 1 张 `C032 委员会沟通`；若添加失败，改为声望 +1 |
| `B004` | `b004_remove_qualification_noise` | 删去资格焦虑 | 牌组净化 | 优先移除自我怀疑、焦虑、信息过载、拖延或恍惚；若无可移除牌，改为方法论笔记 +1 |
| `B005` | `b005_project_ledger` | 项目台账归档 | 局内/局外资源 | 经费 +1，方法论笔记 +1，论文碎片 +1 |
| `B005` | `b005_timeline_protocol` | 固化项目排期 | 牌组构筑 | 获得 1 张 `C034 项目排期表`；若添加失败，改为方法论笔记 +1 |
| `B005` | `b005_remove_project_noise` | 清理项目噪音 | 牌组净化 | 优先移除信息过载、恍惚、焦虑、拖延或自我怀疑；若无可移除牌，改为方法论笔记 +1 |
| `B006` | `b006_defense_narrative` | 重排答辩叙事 | 局外资源 | 论文碎片 +2，方法论笔记 +1 |
| `B006` | `b006_rehearsal_routine` | 固化答辩演练 | 牌组构筑 | 获得 1 张 `C035 预答辩演练`；若添加失败，改为声望 +1 |
| `B006` | `b006_remove_defense_noise` | 清理答辩噪音 | 牌组净化 | 优先移除自我怀疑、信息过载、焦虑、拖延或恍惚；若无可移除牌，改为方法论笔记 +1 |

## 设计意图

- B004 偏“资格考核后确认博士问题链”，奖励更重方法论、论文碎片和委员会关系。
- B005 偏“项目管理和资源管线”，奖励把经费、排期和项目噪音处理放到同一组选择里。
- B006 偏“答辩叙事定型”，奖励把论文碎片、预答辩演练和答辩噪音管理推到终局前。
- 三个 Boss 都保留一个净化选项，保证坏牌较多的构筑仍能获得明确正反馈。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `B004_REWARD_*`、`B005_REWARD_*`、`B006_REWARD_*` 常量。
  - `_get_current_boss_reward_options()` 为 B004/B005/B006 返回专属 reward id。
  - `_select_boss_reward()` 为专属奖励接入资源、加卡和净化效果。
  - `_format_boss_reward_button_text()`、`_format_boss_reward_tooltip()`、`_get_boss_reward_result_label()` 接入专属文案。
  - `_get_boss_reward_accent_color()` 为资源、构筑和净化奖励提供不同强调色。
  - B004/B005/B006 选择奖励后仍沿用博士线推进逻辑：`B004 -> N006`、`B005 -> N007`、`B006 -> B007`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/route_state.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/run/run_settlement.gd=0
```

奖励池和路线验证：

```text
reload_err=0
b004_options=b004_problem_chain,b004_committee_bridge,b004_remove_qualification_noise
b004_selected=true
b004_methodology=2
b004_paper=1
b004_current=N006
b004_settlement=

b005_options=b005_project_ledger,b005_timeline_protocol,b005_remove_project_noise
b005_selected=true
b005_c034_before=0
b005_c034_after=1
b005_current=N007
b005_settlement=

b006_options=b006_defense_narrative,b006_rehearsal_routine,b006_remove_defense_noise
b006_selected=true
b006_c035_before=0
b006_c035_after=1
b006_current=B007
b006_is_boss=true
b006_settlement=
```

按钮文案验证：

```text
b004_labels=确定博士问题链 | 局外资源 | 方法论笔记 +2，论文碎片 +1 || 建立委员会沟通 | 牌组构筑 | 获得 1 张委员会沟通 || 删去资格焦虑 | 牌组净化 | 移除 1 张自我怀疑或焦虑或信息过载或拖延或恍惚
b005_labels=项目台账归档 | 局内/局外资源 | 经费 +1，方法论笔记 +1，论文碎片 +1 || 固化项目排期 | 牌组构筑 | 获得 1 张项目排期表 || 清理项目噪音 | 牌组净化 | 移除 1 张信息过载或恍惚或焦虑或拖延或自我怀疑
b006_labels=重排答辩叙事 | 局外资源 | 论文碎片 +2，方法论笔记 +1 || 固化答辩演练 | 牌组构筑 | 获得 1 张预答辩演练 || 清理答辩噪音 | 牌组净化 | 移除 1 张自我怀疑或信息过载或焦虑或拖延或恍惚
```

## 下一步

1. E007 博四返修会已接入，并继续通向 `N008 返修长夜` 与 `B008 补答辩`，见 [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md) 与 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。
2. 后续可为部分博士 Boss 奖励增加条件增强，例如高声望时强化委员会相关奖励、高经费时强化项目相关奖励。
