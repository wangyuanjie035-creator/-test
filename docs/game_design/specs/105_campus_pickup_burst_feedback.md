# 105 校园资源拾取爆闪反馈

## 目标

升级 [088_campus_resource_visual_feedback.md](088_campus_resource_visual_feedback.md) 的拾取浮字反馈：玩家拾取资源点时，除了 `+数量 资源名` 浮字，还会在资源点位置短暂显示像素光点爆闪。

这一步继续强化“探索有收获”的即时正反馈，不改变资源数值、资源点完成状态、剧情引导或战斗资源注入规则。

## 视觉规则

- 拾取资源时，在资源点原位置生成 `PickupBurst`。
- `PickupBurst` 绘制为资源主色的浅色像素光环与小光点。
- 光点生命周期约 0.55 秒，到时自动释放。
- 原有 `PickupText` 浮字继续保留，和光点同时出现。
- 光点显示在世界层 `WorldFeedback` 下，不受 HUD 布局影响。

## 实现记录

- [campus_pickup_burst.gd](../../../scripts/overworld/campus_pickup_burst.gd)
  - 新增 `CampusPickupBurst` 节点脚本。
  - 使用 `_draw()` 绘制像素光环和光点。
  - 使用 `_process()` 推进生命周期，到期 `queue_free()`。
  - `configure()` 接收资源点主色。
  - `get_lifetime_progress()` 用于自动化验证。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 预加载 `campus_pickup_burst.gd`。
  - `_show_pickup_feedback()` 先生成 `PickupBurst`，再生成原有 `PickupText`。
  - `PickupText` 现在显式命名，便于调试和验证。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_pickup_burst.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_map_marker.gd=0
```

拾取验证：

```text
scene_reload=0
feedback_before=0
collect_ok=true
data_after=2
feedback_after=2
feedback_child_0=PickupBurst
feedback_child_1=PickupText
burst_progress=0.0
```

生命周期验证：

```text
burst_script=loaded
progress_initial=0.0
progress_mid=0.5
queued_after_lifetime=true
```

## 手测重点

1. 运行校园地图。
2. 靠近并拾取任意资源点。
3. 资源点原位置应同时出现像素光点爆闪和 `+数量 资源名` 浮字。
4. 光点应很快消失，浮字继续向上淡出。
5. HUD 资源数、日志、资源点消失和补给高亮刷新应保持原有行为。

## 下一步

1. 已完成：从校园进入学术交流时会显示短暂转场提示，见 [106_campus_battle_transition_feedback.md](106_campus_battle_transition_feedback.md)。
2. 后续加入音效素材后，可给资源拾取、进入学术交流和返回校园增加短促提示音。
3. 如果后续资源点有正式像素素材，可把 `CampusPickupBurst` 的 `_draw()` 替换为动画帧或粒子资源。
