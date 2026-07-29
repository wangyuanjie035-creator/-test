# 143 携带物选择面板

## 目标

承接 [142_carry_item_exclusive_options.md](142_carry_item_exclusive_options.md)，把非资源点的 `携带选项` 从自动触发升级为玩家可点击选择。

当前规则：

- 资源点仍然直接结算 `携带物触发`。
- 非资源点若存在可用携带选项，互动时先打开选择面板。
- 每次互动最多选择 `1` 个携带选项。
- 玩家也可以选择 `直接进入交流`，不消耗/不触发携带选项。
- 玩家可以选择 `返回地图` 或按取消键关闭面板。
- 选择携带选项后，资源立刻进入随身资源，再进入卡牌战斗。

这个取舍让携带物从“被动收益”变成“现场决策”：同一个点位里，玩家可能在 `方法论笔记`、`声望`、`草稿` 等不同准备收益之间取舍。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `CarryChoicePanel`，包含标题、说明和按钮列表。
  - 新增 `_pending_carry_choice_interaction_id` 与 `_pending_carry_choice_options`。
  - 新增 `_get_available_safehouse_carry_options_for_interactable()`，统一为提示、面板和结算供数。
  - 新增 `_choose_pending_carry_option()`、`_skip_pending_carry_choice()`、`_cancel_pending_carry_choice()`。
  - `_start_interaction()` 在非资源点发现携带选项时先打开选择面板。
  - 选择面板打开时隐藏聚焦信息卡，并临时停止玩家移动。
  - 公开测试接口：
    - `is_carry_choice_panel_visible()`
    - `get_pending_carry_choice_summary()`
    - `get_pending_carry_choice_button_count()`
    - `choose_pending_carry_option_by_item_id(item_id)`
    - `skip_pending_carry_choice()`
    - `cancel_pending_carry_choice()`

## 验证记录

### 选择携带物

```text
scene_reload=0
option_id=master1_advisor_direction_card
option_hint=笔记本电脑「现场补写记录」：方法论笔记 +1 / 正装外套「稳住正式场合」：声望 +1
started=true
mode_after_start=overworld
panel_visible=true
button_count=4
pending_summary=master1_advisor_direction_card：笔记本电脑「现场补写记录」：方法论笔记 +1 / 正装外套「稳住正式场合」：声望 +1
method_notes_before_choose=0
reputation_before_choose=0
choose_laptop=true
mode_after_choose=battle
panel_visible_after_choose=false
method_notes_after_choose=1
reputation_after_choose=0
```

含义：

- 互动后先停在地图和选择面板，不直接进战斗。
- 面板包含 2 个携带选项、1 个直接进入、1 个返回地图。
- 选择 `笔记本电脑` 后只获得 `方法论笔记 +1`，不会同时获得 `正装外套` 的声望。

### 直接进入

```text
scene_reload=0
option_id=master1_advisor_direction_card
started=true
panel_visible=true
skip=true
mode_after_skip=battle
panel_visible_after_skip=false
method_notes_after_skip=0
reputation_after_skip=0
```

含义：

- 直接进入战斗不会结算携带选项资源。

### 返回地图

```text
scene_reload=0
started=true
panel_visible=true
cancel=true
mode_after_cancel=overworld
panel_visible_after_cancel=false
pending_after_cancel=
```

含义：

- 取消后仍在校园地图，面板和待选状态均清空。

## 手测重点

1. 在住屋选择两件能匹配同一点位的携带物，例如 `笔记本电脑` 和 `正装外套`。
2. 出门后靠近导师、会议、写作或行政点位。
3. 按互动键后，应出现携带物选择面板。
4. 点击其中一个携带物选项，应只结算该选项收益并进入战斗。
5. 点击 `直接进入交流`，应进入战斗但不增加携带物资源。
6. 点击 `返回地图` 或按取消键，应关闭面板并恢复探索。

## 下一步

1. 携带选项战斗开局效果已在 [144_carry_choice_battle_effects.md](144_carry_choice_battle_effects.md) 中完成第一版。
2. 给选择面板增加更清楚的像素图标和按钮状态。
3. 将普通事件选项也迁移到同一套选择面板结构。
