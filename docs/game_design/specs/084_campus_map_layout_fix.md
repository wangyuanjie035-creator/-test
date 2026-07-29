# 校园地图尺寸与摄像机修正 v0.1

状态：已完成首版修正，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [083_2d_campus_overworld_mvp.md](083_2d_campus_overworld_mvp.md)

## 问题

首版校园地图在 1152x648 窗口下会露出大量灰色地图外区域。

原因：

- 地图尺寸只有 `960x640`，比常见运行窗口偏小。
- 玩家初始位置在左下角附近。
- `Camera2D` 跟随玩家居中，但没有设置地图边界。
- 摄像机 zoom 为 `1.15`，进一步放大了裁切感。

## 修正目标

让校园地图开局像一个完整的顶视角 RPG 场景：

- 开局视野完整落在地图内部。
- 摄像机移动时不轻易看到地图外灰底。
- 建筑分布更疏朗，校园空间更像可探索地图。
- 不影响 NPC、资源点和战斗入口。

## 实现内容

更新：

- `scripts/overworld/campus_map_view.gd`
  - 地图尺寸从 `960x640` 扩大到 `1600x960`。
  - 重新摆放宿舍、图书馆、实验楼、食堂、导师办公室和会议室。
  - 重新绘制主路、横向路径和上下连接路径。
  - 新增 `get_map_size()` 供摄像机设置边界。
- `scripts/overworld/campus_overworld_scene.gd`
  - 玩家初始位置改为 `Vector2(800, 536)`，靠近校园中庭。
  - `Camera2D.zoom` 改为 `Vector2.ONE`。
  - `Camera2D.limit_left/top/right/bottom` 设置为地图边界。
  - 建筑标签和交互点位置同步扩展到新地图。
  - 场景底色改为接近地图草地的深色，极端窗口下也不会出现突兀灰底。

未改变：

- 主场景仍为 `scenes/campus_overworld_scene.tscn`。
- 交互点数量仍为 6。
- 普通学术交流、事件、Boss 和资源点入口逻辑不变。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/overworld/campus_map_view.gd=0
res://scripts/overworld/campus_player.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
```

布局数值验证：

```text
map_size=(1600.0, 960.0)
player_start=(800.0, 536.0)
camera_zoom=(1.0, 1.0)
camera_limits=0,0,1600,960
initial_visible_rect=[P: (224.0, 212.0), S: (1152.0, 648.0)]
visible_inside_map=true
interactable_count=6
```

交互回归验证：

```text
mode_initial=overworld
collect_notes=true
notes=1
start_peer=true
mode_battle=battle
node_peer=N002
mode_return=overworld
start_boss=true
node_boss=B001
```

## 手测要点

运行项目后检查：

- 开局不应再看到大块地图外灰色区域。
- 视野应落在校园中庭附近。
- 移动时 Camera 应跟随玩家，但不会轻易滚出地图边界。
- 六个建筑区域应该比首版更分散，校园空间感更强。
- NPC、资源点和 Boss 入口仍能触发。

## 下一步

1. 继续做战斗/事件结果回写校园地图。
2. 在地图边界修好后，再考虑正式 TileSet 和像素角色动画。
