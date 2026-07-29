# 104 校园标记聚焦反馈

## 目标

当玩家靠近任意校园交互点时，地图标记显示一层轻量像素聚焦框，让玩家更清楚当前底部提示对应哪个地图对象。

这一步承接 [103_campus_focus_prompt_role_tags.md](103_campus_focus_prompt_role_tags.md)。103 解决“文字上知道它是什么”，104 解决“视觉上知道我对准了谁”。

## 视觉规则

- 聚焦反馈显示为暖黄色像素角框，绘制在现有标记和剧情/补给高亮之上。
- 聚焦框使用轻微脉冲透明度，不改变标记本体位置和碰撞区域。
- 同一时间只应有一个交互点处于聚焦状态。
- 离开交互范围后，聚焦框消失，底部提示回到 `校园中庭`。
- 本功能不改变剧情引导、建议补给、材料拦截、资源拾取或战斗入口规则。

## 实现记录

- [campus_map_marker.gd](../../../scripts/overworld/campus_map_marker.gd)
  - 新增 `focused_target` 状态。
  - `configure_marker()` 增加 `new_focused_target` 可选参数。
  - 新增 `set_focused_target()`。
  - `_should_pulse()` 在聚焦时启用 `_process()`，离开后自动关闭。
  - `_draw_focused_target_overlay()` 绘制暖黄色像素角框。
- [campus_interactable.gd](../../../scripts/overworld/campus_interactable.gd)
  - 新增 `focused_target` 状态。
  - 新增 `set_focused_target()` 与 `is_focused_target()`。
  - `refresh_marker()` 将聚焦状态同步给 `CampusMapMarker`。
  - 已收集点会清除聚焦状态。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `is_interactable_focused_target()` 用于验证。
  - 玩家进入交互范围时设置当前聚焦点，切换目标时清理旧聚焦点。
  - 玩家离开当前交互范围时清理聚焦点。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_map_marker.gd=0
```

剧情目标/补给点聚焦验证：

```text
midterm_focus_initial=false
data_pack_focus_initial=false
midterm_focus_enter=true
midterm_prompt=剧情目标｜中期考核 路 B002｜准备不足：数据 0/2、草稿 0/3
midterm_focus_after_switch=false
data_pack_focus_enter=true
data_pack_prompt=建议补给｜复现数据包 +2
data_pack_focus_exit=false
cleared_prompt=校园中庭
```

普通交互点动画处理验证：

```text
chosen_id=data_cleaning_night
marker_processing_before=false
focused_after_enter=true
marker_processing_after_enter=true
focused_after_exit=false
marker_processing_after_exit=false
```

## 手测重点

1. 运行校园地图。
2. 靠近任意 NPC、Boss 或资源点时，该点应出现暖黄色像素聚焦框。
3. 从 `B002 中期考核` 移动到 `复现数据包` 时，聚焦框应从 B002 切到资源点。
4. 离开交互范围后，聚焦框应消失，底部提示回到 `校园中庭`。
5. 对普通非高亮交互点，靠近时也应有聚焦框，离开后不再闪烁。

## 下一步

1. 已完成：资源点被拾取时会短暂弹出像素光点爆闪，见 [105_campus_pickup_burst_feedback.md](105_campus_pickup_burst_feedback.md)。
2. 后续加入音效素材后，可给聚焦、拾取、进入战斗分别配置不同短音效。
