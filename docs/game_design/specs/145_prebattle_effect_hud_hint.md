# 145 携带开局效果 HUD 提示

## 目标

承接 [144_carry_choice_battle_effects.md](144_carry_choice_battle_effects.md)，让玩家进入战斗后不需要翻日志，也能看到本场携带物带来的开局修正。

当前规则：

- 战斗界面在敌人信息下方显示 `携带开局：...`。
- 没有携带开局效果时，该提示隐藏。
- 提示使用短标签模拟图标：
  - `[抽]`：开局额外抽牌
  - `[防]`：开局防护
  - `[进]`：开局进度
  - `[行]`：首回合行动点
  - `[压]`：压力降低
  - `[标]`：目标进度降低
- 提示不会影响战斗流程，只读取已应用的开局效果。

## 实现记录

- [battle_test_scene.gd](../../../scripts/ui/battle_test_scene.gd)
  - 新增 `prebattle_effect_label`。
  - 新增 `active_campus_prebattle_effects`。
  - `apply_campus_prebattle_effect()` 在应用效果后记录 HUD 提示条目。
  - 新增 `_refresh_prebattle_effect_label()`、`_format_prebattle_effect_chip()`、`_get_prebattle_effect_icon_text()`。
  - 新增 `get_prebattle_effect_text()` 供自动验证。

## 验证记录

远程 Godot 执行器验证：

```text
choose_laptop=true
mode=battle
active_route=N002
battle_hand=6
prebattle_text=携带开局：[抽] 笔记本电脑「现场补写记录」 · 开局额外抽 1 张牌
```

验证含义：

- 选择 `笔记本电脑` 后进入真实遭遇节点 `N002`。
- 起手手牌仍为 6，说明开局效果实际生效。
- 战斗 HUD 显示 `[抽]` 短提示，玩家能直接看到本场携带物优势。

## 手测重点

1. 在住屋携带 `笔记本电脑`。
2. 出门触发 `library_peer` 或其他写作/方法相关遭遇点。
3. 选择 `笔记本电脑「现场补写记录」`。
4. 进入战斗后，敌人信息下方应显示 `携带开局：[抽] ...`。
5. 不选择携带选项而直接进入交流时，该提示应隐藏。

## 下一步

1. 将短标签替换为正式像素图标。
2. 开局效果浮字和轻微闪烁反馈已在 [146_prebattle_effect_flash_feedback.md](146_prebattle_effect_flash_feedback.md) 中完成第一版。
3. 为多个开局来源预留横向 chip 布局。
