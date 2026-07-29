# 102 校园引导图例

## 目标

在校园 HUD 中加入一行小图例，解释地图高亮颜色的含义：

- 青色：剧情目标。
- 金色：建议补给。

这一步承接 [097_campus_story_guidance.md](097_campus_story_guidance.md) 和 [101_campus_supply_hint_marker_highlight.md](101_campus_supply_hint_marker_highlight.md)。玩家看到 `下一步` 文案后，可以直接理解地图上的青色框和金色角标分别指向什么。

## UI 规则

- 图例显示在左上状态面板内，位于 `下一步` 文案下方。
- 图例包含两个像素色块和短标签：`剧情目标`、`建议补给`。
- 图例是固定说明，不根据当前阶段动态隐藏。
- 本功能只解释现有视觉语言，不改变剧情目标、补给点、条件拦截或资源回写规则。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `GUIDANCE_STORY_COLOR`、`GUIDANCE_SUPPLY_COLOR` 和 `GUIDANCE_LEGEND_TEXT`。
  - 新增 `get_guidance_legend_text()`，用于自动化验证和后续调试。
  - `_build_hud()` 在 `guidance_label` 后创建 `GuidanceLegend`。
  - `_build_guidance_legend()` 和 `_add_guidance_legend_item()` 负责创建色块与标签。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/overworld/campus_interactable.gd=0
```

场景实例验证：

```text
scene_reload=0
legend_text=青色=剧情目标；金色=建议补给点
legend_exists=true
legend_item_count=2
legend_item_0=剧情目标
legend_item_1=建议补给
guidance=下一步：会议室方向 · 中期考核 · B002（准备不足：数据 0/2、草稿 0/3；建议：前往复现数据包、归档草稿）
sources=2
```

## 手测重点

1. 运行校园地图，观察左上状态面板。
2. `下一步` 文案下方应显示一行图例。
3. 图例应包含青色色块 `剧情目标` 和金色色块 `建议补给`。
4. 切到 `研二` 后，图例仍显示，且 `B002` 青色高亮、`复现数据包/归档草稿` 金色高亮不受影响。

## 下一步

1. 已完成：靠近交互点时，底部提示会显示 `剧情目标` 或 `建议补给` 角色标签，见 [103_campus_focus_prompt_role_tags.md](103_campus_focus_prompt_role_tags.md)。
2. 后续如果加入独立小地图或全屏校园地图，可以复用同一套图例色值和标签。
3. 美术素材到位后，可把色块替换成正式像素图标，但保留 `剧情目标` / `建议补给` 的语义。
