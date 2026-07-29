# 项目与返修流派卡实现 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [054_card_tag_audit.md](054_card_tag_audit.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)

## 目标

在第一批 `equipment`、`mentor`、`rush/risk` 卡之后，继续补齐两个仍然偏薄的构筑方向：

- `project` / `funds`：项目经费流。
- `revision` / `delay`：返修延毕流。

本次继续不新增底层效果类型，只用现有卡牌效果系统完成。

## 新增卡牌

| ID | 名称 | 费用 | 标签 | 定位 | 效果 |
| --- | --- | --- | --- | --- | --- |
| `C027` | 经费申请 | 1 | `project`, `funds`, `risk` | 项目经费流入口 | 获得 2 经费和 3 防护；将 1 张拖延加入牌组 |
| `C036` | 项目台账 | 1 | `project`, `funds`, `methodology` | 项目资源转化 | 获得 1 方法论笔记和 4 防护；若有至少 2 经费，获得 1 论文碎片 |
| `C037` | 返修清单 | 1 | `revision`, `paper`, `delay`, `methodology` | 返修延毕流 | 移除手牌中 1 张拖延；获得 4 进度、1 草稿和 1 方法论笔记 |

## 奖励池调整

| 节点 | 奖励池 | 设计意图 |
| --- | --- | --- |
| `N001 普通压力` | `C002`, `C004`, `C021`, `C007`, `C040` | 文献、笔记、早期照护、论文成果和研究问题沉淀 |
| `N002 周会压力` | `C024`, `C025`, `C027`, `C021`, `C039` | 导师人脉、项目经费、照护恢复和会后反馈沉淀 |
| `N006 项目推进压力` | `C027`, `C036`, `C034` | 经费申请、项目台账、项目排期 |
| `N008 返修长夜` | `C037`, `C033`, `C035` | 返修清单、论文主线和补答辩表达 |

`N003 设备排队` 后续在 [059_experiment_noise_cards.md](059_experiment_noise_cards.md)、[061_negative_result_conversion_card.md](061_negative_result_conversion_card.md) 和 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md) 中扩展为 `C012/C014/C015/C028/C038`，并在 [063_weighted_reward_selection.md](063_weighted_reward_selection.md) 中按构筑倾向裁剪为三选一；`N002 周会压力` 又在 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md) 中扩展为 `C024/C025/C027/C021/C039`；`N001 普通压力` 又在 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md) 中扩展为 `C002/C004/C021/C007/C040`；`N004 截稿临近` 又在 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md) 中扩展为 `C018/C019/C007/C021/C041`。

## 实现内容

新增：

- `data/cards/reward/c027_funding_application.tres`
- `data/cards/reward/c036_project_ledger.tres`
- `data/cards/reward/c037_revision_checklist.tres`

更新：

- `data/encounters/n001_ordinary_pressure.tres`
- `data/encounters/n002_weekly_meeting.tres`
- `scripts/ui/battle_test_scene.gd`
  - `DOCTORAL_REWARD_POOLS["N006"]` 改为 `C027/C036/C034`。
  - `DOCTORAL_REWARD_POOLS["N008"]` 改为 `C037/C033/C035`。

## 设计取舍

`C027 经费申请` 用 `S001 拖延` 表示行政流程和申请周期的副作用。后续如果补 `行政杂务` 状态牌，可以再替换成更精确的负面牌。

`C037 返修清单` 目前只处理手牌中的 `拖延`。这是最小可用版本，先证明 `revision + delay` 的互动成立；后续再扩展到 `焦虑`、`自我怀疑` 或真正的 `返修` 状态牌。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/data/card_definition.gd=0
res://scripts/data/effect_definition.gd=0
res://scripts/data/encounter_definition.gd=0
res://scripts/data/deck_definition.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/run/route_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

数据加载验证：

```text
card_count=32
new_cards=C027:经费申请:common:1:project,funds,risk|C036:项目台账:common:1:project,funds,methodology|C037:返修清单:common:1:revision,paper,delay,methodology
missing_new_cards=
```

效果验证：

```text
C027_funds=2_block=3_hasS001=true
C036_methodology=1_paper=1_block=4
C037_progress=4_draft=1_methodology=1_removedS001=true
```

奖励展示验证：

> 下方输出保留本文首版实现时的历史值；当前 `N001` 已在 [066](./066_n001_reward_pool_expansion.md) 扩展，`N002` 已在 [065](./065_node_reward_pool_expansion.md) 扩展，`N004` 已在 [067](./067_n004_reward_pool_expansion.md) 扩展。

```text
n001_rewards=C002,C004,C021
n002_rewards=C024,C025,C027
scene_reward_options=N001:C002,C004,C021|N002:C024,C025,C027|N006:C027,C036,C034|N008:C037,C033,C035
```

## 下一步

1. 奖励按钮已增加标签/流派提示，见 [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)。
2. 实验负面处理卡已完成，见 [059_experiment_noise_cards.md](059_experiment_noise_cards.md)。
3. 实验噪音转化卡已完成，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
4. 设备维护记录已完成，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
5. 同流派奖励权重已完成，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
6. `N002` 候选池扩展和 `会后纪要` 已完成，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
7. `N001` 候选池扩展和 `研究问题清单` 已完成，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
8. `N004` 候选池扩展和 `截稿后复盘` 已完成，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
