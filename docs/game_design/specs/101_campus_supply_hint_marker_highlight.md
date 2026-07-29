# 101 校园补给点地图高亮

## 目标

把 [100_campus_guidance_supply_advice.md](100_campus_guidance_supply_advice.md) 中的文字建议同步到地图视觉上。玩家看到下一剧情目标时，也能在校园地图上看到当前建议补足资源点，形成“剧情目标点 + 补给点”的双引导。

## 视觉规则

- 剧情下一目标继续使用 `guidance_target` 的青色像素外框和箭头。
- 建议补给点使用新增 `supply_hint_target`，绘制金色像素角标和小十字。
- 两种高亮状态互不覆盖；如果未来某个点同时是剧情目标和补给点，会同时绘制。
- 已拾取资源点会隐藏，并自动退出补给高亮。
- 补给高亮只改变地图视觉，不改变 HUD 文案、条件拦截或资源规则。

## 刷新规则

- `_refresh_story_guidance()` 会同时清理旧的剧情目标和补给目标。
- 找到下一剧情目标后，先设置 `guidance_target`。
- 如果该目标材料不足，则根据当前补足建议找到对应的资源交互点，并设置 `supply_hint_target`。
- 补给点来源与 HUD 建议共用同一套资源查找逻辑，避免文字和地图指向不一致。
- 拾取资源、阶段重置、战斗返回和剧情推进都会触发刷新。

## 修改文件

- `scripts/overworld/campus_map_marker.gd`
  - 新增 `supply_hint_target` 状态。
  - 新增 `set_supply_hint_target()`。
  - 新增金色像素角标和小十字绘制。
- `scripts/overworld/campus_interactable.gd`
  - 新增 `supply_hint_target` 字段。
  - `refresh_marker()` 将补给高亮状态传给 `CampusMapMarker`。
  - 新增 `set_supply_hint_target()` 与 `is_supply_hint_target()`。
- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `get_supply_hint_target_interaction_ids()`，用于验证当前补给高亮点。
  - `_refresh_story_guidance()` 同步刷新剧情目标和补给目标。
  - 补足建议来源从名称列表扩展为交互点列表，HUD 与地图共用。

## 验证记录

验证环境：
- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 脚本和场景验证使用 `ResourceLoader.CACHE_MODE_IGNORE`。

脚本编译验证：

```text
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
```

补给高亮行为验证：

```text
master2_target=midterm_room
master2_sources=replication_data_pack,archived_draft_stack
master2_advice=建议：前往复现数据包、归档草稿
master2_after_data_sources=archived_draft_stack
master2_after_data_advice=建议：前往归档草稿
doctor1_target=qualification_room
doctor1_sources=committee_notes,paper_fragments_stack
```

## 手测要点

1. 运行主场景并切到 `研二`。
2. `B002 中期考核` 应保持青色剧情目标高亮。
3. `复现数据包` 和 `归档草稿` 应显示金色补给高亮。
4. 拾取 `复现数据包` 后，该点应消失，补给高亮只剩 `归档草稿`。
5. 完成 `N005` 后切到博一下一目标 `B004`，`委员会沟通笔记` 和 `论文主线碎片` 应显示补给高亮。
6. 资源满足后，补给高亮应消失。

## 下一步

1. 已完成：把补给高亮纳入校园 HUD 图例，让玩家知道青色与金色分别代表什么，见 [102_campus_guidance_legend.md](102_campus_guidance_legend.md)。
2. 后续可在小地图或独立地图面板中复用同一套高亮状态。
2. 后续可把补给建议改成路线句式，例如“先去复现数据包，再回会议室挑战中期考核”。
3. 美术素材到位后，把金色临时角标替换为正式像素路标、公告栏或 NPC 提醒。
