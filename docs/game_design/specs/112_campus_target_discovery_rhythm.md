# 112 校园目标发现节奏

## 目标

承接 [111_campus_guidance_direction_indicator.md](111_campus_guidance_direction_indicator.md)，为“从学术交流返回校园”这个关键时刻增加短时目标发现节奏。

111 的方向箭头遵循克制规则：目标在舒适区域内就隐藏。112 增加一个短时发现窗口：返回摘要锁定下一剧情目标后的几秒内，即使目标已在舒适区域内，也会短暂显示更亮的方向箭头，帮助玩家把 `返回摘要` 的 `下一步` 和地图目标建立联系；窗口结束后自动恢复 111 的普通规则。

## 体验规则

- 返回校园并显示返回摘要时，下一剧情目标会启动短时发现窗口。
- 发现窗口期间，方向箭头使用更亮的青白绿色，并带额外像素刻度。
- 发现窗口期间，目标在舒适区域内也可以显示方向箭头。
- 玩家已经贴近目标时仍然隐藏箭头，避免遮挡靠近交互。
- 发现窗口结束、进入下一场学术交流、摘要清理或校园重置时，发现状态清空。
- 这一步不改变剧情目标、资源补给、战斗进入和地图交互规则。

## 实现记录

- [campus_target_direction_indicator.gd](../../../scripts/overworld/campus_target_direction_indicator.gd)
  - 新增 `discovery_active` 状态。
  - `configure()` 增加 `new_discovery_active` 参数。
  - `_draw()` 在发现窗口期间使用 `DISCOVERY_COLOR`、更强光晕和额外像素刻度。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `GUIDANCE_INDICATOR_DISCOVERY_DURATION`。
  - 新增 `_guidance_indicator_discovery_time` 计时。
  - `_process()` 递减发现窗口计时。
  - `_set_summary_guidance_target_from_current_story()` 启动发现窗口。
  - `_clear_summary_guidance_target()` 和重置流程清理发现状态。
  - `_refresh_guidance_direction_indicator()` 在发现窗口期间跳过舒适区域隐藏判断，但保留近距离隐藏和战斗隐藏。
  - 新增 `get_guidance_direction_indicator_discovery_active()` 供验证。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_target_direction_indicator.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
```

发现箭头组件验证：

```text
indicator_visible=true
indicator_discovery_active=true
indicator_direction=(0.894427, 0.447214)
indicator_hidden_processing=false
```

返回校园发现窗口验证：

```text
initial_visible=false
initial_discovery=false
after_return_visible=true
after_return_discovery=true
after_return_target=midterm_room
after_return_summary_target=midterm_room
after_stop_visible=false
after_stop_discovery=false
near_target_visible_during_discovery=false
```

进入下一场学术交流清理验证：

```text
visible_after_return=true
discovery_after_return=true
second_start_ok=true
visible_after_second_start=false
discovery_after_second_start=false
mode_after_second_start=battle
```

## 手测重点

1. 切到研二校园阶段。
2. 进入 `数据清洗夜` 后直接返回校园。
3. 右上角显示 `返回摘要` 时，下一剧情目标方向箭头应短暂出现，即使目标已经在屏幕舒适区域内。
4. 短时强调结束后，如果目标仍在舒适区域内，箭头应自动隐藏；如果目标在屏幕边缘，则降级为普通青色方向提示。
5. 靠近目标时箭头应隐藏。
6. 发现窗口期间进入下一场学术交流，箭头和发现状态都应清空。

## 下一步

1. 已完成：HUD、返回摘要、方向箭头和底部提示的层级与安全区域已整理，见 [113_campus_hud_visual_hierarchy.md](113_campus_hud_visual_hierarchy.md)。
2. 后续若目标方向提示过强，可以把 `GUIDANCE_INDICATOR_DISCOVERY_DURATION` 从 `2.4` 秒调短到 `1.6-2.0` 秒。
