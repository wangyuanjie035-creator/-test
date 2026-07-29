# 132 校园点位贴图 fallback

## 目标

承接 [131_campus_art_asset_replacement_checklist.md](131_campus_art_asset_replacement_checklist.md)，让 `CampusMapMarker` 支持正式像素素材接入：

- 优先读取 `res://assets/campus/markers/{profile}.png`。
- 如果 PNG 不存在，继续使用当前 `_draw()` 代码占位。
- 保留资源点脉冲、剧情目标、建议补给、条件不足、Boss 可挑战和聚焦框等覆盖层。

本步没有新增 PNG，也不创建空素材目录；当前项目仍全部走 fallback。

## 路径规则

profile 与贴图路径一一对应：

```text
advisor_npc -> res://assets/campus/markers/advisor_npc.png
defense_gate -> res://assets/campus/markers/defense_gate.png
paper_cache -> res://assets/campus/markers/paper_cache.png
```

贴图规格沿用 [131_campus_art_asset_replacement_checklist.md](131_campus_art_asset_replacement_checklist.md)：

- 静态 PNG，透明背景。
- 建议画布 `64x64`。
- 底部中心锚点 `(32, 52)`。
- Godot Import 使用 Lossless、Nearest、关闭 Mipmaps。

## 实现记录

- [campus_map_marker.gd](../../../scripts/overworld/campus_map_marker.gd)
  - 新增 `MARKER_TEXTURE_BASE_PATH`、`MARKER_TEXTURE_FRAME_SIZE`、`MARKER_TEXTURE_ANCHOR`。
  - `_ready()` 设置 `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`。
  - 新增 `_refresh_texture_cache()`、`_get_visual_profile_texture()`、`_load_profile_texture()`。
  - 新增 `_draw_marker_texture()`，有贴图时绘制贴图主体。
  - 缺图时保留原有 `_draw_resource()`、`_draw_boss()`、`_draw_event()`、`_draw_encounter()`。
  - 贴图主体绘制后仍调用 `_draw_state_overlay()`。
  - 新增调试接口：
    - `get_visual_texture_path()`
    - `has_visual_texture()`
    - `get_visual_texture_source_summary()`

## 绘制顺序

有贴图时：

1. 资源点先绘制脉冲底光；其他点位绘制地面阴影。
2. 绘制 `{profile}.png`。
3. 绘制状态覆盖层。

无贴图时：

1. 使用原有代码占位绘制主体。
2. 绘制状态覆盖层。

这样正式素材不会破坏已有玩法反馈；缺素材也不会导致点位消失。

## 验证记录

远程 Godot 执行器验证：

```text
marker_reload=0
profile=advisor_npc
texture_path=res://assets/campus/markers/advisor_npc.png
has_texture=false
texture_source=advisor_npc=fallback:res://assets/campus/markers/advisor_npc.png
scene_reload=0
spawn_summary=source=candidate,count=12,pool=16,target=12,selected=12,missing_routes=
profile_summary=admin_notice=1,advisor_notice=1,committee_gate=1,data_cache=1,draft_cache=1,inspiration_cache=1,notes_cache=2,paper_cache=1,peer_npc=2,resource_cache=1
legend_has_text=true
```

当前没有 PNG，因此验证重点是：

- 脚本可编译。
- 缺图时能正确报告 fallback。
- 候选池地图仍生成 12 个点位。
- profile 图例仍正常。

## 手测重点

当前无正式素材时：

1. 运行校园地图，视觉应和 131 前保持一致。
2. 打开 `候选池地图`，所有点位仍应出现。
3. 剧情目标、建议补给、条件不足、Boss 可挑战和聚焦框应继续显示。

未来导入 PNG 后：

1. 把 `advisor_npc.png` 放到 `assets/campus/markers/` 后，导师 NPC 应优先显示贴图。
2. 删除或改名该 PNG 后，导师 NPC 应回到代码占位 fallback。
3. 资源类贴图仍应有脉冲底光。
4. 贴图不应遮挡底部交互提示、右上任务视图和靠近信息卡。
5. 图例文字不需要变化，因为它仍基于 profile。

## 下一步

1. 可以创建一批临时测试 PNG，用来验证真实贴图分支、Import 设置和缩放锚点。
2. 每阶段候选池已在 [133_campus_candidate_pool_20_expansion.md](133_campus_candidate_pool_20_expansion.md) 扩展到 20 个，阶段主题权重已在 [134_campus_generation_theme_weighting.md](134_campus_generation_theme_weighting.md) 接入。
