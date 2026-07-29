# 142 携带物专属选项

## 目标

承接 [141_carry_item_interaction_triggers.md](141_carry_item_interaction_triggers.md)，让携带物在学术交流、事件和 Boss 点位中表现为“现场多一种处理方式”，而不只是额外资源。

本页记录的是 `携带选项` 的自动触发第一版；后续已升级为可点击选择面板，见 [143_carry_choice_panel.md](143_carry_choice_panel.md)。

第一版规则：

- 资源点继续使用 `携带物触发`。
- 非资源点使用 `携带选项`。
- 携带选项根据点位内容标签匹配。
- 同一件携带物在同一互动点只结算一次。
- 结算发生在进入战斗前，所得资源可以带入本场卡牌战斗。
- 聚焦信息卡会提前显示本点位可用的携带选项。

## 专属选项

| 携带物 | 专属选项 | 匹配点位 | 当前收益 | 设计目的 |
| --- | --- | --- | --- | --- |
| `笔记本电脑` | 现场补写记录 | 数据 / 草稿 / 写作 / 方法 | 方法论笔记 +1 | 把临场信息转成可复用笔记 |
| `实验耗材包` | 用耗材兜底误差 | 实验室 / 设备 / 数据 | 数据 +1 | 让实验路线更稳定 |
| `正装外套` | 稳住正式场合 | 会议 / 导师 / 委员会 / 行政 / 声望 | 声望 +1 | 让正式交流有准备价值 |
| `咖啡零食` | 补充状态再继续 | 照护 / 灵感 / 食堂 / 恢复 | 灵感 +1 | 把恢复行为接进探索风险 |
| `导师批注稿` | 按批注重排材料 | 导师 / 草稿 / 写作 / 返修 | 草稿 +1 | 让导师反馈变成现场分支 |
| `同门联络表` | 先问同门借经验 | 同门 / 合作 / 社交 | 经验教训 +1 | 强化协作与情性成长路线 |

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 携带物定义新增 `option_label`、`option_resource`、`option_amount`、`option_summary`。
  - 新增 `safehouse_used_carry_option_keys`，防止重复结算。
  - 新增 `_apply_safehouse_carry_options_for_interactable()`。
  - 新增 `_format_safehouse_carry_option_hint()`。
  - 新增 `get_safehouse_carry_option_hint_for_interaction(interaction_id)`。
  - `_start_interaction()` 对非资源点改为结算携带选项。
  - 聚焦信息卡新增 `携带选项：...` 行。
  - 住屋携带物按钮 tooltip 显示资源点触发与非资源点专属选项。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
resource_id=peer_literature_swap
resource_trigger_hint=笔记本电脑：草稿 +1
resource_option_hint=
option_id=master1_advisor_direction_card
option_trigger_hint=
option_hint=笔记本电脑「现场补写记录」：方法论笔记 +1 / 正装外套「稳住正式场合」：声望 +1
draft_before=0
method_notes_before=0
reputation_before=0
resource_started=true
draft_after_resource=1
method_notes_after_resource=0
reputation_after_resource=0
option_started=true
draft_after_option=1
method_notes_after_option=1
reputation_after_option=1
mode_after_option=battle
```

验证含义：

- 资源点只显示 `携带物触发`，不会显示专属选项。
- 非资源点只显示 `携带选项`，不会显示资源点触发。
- 非资源点进入战斗前已结算携带选项，资源可以带入战斗。

## 手测重点

1. 在住屋选择 `笔记本电脑` 和 `正装外套`。
2. 出门后靠近资源点，应看到 `携带：...`，不应看到 `携带选项：...`。
3. 靠近导师、会议、写作或行政点，应看到 `携带选项：...`。
4. 触发非资源点后进入战斗，战斗前随身资源应已经增加。

## 下一步

1. 携带选项可点击面板已在 [143_carry_choice_panel.md](143_carry_choice_panel.md) 中完成第一版。
2. 让不同选项可带来“少损失、改路线、跳过门槛、改变敌人意图”等非资源效果。
3. 后续接入携带物图标、耐久、消耗和升级。
