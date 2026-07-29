# N004 候选池扩展与截稿后复盘 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-02

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)

## 目标

扩展 `N004 截稿临近` 的奖励候选池，让 DDL 爆发流不只提供“短期硬冲”，也能在后续奖励中获得后遗症处理和论文材料沉淀。

本轮新增 `C041 截稿后复盘`。它承接 `C018 通宵赶稿` 的副作用：一方面删除牌组中的 1 张负面牌，另一方面在已有草稿时沉淀为 `paper_fragments`，把冲刺后的混乱转化为毕业材料。

## 新增卡牌

| ID | 名称 | 费用 | 标签 | 定位 | 效果 |
| --- | --- | --- | --- | --- | --- |
| `C041` | 截稿后复盘 | 1 | `rush`, `care`, `paper`, `draft` | DDL 后遗症处理 / 论文转化 | 获得 5 防护；移除牌组中 1 张负面牌；若有 2 草稿，获得 1 论文碎片 |

升级版预留效果：

- 获得 7 防护。
- 移除牌组中 1 张负面牌。
- 若有草稿，获得 1 论文碎片。
- 若有 2 草稿，获得 3 进度。

## N004 奖励池调整

| 节点 | 候选池 | 默认展示 | 设计意图 |
| --- | --- | --- | --- |
| `N004 截稿临近` | `C018`, `C019`, `C007`, `C021`, `C041` | `C018`, `C019`, `C007` | 保留 DDL 爆发和润色摘要的旧体验；用 `C021` 补截稿后的精力恢复，用 `C041` 补负面清理和论文碎片沉淀 |

默认展示仍保持旧体验。玩家已经拿过 DDL 爆发牌后，`C041 截稿后复盘` 会因为 `rush/draft` 标签命中而更容易进入三选一。

## 实现内容

新增：

- `data/cards/reward/c041_deadline_retrospective.tres`

更新：

- `data/encounters/n004_deadline_near.tres`
- `scripts/battle/battle_state.gd`

`C041` 复用现有效果：

- `gain_block`
- `gain_resource`
- `remove_status_by_tag`
- 条件 `has_2_draft`

同时补强了 `remove_status` / `remove_status_by_tag` 的 `target = deck` 语义：当目标是 `deck` 时，会从运行牌组和当前各牌堆中删除对应负面牌。这让 `截稿后复盘` 能真正处理 `通宵赶稿` 加入牌组的 `S005 恍惚`，而不只是临时清理弃牌堆。

## 设计取舍

`C041` 带 `rush` 和 `care`，因此按钮流派显示为 `DDL 爆发 / 心态照护`。它仍然带 `paper/draft` 标签，用于权重和条件协同，但不会在按钮上额外挤出第三个流派。

首版没有让 `C041` 消耗草稿资源，因为当前战斗系统还没有“支付资源作为卡牌费用”的统一机制。它先用 `has_2_draft` 表示“已有足够草稿可供复盘整理”。如果后续发现论文碎片来得太早，可以把条件提高到 `has_3_draft` 或改为只给方法论笔记。

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
card_count=40
c041_summary=C041:截稿后复盘:1:rush,care,paper,draft
n004_pool=C018,C019,C007,C021,C041
n004_default=C018,C019,C007
n004_default_scores=C018:10|C019:10|C007:10|C021:10|C041:10
n004_rush=C018,C019,C041
n004_rush_scores=C018:20|C019:18|C007:12|C021:10|C041:16
c041_rush_tooltip=获得 5 防护；移除牌组中 1 张负面牌；若有 2 草稿，获得 1 论文碎片。|流派：DDL 爆发 / 心态照护|推荐：已有冲刺、草稿相关牌|标签：冲刺、照护、论文、草稿
```

效果验证：

```text
c041_effect_with_draft_status=played=true block=5 paper=1 deck_has_s005=false discard=C041 exhaust=
```

结果说明：

- `C041` 能正常加载，并进入总卡牌计数。
- `N004` 候选池已扩展为 5 张。
- 默认无倾向时，奖励仍展示 `C018/C019/C007`。
- 已有 DDL 倾向时，`C041` 会被推入三选一。
- `C041` 能删除牌组中的 `S005 恍惚`，并在有 2 草稿时获得 1 论文碎片。

## 下一步

1. 观察 `C041` 的牌组净化是否过强；如果 DDL 风险被抵消得太快，可以改为只清当前牌堆，或提高到升级后才清牌组。
2. 观察 `paper_fragments` 是否过早膨胀；如果 B003/B004 条件被明显放轻，可以把论文碎片改为方法论笔记。
3. 普通节点 `N001/N002/N003/N004` 都已具备 5 张候选池，带权随机奖励选择已完成，见 [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)。
