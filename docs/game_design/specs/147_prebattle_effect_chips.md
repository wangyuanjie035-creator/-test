# 147 携带开局效果彩色 Chip

## 目标

承接 [146_prebattle_effect_flash_feedback.md](146_prebattle_effect_flash_feedback.md)，把战斗 HUD 中的纯文字短标签升级为彩色效果 chip。

当前没有正式像素图标，因此先使用代码生成的 `ColorRect` 作为像素色块占位。后续美术素材完成后，可以将色块替换为 `TextureRect`。

## 当前规则

- `携带开局：` 作为标题单独显示。
- 每个开局效果生成一个横向 chip。
- chip 包含：
  - 12x12 色块占位图标。
  - 效果短标签，例如 `抽`、`防`、`压`。
  - 效果摘要，例如 `开局额外抽 1 张牌`。
- chip tooltip 保留完整来源信息，例如 `笔记本电脑「现场补写记录」`。
- 浮字反馈会使用同一套效果颜色。

## 效果颜色

| 效果 | 标签 | 色彩倾向 |
| --- | --- | --- |
| `opening_draw` | 抽 | 蓝色 |
| `starting_block` | 防 | 绿色 |
| `starting_progress` | 进 | 金色 |
| `first_turn_action_point` | 行 | 紫粉色 |
| `pressure_reduction` | 压 | 青色 |
| `target_progress_reduction` | 标 | 橙红色 |

## 实现记录

- [battle_test_scene.gd](../../../scripts/ui/battle_test_scene.gd)
  - 新增 `prebattle_effect_chip_container`。
  - `prebattle_effect_label` 改为标题，完整文本由 `get_prebattle_effect_text()` 生成。
  - 新增 `_create_prebattle_effect_chip()`。
  - 新增 `_create_prebattle_effect_chip_style()`。
  - 新增 `_get_prebattle_effect_style()`。
  - 新增 `get_prebattle_effect_chip_count()` 供自动验证。
  - 浮字颜色改为读取同一套效果样式。

## 验证记录

远程 Godot 执行器验证：

```text
battle_scene_reload=0
choose_laptop=true
battle_hand=6
prebattle_text=携带开局：[抽] 笔记本电脑「现场补写记录」 · 开局额外抽 1 张牌
chip_count=1
feedback_visible=true
feedback_text=[抽] 笔记本电脑「现场补写记录」
开局额外抽 1 张牌
```

验证含义：

- 开局抽牌效果仍然生效。
- 战斗 HUD 生成了 1 个开局效果 chip。
- 浮字和常驻提示仍保持正确文本。

## 手测重点

1. 在住屋携带 `笔记本电脑`。
2. 出门触发 `library_peer`。
3. 选择 `笔记本电脑「现场补写记录」`。
4. 进入战斗后，`携带开局：` 下方应出现蓝色 chip。
5. 浮字颜色应与该效果的蓝色倾向一致。

## 下一步

1. 将 `ColorRect` 占位图标替换为正式像素图标素材。
2. 为开局效果加入轻量音效。
3. 多个效果的浮字队列已在 [148_prebattle_effect_feedback_queue.md](148_prebattle_effect_feedback_queue.md) 中完成第一版；后续继续补 chip 换行与窄屏布局。
