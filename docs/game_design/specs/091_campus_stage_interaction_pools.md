# 091 校园阶段化交互池

## 目标

让同一张 2D 校园地图可以根据学业阶段刷新不同交互点。当前先做内容和系统规则，仍使用自绘占位图标；后续提供像素美术素材后，可以替换 `CampusMapMarker` 的视觉层，不需要重写交互、资源、战斗带入和回写逻辑。

## 阶段

| 阶段 ID | 显示名 | 当前定位 |
| --- | --- | --- |
| `master1` | 研一 | 入学、开题前探索、基础资源积累 |
| `master2` | 研二 | 中期、送审准备、转博窗口 |
| `doctor1` | 博一 | 问题链重构、资格考核、项目和基金压力 |

默认阶段仍为 `master1`，所以直接运行项目时不会改变原本研一校园流程。

## 公共接口

`CampusOverworldScene` 新增：

```gdscript
initialize_campus(seed: int = 1, stage: StringName = &"master1")
set_campus_stage(stage: StringName)
get_campus_stage() -> StringName
get_campus_stage_label() -> String
```

未知阶段会自动回退到 `master1`。

## 阶段交互池

### 研一：`master1`

保留原本首版校园内容：

```text
library_peer, lab_queue, canteen_scholar, advisor_drop_in, proposal_room,
library_notes, draft_outline, quad_inspiration, lab_data_sample, funding_notice
```

核心体验：在图书馆、宿舍、实验楼、食堂和导师办公室附近积累草稿、灵感、数据、经费，并进入开题 Boss。

### 研二：`master2`

新增：

| 交互 ID | 显示名 | 类型 | 路线/资源 |
| --- | --- | --- | --- |
| `data_cleaning_night` | 数据清洗夜 | 普通战斗 | `N009` |
| `submission_rehearsal` | 截稿前复盘 | 普通战斗 | `N004` |
| `replication_alarm` | 设备复现警报 | 事件 | `E003` |
| `transfer_office` | 转博申请窗口 | 事件 | `E005` |
| `midterm_room` | 中期考核 | Boss | `B002` |
| `blind_review_room` | 盲审专家 | Boss | `B003` |
| `replication_data_pack` | 复现数据包 | 资源 | 数据 +2 |
| `archived_draft_stack` | 归档草稿 | 资源 | 草稿 +2 |
| `review_reputation_note` | 送审口碑 | 资源 | 声望 +1 |
| `paper_fragments_pinboard` | 论文碎片墙 | 资源 | 论文碎片 +1 |

核心体验：围绕中期和送审材料准备，加入转博选择的地图入口。

### 博一：`doctor1`

新增：

| 交互 ID | 显示名 | 类型 | 路线/资源 |
| --- | --- | --- | --- |
| `doctoral_problem_chain` | 博一问题链重构 | 普通战斗 | `N005` |
| `project_pressure_board` | 项目推进压力 | 普通战斗 | `N006` |
| `funding_window` | 基金申请窗口 | 事件 | `E006` |
| `qualification_room` | 博士资格考核 | Boss | `B004` |
| `committee_notes` | 委员会沟通笔记 | 资源 | 方法论笔记 +2 |
| `paper_fragments_stack` | 论文主线碎片 | 资源 | 论文碎片 +1 |
| `project_funds_notice` | 项目经费通知 | 资源 | 经费 +2 |
| `longitudinal_data_pack` | 纵向实验数据 | 资源 | 数据 +2 |
| `doctoral_inspiration` | 博士问题灵感 | 资源 | 灵感 +1 |
| `draft_restructure` | 重构草稿 | 资源 | 草稿 +1 |

核心体验：博一从“做出一个硕士课题”转向“建立博士问题链和资格材料”。

## 美术替换说明

当前地图标记和资源图标都是 `CampusMapMarker` 的自绘占位视觉，作用是先把内容和系统跑通。

后续提供美术素材时，可以按以下方式替换：

- 如果是单张小图标：在 `CampusMapMarker` 中改为 `Sprite2D` 或 `Texture2D` 绘制。
- 如果是像素图集：给不同 `marker_kind`、`resource_id`、`marker_state` 配置 atlas 坐标。
- 如果有动态效果：资源脉冲可以换成 `AnimatedSprite2D` 或 Tween 控制的 Sprite。
- 不需要重写 `CampusInteractable`、阶段池、资源收集、战斗带入或回写。

## 实现内容

更新：
- `scripts/overworld/campus_overworld_scene.gd`
  - 新增阶段常量 `master1/master2/doctor1`。
  - `initialize_campus()` 增加阶段参数。
  - 新增 `set_campus_stage()`、`get_campus_stage()`、`get_campus_stage_label()`。
  - `_spawn_interactables()` 改为读取阶段交互池。
  - 新增研一、研二、博一三个交互池。
  - HUD 和日志显示当前阶段标签。

未改变：
- 默认仍是研一。
- 资源收集规则不变。
- 地图视觉占位不变。
- 进入战斗/事件的方式不变。
- 战斗层路线与结算规则不变。

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

阶段池验证：

```text
stage_master1=master1
label_master1=研一
count_master1=10
ids_master1=library_peer,lab_queue,canteen_scholar,advisor_drop_in,proposal_room,library_notes,draft_outline,quad_inspiration,lab_data_sample,funding_notice

stage_master2=master2
label_master2=研二
count_master2=10
ids_master2=data_cleaning_night,submission_rehearsal,replication_alarm,transfer_office,midterm_room,blind_review_room,replication_data_pack,archived_draft_stack,review_reputation_note,paper_fragments_pinboard

stage_doctor1=doctor1
label_doctor1=博一
count_doctor1=10
ids_doctor1=doctoral_problem_chain,project_pressure_board,funding_window,qualification_room,committee_notes,paper_fragments_stack,project_funds_notice,longitudinal_data_pack,doctoral_inspiration,draft_restructure

stage_unknown=master1
label_unknown=研一
count_unknown=10
```

路线入口验证：

```text
collect_master2_data=true
master2_data=2
start_midterm=true
midterm_active=B002

collect_doctor_funds=true
doctor_funds=2
start_qualification=true
qualification_active=B004
```

默认研一回归验证：

```text
default_stage=master1
default_label=研一
default_count=10
collect_draft=true
draft_after_collect=2
feedback_after_collect=1
start_canteen=true
battle_draft_injected=2
show_draft_choice=true
draft_after_event=0
reputation_after_event=2
methodology_after_event=1
available_after_event=8
```

## 手测要点

1. 默认运行项目仍应进入 `研一校园`。
2. 后续调试阶段切换时，HUD 应显示 `研二校园` 或 `博一校园`。
3. 研二阶段应出现 `中期考核`、`盲审专家`、`转博申请窗口`。
4. 博一阶段应出现 `博士资格考核`、`项目推进压力`、`基金申请窗口`。
5. 不同阶段资源点应给出不同资源组合，但拾取、浮字和 HUD 更新应保持一致。

## 下一步

1. 已完成：[092_campus_stage_debug_controls.md](092_campus_stage_debug_controls.md) 在校园 HUD 中增加阶段切换调试按钮。
2. 已完成：[093_campus_condition_locked_requirements.md](093_campus_condition_locked_requirements.md) 把 `condition_locked` 和真实条件检查绑定。
3. 已完成：[094_campus_data_resource_migration.md](094_campus_data_resource_migration.md) 把阶段交互池和条件表迁移成 Resource 数据。
