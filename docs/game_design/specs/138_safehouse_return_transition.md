# 138 住屋入口撤回转场

## 目标

承接 [137_safehouse_map_entrance.md](137_safehouse_map_entrance.md)，让玩家从校园地图触发 `住屋入口` 时，不再瞬间切回住屋，而是先看到一次明确的“安全返回住屋”转场反馈。

## 设计规则

- 触发住屋入口后，先锁定玩家移动。
- 屏幕显示转场标题：`安全返回住屋`。
- 副标题显示来源和结果：`住屋入口 · 带回当前资源`。
- 转场淡入并短暂停留后，切换到住屋界面。
- 住屋界面出现后，转场淡出。
- 转场层绘制在住屋层之上，避免切换瞬间露出突兀画面。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - `transition_layer.layer` 从 `3` 提高到 `5`，保证转场覆盖住屋层。
  - `_enter_safehouse(record_return, keep_transition)` 增加 `keep_transition` 参数。
  - `_return_to_safehouse_from_entrance()` 改为启动 `_show_safehouse_return_transition()`。
  - 新增 `_show_safehouse_return_transition()`，使用 `Tween` 顺序执行淡入、停留、切住屋、淡出。
  - 新增 `_finish_safehouse_return_transition()`。
  - 新增 `_format_safehouse_return_transition_subtitle()`。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
start_entrance=true
mode_after_start=overworld
transition_visible=true
transition_title=安全返回住屋
transition_subtitle=住屋入口 · 带回当前资源
mode_after_finish=safehouse
safehouse_visible=true
transition_visible_after_clear=false
```

## 手测重点

1. 从住屋选择主题并出门。
2. 前往宿舍区域旁的住屋入口。
3. 按确认键后，屏幕应显示“安全返回住屋”。
4. 短暂停留后应回到住屋面板。
5. 返回后资源与当天日志不应被清空。
6. 转场不应遮挡后续住屋操作；淡出后按钮应可点击。

## 下一步

1. 住屋准备行动、智性/情性成长已在 [139_safehouse_prep_attributes.md](139_safehouse_prep_attributes.md) 中完成第一版。
2. 给撤回动作增加资源结算小条，例如“本次带回：数据 +2、草稿 +1”。
3. 后续可加入短音效或像素门开合动画。
