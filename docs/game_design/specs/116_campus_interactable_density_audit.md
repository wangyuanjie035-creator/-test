# 116 校园点位密度与避让审查

## 目标

承接 [115_campus_stage_interaction_variety_pack.md](115_campus_stage_interaction_variety_pack.md)，检查每个阶段扩展到 12 个校园点后的可读性和可交互性。新增点位让校园更丰富，但如果点位互相贴近、落进建筑内部或贴住地图边界，会影响 2D 像素地图的可读性。

本步在生成层加入轻量避让策略：数据表仍提供语义坐标，实际生成时根据 seed 做 jitter，再避开建筑安全区、地图边界和已放置点。

## 体验规则

- 每个阶段仍生成 12 个校园交互点。
- 交互点中心之间建议保持至少 `58px` 距离，避免 marker 和交互区域重叠。
- 交互点不应落入建筑矩形及其 `24px` 安全扩展区。
- 交互点不应贴住地图边界，生成时保留 `28px` 边界安全距。
- 主线剧情目标、Boss、补给建议和返回摘要联动规则不变。
- 数据表里的点位仍表示“语义位置”，例如办公室附近、食堂附近；避让只负责把它推到更适合显示和交互的位置。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `INTERACTABLE_MIN_SPACING`、`INTERACTABLE_BUILDING_CLEARANCE`、`INTERACTABLE_MAP_EDGE_CLEARANCE` 和 `INTERACTABLE_SPAWN_CANDIDATE_ATTEMPTS`。
  - `_spawn_interactables()` 记录已放置点，并通过 `_resolve_interactable_spawn_position()` 选择最终位置。
  - `_sanitize_interactable_spawn_position()` 会将点位推出建筑安全区，并限制在地图安全边界内。
  - `_score_interactable_spawn_position()` 会优先选择离语义坐标近、且不挤压已有点的位置。
  - 新增 `get_interactable_density_audit_summary()`、`get_interactable_min_spacing()`、`get_interactable_building_overlap_count()` 和 `get_interactable_edge_violation_count()`，用于自动验证。

## 验证记录

脚本加载：
```text
campus_reload=0
```

多阶段多 seed 验证：
```text
master1_seed_1=count=12,min_spacing=70.3,building_hits=0,edge_hits=0
master2_seed_1=count=12,min_spacing=67.3,building_hits=0,edge_hits=0
doctor1_seed_1=count=12,min_spacing=96.3,building_hits=0,edge_hits=0
doctor2_seed_1=count=12,min_spacing=61.3,building_hits=0,edge_hits=0
doctor3_seed_1=count=12,min_spacing=77.5,building_hits=0,edge_hits=0
doctor4_seed_1=count=12,min_spacing=85.8,building_hits=0,edge_hits=0

master1_seed_7=count=12,min_spacing=70.3,building_hits=0,edge_hits=0
master2_seed_7=count=12,min_spacing=67.3,building_hits=0,edge_hits=0
doctor1_seed_7=count=12,min_spacing=96.3,building_hits=0,edge_hits=0
doctor2_seed_7=count=12,min_spacing=61.3,building_hits=0,edge_hits=0
doctor3_seed_7=count=12,min_spacing=78.7,building_hits=0,edge_hits=0
doctor4_seed_7=count=12,min_spacing=85.8,building_hits=0,edge_hits=0

master1_seed_23=count=12,min_spacing=70.3,building_hits=0,edge_hits=0
master2_seed_23=count=12,min_spacing=67.3,building_hits=0,edge_hits=0
doctor1_seed_23=count=12,min_spacing=96.3,building_hits=0,edge_hits=0
doctor2_seed_23=count=12,min_spacing=61.3,building_hits=0,edge_hits=0
doctor3_seed_23=count=12,min_spacing=75.6,building_hits=0,edge_hits=0
doctor4_seed_23=count=12,min_spacing=85.8,building_hits=0,edge_hits=0
```

## 手测重点

1. 切换研一到博四，每个阶段都应保持 12 个可交互点。
2. 新增点不应画在建筑内部，也不应贴住地图边缘。
3. 多个点在同一区域时，玩家应能靠近并分别触发底部提示。
4. 换 seed 后，点位可有轻微随机感，但不应出现重叠或挤在建筑边。
5. 主线 HUD 下一步和方向箭头仍应指向原有剧情目标。

## 下一步

1. 已完成：校园点位视觉角色差异已强化 encounter/event/boss/resource 四类像素轮廓，见 [117_campus_marker_role_silhouettes.md](117_campus_marker_role_silhouettes.md)。
2. 也可以进入“校园小地图/任务栏占位”：在 HUD 安全区内增加轻量任务视图，为后续更大的随机校园做准备。
