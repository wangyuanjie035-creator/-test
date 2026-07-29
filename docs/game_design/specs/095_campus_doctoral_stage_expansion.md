# 095 博二博三博四校园阶段扩展

## 目标

在资源化校园阶段系统上继续扩展博士后半程地图：`博二 / 博三 / 博四`。这一步让校园探索覆盖博士线完整过程，从项目推进、中期检查、预答辩、博士答辩，到延毕后的补答辩返修。

## 新增阶段

| 阶段 | 数据文件 | 关键路线 | 资源倾向 |
| --- | --- | --- | --- |
| 博二 | `data/campus/stages/doctor2.tres` | `N006`、`E006`、`B005` | 经费、论文碎片、数据 |
| 博三 | `data/campus/stages/doctor3.tres` | `N007`、`N008`、`B006`、`B007` | 方法论笔记、论文碎片、声望 |
| 博四 | `data/campus/stages/doctor4.tres` | `E007`、`N008`、`B008` | 方法论笔记、论文碎片、声望 |

## 设计规则

- 每个阶段保持 10 个校园交互点，方便和研一、研二、博一比较。
- Boss 仍使用 `boss_available` 作为原始状态，材料不足时由条件表自动切换为 `condition_locked`。
- 每个阶段都至少提供一种能解开本阶段核心 Boss 条件的资源路径。
- 资源数量服务测试可达性，不代表最终平衡；后续可以在数值平衡阶段微调。

## 实现内容

新增：

- `data/campus/stages/doctor2.tres`
  - `项目推进压力`、`设备排期墙`、`合作数据会`
  - `基金申请窗口`、`项目中期检查`
  - 经费、论文碎片、数据、方法论资源点
- `data/campus/stages/doctor3.tres`
  - `预答辩筹备`、`答辩稿长夜`
  - `博士预答辩`、`博士答辩`
  - 方法论笔记、论文碎片、声望、草稿资源点
- `data/campus/stages/doctor4.tres`
  - `博四返修会`、`返修长夜`、`补答辩演练`
  - `补答辩`
  - 返修矩阵、修订稿碎片、补答辩背书等资源点

未改变：

- `CampusOverworldScene` 不需要新增阶段硬编码。
- `data/campus/route_requirements.tres` 中的 B005/B006/B007/B008 条件继续复用。
- 阶段调试按钮由 `sort_order` 自动排序；当前顺序为 `研一 / 研二 / 博一 / 博二 / 博三 / 博四`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/data/campus_resource_requirement_definition.gd=0
res://scripts/data/campus_requirement_group_definition.gd=0
res://scripts/data/campus_interaction_definition.gd=0
res://scripts/data/campus_stage_definition.gd=0
res://scripts/data/campus_route_requirement_definition.gd=0
res://scripts/data/campus_route_requirement_catalog_definition.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
```

阶段加载验证：

```text
stage_count=6
stage_keys=doctor1,doctor2,doctor3,doctor4,master1,master2
stage_doctor1_interactions=10
stage_doctor2_interactions=10
stage_doctor3_interactions=10
stage_doctor4_interactions=10
stage_master1_interactions=10
stage_master2_interactions=10
button_count=6
```

条件锁定验证：

```text
doctor2_project_midterm_room_req=经费 0/2 或 论文碎片 0/2
doctor3_predefense_room_req=论文碎片 0/3 或 声望 0/2
doctor3_defense_room_req=方法论笔记 0/4、论文碎片 0/4 或 方法论笔记 0/4、声望 0/2
doctor4_supplementary_defense_room_req=方法论笔记 0/3 或 论文碎片 0/2 或 声望 0/1
```

拾取解锁验证：

```text
doctor2_b005_initial=condition_locked
doctor2_funds=2
doctor2_b005_after_funds=boss_available
doctor3_b006_initial=condition_locked
doctor3_b007_initial=condition_locked
doctor3_methodology=4
doctor3_paper=4
doctor3_b006_after_materials=boss_available
doctor3_b007_after_materials=boss_available
doctor4_b008_initial=condition_locked
doctor4_reputation=1
doctor4_b008_after_rep=boss_available
```

## 手测要点

1. 运行主场景后，左上阶段按钮应显示 `研一 / 研二 / 博一 / 博二 / 博三 / 博四`。
2. 切到 `博二`，`项目中期检查` 应初始锁定；拾取 `经费批复` 后应恢复为 Boss 可挑战标记。
3. 切到 `博三`，`博士预答辩` 和 `博士答辩` 应初始锁定；拾取 `方法论总表`、`论文主线归档` 和 `终稿碎片` 后应恢复可挑战。
4. 切到 `博四`，`补答辩` 应初始锁定；拾取 `补答辩背书` 后应恢复可挑战。

## 下一步

1. 已完成：将阶段切换接入正式剧情推进，尤其是研二后的转博/不转博分支，见 [096_campus_story_stage_progression.md](096_campus_story_stage_progression.md)。
2. 给校园地图增加路线阶段入口提示，例如下一剧情 Boss 的方向标或地图高亮。
3. 后续美术素材到位后，将这些阶段交互点的临时标记替换为正式像素图标。
