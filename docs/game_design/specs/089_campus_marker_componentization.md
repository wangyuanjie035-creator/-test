# 089 校园地图标记组件化

## 目标

把校园地图上的“可交互逻辑”和“地图标记视觉”拆开。`CampusInteractable` 继续负责碰撞、交互请求和完成状态；`CampusMapMarker` 负责像素图标、脉冲和不同交互类型的外观。这样后续做研一、研二、博一等阶段刷新时，可以复用同一套地图标记，而不需要在交互逻辑里继续堆绘制分支。

## 新结构

```text
CampusInteractable (Area2D)
├─ Marker (CampusMapMarker / Node2D)
└─ CollisionShape2D
```

职责划分：

| 节点 | 职责 |
| --- | --- |
| `CampusInteractable` | 交互 ID、显示名、交互类型、路线节点、资源数量、碰撞、完成状态、发出交互信号 |
| `CampusMapMarker` | 根据交互类型和资源 ID 绘制图标、资源点脉冲、完成后停止刷新 |

## 组件规则

- `CampusInteractable` 在 `_ready()` 中确保存在 `Marker` 和 `CollisionShape2D`。
- `_add_interactable()` 赋值后会调用 `refresh_marker()`，确保脚本测试和运行时都能同步视觉数据。
- `CampusMapMarker.configure_marker(kind, resource_id, color)` 接收视觉配置。
- `CampusMapMarker.set_completed(true)` 会隐藏 marker 并停止 process。
- 当前只有资源点需要脉冲刷新；事件、NPC、Boss 不 process，减少无意义刷新。

## 实现内容

新增：
- `scripts/overworld/campus_map_marker.gd`
  - 从 `CampusInteractable` 迁移原有 NPC、事件、Boss、资源点绘制逻辑。
  - 保留草稿、灵感、数据、经费、方法论笔记的分类像素图标。
  - 资源点未完成时进行轻微脉冲。

更新：
- `scripts/overworld/campus_interactable.gd`
  - 移除自绘和 `_process()` 脉冲逻辑。
  - 新增 `refresh_marker()`、`has_marker_component()`、`is_marker_processing()`、`get_marker_kind()`。
  - `mark_collected()` 同步完成状态到 marker。
- `scripts/overworld/campus_overworld_scene.gd`
  - 生成交互点时调用 `interactable.refresh_marker()`。

未改变：
- 交互 ID 不变。
- 碰撞范围不变。
- 资源数值不变。
- 拾取浮字不变。
- 校园资源带入战斗与回写规则不变。

## 验证记录

验证环境：
- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

组件与行为验证：

```text
count=10
marker_count=10
draft_marker_kind=resource
draft_marker_processing_before=true
event_marker_kind=event
event_marker_processing_before=false
collect_draft=true
draft_after_collect=2
draft_completed=true
feedback_after_collect=1
draft_marker_processing_after=false
draft_visible_after=false
start_canteen=true
battle_draft_injected=2
show_draft_choice=true
draft_after_event=0
reputation_after_event=2
available_after_event=8
```

## 手测要点

1. 进入校园地图，确认 NPC、事件、Boss 和资源点仍正常显示。
2. 靠近不同交互点时，底部提示仍显示正确摘要。
3. 资源点仍有轻微脉冲；事件、NPC、Boss 不需要脉冲。
4. 拾取 `草稿提纲` 后，资源点消失，浮字出现，HUD 显示草稿增加。
5. 进入 `食堂偶遇大牛`，确认草稿仍可带入事件并被消耗。

## 下一步

1. 已完成：[090_campus_marker_state_variants.md](090_campus_marker_state_variants.md) 给 `CampusMapMarker` 增加剧情关键、条件不足和 Boss 可挑战状态。
2. 开始做阶段化校园刷新，让不同学年阶段加载不同交互点池。
3. 把交互点定义迁移为数据表，减少 `_spawn_interactables()` 中的硬编码。
