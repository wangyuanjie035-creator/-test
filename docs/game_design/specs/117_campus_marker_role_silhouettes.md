# 117 校园点位视觉角色差异

## 目标

承接 [116_campus_interactable_density_audit.md](116_campus_interactable_density_audit.md)，强化校园地图上不同交互类型的第一眼辨识度。当前每个阶段已经有 12 个点，如果 marker 只靠颜色和底部文字区分，玩家在探索时会更依赖 HUD，而不是直接阅读地图。

本步在 `CampusMapMarker` 的像素绘制层区分四类轮廓：学术交流、事件、Boss、补给点。后续替换美术素材时，可以直接按这四个视觉 profile 对应不同 sprite。

## 视觉规则

| 交互类型 | 视觉 profile | 轮廓意图 |
|---|---|---|
| `encounter` | `npc_scholar` | 带对话气泡的 NPC，表示学术交流或同门讨论 |
| `event` | `notice_board` | 公告/叹号板，表示需要阅读、选择或处理的事件 |
| `boss` | `challenge_gate` | 挑战门和冠形顶部，表示剧情 Boss 或关键考核 |
| `resource` | `resource_cache` | 带提手的补给箱，内部仍显示资源分类图标 |

## 实现记录

- [campus_map_marker.gd](../../../scripts/overworld/campus_map_marker.gd)
  - 新增 `VISUAL_PROFILE_NPC`、`VISUAL_PROFILE_NOTICE`、`VISUAL_PROFILE_ARENA`、`VISUAL_PROFILE_CACHE`。
  - 新增 `get_visual_profile()` 和 `get_visual_profile_summary()`。
  - `_draw_encounter()` 改为 NPC 轮廓，并增加 `_draw_speech_bubble()`。
  - `_draw_event()` 改为公告/叹号板。
  - `_draw_boss()` 改为挑战门和冠形顶部。
  - `_draw_resource()` 保持资源分类图标，同时强化为补给箱轮廓。
- [campus_interactable.gd](../../../scripts/overworld/campus_interactable.gd)
  - 新增 `get_marker_visual_profile()`。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `get_interactable_marker_visual_profile()` 和 `get_marker_visual_profile_summary()`。

## 验证记录

脚本加载：
```text
marker_reload=0
campus_reload=0
```

marker profile 映射：
```text
profile_encounter=encounter:npc_scholar
profile_event=event:notice_board
profile_boss=boss:challenge_gate
profile_resource=resource:resource_cache
```

阶段 profile 汇总：
```text
master1_profiles=challenge_gate=1,notice_board=2,npc_scholar=3,resource_cache=6
master2_profiles=challenge_gate=2,notice_board=2,npc_scholar=3,resource_cache=5
doctor1_profiles=challenge_gate=1,notice_board=1,npc_scholar=3,resource_cache=7
doctor2_profiles=challenge_gate=1,notice_board=1,npc_scholar=4,resource_cache=6
doctor3_profiles=challenge_gate=2,npc_scholar=3,resource_cache=7
doctor4_profiles=challenge_gate=1,notice_board=1,npc_scholar=3,resource_cache=7
```

点位密度回归仍通过：
```text
master1_density=count=12,min_spacing=70.3,building_hits=0,edge_hits=0
master2_density=count=12,min_spacing=67.3,building_hits=0,edge_hits=0
doctor1_density=count=12,min_spacing=96.3,building_hits=0,edge_hits=0
doctor2_density=count=12,min_spacing=61.3,building_hits=0,edge_hits=0
doctor3_density=count=12,min_spacing=78.7,building_hits=0,edge_hits=0
doctor4_density=count=12,min_spacing=85.8,building_hits=0,edge_hits=0
```

## 手测重点

1. 在校园地图上，学术交流点应能看出是 NPC，并有对话气泡。
2. 事件点应像公告/提示板，不应和普通 NPC 混淆。
3. Boss 点应比普通点更像挑战入口，并保留 Boss 可挑战外框。
4. 资源点应像补给箱，并继续显示草稿、灵感、数据、经费、方法论笔记等分类图标。
5. 剧情目标、补给建议、聚焦、返回摘要高亮仍应叠加在新轮廓上。

## 下一步

1. 已完成：校园点位靠近信息卡已显示类型、路线、收益和准备条件，见 [118_campus_focus_info_card.md](118_campus_focus_info_card.md)。
2. 可以继续做“校园 NPC 内容标签”：为导师、同门、设备、会议、补给等对象建立更明确的数据标签，方便后续素材替换和事件筛选。
