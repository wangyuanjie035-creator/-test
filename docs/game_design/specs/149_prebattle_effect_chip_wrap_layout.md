# 149 携带开局效果 Chip 换行布局

## 目标

承接 [148_prebattle_effect_feedback_queue.md](148_prebattle_effect_feedback_queue.md)，让战斗 HUD 中的携带物开局效果 chip 在数量变多或窗口变窄时保持稳定布局。

上一版已经解决了多个浮字按顺序播放的问题，但常驻 chip 如果继续单行横排，后续叠加住屋准备、携带物、事件奖励时会挤出 HUD。本次把 chip 容器改成可换行布局，并给单个 chip 设置稳定宽度。

## 当前规则

- `prebattle_effect_chip_container` 使用 `HFlowContainer`。
- 每个 chip 固定占用 248 px 宽度。
- chip 文本区域固定 204 px，并允许最多 2 行显示。
- 文本超出时按词组裁切并显示省略效果。
- chip tooltip 仍保留完整来源和效果描述。
- 多个 chip 在横向空间不足时由容器自动换行。

## 实现记录

- [battle_test_scene.gd](../../../scripts/ui/battle_test_scene.gd)
  - 新增 `PREBATTLE_EFFECT_CHIP_MAX_WIDTH`。
  - 新增 `PREBATTLE_EFFECT_CHIP_TEXT_WIDTH`。
  - 新增 `PREBATTLE_EFFECT_CHIP_MIN_HEIGHT`。
  - `prebattle_effect_chip_container` 从 `HBoxContainer` 改为 `HFlowContainer`。
  - chip Label 增加 `autowrap_mode`、`clip_text`、`max_lines_visible` 和 `text_overrun_behavior`。
  - 新增 `get_prebattle_effect_chip_layout_summary()` 供自动验证。

## 验证记录

远程 Godot 执行器验证：

```text
battle_scene_reload=0
campus_scene_reload=0
choose_laptop=true
active_battle=true
chip_count=4
chip_layout=container=HFlowContainer,count=4,widths=248,248,248,248
queue_count=3
battle_hand=6
battle_block=4
battle_progress=5
target_progress=32
```

验证含义：

- 战斗 UI 脚本可以在 Godot 4.5.1 中正常 reload。
- 真实住屋到校园战斗流程仍然可用。
- 4 个开局效果可以同时生成 chip。
- chip 容器已经切换为 `HFlowContainer`。
- 所有 chip 的布局宽度稳定为 248 px。
- 多效果浮字队列仍然保留，战斗数值也都即时生效。

## 手测重点

1. 在住屋携带 `笔记本电脑`，进入带专属携带物选项的战斗。
2. 后续若某场战斗触发多个开局效果，观察 chip 是否自动换行。
3. 缩小游戏窗口，确认 chip 不会挤出战斗 HUD。
4. 鼠标悬停 chip，确认 tooltip 仍能看到完整来源和效果说明。

## 下一步

1. 开局效果浮字的轻量占位音效已在 [150_prebattle_effect_sfx_placeholder.md](150_prebattle_effect_sfx_placeholder.md) 中完成第一版。
2. 后续美术素材完成后，将 `ColorRect` 占位色块替换为正式像素图标。
3. 等战斗 HUD 内容继续增多后，再统一做一轮移动端/窄屏排版验收。
