# 113 校园 HUD 可视层次整理

## 目标

承接 [112_campus_target_discovery_rhythm.md](112_campus_target_discovery_rhythm.md)，整理校园 HUD 中多个提示层的绘制顺序和安全区域。当前校园地图同时存在左上状态面板、右上返回摘要、屏幕边缘方向箭头、底部交互提示和地图标记。若只靠零散 offset，后续小窗口或新提示很容易互相压住。

这一步把 HUD 层级和方向箭头安全区域显式化，让方向提示不会压住返回摘要和底部交互提示。

## 体验规则

- 左上状态面板、方向箭头、底部交互提示、返回摘要有明确绘制顺序。
- 方向箭头中心点被限制在 HUD 安全区域内。
- 方向箭头顶部避开右上返回摘要和左上状态区域。
- 方向箭头底部避开底部交互提示。
- 返回摘要仍然拥有最高 HUD 提示优先级。
- 所有这些整理不改变战斗、资源、路线和地图交互规则。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `HUD_Z_STATUS`、`HUD_Z_DIRECTION_INDICATOR`、`HUD_Z_PROMPT`、`HUD_Z_RETURN_SUMMARY`。
  - `StatusPanel`、`GuidanceDirectionIndicator`、`PromptPanel`、`ReturnSummaryPanel` 设置明确 `z_index`。
  - `GUIDANCE_INDICATOR_BOTTOM_INSET` 从 `92` 调整为 `124`，避免 1152x648 这类窗口中方向箭头压到底部提示。
  - 新增 `status_panel` 和 `prompt_panel` 字段，便于后续布局验证。
  - 新增 `get_guidance_direction_indicator_center_safe_rect()`、`get_prompt_panel_rect()`、`get_return_summary_panel_rect()` 和 `get_hud_z_order_summary()`。
  - `_get_guidance_indicator_edge_position()` 改为使用 `_get_guidance_direction_indicator_center_safe_rect()`。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_target_direction_indicator.gd=0
```

1152x648 布局边界验证：

```text
safe_rect_1152=[P: (64.0, 218.0), S: (1024.0, 306.0)]
edge_position_1152=(894.7711, 524.0)
bottom_gap_ok=true
top_gap_ok=true
z_order=status=10,direction=20,prompt=30,summary=40
```

方向提示回归验证：

```text
discovery_visible=true
discovery_target=midterm_room
```

## 手测重点

1. 使用 1152x648 或相近小窗口运行校园地图。
2. 触发返回摘要和方向箭头后，右上摘要不应被方向箭头遮挡。
3. 方向箭头贴近屏幕下缘时，不应压住底部交互提示。
4. 返回摘要、方向箭头、底部提示同时存在时，视觉优先级应清楚：摘要最高，底部交互提示优先于方向箭头。
5. 方向箭头仍应能在发现窗口中指向 `midterm_room`。

## 下一步

1. 已完成：校园 HUD 信息密度审查已将左上状态面板拆为状态、资源、目标、日志和测试区，见 [114_campus_hud_information_density.md](114_campus_hud_information_density.md)。
2. 后续若加入小地图或任务列表，应复用本规格里的 HUD 安全区和 z 顺序，而不是新增互相覆盖的浮层。
