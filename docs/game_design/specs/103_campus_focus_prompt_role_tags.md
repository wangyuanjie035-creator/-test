# 103 校园靠近提示角色标签

## 目标

让玩家靠近校园交互点时，底部提示同步说明该点在当前引导系统中的角色：

- `剧情目标`：当前剧情推进目标。
- `建议补给`：当前剧情目标材料不足时，推荐先拾取的资源点。

这一步承接 [102_campus_guidance_legend.md](102_campus_guidance_legend.md)。HUD 图例解释颜色含义，底部靠近提示解释当前交互点的用途，两者一起形成更明确的地图引导闭环。

## UI 规则

- 标签显示在底部交互提示文本最前方。
- 剧情目标提示格式：`剧情目标｜中期考核 路 B002｜准备不足：...`。
- 补给点提示格式：`建议补给｜复现数据包 +2`。
- 如果未来某个点同时是剧情目标和补给点，显示为 `剧情目标 / 建议补给｜...`。
- 标签不改变交互规则；材料不足、二次确认、硬拦截和资源拾取逻辑保持不变。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `FOCUS_TAG_STORY` 与 `FOCUS_TAG_SUPPLY`。
  - 新增 `get_interactable_focus_role_tag()`，用于自动化验证某个交互点的当前角色标签。
  - `_format_focused_interaction_prompt()` 在交互摘要前追加角色标签。
  - `_format_interactable_focus_role_tag()` 统一处理剧情目标、建议补给和双角色情况。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_map_marker.gd=0
```

场景实例验证：

```text
scene_reload=0
midterm_tag=剧情目标
data_pack_tag=建议补给
midterm_focus=剧情目标｜中期考核 路 B002｜准备不足：数据 0/2、草稿 0/3
data_pack_focus=建议补给｜复现数据包 +2
cleared_focus=校园中庭
```

## 手测重点

1. 运行校园地图并切到 `研二`。
2. 靠近 `B002 中期考核`，底部提示应以 `剧情目标｜` 开头。
3. 靠近 `复现数据包` 或 `归档草稿`，底部提示应以 `建议补给｜` 开头。
4. 离开交互范围后，底部提示应回到 `校园中庭`。
5. 对材料不足的关键节点，角色标签和 `准备不足` / `再次确认进入` 文案应能同时显示。

## 下一步

1. 已完成：玩家靠近交互点时，地图标记会显示像素聚焦反馈，见 [104_campus_marker_focus_feedback.md](104_campus_marker_focus_feedback.md)。
2. 后续美术素材替换时，可把角色标签、聚焦框与正式图标统一到同一套视觉规范中。
