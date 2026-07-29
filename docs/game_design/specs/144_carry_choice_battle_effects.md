# 144 携带选项战斗开局效果

## 目标

承接 [143_carry_choice_panel.md](143_carry_choice_panel.md)，让携带选项不只给资源，还能对进入战斗后的开局状态产生明确影响。

当前规则：

- 玩家在携带选择面板中最多选择 `1` 个携带选项。
- 被选择的携带物会先结算随身资源，再把一个开局修正带入战斗。
- `直接进入交流` 不触发任何开局修正。
- 开局修正发生在路线节点切换与随身资源注入之后，战斗 UI 刷新之前。
- 战斗日志会显示 `携带物开局：...`，方便玩家理解本场优势来源。

## 效果表

| 携带物 | 资源收益 | 开局修正 | 设计目的 |
| --- | --- | --- | --- |
| `笔记本电脑` | 方法论笔记 +1 | 开局额外抽 1 张牌 | 把现场记录转成更好的起手选择 |
| `实验耗材包` | 数据 +1 | 开局获得 4 防护 | 把实验风险转成容错 |
| `正装外套` | 声望 +1 | 普通交流每回合压力 -1；Boss 场合改为开局防护 | 让正式准备降低场面压力 |
| `咖啡零食` | 灵感 +1 | 首回合行动点 +1 | 把状态补给转成行动余量 |
| `导师批注稿` | 草稿 +1 | 开局获得 5 进度 | 把反馈转成开局推进 |
| `同门联络表` | 经验教训 +1 | 本场目标进度 -4 | 把同门经验转成更清晰的目标 |

## 实现记录

- [battle_state.gd](../../../scripts/battle/battle_state.gd)
  - 新增 `apply_prebattle_modifier(effect_id, amount, source_label)`。
  - 支持 `opening_draw`、`starting_block`、`starting_progress`、`first_turn_action_point`、`pressure_reduction`、`target_progress_reduction`。
- [battle_test_scene.gd](../../../scripts/ui/battle_test_scene.gd)
  - 新增 `apply_campus_prebattle_effect(effect_id, amount, source_label, summary)`。
  - 负责调用 `BattleState` 并追加玩家可见日志。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 携带物定义新增 `battle_effect_id`、`battle_effect_amount`、`battle_effect_summary`。
  - 携带选项提示和按钮文本会显示资源收益 + 开局修正。
  - 选择携带选项后，进入战斗时调用战斗层开局修正。

## 验证记录

### 普通遭遇：笔记本电脑

```text
hint=笔记本电脑「现场补写记录」：方法论笔记 +1，开局额外抽 1 张牌
start=true
panel=true
choose_laptop=true
mode=battle
active_route=N002
active_event=
battle_methodology=1
battle_hand=6
battle_pressure=7
battle_log_tail=... | 进入节点 2/8：周会压力。 | 携带物开局：笔记本电脑「现场补写记录」。开局额外抽 1 张牌。
```

含义：

- 进入真实遭遇节点 `N002`。
- 方法论笔记成功带入战斗。
- 起手手牌从默认 5 张增加到 6 张。

### 正式场合：正装外套

```text
choose_formal=true
mode=battle
campus_reputation=1
battle_reputation=1
battle_methodology=0
battle_hand=5
battle_pressure=5
battle_block=0
battle_log_tail=... | 携带物开局：正装外套「稳住正式场合」。普通交流每回合压力 -1；Boss 场合改为开局防护。
```

含义：

- 选择 `正装外套` 只获得声望和降压，不会同时获得 `笔记本电脑` 的方法论笔记。
- 普通压力从 6 降到 5。

## 手测重点

1. 在住屋携带 `笔记本电脑` 与 `正装外套`。
2. 出门后触发有携带选项的非资源点。
3. 选择 `笔记本电脑`，战斗起手手牌应多 1 张。
4. 选择 `正装外套`，普通交流压力应降低。
5. 选择 `直接进入交流`，不应获得资源收益或开局修正。

## 下一步

1. 战斗内短提示已在 [145_prebattle_effect_hud_hint.md](145_prebattle_effect_hud_hint.md) 中完成第一版。
2. 将 Boss 场合的 `pressure_reduction` 从临时防护升级为真实意图修正。
3. 继续扩展携带物的解锁、升级和耐久。
