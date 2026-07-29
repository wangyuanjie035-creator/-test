# 121 任务视图点位图形化

## 目标

承接 [120_campus_task_tracker_placeholder.md](120_campus_task_tracker_placeholder.md)，把右上任务视图里的“小地图摘要”升级为图形化点位图。首版不做可点击、不做缩放、不做完整建筑缩略，只用像素色块表达当前校园阶段的可互动点、主线目标、建议补给和玩家位置。

本步不改变校园点位生成、碰撞、资源、路线和战斗规则，只给 HUD 增加一个轻量绘制层。后续如果要做真正随机校园地图，可以继续复用本步的数据入口。

## 体验规则

- 点位图显示在右上任务视图内部，位于“点位图摘要”文字下方。
- 青色大点表示当前主线目标。
- 金色点表示建议补给。
- 红色点表示非当前主线的 Boss/考核点。
- 黄色点表示普通资源点。
- 紫色点表示校园事件。
- 蓝灰色点表示普通学术交流。
- 白色小方块表示玩家当前位置。
- 点位图随阶段切换、资源拾取、剧情目标刷新和玩家移动更新。
- 返回摘要出现时，任务视图和点位图一起临时隐藏；摘要结束后恢复。

## 实现记录

- [campus_task_tracker_minimap.gd](../../../scripts/overworld/campus_task_tracker_minimap.gd)
  - 新增 `CampusTaskTrackerMinimap` 自绘 `Control`。
  - `configure()` 接收地图边界、玩家位置和点位列表。
  - `_draw()` 绘制背景、网格、道路十字、点位、玩家和边框。
  - 新增 `get_point_count()`、`get_role_count()` 和 `get_marker_summary()`，用于验证。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `CAMPUS_TASK_TRACKER_MINIMAP` 预加载。
  - 新增 `HUD_TASK_TRACKER_MINIMAP_SIZE` 和 `task_tracker_minimap`。
  - `TaskTrackerPanel` 高度扩展到可容纳点位图。
  - `_build_task_tracker_panel()` 中加入 `MiniMap` 控件。
  - `_refresh_task_tracker_minimap()` 在 HUD 刷新和玩家移动时更新点位图。
  - 新增 `_get_task_tracker_minimap_entries()` 和 `_get_task_tracker_minimap_role()`。
  - 新增验证 getter：`get_task_tracker_minimap_rect()`、`get_task_tracker_minimap_point_count()` 和 `get_task_tracker_minimap_summary_text()`。

## 验证记录

脚本加载：

```text
campus_task_tracker_minimap.gd=0
campus_overworld_scene.gd=0
```

研二校园点位图：

```text
task_visible=true
task_summary=阶段：研二校园 · Seed 1|目标：会议室 · 中期考核 · B002 · 缺数据 0/2、草稿 0/3|点位图：主线会议室 · 补给2 · 剩余12|补给：前往复现数据包、归档草稿|进度：已处理 0/12 · 可互动 12
minimap_points=12
minimap_summary=story=1,supply=2,boss=1,resource=3,event=2,encounter=3,player=1
story_target=midterm_room
supply_ids=replication_data_pack,archived_draft_stack
```

返回摘要让位：

```text
task_during_summary=false
task_after_summary=true
minimap_after_summary=story=1,supply=2,boss=1,resource=3,event=2,encounter=3,player=1
```

拾取补给后的刷新：

```text
before=12|进度：已处理 0/12 · 可互动 12
after=11|进度：已处理 1/12 · 可互动 11|story=1,supply=1,boss=1,resource=3,event=2,encounter=3,player=1
```

## 手测重点

1. 进入研二校园时，右上任务视图应出现点位图，而不只是文本摘要。
2. 点位图中应有一个更醒目的青色主线点，对应 `B002 中期考核`。
3. 材料不足时，金色建议补给点应与地图上的建议补给高亮数量一致。
4. 拾取 `复现数据包` 后，点位图点数应减少，补给建议数量也应减少。
5. 玩家移动时，白色玩家方块应在点位图中移动。
6. 返回摘要出现时，点位图随任务视图隐藏；摘要消失后恢复。
7. 点位图不应拦截鼠标/键盘输入，不应影响地图移动、点位交互和左上调试按钮。

## 下一步

1. 已完成“标签驱动的地图生成草案”，见 [122_campus_tag_driven_generation_draft.md](122_campus_tag_driven_generation_draft.md)。
2. 可以继续做“标签驱动的候选池选择器”：根据阶段配方从交互候选池中稳定抽取 12 个点。
