# 129 候选点视觉差异占位

## 目标

承接 [128_campus_candidate_audit_panel.md](128_campus_candidate_audit_panel.md)，强化校园候选点在地图上的第一眼辨识度。

本步仍使用代码绘制的像素风占位图形，不引入外部美术素材。目标是先建立稳定的视觉 profile：后续替换正式像素素材时，可以按 profile 分类替换导师、同门、设备、补给、Boss 等图形。

## 视觉规则

marker 现在会读取运行时 `content_tags`，并基于交互类型、资源 ID 和标签推断视觉 profile。

### 学术交流点

| Profile | 触发标签 | 占位视觉 |
| --- | --- | --- |
| `advisor_npc` | `advisor` | 导师 NPC，带眼镜/讲义牌 |
| `peer_npc` | `peer`、`collaboration` | 双人同门剪影 |
| `lab_equipment` | `equipment`、`lab`、`data` | 设备台/仪器面板 |
| `library_stack` | `library`、`paper_fragments` | 书堆/资料架 |
| `committee_panel` | `committee`、`exam`、`defense` | 三人评审席 |
| `rest_corner` | `self_care`、`canteen` | 长椅/休息角 |
| `npc_scholar` | 其他 | 普通学术交流 NPC |

### 事件与 Boss

| Profile | 触发条件 | 占位视觉 |
| --- | --- | --- |
| `advisor_notice` | `advisor` 事件 | 导师便签公告 |
| `admin_notice` | `administration`、`campus_notice`、`funds` | 行政/通知公告 |
| `revision_notice` | `revision` | 返修红色标记 |
| `defense_gate` | `defense` Boss | 答辩门，带话筒/演示标记 |
| `committee_gate` | `committee`、`exam` Boss | 委员会门，带评审席标记 |
| `challenge_gate` | 其他 Boss | 通用挑战门 |

### 补给点

| Profile | 资源 ID | 占位视觉 |
| --- | --- | --- |
| `data_cache` | `data` | 数据瓶/样本 |
| `draft_cache` | `draft` | 草稿页 |
| `funds_cache` | `funds` | 经费票据 |
| `inspiration_cache` | `inspiration` | 灵感灯泡 |
| `notes_cache` | `methodology_notes`、`experience_lessons` | 方法/复盘本 |
| `paper_cache` | `paper_fragments` | 论文碎片 |
| `resource_cache` | 其他 | 通用补给箱 |

## 实现记录

- [campus_interactable.gd](../../../scripts/overworld/campus_interactable.gd)
  - `refresh_marker()` 现在把 `content_tags` 传给 `CampusMapMarker`。
- [campus_map_marker.gd](../../../scripts/overworld/campus_map_marker.gd)
  - 新增 `content_tags`。
  - 扩展 `get_visual_profile()`。
  - 新增导师、同门、设备、书堆、委员会、休息角、行政公告、返修公告、答辩门等占位绘制。
  - 补充 `paper_fragments` 和 `experience_lessons` 资源图标。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - `_add_interactable()` 在 `.tres` 未显式配置标签时，把现有推断标签写入运行时点位，保证 marker 和 HUD 使用同一套语义。

## 验证记录

远程 Godot 执行器验证：

```text
marker_reload=0
interactable_reload=0
scene_reload=0
```

候选池地图 profile 抽查：

```text
master1_profiles=admin_notice=1,advisor_notice=1,committee_gate=1,data_cache=1,draft_cache=1,inspiration_cache=1,notes_cache=2,paper_cache=1,peer_npc=2,resource_cache=1
doctor3_profiles=committee_panel=3,defense_gate=2,draft_cache=1,inspiration_cache=1,notice_board=1,paper_cache=3,resource_cache=1
doctor4_profiles=committee_panel=1,data_cache=1,defense_gate=1,draft_cache=2,inspiration_cache=2,peer_npc=2,rest_corner=1,revision_notice=2
```

## 手测重点

1. 打开 `候选池地图` 后，导师事件不应只像普通公告，应显示导师便签类标记。
2. 同门/合作点应能看到双人剪影。
3. 实验室/设备/数据类学术交流点应更像仪器或设备台。
4. 答辩/委员会 Boss 应和通用挑战门有区别。
5. 论文碎片、经验教训、方法论笔记等补给图标应不再全部是通用十字。
6. 靠近信息卡、任务视图、小地图和战斗入口行为不应改变。

## 下一步

1. 可以继续扩展每阶段候选池到 20 个以上，让新的视觉 profile 有更多出现机会。
2. “校园点位图例”已在 [130_campus_marker_profile_legend.md](130_campus_marker_profile_legend.md) 中接入，后续可以按该图例反推正式美术素材清单。
