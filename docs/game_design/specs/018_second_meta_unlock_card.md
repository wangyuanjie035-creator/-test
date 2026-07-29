# 第二个局外解锁卡规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [014_meta_progression_save.md](014_meta_progression_save.md)
- [015_first_meta_unlock_card.md](015_first_meta_unlock_card.md)
- [016_meta_carryover_preview.md](016_meta_carryover_preview.md)
- [019_event_nodes_in_route.md](019_event_nodes_in_route.md)

## 目标

让 `paper_fragments` 也产生真实用途。玩家完成路线或在事件中转化论文挫折时会获得论文碎片，下一局可以因此带入一张论文向卡牌，形成“论文成果 -> 下一局论文能力”的局外成长闭环。

## 解锁规则

| 解锁 ID | 条件 | 解锁卡 |
| --- | --- | --- |
| `revision_strategy_seed` | 累计论文碎片达到 1 | `U002 返修策略` |

## 解锁卡

| 字段 | 内容 |
| --- | --- |
| ID | `U002` |
| 名称 | 返修策略 |
| 类型 | action |
| 稀有度 | unlock |
| 费用 | 1 |
| 标签 | paper, draft |
| 解锁 ID | `revision_strategy_seed` |
| 效果 | 获得 5 进度和 1 草稿 |

设计意图：

- `U002` 是论文向局外成长，不直接回复精力，而是帮助推进论文/汇报目标。
- 它与现有草稿资源联动，为后续论文卡组提供起点。
- 它使用 `U` 前缀，避免占用 MVP 主卡表里的 `C` 系列编号。

## 实现内容

新增资源：

- `data/cards/unlock/u002_revision_strategy_seed.tres`

更新：

- `scripts/run/meta_progression_state.gd`
  - 新增 `UNLOCK_REVISION_STRATEGY_SEED`。
  - `paper_fragments >= 1` 时解锁 `revision_strategy_seed`。
  - 解锁显示名映射为“返修策略种子”。
  - 新解锁摘要改为显示可读名称。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `REVISION_STRATEGY_UNLOCK_ID` 和 `REVISION_STRATEGY_CARD_ID`。
  - 开局带入逻辑支持多张局外解锁卡。
  - 局外预览可显示“自我照护、返修策略”。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据加载验证：

```text
reload_meta_progression_state.gd=0
reload_battle_test_scene.gd=0
reload_game_data_catalog.gd=0
card_count=18
has_u001=true
has_u002=true
u002_name=返修策略
u002_unlock=revision_strategy_seed
u002_rarity=unlock
```

论文碎片解锁验证：

```text
paper_unlocks=revision_strategy_seed
paper_new_unlocks=revision_strategy_seed
paper_summary=累计局外资源：经验教训 0，方法论笔记 0，心理韧性 0，论文碎片 1，黑历史档案 0。
累计结算次数：1。
新解锁：返修策略种子。
paper_preview=局外带入：返修策略 | 累计结算 1 次 | 经验教训 0 | 心理韧性 0
paper_carried=U002
paper_deck_size=16
paper_has_u001=false
paper_has_u002=true
```

卡牌效果验证：

```text
played_u002=true
progress_after_u002=5
draft_after_u002=1
u002_discarded=true
```

多解锁带入验证：

```text
both_save_err=0
both_preview=局外带入：自我照护、返修策略 | 累计结算 0 次 | 经验教训 10 | 心理韧性 0
both_carried=U001,U002
both_deck_size=17
both_has_u001=true
both_has_u002=true
```

结果说明：

- `paper_fragments >= 1` 会解锁 `revision_strategy_seed`。
- 只有论文碎片解锁时，新局只带入 `U002`，不会错误带入 `U001`。
- `U002` 能正常打出，并给 5 进度和 1 草稿。
- 同时拥有两个解锁时，新局会带入 `U001` 和 `U002` 两张卡。

## 下一步

1. 做一个独立结算界面，让局外资源、新解锁和下一局带入更清楚。
2. 把测试工具与正式 UI 分离，避免后续发布版本露出开发按钮。
3. 事件节点已开始产出局外资源倾向，见 [019_event_nodes_in_route.md](019_event_nodes_in_route.md)。
