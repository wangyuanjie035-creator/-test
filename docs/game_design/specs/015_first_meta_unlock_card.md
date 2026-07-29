# 首个真实局外解锁卡规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [014_meta_progression_save.md](014_meta_progression_save.md)
- [013_run_settlement.md](013_run_settlement.md)
- [004_godot_data_model.md](004_godot_data_model.md)

## 目标

让局外成长第一次真实影响下一局。累计经验教训达到 10 后，存档会记录 `self_care_seed`；新旅程开始时，如果检测到这个解锁，就把一张调适卡加入初始牌组。

## 解锁卡

| 字段 | 内容 |
| --- | --- |
| ID | `U001` |
| 名称 | 自我照护 |
| 类型 | skill |
| 稀有度 | unlock |
| 费用 | 0 |
| 标签 | care |
| 解锁 ID | `self_care_seed` |
| 效果 | 恢复 3 精力，本牌消耗 |

设计意图：

- 使用 `U` 前缀，避免占用 MVP 主卡表里的 `C` 系列编号。
- 它不直接提高输出，而是给玩家一次压力缓冲。
- 它对应坏结局正反馈中的“心理韧性/自我照护”方向。
- 它进入初始牌组，而不是普通奖励池，确保玩家能感知到局外成长改变了下一局。

## 规则

- `data/cards/unlock/` 存放局外解锁卡。
- `GameDataCatalog` 会加载 `unlock` 目录，让战斗状态能够识别这些卡。
- `CardDefinition` 新增 `unlock_id` 字段，用于记录卡牌对应的局外解锁。
- `U001` 的 `rarity` 为 `unlock`，不会出现在当前普通奖励三选一逻辑中。
- 新旅程开始时，测试 UI 会读取 `meta_save_path` 指向的局外存档。
- 如果存档包含 `self_care_seed`，调用 `BattleState.add_card_to_starting_deck("U001")`。
- 同一张局外解锁卡不会重复加入初始牌组。

## 实现内容

新增资源：

- `data/cards/unlock/u001_self_care_seed.tres`

更新：

- `scripts/data/card_definition.gd`
  - 新增 `unlock_id` 字段。
- `scripts/data/game_data_catalog.gd`
  - `CARD_DIRS` 新增 `res://data/cards/unlock`。
- `scripts/battle/battle_state.gd`
  - 新增 `add_card_to_starting_deck(card_id)`。
  - 加入后会重新洗当前抽牌堆。
- `scripts/ui/battle_test_scene.gd`
  - 开局读取局外存档。
  - 若有 `self_care_seed`，加入 `U001 自我照护`。
  - 新增 `has_card_in_deck(card_id)` 供验证使用。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译与数据加载验证：

```text
reload_card_definition.gd=0
reload_game_data_catalog.gd=0
reload_meta_progression_state.gd=0
reload_battle_state.gd=0
reload_battle_test_scene.gd=0
card_count=17
has_u001=true
has_c030=false
u001_name=自我照护
u001_unlock=self_care_seed
u001_rarity=unlock
```

无解锁开局验证：

```text
locked_deck_size=15
locked_has_u001=false
locked_reward_has_u001=false
```

有解锁开局验证：

```text
seed_save_err=0
unlocked_deck_size=16
unlocked_has_u001=true
unlocked_meta_unlocks=self_care_seed
played_u001=true
vitality_after_u001=48
u001_exhausted=true
```

结果说明：

- 没有 `self_care_seed` 时，新局保持 15 张初始牌组。
- 没有解锁时，`U001` 不会出现在奖励选项中。
- 存档含有 `self_care_seed` 时，新局初始牌组变为 16 张并包含 `U001`。
- `U001` 可以正常打出，能恢复精力并进入消耗堆。

## 下一步

1. 开局/局外成长预览区域已完成，见 [016_meta_carryover_preview.md](016_meta_carryover_preview.md)。
2. `self_care_seed` 的显示名称映射已完成，见 [016_meta_carryover_preview.md](016_meta_carryover_preview.md)。
3. 第二个局外解锁已完成，见 [018_second_meta_unlock_card.md](018_second_meta_unlock_card.md)。
