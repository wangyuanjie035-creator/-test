# 120 校园小地图/任务视图占位

## 目标

承接 [119_campus_content_tags.md](119_campus_content_tags.md)，在校园 HUD 中加入一个轻量“任务视图/小地图占位”。它不是最终小地图渲染，而是先把玩家探索时最需要扫读的信息放到右上角：当前阶段、主线目标、小地图摘要、补给建议和点位进度。

本步不改变校园移动、点位触发、战斗、资源、路线和条件拦截规则，只补一个常驻 HUD 信息层。后续做随机校园地图时，可以把“主线区域、补给数量、剩余点位”替换成真正的缩略点位图。

## 体验规则

- 任务视图位于右上角，左上状态/资源/目标/日志面板保持不变。
- 任务视图显示五行：阶段、目标、小地图摘要、补给建议、进度。
- 目标行优先显示当前剧情目标的区域、名称、路线 ID 和准备缺口。
- 补给行读取当前剧情目标的资源缺口，显示建议前往的补给点。
- 小地图摘要首版用文本占位：主线区域、补给高亮数量、剩余可互动点位数。
- 返回摘要出现时，任务视图临时隐藏；返回摘要结束后恢复。
- 面板只展示信息，`mouse_filter` 为 `IGNORE`，不应拦截地图输入。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `HUD_Z_TASK_TRACKER` 和 `HUD_TASK_TRACKER_PANEL_WIDTH`。
  - 新增 `TaskTrackerPanel`，锚定右上角。
  - 新增 `Stage/Objective/Map/Supply/Progress` 五个 Label。
  - 新增 `_build_task_tracker_panel()` 和 `_create_task_tracker_label()`。
  - `_refresh_hud()` 中新增 `_refresh_task_tracker_panel()`。
  - 新增 `_format_task_tracker_stage()`、`_format_task_tracker_objective()`、`_format_task_tracker_map()`、`_format_task_tracker_supply()` 和 `_format_task_tracker_progress()`。
  - 新增验证 getter：`get_task_tracker_panel_visible()`、`get_task_tracker_panel_rect()`、`get_task_tracker_summary_text()` 等。
  - 返回摘要显示时隐藏任务视图，摘要结束后恢复任务视图。

## 验证记录

脚本加载：

```text
campus_overworld_scene=0
```

研二校园任务视图：

```text
task_visible=true
task_summary=阶段：研二校园 · Seed 1|目标：会议室 · 中期考核 · B002 · 缺数据 0/2、草稿 0/3|小地图：主线会议室 · 补给2 · 剩余12|补给：前往复现数据包、归档草稿|进度：已处理 0/12 · 可互动 12
story_target=midterm_room
supply_ids=replication_data_pack,archived_draft_stack
```

HUD 层级与返回摘要让位：

```text
z_order=status=10,task=15,direction=20,prompt=30,summary=40
task_during_summary=false
summary_visible=true
task_after_summary=true
summary_after_finish=false
```

## 手测重点

1. 进入研二校园时，右上任务视图应显示 `中期考核 · B002`。
2. 当 `B002` 材料不足时，补给行应提示前往 `复现数据包、归档草稿`。
3. 切换不同阶段后，阶段名、主线目标和剩余点位数应刷新。
4. 拾取补给后，进度和补给建议应刷新。
5. 从战斗返回校园显示返回摘要时，任务视图应临时隐藏；摘要消失后恢复。
6. 任务视图不应遮住左上 HUD、底部交互提示、靠近信息卡和方向箭头。

## 下一步

1. 已完成“任务视图点位图形化”，见 [121_campus_task_tracker_minimap_points.md](121_campus_task_tracker_minimap_points.md)。
2. 可以继续做“标签驱动的地图生成草案”：按导师/同门/实验室/补给比例控制随机校园点位池。
