# N001 候选池扩展与研究问题清单 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-02

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)

## 目标

扩展开局节点 `N001 普通压力` 的奖励候选池，让第一张奖励就能更明确地服务“文献论文流”或“心态照护流”。

本轮新增 `C040 研究问题清单`，用来把早期灵感整理成方法论笔记。它不是纯进度牌，而是给后续 Boss 材料、博士线资格和论文主线提供基础资源。

## 新增卡牌

| ID | 名称 | 费用 | 标签 | 定位 | 效果 |
| --- | --- | --- | --- | --- | --- |
| `C040` | 研究问题清单 | 1 | `literature`, `inspiration`, `methodology` | 文献论文流桥接 | 若有灵感，抽 1 张牌；获得 1 灵感和 1 方法论笔记 |

升级版预留效果：

- 若有灵感，抽 2 张牌。
- 获得 1 灵感和 1 方法论笔记。

## N001 奖励池调整

| 节点 | 候选池 | 默认展示 | 设计意图 |
| --- | --- | --- | --- |
| `N001 普通压力` | `C002`, `C004`, `C021`, `C007`, `C040` | `C002`, `C004`, `C021` | 保留精读文献、整理笔记、早期照护的旧体验；用 `C007` 提前给论文成果入口，用 `C040` 补方法论沉淀 |

默认展示仍保持当前旧体验。玩家已经拿过文献/灵感牌后，`C040 研究问题清单` 会因为 `literature/inspiration` 标签命中而更容易进入三选一。

## 实现内容

新增：

- `data/cards/reward/c040_research_question_checklist.tres`

更新：

- `data/encounters/n001_ordinary_pressure.tres`

未新增效果类型；`C040` 复用现有效果：

- `draw`
- `gain_resource`
- 条件 `has_inspiration`

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/data/card_definition.gd=0
res://scripts/data/effect_definition.gd=0
res://scripts/data/encounter_definition.gd=0
```

数据和奖励权重验证：

```text
card_count=39
c040_summary=C040:研究问题清单:1:literature,inspiration,methodology
n001_pool=C002,C004,C021,C007,C040
n001_default=C002,C004,C021
n001_default_scores=C002:10|C004:10|C021:10|C007:10|C040:10
n001_literature=C002,C021,C040
n001_literature_scores=C002:14|C004:12|C021:14|C007:10|C040:14
c040_literature_tooltip=若有灵感，抽 1 张牌；获得 1 灵感和 1 方法论笔记。|流派：文献论文|推荐：已有文献、灵感相关牌|标签：文献、灵感、方法论
```

效果验证：

```text
c040_effect_no_inspiration=played=true inspiration=1 methodology=1 hand= discard=C040
c040_effect_with_inspiration=played=true inspiration=2 methodology=1 hand=C001 discard=C040
```

结果说明：

- `C040` 能正常加载，并进入总卡牌计数。
- `N001` 候选池已扩展为 5 张。
- 默认无倾向时，奖励仍展示 `C002/C004/C021`。
- 已有文献/灵感倾向时，`C040` 会被推入三选一。
- 有灵感时，`C040` 能额外抽 1 张牌。

## 下一步

1. `N004 截稿临近` 候选池扩展已完成，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
2. 观察 `C040` 是否让方法论笔记过早膨胀；如果 B004/B006 的材料门槛变得过轻，可以改为只给灵感和抽牌。
3. 后续带权随机接入后，`C040` 应保持在文献/灵感倾向时较容易出现。
