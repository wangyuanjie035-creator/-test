# 109 校园返回摘要下一步联动

## 目标

在 [108_campus_return_summary_panel.md](108_campus_return_summary_panel.md) 的返回摘要基础上，强化“下一步”与地图目标之间的对应关系。玩家从学术交流返回校园时，HUD 右上角的 `下一步` 文本应和地图上的剧情目标同时成立，地图目标在摘要显示期间获得额外的青白色像素提示，帮助玩家更快确认接下来该去哪里。

这一步只增强提示层，不改变路线推进、资源条件、战斗结果或交互规则。

## 体验规则

- 返回摘要显示期间，当前剧情目标除了原有青色剧情目标框，还会出现额外的青白色外层角标与顶部脉冲。
- 摘要淡出、进入下一次学术交流、重置校园或目标被重新刷新后，额外提示会被清理。
- 原有剧情目标高亮、补给点高亮、靠近聚焦框和资源拾取爆闪继续保留各自职责。
- 资源点拾取不触发返回摘要，因此也不会单独触发这层摘要目标提示。

## 实现记录

- [campus_map_marker.gd](../../../scripts/overworld/campus_map_marker.gd)
  - 新增 `summary_guidance_target` 状态。
  - `configure_marker()` 增加摘要目标参数。
  - `_draw_summary_guidance_target_overlay()` 绘制青白色外层角标和顶部脉冲。
  - `_should_pulse()` 将摘要目标纳入处理循环。
- [campus_interactable.gd](../../../scripts/overworld/campus_interactable.gd)
  - 新增 `summary_guidance_target` 状态与 `set_summary_guidance_target()`。
  - `refresh_marker()` 将状态转发给 `CampusMapMarker`。
  - 新增 `is_summary_guidance_target()` 供场景验证。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `get_return_summary_guidance_target_interaction_id()`。
  - 新增 `is_interactable_summary_guidance_target()`。
  - `_show_return_summary_panel()` 显示摘要时锁定当前剧情目标。
  - `_finish_return_summary_panel()`、`_refresh_story_guidance()` 和重置流程会清理旧摘要目标。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_map_marker.gd=0
```

研二未完成返回验证：

```text
start_ok=true
mode_after_return=overworld
summary_visible=true
summary_target_id=midterm_room
summary_target_active=true
story_target_active=true
summary_guidance_has_midterm=true
```

进入下一场学术交流后的清理验证：

```text
second_start_ok=true
summary_after_second_start=false
summary_target_id_after_second_start=
summary_target_active_after_second_start=false
mode_after_second_start=battle
```

摘要淡出回调清理验证：

```text
target_before_finish=midterm_room
active_before_finish=true
summary_after_finish=false
target_after_finish=
active_after_finish=false
```

## 手测重点

1. 切到研二校园阶段。
2. 进入 `数据清洗夜` 等普通学术交流后直接返回校园。
3. HUD 右上角应显示 `返回摘要`，其 `下一步` 指向 `中期考核 · B002`。
4. 地图上的会议室目标应同时保留青色剧情目标框，并在摘要显示期间出现更明显的青白色外层提示。
5. 进入下一次学术交流或等待摘要淡出后，额外青白色提示应消失。
6. 补给点金色提示、靠近黄色聚焦框和资源拾取爆闪不应受影响。

## 下一步

1. 已完成：剧情目标、摘要目标、靠近聚焦等脉冲已错开节奏，见 [110_campus_marker_pulse_rhythm.md](110_campus_marker_pulse_rhythm.md)。
2. 后续替换美术素材时，可把 `CampusMapMarker` 的摘要目标层替换成独立 Sprite2D 或动画帧，但先保留当前自绘版，方便无素材阶段迭代。
