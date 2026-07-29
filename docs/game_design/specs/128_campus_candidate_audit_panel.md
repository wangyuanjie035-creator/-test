# 128 候选地图审查面板

## 目标

承接 [127_campus_candidate_layout_weighting.md](127_campus_candidate_layout_weighting.md)，把候选地图调试信息从 tooltip 中提到左上 HUD 的“测试”区域，形成常驻小型审查面板。

这样测试候选池地图时，不需要悬停按钮也能看到当前 seed、生成来源、标签命中、路线保护和布局分布。后续反馈截图只要包含左上角，就能更容易复现问题。

## 面板内容

审查面板显示 5 行：

```text
Seed 1 · 研一 · 候选池地图
候选：pool=16,target=12,selected=12,missing=0,focus_hits=7/7
刷图：source=candidate,count=12,pool=16,target=12,selected=12,missing_routes=
路线：B001/E008 · 缺失无
布局：areas=宿舍1、图书馆4、实验楼1、校园中庭1、食堂2、导师办公室2、会议室1,unique=7,max=图书馆4,resources=7,avg_route_dist=416
```

字段含义：

- `Seed`：当前校园 seed。
- `候选`：123/124 的候选选择器审查。
- `刷图`：实际刷图来源和点位数量。
- `路线`：当前阶段需要保护的剧情路线，以及缺失路线。
- `布局`：127 的区域分布审查。

## 交互规则

- 面板位于左上 HUD 的“测试”区域按钮下方。
- 默认固定地图模式也显示审查信息，但字体颜色更弱。
- 打开 `候选池地图` 后，面板颜色变亮。
- 点击 `重随 Seed`、切换阶段、切换候选池地图，面板都会刷新。
- 战斗层中不会新增额外操作，面板仅作为校园 HUD 信息。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `generation_audit_label`。
  - 新增 `get_stage_spawn_audit_panel_text()`。
  - 新增 `get_generation_audit_panel_text()`，便于远程验证。
  - 新增 `_format_generation_audit_route_summary()`。
  - 新增 `_refresh_generation_audit_panel()`，接入 `_refresh_stage_debug_buttons()`。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
seed_changed=true
```

固定地图模式示例：

```text
Seed 1 · 研一 · 固定地图
候选：pool=16,target=12,selected=12,missing=0,focus_hits=7/7
刷图：source=fixed,count=12,pool=16,target=12,selected=12,missing_routes=
路线：B001/E008 · 缺失无
布局：areas=宿舍1、图书馆3、实验楼2、校园中庭2、食堂2、导师办公室1、会议室1,unique=7,max=图书馆3,resources=6,avg_route_dist=423
```

候选池地图模式示例：

```text
Seed 1 · 研一 · 候选池地图
候选：pool=16,target=12,selected=12,missing=0,focus_hits=7/7
刷图：source=candidate,count=12,pool=16,target=12,selected=12,missing_routes=
路线：B001/E008 · 缺失无
布局：areas=宿舍1、图书馆4、实验楼1、校园中庭1、食堂2、导师办公室2、会议室1,unique=7,max=图书馆4,resources=7,avg_route_dist=416
```

## 手测重点

1. 默认固定地图模式下，审查面板应显示 `固定地图` 和 `source=fixed`。
2. 打开 `候选池地图` 后，审查面板应显示 `候选池地图` 和 `source=candidate`。
3. 点击 `重随 Seed` 后，面板第一行 Seed 和布局行应刷新。
4. 切换阶段后，面板第一行阶段名和路线行应刷新。
5. `路线` 行应显示 `缺失无`；如果不是，应记录阶段和 Seed。
6. 面板不应遮挡右上任务视图、底部交互提示或地图移动区域。

## 下一步

1. 可以继续扩展每阶段候选池到 20 个以上，让标签和布局权重有更多选择空间。
2. 已完成“候选点视觉差异占位”，见 [129_campus_marker_visual_variety_placeholders.md](129_campus_marker_visual_variety_placeholders.md)。
