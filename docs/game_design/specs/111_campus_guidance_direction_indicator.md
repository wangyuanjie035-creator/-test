# 111 校园剧情目标方向提示

## 目标

承接 [110_campus_marker_pulse_rhythm.md](110_campus_marker_pulse_rhythm.md)，为校园地图的下一剧情目标增加 HUD 边缘方向提示。当前地图已经有青色剧情目标框、摘要强化和聚焦框，但当目标处在当前视野边缘、被建筑视觉压住或玩家刚返回校园时，玩家仍可能需要更直接的方向确认。

这一步新增一个非阻塞、无文字说明的像素方向箭头。它只在目标距离较远且不在屏幕舒适区域内时显示。

## 体验规则

- 箭头只服务当前下一剧情目标，不改变补给点、资源点和普通 NPC 的地图标记。
- 目标距离玩家较近时隐藏，避免干扰靠近交互。
- 目标已经在屏幕舒适区域内时隐藏，避免一直占用 HUD。
- 进入学术交流、HUD 隐藏或没有剧情目标时隐藏。
- 如果目标同时处于返回摘要强化态，箭头使用更亮的青白色；否则使用剧情目标青色。
- 箭头不拦截鼠标输入，不影响校园移动、交互和 HUD 按钮。

## 实现记录

- [campus_target_direction_indicator.gd](../../../scripts/overworld/campus_target_direction_indicator.gd)
  - 新增 `CampusTargetDirectionIndicator`，作为 HUD 自绘 Control。
  - `configure()` 接收显示状态、方向向量和摘要强化状态。
  - `_draw()` 绘制像素风方向箭头、底色阴影和轻微脉冲。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `CAMPUS_TARGET_DIRECTION_INDICATOR` 预加载。
  - 新增方向提示 HUD 节点 `GuidanceDirectionIndicator`。
  - 新增 `get_guidance_direction_indicator_visible()`、`get_guidance_direction_indicator_position()`、`get_guidance_direction_indicator_direction()` 和 `get_guidance_direction_indicator_target_interaction_id()`。
  - `_refresh_guidance_direction_indicator()` 根据玩家、剧情目标、屏幕舒适区域和模式状态刷新箭头。
  - `_get_guidance_indicator_edge_position()` 将方向投射到 HUD 安全边界。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_target_direction_indicator.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
```

方向箭头组件验证：

```text
indicator_visible=true
indicator_processing=true
indicator_direction=(0.894427, 0.447214)
indicator_hidden_processing=false
```

小视口边缘位置验证：

```text
edge_position_1152=(945.7744, 556.0)
edge_inside_bounds=true
```

校园状态回归验证：

```text
visible_near_target=false
start_ok=true
visible_in_battle=false
mode_in_battle=battle
```

说明：远程编辑器验证环境的视口为 `3840x2066`，研二默认目标已处于舒适区域内，因此默认不显示箭头；小视口边缘计算单独验证了常见运行窗口下的边界位置。

## 手测重点

1. 使用普通运行窗口进入校园地图，切到研二阶段。
2. 玩家在校园中庭附近时，若 `B002 中期考核` 位于屏幕边缘或视野外，应出现青色方向箭头。
3. 向目标移动，目标进入舒适可见区域或距离足够近后，箭头应隐藏。
4. 从学术交流返回校园后，如果摘要目标仍在边缘，箭头应使用更亮的青白色。
5. 进入学术交流后箭头应隐藏，且不影响战斗层按钮。

## 下一步

1. 已完成：返回校园后方向箭头会短时配合摘要强调下一剧情目标，见 [112_campus_target_discovery_rhythm.md](112_campus_target_discovery_rhythm.md)。
2. 后续如果地图变大，可以把方向箭头扩展成小型罗盘或边缘目标列表，但当前阶段只保留单一剧情目标。
