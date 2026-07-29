# 148 携带开局效果浮字队列

## 目标

承接 [147_prebattle_effect_chips.md](147_prebattle_effect_chips.md)，让多个携带物开局效果在进入战斗时按顺序播放浮字反馈。

上一版已经能在 HUD 中同时显示多个彩色 chip，但浮字仍然偏向“即时覆盖”。当后续出现多件携带物、多段住屋准备、事件奖励同时触发时，如果所有浮字同时抢同一个位置，玩家会漏看正反馈。因此本次把浮字改成轻量队列。

## 当前规则

- 每次 `apply_campus_prebattle_effect()` 成功后，都会把该效果加入浮字反馈队列。
- 如果当前没有浮字 tween 正在播放，立即取出队首播放。
- 如果已有浮字正在播放，新效果保留在队列中，等待上一条播放结束。
- 每条浮字结束后自动隐藏当前 Label，并继续播放下一条。
- 新开一场战斗时清空旧队列，避免上一场残留反馈串到下一场。

## 实现记录

- [battle_test_scene.gd](../../../scripts/ui/battle_test_scene.gd)
  - 新增 `_prebattle_effect_feedback_queue`。
  - 新增 `_enqueue_prebattle_effect_feedback()`。
  - 新增 `_play_next_prebattle_effect_feedback()`。
  - 新增 `_on_prebattle_effect_feedback_finished()`。
  - `apply_campus_prebattle_effect()` 改为入队，而不是直接播放。
  - `_clear_prebattle_effect_feedback()` 现在会同时清理队列、tween 和浮字 Label。
  - 新增 `get_prebattle_effect_feedback_queue_count()` 供自动验证。

## 验证记录

远程 Godot 执行器验证：

```text
battle_scene_reload=0
campus_scene_reload=0
carry_laptop=true
carry_jacket=true
started=true
choose_laptop=true
active_battle=true
first_feedback_text=[抽] 笔记本电脑「现场补写记录」 / 开局额外抽 1 张牌
first_queue_count=0
second_apply=true
chip_count=2
queue_count=1
feedback_visible=true
battle_hand=6
battle_block=4
```

验证含义：

- Seed 1 住屋流程可以携带 `laptop` 和 `formal_jacket` 出门。
- `library_peer` 互动可以触发携带物专属选择，并进入战斗。
- `laptop` 的 `opening_draw` 让开局手牌从 5 变为 6。
- 手动追加 `starting_block` 后，HUD 中 chip 数量变为 2。
- 第一条浮字仍在播放时，第二条浮字进入队列，`queue_count=1`。
- 第二条效果的数据也已立即生效，`battle_block=4`。

## 手测重点

1. 在住屋选择 `笔记本电脑` 和另一个可触发战斗开局效果的携带物。
2. 出门进入校园，触发带携带物专属选项的战斗点。
3. 选择携带物方案后进入战斗。
4. 观察 HUD：常驻 chip 可以同时显示多个效果。
5. 观察浮字：如果多个开局效果在短时间内触发，应按顺序出现，而不是后者覆盖前者。

## 下一步

1. 为开局效果浮字加入轻量音效。
2. 多个 chip 的换行和最大宽度规则已在 [149_prebattle_effect_chip_wrap_layout.md](149_prebattle_effect_chip_wrap_layout.md) 中完成第一版。
3. 后续美术素材完成后，将 `ColorRect` 占位色块替换为正式像素图标。
