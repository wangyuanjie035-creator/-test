# 097 校园下一剧情节点引导

## 目标

在阶段化校园地图上给玩家明确的下一步提示。玩家进入或返回某个校园阶段后，地图会高亮当前阶段的下一剧情节点，HUD 会显示目标名称、路线 ID、粗略方位和材料不足提示。

这一步解决“阶段切换后不知道该去哪”的问题。本版实现时暂不改变交互规则；后续已升级为条件不足二次确认软拦截，见 [098_campus_condition_soft_gate.md](098_campus_condition_soft_gate.md)。

## 引导顺序

| 校园阶段 | 引导顺序 |
| --- | --- |
| `master1` 研一 | `B001 开题报告`，备用 `E008 导师临时约谈` |
| `master2` 研二 | `B002 中期考核 -> E005 转博申请 -> B003 盲审专家` |
| `doctor1` 博一 | `N005 博一问题链重构 -> B004 博士资格考核` |
| `doctor2` 博二 | `N006 项目推进压力 -> E006 基金申请窗口 -> B005 项目中期检查` |
| `doctor3` 博三 | `N007 预答辩筹备 -> B006 博士预答辩 -> B007 博士答辩` |
| `doctor4` 博四 | `E007 博四返修会 -> N008 返修长夜 -> B008 补答辩` |

如果顺序中的目标已完成或不在当前阶段交互池中，系统会查找下一个目标；如果都找不到，则回退到当前阶段第一个未完成的 `story_key` 或 `boss_available` 交互点。

## 视觉规则

- `CampusMapMarker` 新增独立的 `guidance_target` 叠层。
- 引导叠层不覆盖原有 `story_key`、`boss_available` 或 `condition_locked` 状态。
- 条件不足时，目标仍可以同时显示引导外框和 `condition_locked` 标记。
- HUD 状态面板新增一行 `下一步：...`，格式为：

```text
下一步：会议室方向 · 中期考核 · B002（准备不足：数据 0/2、草稿 0/3）
```

## 修改文件

- `scripts/overworld/campus_map_marker.gd`
  - 新增 `guidance_target` 状态。
  - 新增青色像素外框和箭头叠层。
  - 引导目标会参与轻微脉冲刷新。
- `scripts/overworld/campus_interactable.gd`
  - 新增 `guidance_target` 字段和 `set_guidance_target()`。
  - 地图标记刷新时把引导状态传给 `CampusMapMarker`。
- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 HUD 引导文本。
  - 新增阶段到剧情目标的顺序表。
  - 在阶段重置、资源拾取和战斗返回时刷新引导目标。
  - 新增只读验证接口：当前引导交互 ID、路线节点 ID、引导文本和交互是否被引导。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 脚本和场景验证使用 `ResourceLoader.CACHE_MODE_IGNORE`。

脚本编译验证：

```text
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

阶段初始引导验证：

```text
master1_target_route=B001
master1_guidance_text=下一步：会议室方向 · 开题报告 · B001
master2_target_route=B002
master2_guidance_text=下一步：会议室方向 · 中期考核 · B002（准备不足：数据 0/2、草稿 0/3）
doctor1_target_route=N005
doctor2_target_route=N006
doctor3_target_route=N007
doctor4_target_route=E007
```

完成节点后的引导验证：

```text
master2_after_b002_route=E005
master2_after_b002_text=下一步：导师办公室方向 · 转博申请窗口 · E005（准备不足：声望 0/2 或 草稿 0/4）
doctor1_after_n005_route=B004
doctor1_after_n005_text=下一步：会议室方向 · 博士资格考核 · B004（准备不足：方法论笔记 0/3 或 论文碎片 0/2）
doctor2_after_n006_route=E006
doctor2_after_e006_route=B005
doctor2_after_e006_marker=condition_locked
doctor2_after_e006_text=下一步：会议室方向 · 项目中期检查 · B005（准备不足：经费 0/2 或 论文碎片 0/2）
```

## 手测要点

1. 运行主场景后，HUD 状态面板应显示 `下一步：会议室方向 · 开题报告 · B001`。
2. 地图上的下一目标应有青色像素外框和箭头提示。
3. 切到 `研二` 后，引导应指向 `B002 中期考核`；完成中期后应指向 `E005 转博申请`。
4. 条件不足的下一目标应同时显示引导叠层和 `condition_locked` 标记。
5. 博士线阶段应按 `N005/B004`、`N006/E006/B005`、`N007/B006/B007`、`E007/N008/B008` 的顺序逐步更新。

## 下一步

1. 已完成：将条件不足的关键节点升级为二次确认软拦截，见 [098_campus_condition_soft_gate.md](098_campus_condition_soft_gate.md)。
2. 已完成：给 HUD 引导增加更具体的资源补足建议，见 [100_campus_guidance_supply_advice.md](100_campus_guidance_supply_advice.md)。
3. 后续美术素材到位后，把青色叠层替换为正式像素路标、门牌或地面箭头。
