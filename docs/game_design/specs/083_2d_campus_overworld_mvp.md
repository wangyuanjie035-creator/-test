# 2D 校园地图 MVP v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [008_battle_test_ui.md](008_battle_test_ui.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md)
- [082_event_requirement_progress.md](082_event_requirement_progress.md)

## 目标

把游戏外层从纯卡牌测试 UI 扩展为：

```text
2D 像素校园探索
-> 地图 NPC / 地点遭遇
-> 学术交流回合制卡牌战
-> 获得资源、卡牌和路线推进
-> 剧情 Boss
```

卡牌构筑仍是战斗核心，但玩家的主要入口改为类似宝可梦的校园地图：在宿舍、图书馆、实验楼、食堂、导师办公室和会议室之间移动，与同学、师兄、导师或评审触发学术交流。

## 首版边界

本版本先做“地图壳 + 战斗入口”，不一次性引入复杂 TileSet、美术资源和完整地图随机生成。

已经实现：

- 2D 像素块风格校园地图。
- 玩家顶视角移动。
- 6 个半随机交互点。
- 普通遭遇、事件、Boss 和资源点四类交互。
- 地图交互进入现有卡牌战斗测试场景。
- 战斗层可返回校园地图。
- 项目主场景切换为 `scenes/campus_overworld_scene.tscn`。

暂未实现：

- 真正的 TileSet 地图编辑。
- 动画帧和正式像素角色素材。
- 战斗胜利后自动回到地图并移除 NPC。
- 校园地图与完整路线状态共享。
- 地图区域随学历阶段解锁。

## 场景结构

```text
CampusOverworldScene (Node2D)
├── World (Node2D)
│   ├── CampusMap (Node2D)
│   ├── BuildingLabels (Label nodes)
│   ├── Interactables (Node2D)
│   │   ├── library_peer
│   │   ├── lab_queue
│   │   ├── canteen_scholar
│   │   ├── advisor_drop_in
│   │   ├── proposal_room
│   │   └── library_notes
│   └── Player (CharacterBody2D)
│       └── CampusCamera (Camera2D)
├── HUDLayer (CanvasLayer)
│   └── CampusHUD (Control)
└── BattleLayer (CanvasLayer)
    ├── BattleTestScene
    └── ReturnToCampusButton
```

## 交互点

| ID | 类型 | 显示 | 进入节点 |
| --- | --- | --- | --- |
| `library_peer` | 普通学术交流 | 同门交流 | `N002 周会追问` |
| `lab_queue` | 普通学术交流 | 实验室排队 | `N003 设备排队` |
| `canteen_scholar` | 事件 | 食堂偶遇大牛 | `E001` |
| `advisor_drop_in` | 事件 | 导师临时约谈 | `E008` |
| `proposal_room` | Boss | 开题报告 | `B001` |
| `library_notes` | 资源点 | 方法论笔记 | `methodology_notes +1` |

交互点位置会根据 `campus_seed` 在一组校园点位中稳定洗牌。首版不是完整随机地图，但已经让地图遭遇具备 seed 差异。

## 实现内容

新增：

- `scenes/campus_overworld_scene.tscn`
- `scripts/overworld/campus_map_view.gd`
- `scripts/overworld/campus_player.gd`
- `scripts/overworld/campus_interactable.gd`
- `scripts/overworld/campus_overworld_scene.gd`

更新：

- `project.godot`
  - 主场景从 `res://scenes/battle_test_scene.tscn` 改为 `res://scenes/campus_overworld_scene.tscn`。

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
res://scripts/ui/battle_test_scene.gd=0
campus_scene_loaded=true
```

地图与交互验证：

```text
mode_initial=overworld
ids=library_peer,lab_queue,canteen_scholar,advisor_drop_in,proposal_room,library_notes
resource_before=0
collect_notes=true
resource_after=1
start_peer=true
mode_after_peer=battle
active_node_peer=N002
mode_after_return=overworld
start_event=true
active_node_event=E008
start_boss=true
active_node_boss=B001
```

## 手测要点

运行项目后应该先进入校园地图，而不是直接进入战斗测试 UI。

检查：

- 玩家是否能在校园地图上移动。
- 校园建筑是否能读出宿舍、图书馆、实验楼、食堂、导师办公室、会议室。
- 靠近 NPC 或资源点后，下方提示是否显示对应名称。
- 与普通 NPC 交互后是否进入卡牌战斗。
- 与导师/食堂事件交互后是否进入事件节点。
- 与会议室 Boss 交互后是否进入开题报告 Boss。
- 点击战斗层右上角 `返回校园` 后是否回到地图。

## 下一步

1. 战斗/事件结果回写校园地图已完成首版，见 [085_campus_battle_result_writeback.md](085_campus_battle_result_writeback.md)。
2. 地图上的 NPC 完成交互后会隐藏，避免同一个遭遇无限重复，见 [085_campus_battle_result_writeback.md](085_campus_battle_result_writeback.md)。
3. 将当前路线候选系统逐步转换成地图上的可见区域和 NPC 刷新。
4. 加入正式 TileSet 和像素角色动画，让美术风格从“程序色块”进入真正像素风。
