# 141 携带物具体互动触发

## 目标

承接 [140_safehouse_carry_slots.md](140_safehouse_carry_slots.md)，让携带物不只影响地图生成，还能在实际校园点位中触发具体收益。

当前 MVP 规则：

- 每个携带物有一组匹配标签。
- 当玩家互动的点位包含匹配标签时，携带物触发一次。
- 触发会给一个小资源奖励，并写入日志。
- 同一件携带物对同一互动点只触发一次。
- 资源点会先结算携带物，再结算原本拾取。
- 学术交流 / 事件 / Boss 的携带物处理已拆到 [142_carry_item_exclusive_options.md](142_carry_item_exclusive_options.md)，用“携带选项”表现。

## 触发规则

| 携带物 | 匹配点位 | 触发收益 | 设计目的 |
| --- | --- | --- | --- |
| `笔记本电脑` | 数据 / 草稿 / 写作 / 方法 | 草稿 +1 | 现场整理材料、补写记录 |
| `实验耗材包` | 实验室 / 设备 / 数据 | 数据 +1 | 临时补齐实验材料 |
| `正装外套` | 会议 / 导师 / 委员会 / 行政 / 声望 | 声望 +1 | 稳住正式场合 |
| `咖啡零食` | 照护 / 灵感 / 食堂 / 恢复 | 灵感 +1 | 补一点精神余量 |
| `导师批注稿` | 导师 / 草稿 / 写作 / 返修 | 草稿 +1 | 对照批注修稿 |
| `同门联络表` | 同门 / 合作 / 社交 | 经验教训 +1 | 交换一手经验 |

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 携带物定义新增 `trigger_resource`、`trigger_amount`、`trigger_summary`。
  - 新增 `safehouse_used_carry_trigger_keys`，防止同一互动重复触发。
  - 新增 `_apply_safehouse_carry_triggers_for_interactable()`。
  - 新增 `_format_safehouse_carry_trigger_hint()`。
  - 新增 `get_safehouse_carry_trigger_hint_for_interaction(interaction_id)`。
  - 聚焦信息卡收益行会显示可触发携带物。
  - `_start_interaction()` 在资源拾取前结算携带物。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
selected_id=peer_literature_swap
selected_kind=resource
selected_hint=笔记本电脑：草稿 +1
draft_before=0
inspiration_before=0
started=true
mode_after=overworld
draft_after=1
inspiration_after=0
started_again=false
draft_after_again=1
inspiration_after_again=0
```

验证含义：

- `笔记本电脑` 在匹配资源点显示触发提示。
- 互动后实际给 `草稿 +1`。
- 已拾取点位再次互动失败，奖励不会重复刷。

## 手测重点

1. 住屋选择 `笔记本电脑` 并出门。
2. 靠近数据、草稿、写作或方法相关点位，信息卡应显示携带物收益。
3. 触发互动后，日志应显示携带物触发，资源应增加。
4. 同一个点位不能重复刷同一件携带物奖励。
5. 选择 `正装外套` 后，导师、会议、委员会或行政等非资源点位应显示携带选项，见 [142_carry_item_exclusive_options.md](142_carry_item_exclusive_options.md)。

## 下一步

1. 给携带物触发增加小型浮字或音效反馈。
2. 后续可加入携带物耐久、消耗或升级规则。
