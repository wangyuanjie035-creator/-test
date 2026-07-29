# 110 校园地图标记脉冲节奏

## 目标

承接 [109_campus_summary_next_step_link.md](109_campus_summary_next_step_link.md)，对校园地图标记的多层提示做节奏调优。当前同一个交互点可能同时具备剧情目标、返回摘要目标、靠近聚焦、条件状态等多种视觉层，如果所有层同步闪烁，容易显得过亮和杂乱。

这一步把不同提示层的脉冲透明度错开相位，并略微收敛叠加时的峰值亮度，让信息层次更清楚。

## 体验规则

- 剧情目标青色框、补给点金色框、返回摘要青白色外层提示和靠近黄色聚焦框不应同拍闪烁。
- 当一个目标同时具有剧情目标和返回摘要目标时，摘要提示应像额外确认层，而不是把原剧情框直接变得过亮。
- 靠近聚焦仍然绘制在最后，确保玩家当前位置反馈优先。
- 资源点光晕和 Boss 可挑战框也使用错峰脉冲，但不改变原有含义。

## 实现记录

- [campus_map_marker.gd](../../../scripts/overworld/campus_map_marker.gd)
  - 新增 `PULSE_*_PHASE` 常量，为不同标记层分配固定相位。
  - 新增 `_pulse01(multiplier, phase)`，统一把 `_pulse_time` 转成 `0.0 - 1.0` 采样值。
  - 资源光晕、剧情关键、Boss 可挑战、剧情目标、补给提示、返回摘要目标和靠近聚焦均改用 `_pulse01()`。
  - 略微降低剧情目标、摘要目标、靠近聚焦等叠加层的峰值 alpha，减少多层同时出现时的压迫感。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
```

多状态标记行为验证：

```text
configure_ok=true
marker_processing=true
guidance_target=true
summary_guidance_target=true
supply_hint_target=true
focused_target=true
completed_after_false=false
processing_after_completed=false
```

返回摘要联动回归验证：

```text
summary_target_id=midterm_room
summary_target_active=true
story_target_active=true
summary_target_active_after_second_start=false
mode_after_second_start=battle
```

## 手测重点

1. 切到研二校园阶段。
2. 未完成 `数据清洗夜` 后返回校园，观察 `B002 中期考核`。
3. `B002` 应同时有青色剧情目标框和青白色摘要外层提示，但二者闪烁节奏不应完全同步。
4. 靠近 `B002` 时，黄色聚焦框应仍然最清楚，且不会和青色/青白色提示同拍一起变亮。
5. 查看补给点金色提示和资源点光晕，它们应维持原有职责，只是呼吸节奏更分散。

## 下一步

1. 已完成：屏幕边缘的下一剧情目标会显示 HUD 方向提示，见 [111_campus_guidance_direction_indicator.md](111_campus_guidance_direction_indicator.md)。
2. 后续美术替换时，这些相位常量可以迁移到独立动画资源或 Sprite2D 动画轨。
