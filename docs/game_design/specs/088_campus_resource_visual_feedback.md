# 088 校园资源点视觉反馈

## 目标

让校园资源点在 2D 像素地图上更容易被识别，并在拾取时给玩家明确的即时正反馈。资源点不再只是同一种方块，而是能按资源类型表现为不同小图标；拾取后出现浮字，强化“探索有收获”的手感。

## 视觉规则

资源点使用自绘像素图标，不引入临时图片资源。首版由 `CampusInteractable` 承载绘制逻辑；在 [089_campus_marker_componentization.md](089_campus_marker_componentization.md) 后，绘制逻辑已迁移到 `CampusMapMarker`。

| 资源 | 地图图标语义 | 视觉目的 |
| --- | --- | --- |
| 草稿 | 纸张和短横线 | 让玩家一眼看出是可用于事件条件的材料 |
| 灵感 | 黄色灯泡/便签感 | 和文献、方向、想法类收益形成关联 |
| 数据 | 试管/样本瓶 | 和实验楼、实验数据流关联 |
| 经费 | 两枚金币/票据 | 和项目、设备维护、基金申请关联 |
| 方法论笔记 | 笔记本 | 和图书馆、材料积累关联 |

所有资源点都会保留：
- 深色底座。
- 资源主色。
- 小范围脉冲光晕。
- 地面阴影。

## 拾取反馈

收集资源时，校园层会在资源点位置生成浮字：

```text
+数量 资源名
```

示例：

```text
+2 草稿
+1 灵感
```

浮字规则：
- 出现在世界坐标中，会跟随地图镜头位置。
- 使用资源点主色的浅色版本。
- 带深色描边，避免和地图背景混在一起。
- 通过 Tween 向上漂浮并淡出。
- 动画结束后自动释放节点。

## 实现内容

更新：
- `scripts/overworld/campus_interactable.gd`
  - 为资源点增加 `_process()` 脉冲刷新。
  - 按 `resource_id` 绘制不同像素小图标。
  - 资源点被收集后停止 process，避免无意义刷新。
- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `feedback_root`，用于承载世界层拾取浮字。
  - 新增 `get_pickup_feedback_count()`，方便脚本验证。
  - `_collect_resource()` 在统一完成状态后调用 `_show_pickup_feedback()`。
  - `_show_pickup_feedback()` 使用 Tween 做向上淡出，并在结束后释放。

未改变：
- 资源数值不变。
- 资源收集完成状态不变。
- 战斗/事件资源注入与回写规则不变。
- 交互碰撞范围不变。

## 验证记录

验证环境：
- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

拾取反馈验证：

```text
count=10
initial_feedback_count=0
draft_process_before=true
collect_draft=true
draft_after_collect=2
draft_completed=true
feedback_after_collect=1
draft_visible_after=false
draft_process_after=false
start_canteen=true
active_node=E001
battle_draft_injected=2
show_draft_choice=true
draft_after_event=0
reputation_after_event=2
methodology_after_event=1
available_after_event=8
```

## 手测要点

1. 进入校园地图后观察资源点是否有轻微光晕脉冲。
2. `草稿提纲`、`灵感便签`、`实验数据`、`经费通知`、`方法论笔记` 应该能通过小图标区分。
3. 拾取资源时，资源点位置应出现 `+数量 资源名` 浮字。
4. 浮字应向上移动、逐渐透明，并自动消失。
5. 拾取后资源点仍应从地图上消失，HUD 和日志仍应更新。

## 下一步

1. 已完成：[089_campus_marker_componentization.md](089_campus_marker_componentization.md) 将资源点和 NPC/事件/Boss 图标统一为可复用的 `CampusMapMarker`。
2. 给 NPC/事件/Boss 也增加轻量状态差异，例如可战斗、已完成、剧情关键提示。
3. 开始做阶段化校园刷新：研一、研二、博一出现不同资源点和遭遇。
