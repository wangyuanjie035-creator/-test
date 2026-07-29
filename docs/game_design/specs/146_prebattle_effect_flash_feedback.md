# 146 携带开局效果浮字反馈

## 目标

承接 [145_prebattle_effect_hud_hint.md](145_prebattle_effect_hud_hint.md)，在携带物开局效果生效时增加一次短暂浮字和轻微闪烁，让玩家进入战斗的瞬间获得正反馈。

当前规则：

- 常驻提示 `携带开局：...` 保留。
- 携带效果生效时，在战斗界面上方中央显示一次浮字。
- 浮字包含短标签、携带物来源和效果摘要，例如：
  - `[抽] 笔记本电脑「现场补写记录」`
  - `开局额外抽 1 张牌`
- 浮字不参与主 UI 布局，出现和消失不会推挤战斗界面。
- `直接进入交流` 不显示浮字。
- 重开战斗时会清理正在播放的浮字。

## 实现记录

- [battle_test_scene.gd](../../../scripts/ui/battle_test_scene.gd)
  - 新增 `prebattle_effect_feedback_label` 覆盖层 Label。
  - 新增 `_prebattle_effect_feedback_tween`。
  - 新增 `_build_prebattle_effect_feedback()`。
  - 新增 `_show_prebattle_effect_feedback()`、`_hide_prebattle_effect_feedback()`、`_clear_prebattle_effect_feedback()`。
  - `apply_campus_prebattle_effect()` 应用开局效果后刷新常驻提示，并播放浮字。
  - 新增 `get_prebattle_effect_feedback_text()` 和 `is_prebattle_effect_feedback_visible()` 供自动验证。

## 验证记录

### 选择携带物

```text
choose_laptop=true
mode=battle
active_route=N002
battle_hand=6
prebattle_text=携带开局：[抽] 笔记本电脑「现场补写记录」 · 开局额外抽 1 张牌
feedback_visible=true
feedback_text=[抽] 笔记本电脑「现场补写记录」
开局额外抽 1 张牌
```

含义：

- 携带物开局效果实际生效，手牌为 6。
- 常驻提示和浮字同时显示正确内容。

### 直接进入

```text
skip=true
mode=battle
prebattle_text=
feedback_visible=false
feedback_text=
```

含义：

- 不使用携带选项时，不显示携带开局提示和浮字。

## 手测重点

1. 在住屋携带 `笔记本电脑`。
2. 出门触发 `library_peer` 或其他写作/方法相关遭遇点。
3. 选择 `笔记本电脑「现场补写记录」`。
4. 进入战斗瞬间，应看到一次上方中央浮字。
5. 浮字消失后，常驻 `携带开局：...` 提示仍保留。
6. 选择 `直接进入交流` 时，不应出现浮字。

## 下一步

1. 彩色 chip 占位图标已在 [147_prebattle_effect_chips.md](147_prebattle_effect_chips.md) 中完成第一版。
2. 给不同效果配置不同颜色和音效。
3. 为多个开局来源预留 chip 动画队列。
