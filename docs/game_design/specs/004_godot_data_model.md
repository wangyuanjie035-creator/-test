# Godot 数据模型规格 v0.1

状态：草案，准备进入实现

创建日期：2026-05-26

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [002_mvp_boss_set.md](002_mvp_boss_set.md)
- [003_mvp_event_set.md](003_mvp_event_set.md)
- [../DECISIONS.md](../DECISIONS.md)

## 目标

Godot 原型阶段先把内容和逻辑分开：

- 卡牌、Boss、事件、状态用 Resource 数据保存。
- 战斗逻辑读取 Resource，不把具体卡牌写死在代码里。
- 数值调整尽量只改数据文件。
- 后续可以从纸面规格逐步录入为 `.tres` 资源。

## 推荐目录

```text
res://scripts/data/
  card_definition.gd
  status_definition.gd
  boss_definition.gd
  boss_intent_definition.gd
  event_definition.gd
  event_choice_definition.gd
  effect_definition.gd

res://data/cards/
  base/
  reward/
  status/
  unlock/

res://data/bosses/
res://data/events/
res://data/decks/
```

## 通用 ID 规则

| 类型 | 前缀 | 示例 |
| --- | --- | --- |
| 卡牌 | C | C001 |
| 状态牌 | S | S001 |
| Boss | B | B001 |
| 事件 | E | E001 |
| 效果 | FX | FX_GAIN_PROGRESS |
| 标签 | 小写英文 | literature, experiment, thesis |

显示名可以改，ID 不应改。存档、解锁和统计都只引用 ID。

## CardDefinition

建议脚本：`res://scripts/data/card_definition.gd`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | StringName | 稳定 ID |
| display_name | String | 显示名 |
| card_type | StringName | action, skill, thesis, equipment, cooperation, risk, status |
| rarity | StringName | starter, common, build, status |
| cost | int | 行动点费用，负数表示不可主动打出 |
| tags | PackedStringArray | 构筑标签 |
| description | String | 展示文本 |
| upgraded_description | String | 升级后展示文本 |
| effects | Array[EffectDefinition] | 普通效果 |
| upgraded_effects | Array[EffectDefinition] | 升级效果 |
| exhausts | bool | 打出后是否消耗 |
| temporary | bool | 是否仅本场战斗存在 |
| status_id_to_add | StringName | 简单状态注入可先用该字段，复杂逻辑用 effect |

## EffectDefinition

建议脚本：`res://scripts/data/effect_definition.gd`

MVP 先用通用效果资源，避免为每张牌写脚本。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| effect_type | StringName | gain_progress, gain_block, draw, gain_resource, lose_energy, add_card, discover, remove_status, modify_next_card |
| amount | int | 数值 |
| resource | StringName | inspiration, data, draft, funds, reputation, energy |
| target | StringName | self, enemy, hand, discard, deck |
| card_id | StringName | 需要添加或引用的卡牌 |
| tag_filter | StringName | 发现或修改时筛选标签 |
| condition | StringName | 简化条件，例如 has_data, played_literature_this_turn |

后续如果通用效果不够，再增加脚本化效果，但 MVP 先保持数据驱动。

## StatusDefinition

建议脚本：`res://scripts/data/status_definition.gd`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | StringName | 状态 ID |
| display_name | String | 显示名 |
| trigger | StringName | on_draw, end_turn, next_thesis, next_equipment |
| description | String | 展示文本 |
| effects | Array[EffectDefinition] | 触发效果 |
| exhaust_after_trigger | bool | 触发后是否消耗 |
| playable_cost | int | 玩家主动处理需要的费用，-1 表示不能主动打出 |

## BossDefinition

建议脚本：`res://scripts/data/boss_definition.gd`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | StringName | Boss ID |
| display_name | String | 显示名 |
| stage | StringName | master_1, master_2, master_3 |
| target_progress | int | 胜利所需进度 |
| starting_status_cards | PackedStringArray | 开局加入玩家牌组或弃牌堆的状态 |
| passive_rules | PackedStringArray | 被动规则 ID，MVP 可先用文本 |
| intents | Array[BossIntentDefinition] | 意图循环 |
| phase_trigger_progress | int | 阶段转换阈值 |
| phase_event_id | StringName | 阶段转换事件 ID，可后续实现 |
| victory_rewards | PackedStringArray | 奖励池 ID |
| failure_result | StringName | 失败结算 ID |

## BossIntentDefinition

建议脚本：`res://scripts/data/boss_intent_definition.gd`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | StringName | 意图 ID |
| display_name | String | 显示名 |
| intent_type | StringName | pressure, disrupt, check, phase |
| pressure | int | 压力伤害 |
| effects | Array[EffectDefinition] | 附加效果 |
| condition | StringName | 条件检查 |
| success_effects | Array[EffectDefinition] | 条件达成 |
| failure_effects | Array[EffectDefinition] | 条件失败 |

## EventDefinition

建议脚本：`res://scripts/data/event_definition.gd`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | StringName | 事件 ID |
| display_name | String | 显示名 |
| stage_min | StringName | 最早出现阶段 |
| stage_max | StringName | 最晚出现阶段，可空 |
| description | String | 事件正文 |
| choices | Array[EventChoiceDefinition] | 选项列表 |
| tags | PackedStringArray | event, lab, mentor, thesis |

## EventChoiceDefinition

建议脚本：`res://scripts/data/event_choice_definition.gd`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | StringName | 选项 ID |
| label | String | 选项文本 |
| requirement | StringName | 条件，例如 has_funds_2 |
| preview | String | UI 预览 |
| effects | Array[EffectDefinition] | 选项结果 |
| risk_level | int | 0 到 3，标注风险 |

## 首批实现顺序

1. 建立 Resource 脚本。
2. 录入 5 张初始牌作为 `.tres`。
3. 实现一个测试牌库加载器。
4. 实现最小战斗状态：抽牌、行动点、手牌、弃牌、进度、防护、精力。
5. 接入 B001 开题报告。
6. 再录入完整 30 张卡和剩余 Boss。

## 编辑器加载注意事项

所有需要在 Godot 编辑器、Hastur editor executor 或 `EditorScript` 中读取的 Resource 脚本都应标记 `@tool`。否则编辑器可能把 `.tres` 实例加载为 placeholder，字段可以读到，但自定义方法不可调用。

验证脚本应优先读取导出字段，例如 `deck.card_ids.size()`，不要依赖 `deck.size()` 这类 helper 方法作为唯一校验路径。编辑器热更新后如果仍显示 placeholder，可重启编辑器或重新打开项目刷新脚本类缓存。

## 验收标准

- 新增一张卡不需要改战斗主逻辑。
- 卡牌显示名、费用、标签和描述都来自 Resource。
- 初始牌组可以通过 deck 数据组装。
- 至少一个 Boss 可以通过数据配置意图循环。
- 事件选项可以通过数据配置条件和效果。

## 开放问题

- 卡牌效果是否全部数据驱动，还是允许脚本化特殊效果。
- 论文牌的投稿判定是否需要概率。
- 灵感、数据、草稿是否跨节点保留，MVP 暂定节点内清空。
- 延毕线资源是否提前进数据模型，MVP 暂缓。
