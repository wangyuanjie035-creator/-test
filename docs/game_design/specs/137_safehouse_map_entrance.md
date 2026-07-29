# 137 校园地图住屋入口

## 目标

把 [136_safehouse_campus_day_loop.md](136_safehouse_campus_day_loop.md) 中临时依赖 HUD 的“安全返回住屋”，推进成校园地图上的固定交互点。

当前规则：

- 每次从住屋出门生成校园地图时，宿舍区域旁都会出现 `住屋入口`。
- 入口使用 `CampusInteractable`，因此复用靠近、聚焦、确认键、小地图和信息卡逻辑。
- 入口不参与候选池抽取，不占用 12 个校园探索点位。
- 入口触发后保留当前资源和日志，并返回住屋。
- HUD 中的返回按钮保留为调试兜底，正式手测优先走地图入口。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `SAFEHOUSE_INTERACTION_ID`、`SAFEHOUSE_INTERACTION_KIND`、入口默认位置和颜色。
  - `_spawn_interactables()` 先保留住屋入口位置，再生成 12 个校园探索点，避免点位重叠。
  - 新增 `_add_safehouse_entrance_interactable()`。
  - `_start_interaction()` 识别 `safehouse` 类型，直接返回住屋，不进入战斗。
  - `get_available_interactable_ids()`、`get_interactable_ids()`、密度审查排除住屋入口，保持探索点统计稳定。
  - 聚焦信息卡显示“住屋入口 · 安全撤回”。
- [campus_map_marker.gd](../../../scripts/overworld/campus_map_marker.gd)
  - 新增 `safehouse_gate` profile。
  - 缺素材时绘制像素风宿舍/住屋门 fallback。
- [campus_task_tracker_minimap.gd](../../../scripts/overworld/campus_task_tracker_minimap.gd)
  - 新增 `safehouse` 小地图角色和绿色标记。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
marker_reload=0
minimap_reload=0
after_depart=mode=overworld,day=1,stage=master1,seed=101,theme=recovery_day,map=candidate
has_entrance=true
entrance_id=SAFEHOUSE_ENTRANCE
entrance_position=(210.0, 284.0)
exploration_count=12
spawn=source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=
profiles=advisor_notice=2,committee_gate=1,data_cache=2,draft_cache=1,inspiration_cache=2,notes_cache=1,paper_cache=1,peer_npc=1,resource_cache=1,safehouse_gate=1
start_entrance=true
after_entrance=mode=safehouse,day=1,stage=master1,seed=101,theme=recovery_day,map=candidate
safehouse_visible=true
```

## 手测重点

1. 在住屋选择主题并出门后，前往宿舍区域下方，应能看到住屋入口。
2. 靠近入口时，底部提示应显示“住屋入口｜安全返回住屋”。
3. 信息卡应显示入口类型、返回收益和“随时可以返回”。
4. 按确认键触发入口后，应返回住屋。
5. 左上候选池审查仍应保持 `count=12,pool=20,target=12,selected=12`。
6. 图例应包含 `住屋=门×1` 或 profile summary 中包含 `safehouse_gate=1`。

## 下一步

1. 住屋入口撤回转场已在 [138_safehouse_return_transition.md](138_safehouse_return_transition.md) 中完成。
2. 在住屋中加入休息、整理卡组、携带物选择等出门前准备。
3. 后续拿到美术素材后，用 `assets/campus/markers/safehouse_gate.png` 替换代码 fallback。
