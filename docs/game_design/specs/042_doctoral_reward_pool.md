# 博士线普通奖励池 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-28

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [010_reward_selection.md](010_reward_selection.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [035_doctoral_route_entry.md](035_doctoral_route_entry.md)
- [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)

## 目标

让博士线普通节点不再复用普通奖励池，而是给出更贴合长线研究的构筑选择。

首版覆盖节点：

```text
N005 博一开题重构
N006 项目推进压力
N007 预答辩筹备
```

## 新增卡牌

| ID | 名称 | 费用 | 定位 | 效果 |
| --- | --- | --- | --- | --- |
| `C031` | 问题链重排 | 1 | 方法论沉淀 | 方法论笔记 +1，抽 1 |
| `C032` | 委员会沟通 | 1 | 声望与防护 | 声望 +1，防护 +5 |
| `C033` | 论文主线图 | 1 | 论文主线 | 进度 +5，论文碎片 +1 |
| `C034` | 项目排期表 | 0 | 项目节奏 | 防护 +4；若有 2 经费，进度 +5 |
| `C035` | 预答辩演练 | 2 | 答辩准备 | 进度 +8，声望 +1 |

这些卡的 `rarity` 统一为 `doctoral`，不会进入普通节点奖励池。

## 节点奖励池

| 节点 | 奖励三选一 |
| --- | --- |
| `N005 博一开题重构` | `C031 问题链重排`、`C032 委员会沟通`、`C033 论文主线图` |
| `N006 项目推进压力` | `C027 经费申请`、`C036 项目台账`、`C034 项目排期表` |
| `N007 预答辩筹备` | `C031 问题链重排`、`C033 论文主线图`、`C035 预答辩演练` |
| `N008 返修长夜` | `C037 返修清单`、`C033 论文主线图`、`C035 预答辩演练` |

设计意图：

- N005 偏“把课题改写成博士问题链”。
- N006 偏“项目经费、项目台账和排期压力”。
- N007 偏“论文主线和预答辩表达”。
- N008 偏“返修清单、论文主线和补答辩表达”。

## 实现内容

新增：

- `data/cards/reward/c031_problem_chain_reframe.tres`
- `data/cards/reward/c032_committee_alignment.tres`
- `data/cards/reward/c033_dissertation_spine_map.tres`
- `data/cards/reward/c034_project_timeline.tres`
- `data/cards/reward/c035_predefense_rehearsal.tres`

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `DOCTORAL_REWARD_POOLS`。
  - 新增 `_append_doctoral_reward_options()`。
  - N005/N006/N007 胜利时优先展示博士线奖励池。
  - 奖励区标题在博士线普通节点显示为“博士线节点通过”。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/run/route_state.gd=0
res://scripts/run/run_settlement.gd=0
card_count=23
doctoral_cards=C031:问题链重排:doctoral:1,C032:委员会沟通:doctoral:1,C033:论文主线图:doctoral:1,C034:项目排期表:doctoral:0,C035:预答辩演练:doctoral:2
```

路线奖励验证：

```text
current_after_transfer=N005
n005_reward_options=C031,C032,C033
current_after_n005=B004
has_c031_after_n005=true
current_after_b004=N006
n006_reward_options=C027,C036,C034
current_after_n006=E006
has_c027_after_n006=true
current_after_b005=N007
n007_reward_options=C031,C033,C035
current_after_n007=B006
route_ids=N001,N002,E004,N003,N004,B001,B002,E005,N005,B004,N006,E006,B005,N007,B006
settlement_after_n007=
```

当前奖励池已经在 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md) 中扩展：

```text
scene_reward_options=N006:C027,C036,C034|N008:C037,C033,C035
```

## 下一步

1. `B007 博士答辩` 已接入，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
2. 博士 Boss 专属奖励池已接入，覆盖 `B004`、`B005` 和 `B006`；`B007` 保持博士毕业结局选择，见 [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)。
